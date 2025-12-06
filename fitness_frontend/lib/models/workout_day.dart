import 'exercise.dart';

/// Represents a single workout day with its exercises and metadata
class WorkoutDay {
  final int dayNumber;
  final String dayName;
  final String phase;
  final int weekNumber;
  final int duration;
  final List<Exercise> exercises;

  const WorkoutDay({
    required this.dayNumber,
    required this.dayName,
    required this.phase,
    required this.weekNumber,
    required this.duration,
    required this.exercises,
  });

  /// Total number of exercises
  int get totalExercises => exercises.length;

  /// Number of compound exercises
  int get compoundCount =>
      exercises.where((e) => e.movementType == 'Compound').length;

  /// Number of isolation exercises
  int get isolationCount =>
      exercises.where((e) => e.movementType == 'Isolation').length;

  /// Get compound exercises only
  List<Exercise> get compoundExercises =>
      exercises.where((e) => e.movementType == 'Compound').toList();

  /// Get isolation exercises only
  List<Exercise> get isolationExercises =>
      exercises.where((e) => e.movementType == 'Isolation').toList();

  /// Get phase description
  String get phaseDescription {
    switch (phase) {
      case 'Foundation':
        return 'Building strength base with higher reps';
      case 'Growth':
        return 'Maximizing muscle growth';
      case 'Peak':
        return 'Strength and power development';
      default:
        return 'Balanced training';
    }
  }

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'dayName': dayName,
        'phase': phase,
        'weekNumber': weekNumber,
        'duration': duration,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
        dayNumber: json['dayNumber'] as int,
        dayName: json['dayName'] as String,
        phase: json['phase'] as String,
        weekNumber: json['weekNumber'] as int,
        duration: json['duration'] as int,
        exercises: (json['exercises'] as List<dynamic>)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
