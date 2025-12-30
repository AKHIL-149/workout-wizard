import '../models/workout_session.dart';
import '../models/workout_statistics.dart';
import 'workout_session_service.dart';

/// Service for calculating workout statistics and analytics
class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  final WorkoutSessionService _sessionService = WorkoutSessionService();

  /// Calculate comprehensive workout statistics
  WorkoutStatistics calculateStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var sessions = _sessionService.getAllWorkoutSessions();

    // Filter by date range if specified
    if (startDate != null || endDate != null) {
      sessions = sessions.where((session) {
        final date = session.startTime;
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null && date.isAfter(endDate)) return false;
        return true;
      }).toList();
    }

    if (sessions.isEmpty) {
      return WorkoutStatistics.empty();
    }

    // Basic counts
    final totalWorkouts = sessions.length;
    var totalSets = 0;
    var totalReps = 0;
    var totalVolume = 0.0;
    var totalWorkoutTime = Duration.zero;

    // Exercise tracking
    final exerciseFrequency = <String, int>{};
    final exerciseVolume = <String, double>{};
    final personalRecords = <String, PersonalRecord>{};

    // Process each session
    for (final session in sessions) {
      totalSets += session.totalSets;
      totalReps += session.totalReps;
      totalVolume += session.totalVolume;
      totalWorkoutTime += session.duration ?? Duration.zero;

      // Track exercises
      for (final exercise in session.exercises) {
        final name = exercise.exerciseName;

        // Frequency
        exerciseFrequency[name] = (exerciseFrequency[name] ?? 0) + 1;

        // Volume
        exerciseVolume[name] = (exerciseVolume[name] ?? 0) + exercise.totalVolume;

        // Personal records (highest volume set)
        for (final set in exercise.sets) {
          final currentPR = personalRecords[name];
          if (currentPR == null || set.volume > currentPR.volume) {
            personalRecords[name] = PersonalRecord(
              exerciseName: name,
              weight: set.weight,
              reps: set.reps,
              achievedDate: session.startTime,
              volume: set.volume,
            );
          }
        }
      }
    }

    // Calculate streaks
    final streaks = _calculateStreaks(sessions);
    final currentStreak = streaks['current'] ?? 0;
    final longestStreak = streaks['longest'] ?? 0;

    // Weekly activity (last 12 weeks)
    final weeklyActivity = _calculateWeeklyActivity(sessions);

    // Recent activity
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final workoutsThisWeek = sessions
        .where((s) => s.startTime.isAfter(weekStart))
        .length;

    final workoutsThisMonth = sessions
        .where((s) => s.startTime.isAfter(monthStart))
        .length;

    // Average workout duration
    final averageWorkoutDuration = totalWorkoutTime.inMinutes / totalWorkouts;

    // Last workout date
    final lastWorkoutDate = sessions.first.startTime;

    return WorkoutStatistics(
      totalWorkouts: totalWorkouts,
      totalSets: totalSets,
      totalReps: totalReps,
      totalVolume: totalVolume,
      totalWorkoutTime: totalWorkoutTime,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastWorkoutDate: lastWorkoutDate,
      exerciseFrequency: exerciseFrequency,
      exerciseVolume: exerciseVolume,
      personalRecords: personalRecords.values.toList()
        ..sort((a, b) => b.volume.compareTo(a.volume)),
      weeklyActivity: weeklyActivity,
      averageWorkoutDuration: averageWorkoutDuration,
      workoutsThisWeek: workoutsThisWeek,
      workoutsThisMonth: workoutsThisMonth,
    );
  }

  /// Calculate workout streaks
  Map<String, int> _calculateStreaks(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    // Get unique workout dates (normalized to day)
    final workoutDates = sessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending

    if (workoutDates.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    var currentStreak = 0;
    var longestStreak = 0;
    var tempStreak = 1;

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    // Check if current streak is active (workout today or yesterday)
    final mostRecent = workoutDates.first;
    final daysSinceLastWorkout = todayNormalized.difference(mostRecent).inDays;

    if (daysSinceLastWorkout <= 1) {
      currentStreak = 1;

      // Count consecutive days backwards
      for (var i = 1; i < workoutDates.length; i++) {
        final diff = workoutDates[i - 1].difference(workoutDates[i]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    // Find longest streak in history
    for (var i = 1; i < workoutDates.length; i++) {
      final diff = workoutDates[i - 1].difference(workoutDates[i]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else {
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        tempStreak = 1;
      }
    }

    // Check final streak
    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }

    // Ensure current streak is counted in longest
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }

  /// Calculate weekly activity for last 12 weeks
  List<WeeklyActivity> _calculateWeeklyActivity(List<WorkoutSession> sessions) {
    final now = DateTime.now();
    final weeks = <WeeklyActivity>[];

    // Generate last 12 weeks
    for (var i = 11; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekStartNormalized = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEnd = weekStartNormalized.add(const Duration(days: 6, hours: 23, minutes: 59));

      // Filter sessions for this week
      final weekSessions = sessions.where((session) {
        return session.startTime.isAfter(weekStartNormalized) &&
               session.startTime.isBefore(weekEnd);
      }).toList();

      var totalVolume = 0.0;
      var totalTime = Duration.zero;

      for (final session in weekSessions) {
        totalVolume += session.totalVolume;
        totalTime += session.duration ?? Duration.zero;
      }

      weeks.add(WeeklyActivity(
        weekStart: weekStartNormalized,
        workoutCount: weekSessions.length,
        totalVolume: totalVolume,
        totalTime: totalTime,
      ));
    }

    return weeks;
  }

  /// Get statistics for a specific time period
  WorkoutStatistics getStatisticsForPeriod(String period) {
    final now = DateTime.now();
    DateTime? startDate;

    switch (period) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3months':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '6months':
        startDate = now.subtract(const Duration(days: 180));
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      case 'all':
      default:
        startDate = null;
    }

    return calculateStatistics(startDate: startDate);
  }
}
