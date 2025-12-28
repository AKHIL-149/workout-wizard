import 'package:hive/hive.dart';

part 'exercise_set.g.dart';

/// Represents a single set of an exercise
@HiveType(typeId: 10)
class ExerciseSet {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double weight; // Weight used (kg or lbs)

  @HiveField(2)
  final int reps; // Actual reps completed

  @HiveField(3)
  final int targetReps; // Target reps planned

  @HiveField(4)
  final int restSeconds; // Rest time after set (seconds)

  @HiveField(5)
  final double? formScore; // Form quality score (0-100), null if not tracked

  @HiveField(6)
  final DateTime timestamp; // When the set was completed

  @HiveField(7)
  final String? notes; // Optional notes about the set

  @HiveField(8)
  final bool isWarmup; // Whether this is a warmup set

  ExerciseSet({
    required this.id,
    required this.weight,
    required this.reps,
    required this.targetReps,
    this.restSeconds = 60,
    this.formScore,
    DateTime? timestamp,
    this.notes,
    this.isWarmup = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Calculate volume (weight × reps)
  double get volume => weight * reps;

  /// Check if target reps were achieved
  bool get targetAchieved => reps >= targetReps;

  /// Calculate percentage of target achieved
  double get targetPercentage => (reps / targetReps * 100).clamp(0, 200);

  /// Check if form was good (>= 80%)
  bool get goodForm => formScore != null && formScore! >= 80.0;

  /// JSON serialization for backup/restore
  Map<String, dynamic> toJson() => {
        'id': id,
        'weight': weight,
        'reps': reps,
        'target_reps': targetReps,
        'rest_seconds': restSeconds,
        'form_score': formScore,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
        'is_warmup': isWarmup,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        id: json['id'] as String,
        weight: (json['weight'] as num).toDouble(),
        reps: json['reps'] as int,
        targetReps: json['target_reps'] as int,
        restSeconds: json['rest_seconds'] as int? ?? 60,
        formScore: json['form_score'] != null
            ? (json['form_score'] as num).toDouble()
            : null,
        timestamp: DateTime.parse(json['timestamp'] as String),
        notes: json['notes'] as String?,
        isWarmup: json['is_warmup'] as bool? ?? false,
      );

  /// Create a copy with updated fields
  ExerciseSet copyWith({
    String? id,
    double? weight,
    int? reps,
    int? targetReps,
    int? restSeconds,
    double? formScore,
    DateTime? timestamp,
    String? notes,
    bool? isWarmup,
  }) =>
      ExerciseSet(
        id: id ?? this.id,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        targetReps: targetReps ?? this.targetReps,
        restSeconds: restSeconds ?? this.restSeconds,
        formScore: formScore ?? this.formScore,
        timestamp: timestamp ?? this.timestamp,
        notes: notes ?? this.notes,
        isWarmup: isWarmup ?? this.isWarmup,
      );

  @override
  String toString() =>
      'ExerciseSet(weight: $weight, reps: $reps/$targetReps, volume: ${volume.toStringAsFixed(1)})';
}
