// Recommendation model for fitness programs

class Recommendation {
  final String programId;
  final String title;
  final String description;
  final List<String> level;
  final List<String> goal;
  final String equipment;
  final int programLength;
  final int timePerWorkout;
  final int totalExercises;
  final int workoutFrequency;
  final String exerciseGuidance;
  final int matchPercentage; // Calculated by algorithm

  // Derived properties for compatibility
  String get primaryLevel => level.isNotEmpty ? level.first : 'Beginner';
  String get primaryGoal => goal.isNotEmpty ? goal.first : 'General Fitness';

  Recommendation({
    required this.programId,
    required this.title,
    required this.description,
    required this.level,
    required this.goal,
    required this.equipment,
    required this.programLength,
    required this.timePerWorkout,
    required this.totalExercises,
    required this.workoutFrequency,
    required this.exerciseGuidance,
    this.matchPercentage = 0,
  });

  factory Recommendation.fromJson(String programId, Map<String, dynamic> json) {
    return Recommendation(
      programId: programId,
      title: json['title'] as String,
      description: json['description'] as String,
      level: List<String>.from(json['level'] ?? ['Beginner']),
      goal: List<String>.from(json['goal'] ?? ['General Fitness']),
      equipment: json['equipment'] as String,
      programLength: json['program_length'] is int
          ? json['program_length']
          : int.parse(json['program_length'].toString()),
      timePerWorkout: json['time_per_workout'] is int
          ? json['time_per_workout']
          : int.parse(json['time_per_workout'].toString()),
      totalExercises: json['total_exercises'] is int
          ? json['total_exercises']
          : int.parse(json['total_exercises'].toString()),
      workoutFrequency: json['workout_frequency'] is int
          ? json['workout_frequency']
          : int.parse(json['workout_frequency'].toString()),
      exerciseGuidance: json['exercise_guidance'] as String? ?? '',
      matchPercentage: json['match_percentage'] is int
          ? json['match_percentage']
          : 0,
    );
  }

  // Create a copy with updated match percentage
  Recommendation copyWith({
    int? matchPercentage,
  }) {
    return Recommendation(
      programId: programId,
      title: title,
      description: description,
      level: level,
      goal: goal,
      equipment: equipment,
      programLength: programLength,
      timePerWorkout: timePerWorkout,
      totalExercises: totalExercises,
      workoutFrequency: workoutFrequency,
      exerciseGuidance: exerciseGuidance,
      matchPercentage: matchPercentage ?? this.matchPercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'program_id': programId,
      'title': title,
      'description': description,
      'level': level,
      'goal': goal,
      'equipment': equipment,
      'program_length': programLength,
      'time_per_workout': timePerWorkout,
      'total_exercises': totalExercises,
      'workout_frequency': workoutFrequency,
      'exercise_guidance': exerciseGuidance,
      'match_percentage': matchPercentage,
    };
  }

  // Helper: Get short description (first line)
  String get shortDescription {
    final lines = description.split('\n');
    return lines.isNotEmpty ? lines.first : description;
  }

  // Helper: Get weekly schedule from description
  String? get weeklySchedule {
    final scheduleMatch = RegExp(r'Weekly Schedule:(.*?)(?:\n\n|$)', dotAll: true)
        .firstMatch(description);
    return scheduleMatch?.group(1)?.trim();
  }

  // Helper: Check if program matches a specific level
  bool matchesLevel(String userLevel) {
    return level.any((l) => l.toLowerCase() == userLevel.toLowerCase());
  }

  // Helper: Check if program matches any goal
  bool matchesAnyGoal(List<String> userGoals) {
    return userGoals.any((userGoal) =>
        goal.any((programGoal) =>
            programGoal.toLowerCase().contains(userGoal.toLowerCase()) ||
            userGoal.toLowerCase().contains(programGoal.toLowerCase())
        )
    );
  }
}
