import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_session.dart';
import 'health_integration_service.dart';

/// Service for managing workout session data with Hive storage
class WorkoutSessionService {
  static final WorkoutSessionService _instance =
      WorkoutSessionService._internal();
  factory WorkoutSessionService() => _instance;
  WorkoutSessionService._internal();

  static const String _boxName = 'workout_sessions';
  Box<WorkoutSession>? _box;
  final HealthIntegrationService _healthService = HealthIntegrationService();

  /// Initialize the service and open Hive box
  Future<void> initialize() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<WorkoutSession>(_boxName);
  }

  /// Get the Hive box (ensure initialized first)
  Box<WorkoutSession> get _getBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception('WorkoutSessionService not initialized');
    }
    return _box!;
  }

  /// Save a workout session
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    await _getBox.put(session.id, session);

    // Auto-sync to health app if enabled
    try {
      final config = _healthService.getSyncConfig();
      if (config != null && config.isEnabled && config.autoSync) {
        // Calculate workout duration and calories
        final duration = session.endTime.difference(session.startTime);
        final caloriesBurned = session.caloriesBurned?.toInt() ?? 0;

        if (caloriesBurned > 0) {
          await _healthService.exportWorkout(
            startTime: session.startTime,
            endTime: session.endTime,
            caloriesBurned: caloriesBurned,
          );
        }
      }
    } catch (e) {
      // Log error but don't fail the save operation
      print('Health sync error: $e');
    }
  }

  /// Get a workout session by ID
  WorkoutSession? getWorkoutSession(String id) {
    return _getBox.get(id);
  }

  /// Get all workout sessions
  List<WorkoutSession> getAllWorkoutSessions() {
    return _getBox.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Most recent first
  }

  /// Get workout sessions within a date range
  List<WorkoutSession> getWorkoutSessionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _getBox.values.where((session) {
      return session.startTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
          session.startTime.isBefore(endDate.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Get workout sessions for a specific program
  List<WorkoutSession> getWorkoutSessionsByProgram(String programId) {
    return _getBox.values
        .where((session) => session.programId == programId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Get workout sessions for a specific exercise
  List<WorkoutSession> getWorkoutSessionsWithExercise(String exerciseName) {
    return _getBox.values
        .where((session) =>
            session.exercises.any((ex) => ex.exerciseName == exerciseName))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Get most recent workout session
  WorkoutSession? getMostRecentWorkoutSession() {
    final sessions = getAllWorkoutSessions();
    return sessions.isNotEmpty ? sessions.first : null;
  }

  /// Get most recent workout for a specific exercise
  WorkoutSession? getMostRecentWorkoutWithExercise(String exerciseName) {
    final sessions = getWorkoutSessionsWithExercise(exerciseName);
    return sessions.isNotEmpty ? sessions.first : null;
  }

  /// Delete a workout session
  Future<void> deleteWorkoutSession(String id) async {
    await _getBox.delete(id);
  }

  /// Delete all workout sessions
  Future<void> deleteAllWorkoutSessions() async {
    await _getBox.clear();
  }

  /// Delete workout sessions older than specified days
  Future<int> deleteOldWorkoutSessions({required int daysOld}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final oldSessions = _getBox.values
        .where((session) => session.startTime.isBefore(cutoffDate))
        .toList();

    for (final session in oldSessions) {
      await _getBox.delete(session.id);
    }

    return oldSessions.length;
  }

  /// Get workout statistics
  Map<String, dynamic> getWorkoutStatistics() {
    final sessions = getAllWorkoutSessions();
    if (sessions.isEmpty) {
      return {
        'total_sessions': 0,
        'total_volume': 0.0,
        'total_sets': 0,
        'total_reps': 0,
        'average_duration': 0,
        'completed_sessions': 0,
      };
    }

    final completedSessions = sessions.where((s) => s.completed).toList();
    final totalVolume = sessions.fold(0.0, (sum, s) => sum + s.totalVolume);
    final totalSets = sessions.fold(0, (sum, s) => sum + s.totalSets);
    final totalReps = sessions.fold(0, (sum, s) => sum + s.totalReps);

    final sessionsWithDuration =
        sessions.where((s) => s.duration != null).toList();
    final averageDuration = sessionsWithDuration.isEmpty
        ? 0
        : sessionsWithDuration
                .fold(0, (sum, s) => sum + s.duration!.inMinutes) ~/
            sessionsWithDuration.length;

    return {
      'total_sessions': sessions.length,
      'total_volume': totalVolume,
      'total_sets': totalSets,
      'total_reps': totalReps,
      'average_duration': averageDuration,
      'completed_sessions': completedSessions.length,
    };
  }

  /// Get workout frequency (sessions per week)
  double getWorkoutFrequency({int? lastNDays}) {
    final sessions = getAllWorkoutSessions();
    if (sessions.isEmpty) return 0.0;

    final now = DateTime.now();
    final relevantSessions = lastNDays != null
        ? sessions
            .where((s) =>
                s.startTime.isAfter(now.subtract(Duration(days: lastNDays))))
            .toList()
        : sessions;

    if (relevantSessions.isEmpty) return 0.0;

    final oldestSession = relevantSessions.last.startTime;
    final daysDifference = now.difference(oldestSession).inDays + 1;
    final weeks = daysDifference / 7.0;

    return relevantSessions.length / weeks;
  }

  /// Export all workout sessions for backup
  Future<Map<String, dynamic>> exportAllWorkoutSessions() async {
    final sessions = getAllWorkoutSessions();
    return {
      'workout_sessions': sessions.map((s) => s.toJson()).toList(),
      'total_count': sessions.length,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Import workout sessions from backup
  Future<void> importWorkoutSessions(
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    if (data['workout_sessions'] == null) return;

    final sessionsList = data['workout_sessions'] as List;

    if (!merge) {
      // Replace: clear existing data
      await deleteAllWorkoutSessions();
    }

    // Import sessions
    for (final sessionData in sessionsList) {
      try {
        final session =
            WorkoutSession.fromJson(sessionData as Map<String, dynamic>);

        if (merge) {
          // Check if session already exists
          final existing = getWorkoutSession(session.id);
          if (existing == null) {
            await saveWorkoutSession(session);
          }
          // If exists, keep existing (don't overwrite in merge mode)
        } else {
          await saveWorkoutSession(session);
        }
      } catch (e) {
        // Skip invalid sessions
        continue;
      }
    }
  }

  /// Get unique exercise names from all sessions
  List<String> getUniqueExerciseNames() {
    final sessions = getAllWorkoutSessions();
    final exerciseNames = <String>{};

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        exerciseNames.add(exercise.exerciseName);
      }
    }

    return exerciseNames.toList()..sort();
  }

  /// Get sessions count by month
  Map<String, int> getSessionsByMonth({int? lastNMonths}) {
    final sessions = getAllWorkoutSessions();
    final now = DateTime.now();
    final monthCounts = <String, int>{};

    for (final session in sessions) {
      if (lastNMonths != null) {
        final monthsDiff =
            (now.year - session.startTime.year) * 12 +
            (now.month - session.startTime.month);
        if (monthsDiff >= lastNMonths) continue;
      }

      final monthKey =
          '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}';
      monthCounts[monthKey] = (monthCounts[monthKey] ?? 0) + 1;
    }

    return monthCounts;
  }

  /// Close the Hive box
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
