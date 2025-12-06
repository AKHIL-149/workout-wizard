/// Represents a single exercise with its specifications and volume recommendations
class Exercise {
  final String id;
  final String name;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final String movementType; // "Compound" or "Isolation"
  final String difficulty;

  // Volume recommendations
  final int minSets;
  final int maxSets;
  final int minReps;
  final int maxReps;
  final int restSeconds;

  // Optional
  final String? videoUrl;
  final String? description;
  final String? technique;

  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.movementType,
    this.difficulty = 'Intermediate',
    required this.minSets,
    required this.maxSets,
    required this.minReps,
    required this.maxReps,
    this.restSeconds = 90,
    this.videoUrl,
    this.description,
    this.technique,
  });

  /// Create a copy with modified fields
  Exercise copyWith({
    String? id,
    String? name,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    String? equipment,
    String? movementType,
    String? difficulty,
    int? minSets,
    int? maxSets,
    int? minReps,
    int? maxReps,
    int? restSeconds,
    String? videoUrl,
    String? description,
    String? technique,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      movementType: movementType ?? this.movementType,
      difficulty: difficulty ?? this.difficulty,
      minSets: minSets ?? this.minSets,
      maxSets: maxSets ?? this.maxSets,
      minReps: minReps ?? this.minReps,
      maxReps: maxReps ?? this.maxReps,
      restSeconds: restSeconds ?? this.restSeconds,
      videoUrl: videoUrl ?? this.videoUrl,
      description: description ?? this.description,
      technique: technique ?? this.technique,
    );
  }

  /// Get formatted sets/reps string
  String get setsRepsFormatted {
    final setsRange = minSets == maxSets ? '$minSets' : '$minSets-$maxSets';
    final repsRange = minReps == maxReps ? '$minReps' : '$minReps-$maxReps';
    return '$setsRange sets, $repsRange reps';
  }

  /// Get formatted rest time
  String get restFormatted {
    if (restSeconds < 60) {
      return '${restSeconds}s';
    }
    final minutes = restSeconds ~/ 60;
    final seconds = restSeconds % 60;
    return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryMuscle': primaryMuscle,
        'secondaryMuscles': secondaryMuscles,
        'equipment': equipment,
        'movementType': movementType,
        'difficulty': difficulty,
        'minSets': minSets,
        'maxSets': maxSets,
        'minReps': minReps,
        'maxReps': maxReps,
        'restSeconds': restSeconds,
        'videoUrl': videoUrl,
        'description': description,
        'technique': technique,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        primaryMuscle: json['primaryMuscle'] as String,
        secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        equipment: json['equipment'] as String,
        movementType: json['movementType'] as String,
        difficulty: json['difficulty'] as String? ?? 'Intermediate',
        minSets: json['minSets'] as int,
        maxSets: json['maxSets'] as int,
        minReps: json['minReps'] as int,
        maxReps: json['maxReps'] as int,
        restSeconds: json['restSeconds'] as int? ?? 90,
        videoUrl: json['videoUrl'] as String?,
        description: json['description'] as String?,
        technique: json['technique'] as String?,
      );
}
