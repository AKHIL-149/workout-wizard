import 'package:hive/hive.dart';

part 'workout_template.g.dart';

/// Template for a workout routine
@HiveType(typeId: 13)
class WorkoutTemplate {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final List<TemplateExercise> exercises;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastUsed;

  @HiveField(6)
  final int timesUsed;

  @HiveField(7)
  final String? category; // e.g., "Push", "Pull", "Legs", "Full Body"

  @HiveField(8)
  final bool isFavorite;

  WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
    required this.createdAt,
    required this.lastUsed,
    this.timesUsed = 0,
    this.category,
    this.isFavorite = false,
  });

  int get totalExercises => exercises.length;

  int get estimatedDuration {
    // Estimate: 5 minutes per exercise + 1 minute per set
    final exerciseTime = exercises.length * 5;
    final setTime = exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets,
    );
    return exerciseTime + setTime;
  }

  String get estimatedDurationFormatted {
    final duration = estimatedDuration;
    if (duration >= 60) {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      return '${hours}h ${minutes}m';
    } else {
      return '${duration}m';
    }
  }

  /// Create a copy with updated fields
  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<TemplateExercise>? exercises,
    DateTime? createdAt,
    DateTime? lastUsed,
    int? timesUsed,
    String? category,
    bool? isFavorite,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      timesUsed: timesUsed ?? this.timesUsed,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'timesUsed': timesUsed,
      'category': category,
      'isFavorite': isFavorite,
    };
  }

  /// Create from JSON
  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      exercises: (json['exercises'] as List)
          .map((e) => TemplateExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
      timesUsed: json['timesUsed'] as int? ?? 0,
      category: json['category'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

/// Exercise in a workout template
@HiveType(typeId: 14)
class TemplateExercise {
  @HiveField(0)
  final String exerciseId;

  @HiveField(1)
  final String exerciseName;

  @HiveField(2)
  final int sets;

  @HiveField(3)
  final int targetReps;

  @HiveField(4)
  final double? targetWeight; // Optional suggested weight

  @HiveField(5)
  final int restSeconds;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final int orderIndex; // Position in the workout

  TemplateExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.targetReps,
    this.targetWeight,
    this.restSeconds = 90,
    this.notes,
    required this.orderIndex,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'restSeconds': restSeconds,
      'notes': notes,
      'orderIndex': orderIndex,
    };
  }

  /// Create from JSON
  factory TemplateExercise.fromJson(Map<String, dynamic> json) {
    return TemplateExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: json['sets'] as int,
      targetReps: json['targetReps'] as int,
      targetWeight: json['targetWeight'] as double?,
      restSeconds: json['restSeconds'] as int? ?? 90,
      notes: json['notes'] as String?,
      orderIndex: json['orderIndex'] as int,
    );
  }

  /// Create a copy with updated fields
  TemplateExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    int? sets,
    int? targetReps,
    double? targetWeight,
    int? restSeconds,
    String? notes,
    int? orderIndex,
  }) {
    return TemplateExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
