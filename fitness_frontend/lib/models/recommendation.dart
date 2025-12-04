// Recommendation model matching the FastAPI response

class Recommendation {
  final String programId;
  final String title;
  final String primaryLevel;
  final String primaryGoal;
  final String equipment;
  final int programLength;
  final int timePerWorkout;
  final int workoutFrequency;
  final int matchPercentage;
  final String? trainingStyle;

  // Enhanced fields for better UI
  final double? rating;
  final String? userCount;
  final String? description;
  final List<String>? highlights;

  Recommendation({
    required this.programId,
    required this.title,
    required this.primaryLevel,
    required this.primaryGoal,
    required this.equipment,
    required this.programLength,
    required this.timePerWorkout,
    required this.workoutFrequency,
    required this.matchPercentage,
    this.trainingStyle,
    this.rating,
    this.userCount,
    this.description,
    this.highlights,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      programId: json['program_id'] as String,
      title: json['title'] as String,
      primaryLevel: json['primary_level'] as String,
      primaryGoal: json['primary_goal'] as String,
      equipment: json['equipment'] as String,
      programLength: json['program_length'] is int
          ? json['program_length']
          : int.parse(json['program_length'].toString()),
      timePerWorkout: json['time_per_workout'] is int
          ? json['time_per_workout']
          : int.parse(json['time_per_workout'].toString()),
      workoutFrequency: json['workout_frequency'] is int
          ? json['workout_frequency']
          : int.parse(json['workout_frequency'].toString()),
      matchPercentage: json['match_percentage'] is int
          ? json['match_percentage']
          : int.parse(json['match_percentage'].toString()),
      trainingStyle: json['training_style'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      userCount: json['user_count'] as String?,
      description: json['description'] as String?,
      highlights: json['highlights'] != null
          ? List<String>.from(json['highlights'])
          : null,
    );
  }
}

