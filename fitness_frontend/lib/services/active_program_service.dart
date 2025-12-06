import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recommendation.dart';

/// Service for managing the user's active fitness program
class ActiveProgramService {
  static final ActiveProgramService _instance = ActiveProgramService._internal();
  factory ActiveProgramService() => _instance;
  ActiveProgramService._internal();

  static const String _activeProgramKey = 'active_program';
  static const String _programStartDateKey = 'program_start_date';
  static const String _completedWorkoutsKey = 'completed_workouts';
  static const String _currentWeekKey = 'current_week';
  static const String _currentDayKey = 'current_day';

  /// Start a new program
  Future<void> startProgram(Recommendation program) async {
    final prefs = await SharedPreferences.getInstance();

    // Save program data
    final programJson = json.encode(program.toJson());
    await prefs.setString(_activeProgramKey, programJson);

    // Save start date
    final startDate = DateTime.now().toIso8601String();
    await prefs.setString(_programStartDateKey, startDate);

    // Reset progress
    await prefs.setStringList(_completedWorkoutsKey, []);
    await prefs.setInt(_currentWeekKey, 1);
    await prefs.setInt(_currentDayKey, 1);
  }

  /// Get the active program
  Future<Recommendation?> getActiveProgram() async {
    final prefs = await SharedPreferences.getInstance();
    final programJson = prefs.getString(_activeProgramKey);

    if (programJson == null) return null;

    try {
      final programData = json.decode(programJson) as Map<String, dynamic>;
      final programId = programData['program_id'] as String? ?? 'UNKNOWN';
      return Recommendation.fromJson(programId, programData);
    } catch (e) {
      return null;
    }
  }

  /// Get program start date
  Future<DateTime?> getProgramStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final startDateStr = prefs.getString(_programStartDateKey);

    if (startDateStr == null) return null;

    try {
      return DateTime.parse(startDateStr);
    } catch (e) {
      return null;
    }
  }

  /// Get days since program started
  Future<int> getDaysSinceStart() async {
    final startDate = await getProgramStartDate();
    if (startDate == null) return 0;

    final now = DateTime.now();
    return now.difference(startDate).inDays;
  }

  /// Get current week number
  Future<int> getCurrentWeek() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentWeekKey) ?? 1;
  }

  /// Set current week
  Future<void> setCurrentWeek(int week) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentWeekKey, week);
  }

  /// Get current day number
  Future<int> getCurrentDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentDayKey) ?? 1;
  }

  /// Set current day
  Future<void> setCurrentDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentDayKey, day);
  }

  /// Mark a workout as completed
  Future<void> completeWorkout(String workoutId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await getCompletedWorkouts();

    if (!completed.contains(workoutId)) {
      completed.add(workoutId);
      await prefs.setStringList(_completedWorkoutsKey, completed);
    }
  }

  /// Get list of completed workout IDs
  Future<List<String>> getCompletedWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedWorkoutsKey) ?? [];
  }

  /// Check if a workout is completed
  Future<bool> isWorkoutCompleted(String workoutId) async {
    final completed = await getCompletedWorkouts();
    return completed.contains(workoutId);
  }

  /// Get program progress percentage
  Future<double> getProgramProgress() async {
    final program = await getActiveProgram();
    if (program == null) return 0.0;

    final totalWorkouts = program.programLength * program.workoutFrequency;
    final completed = await getCompletedWorkouts();

    if (totalWorkouts == 0) return 0.0;

    return (completed.length / totalWorkouts).clamp(0.0, 1.0);
  }

  /// Check if there's an active program
  Future<bool> hasActiveProgram() async {
    final program = await getActiveProgram();
    return program != null;
  }

  /// End/Clear the active program
  Future<void> endProgram() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeProgramKey);
    await prefs.remove(_programStartDateKey);
    await prefs.remove(_completedWorkoutsKey);
    await prefs.remove(_currentWeekKey);
    await prefs.remove(_currentDayKey);
  }

  /// Get program stats
  Future<Map<String, dynamic>> getProgramStats() async {
    final program = await getActiveProgram();
    final startDate = await getProgramStartDate();
    final daysSinceStart = await getDaysSinceStart();
    final progress = await getProgramProgress();
    final completedWorkouts = await getCompletedWorkouts();
    final currentWeek = await getCurrentWeek();
    final currentDay = await getCurrentDay();

    return {
      'hasActiveProgram': program != null,
      'programTitle': program?.title,
      'programId': program?.programId,
      'startDate': startDate?.toIso8601String(),
      'daysSinceStart': daysSinceStart,
      'progress': progress,
      'completedWorkoutsCount': completedWorkouts.length,
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'totalWeeks': program?.programLength ?? 0,
      'workoutsPerWeek': program?.workoutFrequency ?? 0,
    };
  }
}
