import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../models/backup_model.dart';
import '../utils/encryption_helper.dart';
import 'storage_service.dart';
import 'session_service.dart';
import 'analytics_service.dart';
import 'gamification_service.dart';
import 'form_correction_storage_service.dart';

/// Service for backing up and restoring user data
class BackupService {
  static const String backupVersion = '1.0.0';
  static const String appVersion = '0.4.20'; // Update this with app version

  final StorageService _storageService;
  final SessionService _sessionService;
  final AnalyticsService _analyticsService;
  final GamificationService _gamificationService;
  final FormCorrectionStorageService _formCorrectionService;

  BackupService({
    required StorageService storageService,
    required SessionService sessionService,
    required AnalyticsService analyticsService,
    required GamificationService gamificationService,
    required FormCorrectionStorageService formCorrectionService,
  })  : _storageService = storageService,
        _sessionService = sessionService,
        _analyticsService = analyticsService,
        _gamificationService = gamificationService,
        _formCorrectionService = formCorrectionService;

  /// Export all user data to a backup file
  Future<ExportResult> exportAllData({String? password}) async {
    try {
      // Collect data from all services
      final data = await _collectAllData();

      // Create backup object
      final backup = BackupData(
        version: backupVersion,
        appVersion: appVersion,
        exportDate: DateTime.now(),
        encrypted: password != null && password.isNotEmpty,
        data: data,
        checksum: '', // Will be set after serialization
      );

      // Serialize to JSON
      var jsonString = json.encode(backup.toJson());

      // Generate checksum before encryption
      final checksum = EncryptionHelper.generateChecksum(jsonString);

      // Update backup with checksum
      final backupWithChecksum = BackupData(
        version: backup.version,
        appVersion: backup.appVersion,
        exportDate: backup.exportDate,
        encrypted: backup.encrypted,
        data: backup.data,
        checksum: checksum,
      );

      // Serialize again with checksum
      jsonString = json.encode(backupWithChecksum.toJson());

      // Encrypt if password provided
      if (password != null && password.isNotEmpty) {
        jsonString = EncryptionHelper.encryptData(jsonString, password);
      }

      // Generate backup file
      final filePath = await _saveBackupFile(jsonString);

      if (filePath == null) {
        return ExportResult.failure('Failed to save backup file');
      }

      final summary = backupWithChecksum.getSummary();

      return ExportResult.success(
        filePath: filePath,
        summary: summary,
      );
    } catch (e) {
      debugPrint('BackupService: Export failed: $e');
      return ExportResult.failure('Export failed: ${e.toString()}');
    }
  }

  /// Import data from backup file
  Future<ImportResult> importAllData(
    String filePath, {
    String? password,
    MergeStrategy? strategy,
  }) async {
    try {
      // Read backup file
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult.failure('Backup file not found');
      }

      var fileContent = await file.readAsString();

      // Decrypt if encrypted
      if (password != null && password.isNotEmpty) {
        try {
          fileContent = EncryptionHelper.decryptData(fileContent, password);
        } catch (e) {
          return ImportResult.failure(
            'Decryption failed - wrong password or corrupted file',
          );
        }
      }

      // Parse JSON
      final Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(fileContent) as Map<String, dynamic>;
      } catch (e) {
        return ImportResult.failure('Invalid backup file format');
      }

      // Create backup object
      final backup = BackupData.fromJson(jsonData);

      // Verify checksum
      final jsonForChecksum = json.encode({
        ...backup.toJson(),
        'checksum': '', // Exclude checksum field for verification
      });
      if (!EncryptionHelper.verifyChecksum(
        jsonForChecksum,
        backup.checksum,
      )) {
        debugPrint('BackupService: Checksum mismatch - file may be corrupted');
        // Continue anyway, just warn user
      }

      // Check version compatibility
      if (!backup.isCompatible(backupVersion)) {
        return ImportResult.failure(
          'Incompatible backup version: ${backup.version}',
        );
      }

      // Check if existing data exists
      final hasExistingData = await _hasExistingData();

      // Determine merge strategy
      MergeStrategy finalStrategy;
      if (!hasExistingData) {
        // No existing data, always replace
        finalStrategy = MergeStrategy.replaceAll;
      } else if (strategy != null) {
        // Strategy provided by caller
        finalStrategy = strategy;
      } else {
        // Need to ask user - return error indicating strategy needed
        return ImportResult.failure('STRATEGY_REQUIRED');
      }

      if (finalStrategy == MergeStrategy.cancel) {
        return ImportResult.failure('Import cancelled by user');
      }

      // Restore data to services
      await _restoreAllData(
        backup.data,
        strategy: finalStrategy,
      );

      final summary = backup.getSummary();

      return ImportResult.success(
        summary: summary,
        strategy: finalStrategy,
      );
    } catch (e) {
      debugPrint('BackupService: Import failed: $e');
      return ImportResult.failure('Import failed: ${e.toString()}');
    }
  }

  /// Preview backup contents without importing
  Future<BackupSummary?> previewBackup(
    String filePath, {
    String? password,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      var fileContent = await file.readAsString();

      // Decrypt if needed
      if (password != null && password.isNotEmpty) {
        try {
          fileContent = EncryptionHelper.decryptData(fileContent, password);
        } catch (e) {
          debugPrint('BackupService: Failed to decrypt for preview: $e');
          return null;
        }
      }

      final jsonData = json.decode(fileContent) as Map<String, dynamic>;
      final backup = BackupData.fromJson(jsonData);

      return backup.getSummary();
    } catch (e) {
      debugPrint('BackupService: Preview failed: $e');
      return null;
    }
  }

  /// Share backup file using system share dialog
  Future<bool> shareBackupFile(String filePath) async {
    try {
      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        subject: 'Workout Wizard Backup - ${DateTime.now().toLocal()}',
        text: 'My Workout Wizard backup file. Keep this safe to restore your progress!',
      );
      return true;
    } catch (e) {
      debugPrint('BackupService: Share failed: $e');
      return false;
    }
  }

  /// Collect all data from services
  Future<Map<String, dynamic>> _collectAllData() async {
    final data = <String, dynamic>{};

    // Session data (excluding fingerprint for privacy)
    data['session_data'] = await _sessionService.exportSessionData();

    // User profile
    final profile = await _storageService.getLastUserProfile();
    data['user_profile'] = profile?.toJson();

    // Favorites
    data['favorites'] = await _storageService.getFavorites();

    // Search history
    data['search_history'] = await _storageService.getSearchHistory();

    // Viewed programs
    data['viewed_programs'] = await _storageService.getViewedPrograms();

    // Completed programs
    data['completed_programs'] = await _storageService.getCompletedPrograms();

    // Analytics
    data['analytics'] = await _analyticsService.exportAnalytics();

    // Gamification
    data['gamification'] = await _gamificationService.exportGamificationData();

    // Form correction
    data['form_correction'] =
        await _formCorrectionService.exportData();

    return data;
  }

  /// Restore all data to services
  Future<void> _restoreAllData(
    Map<String, dynamic> data, {
    required MergeStrategy strategy,
  }) async {
    // Restore session data
    if (data.containsKey('session_data')) {
      await _sessionService.importSessionData(
        data['session_data'] as Map<String, dynamic>,
      );
    }

    // Restore based on strategy
    final merge = strategy == MergeStrategy.mergeIntelligently;

    // Restore storage data
    await _storageService.importData(data, merge: merge);

    // Restore analytics
    if (data.containsKey('analytics')) {
      await _analyticsService.importAnalytics(
        data['analytics'] as Map<String, dynamic>,
        merge: merge,
      );
    }

    // Restore gamification
    if (data.containsKey('gamification')) {
      await _gamificationService.importGamificationData(
        data['gamification'] as Map<String, dynamic>,
        merge: merge,
      );
    }

    // Restore form correction
    if (data.containsKey('form_correction')) {
      await _formCorrectionService.importData(
        data['form_correction'] as Map<String, dynamic>,
        merge: merge,
      );
    }
  }

  /// Save backup to file and return file path
  Future<String?> _saveBackupFile(String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(directory.path, 'backups'));

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'workout_wizard_backup_$timestamp.wwb';
      final filePath = path.join(backupDir.path, fileName);

      final file = File(filePath);
      await file.writeAsString(content, flush: true);

      return filePath;
    } catch (e) {
      debugPrint('BackupService: Failed to save backup file: $e');
      return null;
    }
  }

  /// Check if user has existing data
  Future<bool> _hasExistingData() async {
    final favorites = await _storageService.getFavorites();
    final searchHistory = await _storageService.getSearchHistory();
    final profile = await _storageService.getLastUserProfile();

    return favorites.isNotEmpty ||
        searchHistory.isNotEmpty ||
        profile != null;
  }

  /// Delete old backup files (keep last N backups)
  Future<void> cleanOldBackups({int keepCount = 5}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(directory.path, 'backups'));

      if (!await backupDir.exists()) {
        return;
      }

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.wwb'))
          .cast<File>()
          .toList();

      if (files.length <= keepCount) {
        return;
      }

      // Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Delete old files
      for (var i = keepCount; i < files.length; i++) {
        await files[i].delete();
      }

      debugPrint('BackupService: Cleaned ${files.length - keepCount} old backup files');
    } catch (e) {
      debugPrint('BackupService: Failed to clean old backups: $e');
    }
  }
}
