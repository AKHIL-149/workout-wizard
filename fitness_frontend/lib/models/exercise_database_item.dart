/// Exercise information from the exercise database
class ExerciseDatabaseItem {
  final String id;
  final String name;
  final String category; // e.g., "Chest", "Back", "Legs"
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment; // e.g., "Barbell", "Dumbbell", "Bodyweight"
  final String difficulty; // "Beginner", "Intermediate", "Advanced"
  final String description;
  final List<String> instructions;
  final List<String> tips;
  final List<String> commonMistakes;
  final String? videoUrl;
  final String? imageUrl;

  const ExerciseDatabaseItem({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.difficulty,
    required this.description,
    required this.instructions,
    required this.tips,
    required this.commonMistakes,
    this.videoUrl,
    this.imageUrl,
  });

  /// Create from JSON
  factory ExerciseDatabaseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseDatabaseItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      primaryMuscles: (json['primaryMuscles'] as List).cast<String>(),
      secondaryMuscles: (json['secondaryMuscles'] as List).cast<String>(),
      equipment: json['equipment'] as String,
      difficulty: json['difficulty'] as String,
      description: json['description'] as String,
      instructions: (json['instructions'] as List).cast<String>(),
      tips: (json['tips'] as List).cast<String>(),
      commonMistakes: (json['commonMistakes'] as List).cast<String>(),
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'difficulty': difficulty,
      'description': description,
      'instructions': instructions,
      'tips': tips,
      'commonMistakes': commonMistakes,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
    };
  }

  /// Get all muscles targeted (primary + secondary)
  List<String> get allMuscles => [...primaryMuscles, ...secondaryMuscles];

  /// Get difficulty color
  String get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'green';
      case 'intermediate':
        return 'orange';
      case 'advanced':
        return 'red';
      default:
        return 'grey';
    }
  }
}
