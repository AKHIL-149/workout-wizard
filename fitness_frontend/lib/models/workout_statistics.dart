/// Model representing overall workout statistics and analytics
class WorkoutStatistics {
  final int totalWorkouts;
  final int totalSets;
  final int totalReps;
  final double totalVolume; // kg
  final Duration totalWorkoutTime;
  final int currentStreak; // consecutive days with workouts
  final int longestStreak;
  final DateTime? lastWorkoutDate;
  final Map<String, int> exerciseFrequency; // exercise name -> count
  final Map<String, double> exerciseVolume; // exercise name -> total volume
  final List<PersonalRecord> personalRecords;
  final List<WeeklyActivity> weeklyActivity;
  final double averageWorkoutDuration; // minutes
  final int workoutsThisWeek;
  final int workoutsThisMonth;

  const WorkoutStatistics({
    required this.totalWorkouts,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    required this.totalWorkoutTime,
    required this.currentStreak,
    required this.longestStreak,
    this.lastWorkoutDate,
    required this.exerciseFrequency,
    required this.exerciseVolume,
    required this.personalRecords,
    required this.weeklyActivity,
    required this.averageWorkoutDuration,
    required this.workoutsThisWeek,
    required this.workoutsThisMonth,
  });

  String get totalWorkoutTimeFormatted {
    final hours = totalWorkoutTime.inHours;
    final minutes = totalWorkoutTime.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get averageWorkoutDurationFormatted {
    final hours = averageWorkoutDuration ~/ 60;
    final minutes = (averageWorkoutDuration % 60).round();

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get top N exercises by frequency
  List<MapEntry<String, int>> getTopExercisesByFrequency(int count) {
    final sorted = exerciseFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  /// Get top N exercises by volume
  List<MapEntry<String, double>> getTopExercisesByVolume(int count) {
    final sorted = exerciseVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  /// Empty statistics
  factory WorkoutStatistics.empty() {
    return const WorkoutStatistics(
      totalWorkouts: 0,
      totalSets: 0,
      totalReps: 0,
      totalVolume: 0,
      totalWorkoutTime: Duration.zero,
      currentStreak: 0,
      longestStreak: 0,
      exerciseFrequency: {},
      exerciseVolume: {},
      personalRecords: [],
      weeklyActivity: [],
      averageWorkoutDuration: 0,
      workoutsThisWeek: 0,
      workoutsThisMonth: 0,
    );
  }
}

/// Personal record for an exercise
class PersonalRecord {
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime achievedDate;
  final double volume;

  const PersonalRecord({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.achievedDate,
    required this.volume,
  });

  String get displayText => '${weight}kg × $reps reps';
}

/// Weekly activity data for charts
class WeeklyActivity {
  final DateTime weekStart;
  final int workoutCount;
  final double totalVolume;
  final Duration totalTime;

  const WeeklyActivity({
    required this.weekStart,
    required this.workoutCount,
    required this.totalVolume,
    required this.totalTime,
  });
}
