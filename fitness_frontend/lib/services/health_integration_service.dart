import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:health/health.dart';
import 'package:uuid/uuid.dart';
import '../models/health_data.dart';

/// Service for integrating with Apple Health and Google Fit
class HealthIntegrationService {
  static final HealthIntegrationService _instance = HealthIntegrationService._internal();
  factory HealthIntegrationService() => _instance;
  HealthIntegrationService._internal();

  static const String _configBoxName = 'health_sync_config';
  static const String _dataBoxName = 'health_data_records';
  static const String _historyBoxName = 'health_sync_history';

  final Uuid _uuid = const Uuid();
  Health? _health;

  /// Supported health data types
  final List<HealthDataType> _dataTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
  ];

  /// Initialize Hive boxes and Health plugin
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_configBoxName)) {
        await Hive.openBox<HealthSyncConfig>(_configBoxName);
      }
      if (!Hive.isBoxOpen(_dataBoxName)) {
        await Hive.openBox<HealthDataRecord>(_dataBoxName);
      }
      if (!Hive.isBoxOpen(_historyBoxName)) {
        await Hive.openBox<HealthSyncHistory>(_historyBoxName);
      }

      _health = Health();

      // Create default config if none exists
      final config = getSyncConfig();
      if (config == null) {
        await _createDefaultConfig();
      }

      debugPrint('HealthIntegrationService: Initialized');
    } catch (e) {
      debugPrint('HealthIntegrationService: Error initializing: $e');
      rethrow;
    }
  }

  /// Get sync configuration
  HealthSyncConfig? getSyncConfig() {
    try {
      final box = Hive.box<HealthSyncConfig>(_configBoxName);
      return box.get('config');
    } catch (e) {
      debugPrint('HealthIntegrationService: Error getting config: $e');
      return null;
    }
  }

  /// Update sync configuration
  Future<void> updateSyncConfig(HealthSyncConfig config) async {
    try {
      final box = Hive.box<HealthSyncConfig>(_configBoxName);
      await box.put('config', config);
      debugPrint('HealthIntegrationService: Config updated');
    } catch (e) {
      debugPrint('HealthIntegrationService: Error updating config: $e');
      rethrow;
    }
  }

  /// Create default configuration
  Future<void> _createDefaultConfig() async {
    final platform = Platform.isIOS ? 'apple_health' : 'google_fit';
    final config = HealthSyncConfig(
      id: _uuid.v4(),
      lastSyncTime: DateTime.now(),
      platform: platform,
    );
    await updateSyncConfig(config);
  }

  /// Request health permissions
  Future<bool> requestPermissions() async {
    try {
      if (_health == null) {
        throw Exception('Health plugin not initialized');
      }

      final permissions = _dataTypes.map((type) => HealthDataAccess.READ_WRITE).toList();

      final granted = await _health!.requestAuthorization(_dataTypes, permissions: permissions);

      if (granted) {
        debugPrint('HealthIntegrationService: Permissions granted');

        // Enable sync after permissions granted
        final config = getSyncConfig();
        if (config != null) {
          await updateSyncConfig(config.copyWith(isEnabled: true));
        }
      }

      return granted;
    } catch (e) {
      debugPrint('HealthIntegrationService: Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if health integration is available
  Future<bool> isAvailable() async {
    try {
      if (_health == null) return false;

      // Health integration is only available on iOS and Android
      if (!Platform.isIOS && !Platform.isAndroid) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('HealthIntegrationService: Error checking availability: $e');
      return false;
    }
  }

  /// Export workout to health app
  Future<bool> exportWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required int caloriesBurned,
    String workoutType = 'STRENGTH_TRAINING',
  }) async {
    try {
      final config = getSyncConfig();
      if (config == null || !config.isEnabled || !config.syncWorkouts) {
        debugPrint('HealthIntegrationService: Workout sync disabled');
        return false;
      }

      if (_health == null) {
        throw Exception('Health plugin not initialized');
      }

      // Write workout data
      final success = await _health!.writeWorkoutData(
        HealthWorkoutActivityType.STRENGTH_TRAINING,
        startTime,
        endTime,
        totalEnergyBurned: caloriesBurned,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );

      if (success) {
        debugPrint('HealthIntegrationService: Workout exported successfully');

        // Update last sync time
        await updateSyncConfig(config.copyWith(lastSyncTime: DateTime.now()));

        // Record sync history
        await _addSyncHistory(
          syncType: 'export',
          recordsProcessed: 1,
          recordsByType: {'workout': 1},
        );
      }

      return success;
    } catch (e) {
      debugPrint('HealthIntegrationService: Error exporting workout: $e');
      await _addSyncHistory(
        syncType: 'export',
        recordsProcessed: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Import heart rate data
  Future<List<HealthDataRecord>> importHeartRate({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final config = getSyncConfig();
      if (config == null || !config.isEnabled || !config.syncHeartRate) {
        return [];
      }

      if (_health == null) {
        throw Exception('Health plugin not initialized');
      }

      final end = endTime ?? DateTime.now();
      final start = startTime ?? end.subtract(const Duration(days: 7));

      final healthData = await _health!.getHealthDataFromTypes(
        start,
        end,
        [HealthDataType.HEART_RATE],
      );

      final records = <HealthDataRecord>[];
      for (var data in healthData) {
        final record = HealthDataRecord(
          id: _uuid.v4(),
          type: 'heart_rate',
          value: data.value.toDouble(),
          unit: data.unit.name,
          timestamp: data.dateFrom,
          endTime: data.dateTo,
          source: config.platform,
          metadata: {
            'sourceName': data.sourceName,
            'sourceId': data.sourceId,
          },
        );
        records.add(record);

        // Save to local storage
        await _saveHealthRecord(record);
      }

      debugPrint('HealthIntegrationService: Imported ${records.length} heart rate records');

      // Update last sync time
      await updateSyncConfig(config.copyWith(lastSyncTime: DateTime.now()));

      // Record sync history
      await _addSyncHistory(
        syncType: 'import',
        recordsProcessed: records.length,
        recordsByType: {'heart_rate': records.length},
      );

      return records;
    } catch (e) {
      debugPrint('HealthIntegrationService: Error importing heart rate: $e');
      await _addSyncHistory(
        syncType: 'import',
        recordsProcessed: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Import steps data
  Future<List<HealthDataRecord>> importSteps({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final config = getSyncConfig();
      if (config == null || !config.isEnabled || !config.syncSteps) {
        return [];
      }

      if (_health == null) {
        throw Exception('Health plugin not initialized');
      }

      final end = endTime ?? DateTime.now();
      final start = startTime ?? end.subtract(const Duration(days: 7));

      final healthData = await _health!.getHealthDataFromTypes(
        start,
        end,
        [HealthDataType.STEPS],
      );

      final records = <HealthDataRecord>[];
      for (var data in healthData) {
        final record = HealthDataRecord(
          id: _uuid.v4(),
          type: 'steps',
          value: data.value.toDouble(),
          unit: data.unit.name,
          timestamp: data.dateFrom,
          endTime: data.dateTo,
          source: config.platform,
          metadata: {
            'sourceName': data.sourceName,
            'sourceId': data.sourceId,
          },
        );
        records.add(record);

        // Save to local storage
        await _saveHealthRecord(record);
      }

      debugPrint('HealthIntegrationService: Imported ${records.length} steps records');

      // Update last sync time
      await updateSyncConfig(config.copyWith(lastSyncTime: DateTime.now()));

      // Record sync history
      await _addSyncHistory(
        syncType: 'import',
        recordsProcessed: records.length,
        recordsByType: {'steps': records.length},
      );

      return records;
    } catch (e) {
      debugPrint('HealthIntegrationService: Error importing steps: $e');
      await _addSyncHistory(
        syncType: 'import',
        recordsProcessed: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Perform full sync (import and export)
  Future<Map<String, dynamic>> performFullSync() async {
    try {
      final config = getSyncConfig();
      if (config == null || !config.isEnabled) {
        throw Exception('Health sync not enabled');
      }

      final results = <String, dynamic>{
        'heartRate': 0,
        'steps': 0,
        'success': true,
      };

      // Import heart rate data from last 7 days
      if (config.syncHeartRate) {
        final hrRecords = await importHeartRate();
        results['heartRate'] = hrRecords.length;
      }

      // Import steps data from last 7 days
      if (config.syncSteps) {
        final stepsRecords = await importSteps();
        results['steps'] = stepsRecords.length;
      }

      debugPrint('HealthIntegrationService: Full sync completed');
      return results;
    } catch (e) {
      debugPrint('HealthIntegrationService: Error performing full sync: $e');
      return {
        'heartRate': 0,
        'steps': 0,
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Save health record to local storage
  Future<void> _saveHealthRecord(HealthDataRecord record) async {
    try {
      final box = Hive.box<HealthDataRecord>(_dataBoxName);
      await box.put(record.id, record);
    } catch (e) {
      debugPrint('HealthIntegrationService: Error saving record: $e');
    }
  }

  /// Get stored health records
  List<HealthDataRecord> getHealthRecords({
    String? type,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    try {
      final box = Hive.box<HealthDataRecord>(_dataBoxName);
      var records = box.values.toList();

      if (type != null) {
        records = records.where((r) => r.type == type).toList();
      }

      if (startTime != null) {
        records = records.where((r) => r.timestamp.isAfter(startTime)).toList();
      }

      if (endTime != null) {
        records = records.where((r) => r.timestamp.isBefore(endTime)).toList();
      }

      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (e) {
      debugPrint('HealthIntegrationService: Error getting records: $e');
      return [];
    }
  }

  /// Add sync history entry
  Future<void> _addSyncHistory({
    required String syncType,
    required int recordsProcessed,
    bool success = true,
    String? errorMessage,
    Map<String, int>? recordsByType,
  }) async {
    try {
      final history = HealthSyncHistory(
        id: _uuid.v4(),
        syncTime: DateTime.now(),
        syncType: syncType,
        recordsProcessed: recordsProcessed,
        success: success,
        errorMessage: errorMessage,
        recordsByType: recordsByType,
      );

      final box = Hive.box<HealthSyncHistory>(_historyBoxName);
      await box.put(history.id, history);

      // Keep only last 100 sync history entries
      if (box.length > 100) {
        final keys = box.keys.toList();
        for (var i = 0; i < box.length - 100; i++) {
          await box.delete(keys[i]);
        }
      }
    } catch (e) {
      debugPrint('HealthIntegrationService: Error adding sync history: $e');
    }
  }

  /// Get sync history
  List<HealthSyncHistory> getSyncHistory({int limit = 20}) {
    try {
      final box = Hive.box<HealthSyncHistory>(_historyBoxName);
      final history = box.values.toList()
        ..sort((a, b) => b.syncTime.compareTo(a.syncTime));

      return history.take(limit).toList();
    } catch (e) {
      debugPrint('HealthIntegrationService: Error getting sync history: $e');
      return [];
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    try {
      final config = getSyncConfig();
      final records = getHealthRecords();
      final history = getSyncHistory();

      final hrRecords = records.where((r) => r.type == 'heart_rate').length;
      final stepsRecords = records.where((r) => r.type == 'steps').length;
      final successfulSyncs = history.where((h) => h.success).length;
      final failedSyncs = history.where((h) => !h.success).length;

      return {
        'isEnabled': config?.isEnabled ?? false,
        'lastSyncTime': config?.lastSyncTime,
        'platform': config?.platform,
        'totalRecords': records.length,
        'heartRateRecords': hrRecords,
        'stepsRecords': stepsRecords,
        'totalSyncs': history.length,
        'successfulSyncs': successfulSyncs,
        'failedSyncs': failedSyncs,
      };
    } catch (e) {
      debugPrint('HealthIntegrationService: Error getting stats: $e');
      return {
        'isEnabled': false,
        'totalRecords': 0,
        'heartRateRecords': 0,
        'stepsRecords': 0,
        'totalSyncs': 0,
        'successfulSyncs': 0,
        'failedSyncs': 0,
      };
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await Hive.box<HealthSyncConfig>(_configBoxName).clear();
      await Hive.box<HealthDataRecord>(_dataBoxName).clear();
      await Hive.box<HealthSyncHistory>(_historyBoxName).clear();
      debugPrint('HealthIntegrationService: All data cleared');
    } catch (e) {
      debugPrint('HealthIntegrationService: Error clearing data: $e');
      rethrow;
    }
  }
}
