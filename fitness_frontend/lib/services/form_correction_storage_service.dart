import 'package:hive_flutter/hive_flutter.dart';
import '../providers/form_correction_provider.dart';

/// Service for persisting form correction data using Hive
class FormCorrectionStorageService {
  static const String _sessionsBoxName = 'form_correction_sessions';
  static const String _statsBoxName = 'form_correction_stats';
  static const String _settingsBoxName = 'form_correction_settings';

  /// Get sessions box
  Box<Map> get _sessionsBox => Hive.box<Map>(_sessionsBoxName);

  /// Get stats box
  Box<Map> get _statsBox => Hive.box<Map>(_statsBoxName);

  /// Get settings box
  Box<Map> get _settingsBox => Hive.box<Map>(_settingsBoxName);

  /// Save a form correction session
  Future<void> saveSession(FormCorrectionSession session) async {
    await _sessionsBox.put(session.sessionId, session.toJson());
  }

  /// Get a session by ID
  FormCorrectionSession? getSession(String sessionId) {
    final data = _sessionsBox.get(sessionId);
    if (data == null) return null;

    return FormCorrectionSession.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get all sessions
  List<FormCorrectionSession> getAllSessions() {
    final sessions = <FormCorrectionSession>[];

    for (final key in _sessionsBox.keys) {
      final data = _sessionsBox.get(key);
      if (data != null) {
        try {
          sessions.add(
            FormCorrectionSession.fromJson(Map<String, dynamic>.from(data)),
          );
        } catch (e) {
          // Skip corrupted sessions
          continue;
        }
      }
    }

    // Sort by start time (most recent first)
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return sessions;
  }

  /// Get sessions for a specific exercise
  List<FormCorrectionSession> getSessionsByExercise(String exerciseName) {
    final allSessions = getAllSessions();
    return allSessions
        .where((s) => s.exerciseName.toLowerCase() == exerciseName.toLowerCase())
        .toList();
  }

  /// Get sessions for a specific program
  List<FormCorrectionSession> getSessionsByProgram(String programId) {
    final allSessions = getAllSessions();
    return allSessions.where((s) => s.programId == programId).toList();
  }

  /// Get recent sessions (last N)
  List<FormCorrectionSession> getRecentSessions({int limit = 10}) {
    final sessions = getAllSessions();
    return sessions.take(limit).toList();
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    await _sessionsBox.delete(sessionId);
  }

  /// Delete all sessions
  Future<void> deleteAllSessions() async {
    await _sessionsBox.clear();
  }

  /// Delete old sessions (older than N days)
  Future<void> deleteOldSessions({int daysToKeep = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final allSessions = getAllSessions();

    for (final session in allSessions) {
      if (session.startTime.isBefore(cutoffDate)) {
        await deleteSession(session.sessionId);
      }
    }
  }

  /// Save exercise statistics
  Future<void> saveExerciseStatistics(
    String exerciseName,
    Map<String, dynamic> stats,
  ) async {
    await _statsBox.put(exerciseName, stats);
  }

  /// Get exercise statistics
  Future<Map<String, dynamic>> getExerciseStatistics(String exerciseName) async {
    final data = _statsBox.get(exerciseName);
    if (data == null) {
      return {
        'totalSessions': 0,
        'bestScore': 0.0,
        'violations': <String, int>{},
      };
    }

    return Map<String, dynamic>.from(data);
  }

  /// Get all exercise statistics
  Map<String, Map<String, dynamic>> getAllExerciseStatistics() {
    final stats = <String, Map<String, dynamic>>{};

    for (final key in _statsBox.keys) {
      final data = _statsBox.get(key);
      if (data != null) {
        stats[key as String] = Map<String, dynamic>.from(data);
      }
    }

    return stats;
  }

  /// Save user settings
  Future<void> saveSetting(String key, dynamic value) async {
    final settings = _settingsBox.get('user_settings') ?? {};
    final updatedSettings = Map<String, dynamic>.from(settings);
    updatedSettings[key] = value;
    await _settingsBox.put('user_settings', updatedSettings);
  }

  /// Get user setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    final settings = _settingsBox.get('user_settings');
    if (settings == null) return defaultValue;

    final value = settings[key];
    return value as T? ?? defaultValue;
  }

  /// Get all settings
  Map<String, dynamic> getAllSettings() {
    final settings = _settingsBox.get('user_settings');
    if (settings == null) return {};

    return Map<String, dynamic>.from(settings);
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    await _settingsBox.clear();
  }

  /// Get database statistics
  Map<String, dynamic> getDatabaseStats() {
    return {
      'totalSessions': _sessionsBox.length,
      'totalExercises': _statsBox.length,
      'databaseSizeKB': (_sessionsBox.length * 10), // Rough estimate
    };
  }

  /// Export all data (for backup)
  Map<String, dynamic> exportData() {
    return {
      'sessions': getAllSessions().map((s) => s.toJson()).toList(),
      'statistics': getAllExerciseStatistics(),
      'settings': getAllSettings(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Import data (from backup)
  Future<void> importData(Map<String, dynamic> data, {bool merge = false}) async {
    try {
      // Import sessions
      if (data.containsKey('sessions')) {
        final sessions = data['sessions'] as List;

        if (merge) {
          // Merge sessions - check for duplicates by session_id
          final existingSessionIds = getAllSessions().map((s) => s.sessionId).toSet();

          for (final sessionData in sessions) {
            final session = FormCorrectionSession.fromJson(
              Map<String, dynamic>.from(sessionData),
            );

            // Only add if not duplicate, or update if backup is newer
            if (!existingSessionIds.contains(session.sessionId)) {
              await saveSession(session);
            } else {
              // Could add logic to keep newer session based on timestamp
              // For now, skip duplicates when merging
            }
          }
        } else {
          // Replace all - clear existing and import backup
          await deleteAllSessions();
          for (final sessionData in sessions) {
            final session = FormCorrectionSession.fromJson(
              Map<String, dynamic>.from(sessionData),
            );
            await saveSession(session);
          }
        }
      }

      // Import statistics
      if (data.containsKey('statistics')) {
        final stats = data['statistics'] as Map<String, dynamic>;

        if (merge) {
          // Merge statistics - combine with existing
          for (final entry in stats.entries) {
            await saveExerciseStatistics(
              entry.key,
              Map<String, dynamic>.from(entry.value),
            );
          }
        } else {
          // Replace all statistics
          await _statsBox.clear();
          for (final entry in stats.entries) {
            await saveExerciseStatistics(
              entry.key,
              Map<String, dynamic>.from(entry.value),
            );
          }
        }
      }

      // Import settings (always use backup settings for consistency)
      if (data.containsKey('settings')) {
        final settings = Map<String, dynamic>.from(data['settings']);
        await _settingsBox.put('user_settings', settings);
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  /// Compact database (remove unused space)
  Future<void> compactDatabase() async {
    await _sessionsBox.compact();
    await _statsBox.compact();
    await _settingsBox.compact();
  }
}

/// Settings keys
class FormCorrectionSettings {
  static const String audioEnabled = 'audio_enabled';
  static const String skeletonColor = 'skeleton_color';
  static const String showLabels = 'show_labels';
  static const String showSkeleton = 'show_skeleton';
  static const String frameSkipCount = 'frame_skip_count';
  static const String detectionMode = 'detection_mode';
  static const String autoSave = 'auto_save';
  static const String dataRetentionDays = 'data_retention_days';
  static const String defaultCamera = 'default_camera';
}
