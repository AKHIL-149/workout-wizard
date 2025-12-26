import 'package:flutter/foundation.dart';

/// Backup data model containing all user data for export/import
class BackupData {
  final String version;
  final String appVersion;
  final DateTime exportDate;
  final bool encrypted;
  final Map<String, dynamic> data;
  final String checksum;

  const BackupData({
    required this.version,
    required this.appVersion,
    required this.exportDate,
    required this.encrypted,
    required this.data,
    required this.checksum,
  });

  /// Convert to JSON for file export
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'app_version': appVersion,
      'export_date': exportDate.toIso8601String(),
      'encrypted': encrypted,
      'data': data,
      'checksum': checksum,
    };
  }

  /// Create from JSON for file import
  factory BackupData.fromJson(Map<String, dynamic> json) {
    try {
      return BackupData(
        version: json['version'] as String,
        appVersion: json['app_version'] as String? ?? 'unknown',
        exportDate: DateTime.parse(json['export_date'] as String),
        encrypted: json['encrypted'] as bool? ?? false,
        data: Map<String, dynamic>.from(json['data'] as Map),
        checksum: json['checksum'] as String,
      );
    } catch (e) {
      debugPrint('BackupData: Failed to parse backup: $e');
      throw FormatException('Invalid backup file format');
    }
  }

  /// Check if backup version is compatible with current app
  bool isCompatible(String currentVersion) {
    // For now, accept any version (can add version checks later)
    // Format: major.minor.patch (e.g., "1.0.0")
    return version.isNotEmpty;
  }

  /// Get summary of backup contents
  BackupSummary getSummary() {
    final sessionData = data['session_data'] as Map<String, dynamic>?;
    final userProfile = data['user_profile'] as Map<String, dynamic>?;
    final favorites = data['favorites'] as List?;
    final searchHistory = data['search_history'] as List?;
    final gamification = data['gamification'] as Map<String, dynamic>?;
    final formCorrection = data['form_correction'] as Map<String, dynamic>?;

    return BackupSummary(
      exportDate: exportDate,
      sessionCount: sessionData?['session_count'] as int? ?? 0,
      hasProfile: userProfile != null,
      favoritesCount: favorites?.length ?? 0,
      searchHistoryCount: searchHistory?.length ?? 0,
      currentStreak: gamification?['current_streak'] as int? ?? 0,
      achievementsCount: (gamification?['achievements'] as List?)?.length ?? 0,
      formSessionsCount: (formCorrection?['sessions'] as List?)?.length ?? 0,
      totalSizeBytes: toJson().toString().length,
    );
  }
}

/// Summary of backup contents for user preview
class BackupSummary {
  final DateTime exportDate;
  final int sessionCount;
  final bool hasProfile;
  final int favoritesCount;
  final int searchHistoryCount;
  final int currentStreak;
  final int achievementsCount;
  final int formSessionsCount;
  final int totalSizeBytes;

  const BackupSummary({
    required this.exportDate,
    required this.sessionCount,
    required this.hasProfile,
    required this.favoritesCount,
    required this.searchHistoryCount,
    required this.currentStreak,
    required this.achievementsCount,
    required this.formSessionsCount,
    required this.totalSizeBytes,
  });

  /// Get human-readable size
  String get humanReadableSize {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if backup has significant data
  bool get hasSignificantData {
    return favoritesCount > 0 ||
        searchHistoryCount > 0 ||
        currentStreak > 0 ||
        achievementsCount > 0 ||
        formSessionsCount > 0;
  }

  /// Get summary text for display
  String getSummaryText() {
    final buffer = StringBuffer();
    buffer.writeln('Exported: ${exportDate.toLocal()}');
    buffer.writeln('Sessions: $sessionCount');
    if (hasProfile) buffer.writeln('Profile: Yes');
    if (favoritesCount > 0) buffer.writeln('Favorites: $favoritesCount');
    if (searchHistoryCount > 0) {
      buffer.writeln('Search History: $searchHistoryCount items');
    }
    if (currentStreak > 0) buffer.writeln('Current Streak: $currentStreak days');
    if (achievementsCount > 0) {
      buffer.writeln('Achievements: $achievementsCount');
    }
    if (formSessionsCount > 0) {
      buffer.writeln('Form Correction Sessions: $formSessionsCount');
    }
    buffer.writeln('Size: $humanReadableSize');
    return buffer.toString();
  }
}

/// Merge strategy for importing data when existing data is present
enum MergeStrategy {
  /// Replace all current data with backup data
  replaceAll,

  /// Intelligently merge backup with current data
  mergeIntelligently,

  /// Cancel import operation
  cancel;

  String get displayName {
    switch (this) {
      case MergeStrategy.replaceAll:
        return 'Replace All';
      case MergeStrategy.mergeIntelligently:
        return 'Merge Intelligently';
      case MergeStrategy.cancel:
        return 'Cancel';
    }
  }

  String get description {
    switch (this) {
      case MergeStrategy.replaceAll:
        return 'Discard all current data and use backup data';
      case MergeStrategy.mergeIntelligently:
        return 'Combine backup with current data (favorites, achievements, etc.)';
      case MergeStrategy.cancel:
        return 'Abort import and keep current data';
    }
  }
}

/// Result of import operation
class ImportResult {
  final bool success;
  final String? errorMessage;
  final BackupSummary? summary;
  final MergeStrategy? strategyUsed;

  const ImportResult({
    required this.success,
    this.errorMessage,
    this.summary,
    this.strategyUsed,
  });

  factory ImportResult.success({
    required BackupSummary summary,
    MergeStrategy? strategy,
  }) {
    return ImportResult(
      success: true,
      summary: summary,
      strategyUsed: strategy,
    );
  }

  factory ImportResult.failure(String error) {
    return ImportResult(
      success: false,
      errorMessage: error,
    );
  }
}

/// Result of export operation
class ExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final BackupSummary? summary;

  const ExportResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    this.summary,
  });

  factory ExportResult.success({
    required String filePath,
    required BackupSummary summary,
  }) {
    return ExportResult(
      success: true,
      filePath: filePath,
      summary: summary,
    );
  }

  factory ExportResult.failure(String error) {
    return ExportResult(
      success: false,
      errorMessage: error,
    );
  }
}
