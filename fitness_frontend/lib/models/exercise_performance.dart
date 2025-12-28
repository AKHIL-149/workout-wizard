import 'package:hive/hive.dart';
import 'exercise_set.dart';

part 'exercise_performance.g.dart';

/// Represents an exercise performed within a workout session
@HiveType(typeId: 11)
class ExercisePerformance {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String exerciseName; // Name of the exercise (e.g., "Bench Press")

  @HiveField(2)
  final String? exerciseId; // Reference to exercise database (optional)

  @HiveField(3)
  final List<ExerciseSet> sets; // All sets performed for this exercise

  @HiveField(4)
  final String? formCorrectionSessionId; // Link to form correction session if tracked

  @HiveField(5)
  final String? notes; // Notes about this exercise in the workout

  @HiveField(6)
  final DateTime startTime; // When exercise started

  @HiveField(7)
  final DateTime? endTime; // When exercise completed

  ExercisePerformance({
    required this.id,
    required this.exerciseName,
    this.exerciseId,
    required this.sets,
    this.formCorrectionSessionId,
    this.notes,
    DateTime? startTime,
    this.endTime,
  }) : startTime = startTime ?? DateTime.now();

  /// Calculate total volume (sum of all set volumes)
  double get totalVolume => sets.fold(0.0, (sum, set) => sum + set.volume);

  /// Calculate average weight across all sets (excluding warmup)
  double get averageWeight {
    final workingSets = sets.where((s) => !s.isWarmup).toList();
    if (workingSets.isEmpty) return 0.0;
    return workingSets.fold(0.0, (sum, set) => sum + set.weight) /
        workingSets.length;
  }

  /// Calculate total reps (all sets)
  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);

  /// Get maximum weight used (1RM attempt or heaviest set)
  double get maxWeight {
    if (sets.isEmpty) return 0.0;
    return sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  /// Get average form score (if tracked)
  double? get averageFormScore {
    final setsWithForm = sets.where((s) => s.formScore != null).toList();
    if (setsWithForm.isEmpty) return null;
    return setsWithForm.fold(0.0, (sum, set) => sum + set.formScore!) /
        setsWithForm.length;
  }

  /// Check if all target reps were achieved
  bool get allTargetsAchieved => sets.every((s) => s.targetAchieved);

  /// Get number of working sets (exclude warmup)
  int get workingSetCount => sets.where((s) => !s.isWarmup).length;

  /// Get exercise duration (if endTime set)
  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  /// JSON serialization for backup/restore
  Map<String, dynamic> toJson() => {
        'id': id,
        'exercise_name': exerciseName,
        'exercise_id': exerciseId,
        'sets': sets.map((s) => s.toJson()).toList(),
        'form_correction_session_id': formCorrectionSessionId,
        'notes': notes,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
      };

  factory ExercisePerformance.fromJson(Map<String, dynamic> json) =>
      ExercisePerformance(
        id: json['id'] as String,
        exerciseName: json['exercise_name'] as String,
        exerciseId: json['exercise_id'] as String?,
        sets: (json['sets'] as List)
            .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
            .toList(),
        formCorrectionSessionId: json['form_correction_session_id'] as String?,
        notes: json['notes'] as String?,
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: json['end_time'] != null
            ? DateTime.parse(json['end_time'] as String)
            : null,
      );

  /// Create a copy with updated fields
  ExercisePerformance copyWith({
    String? id,
    String? exerciseName,
    String? exerciseId,
    List<ExerciseSet>? sets,
    String? formCorrectionSessionId,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      ExercisePerformance(
        id: id ?? this.id,
        exerciseName: exerciseName ?? this.exerciseName,
        exerciseId: exerciseId ?? this.exerciseId,
        sets: sets ?? this.sets,
        formCorrectionSessionId:
            formCorrectionSessionId ?? this.formCorrectionSessionId,
        notes: notes ?? this.notes,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );

  @override
  String toString() =>
      'ExercisePerformance($exerciseName: ${sets.length} sets, ${totalVolume.toStringAsFixed(1)} total volume)';
}
