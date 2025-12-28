import 'package:hive/hive.dart';
import 'exercise_performance.dart';

part 'workout_session.g.dart';

/// Represents a complete workout session
@HiveType(typeId: 12)
class WorkoutSession {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? programId; // Reference to active program (optional)

  @HiveField(2)
  final String? workoutName; // Name of the workout (e.g., "Push Day A")

  @HiveField(3)
  final int? weekNumber; // Week number in program (optional)

  @HiveField(4)
  final int? dayNumber; // Day number in program (optional)

  @HiveField(5)
  final List<ExercisePerformance> exercises; // All exercises in this workout

  @HiveField(6)
  final DateTime startTime; // When workout started

  @HiveField(7)
  final DateTime? endTime; // When workout ended

  @HiveField(8)
  final String? notes; // Workout notes (energy level, mood, etc.)

  @HiveField(9)
  final double? bodyweight; // User's bodyweight on this day (optional)

  @HiveField(10)
  final String? location; // Gym location (optional)

  @HiveField(11)
  final List<String>? tags; // Tags for categorization (e.g., "strength", "hypertrophy")

  @HiveField(12)
  final bool completed; // Whether workout was completed or abandoned

  WorkoutSession({
    required this.id,
    this.programId,
    this.workoutName,
    this.weekNumber,
    this.dayNumber,
    required this.exercises,
    DateTime? startTime,
    this.endTime,
    this.notes,
    this.bodyweight,
    this.location,
    this.tags,
    this.completed = true,
  }) : startTime = startTime ?? DateTime.now();

  /// Calculate total workout duration
  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  /// Calculate total volume across all exercises
  double get totalVolume =>
      exercises.fold(0.0, (sum, ex) => sum + ex.totalVolume);

  /// Calculate total sets performed
  int get totalSets => exercises.fold(0, (sum, ex) => sum + ex.sets.length);

  /// Calculate total reps performed
  int get totalReps => exercises.fold(0, (sum, ex) => sum + ex.totalReps);

  /// Get average form score across all exercises
  double? get averageFormScore {
    final scores = exercises
        .map((e) => e.averageFormScore)
        .where((s) => s != null)
        .cast<double>()
        .toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Get total working sets (exclude warmup)
  int get totalWorkingSets =>
      exercises.fold(0, (sum, ex) => sum + ex.workingSetCount);

  /// Check if this is from an active program
  bool get isFromProgram => programId != null;

  /// Get formatted duration string (e.g., "1h 23m")
  String get durationFormatted {
    if (duration == null) return 'In progress';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Get date without time
  DateTime get date => DateTime(startTime.year, startTime.month, startTime.day);

  /// JSON serialization for backup/restore
  Map<String, dynamic> toJson() => {
        'id': id,
        'program_id': programId,
        'workout_name': workoutName,
        'week_number': weekNumber,
        'day_number': dayNumber,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'notes': notes,
        'bodyweight': bodyweight,
        'location': location,
        'tags': tags,
        'completed': completed,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String,
        programId: json['program_id'] as String?,
        workoutName: json['workout_name'] as String?,
        weekNumber: json['week_number'] as int?,
        dayNumber: json['day_number'] as int?,
        exercises: (json['exercises'] as List)
            .map((e) =>
                ExercisePerformance.fromJson(e as Map<String, dynamic>))
            .toList(),
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: json['end_time'] != null
            ? DateTime.parse(json['end_time'] as String)
            : null,
        notes: json['notes'] as String?,
        bodyweight: json['bodyweight'] != null
            ? (json['bodyweight'] as num).toDouble()
            : null,
        location: json['location'] as String?,
        tags: json['tags'] != null
            ? (json['tags'] as List).cast<String>()
            : null,
        completed: json['completed'] as bool? ?? true,
      );

  /// Create a copy with updated fields
  WorkoutSession copyWith({
    String? id,
    String? programId,
    String? workoutName,
    int? weekNumber,
    int? dayNumber,
    List<ExercisePerformance>? exercises,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    double? bodyweight,
    String? location,
    List<String>? tags,
    bool? completed,
  }) =>
      WorkoutSession(
        id: id ?? this.id,
        programId: programId ?? this.programId,
        workoutName: workoutName ?? this.workoutName,
        weekNumber: weekNumber ?? this.weekNumber,
        dayNumber: dayNumber ?? this.dayNumber,
        exercises: exercises ?? this.exercises,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        notes: notes ?? this.notes,
        bodyweight: bodyweight ?? this.bodyweight,
        location: location ?? this.location,
        tags: tags ?? this.tags,
        completed: completed ?? this.completed,
      );

  @override
  String toString() =>
      'WorkoutSession(${workoutName ?? "Workout"}: ${exercises.length} exercises, ${totalVolume.toStringAsFixed(1)} total volume)';
}
