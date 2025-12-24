import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/recommendation.dart';
import '../models/user_profile.dart';

/// On-device recommendation engine using rule-based scoring algorithm
/// This is the PRIMARY recommendation method, with backend as fallback
class OnDeviceRecommender {
  static final OnDeviceRecommender _instance = OnDeviceRecommender._internal();
  factory OnDeviceRecommender() => _instance;
  OnDeviceRecommender._internal();

  List<Recommendation> _programDatabase = [];
  bool _isInitialized = false;

  /// Initialize by loading embedded program database
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load programs from embedded JSON
      final jsonString = await rootBundle.loadString('assets/data/programs_database.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Parse the map structure: {"FP000001": {...}, "FP000002": {...}}
      _programDatabase = jsonData.entries.map((entry) {
        final programId = entry.key;
        final programData = entry.value as Map<String, dynamic>;
        return Recommendation.fromJson(programId, programData);
      }).toList();

      _isInitialized = true;
      debugPrint('OnDeviceRecommender: ✅ On-device recommender initialized with ${_programDatabase.length} programs');
    } catch (e) {
      debugPrint('OnDeviceRecommender: ❌ Failed to initialize on-device recommender: $e');
      _isInitialized = false;
    }
  }

  /// Get recommendations using on-device algorithm
  Future<List<Recommendation>> getRecommendations(UserProfile profile) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_programDatabase.isEmpty) {
      throw Exception('Program database not loaded');
    }

    // Score all programs based on user profile
    final scoredPrograms = _programDatabase.map((program) {
      final score = _calculateMatchScore(program, profile);
      return _ScoredProgram(program, score);
    }).toList();

    // Sort by score (highest first)
    scoredPrograms.sort((a, b) => b.score.compareTo(a.score));

    // Take top 10 and convert scores to percentages
    final topPrograms = scoredPrograms.take(10).map((scored) {
      // Convert score to match percentage (0-100)
      final matchPercentage = (scored.score * 100).clamp(0, 100).toInt();

      // Create new recommendation with calculated match percentage
      return scored.program.copyWith(matchPercentage: matchPercentage);
    }).toList();

    return topPrograms;
  }

  /// Calculate match score for a program (0.0 to 1.0)
  double _calculateMatchScore(Recommendation program, UserProfile profile) {
    double score = 0.0;

    // 1. Fitness Level Match (Weight: 25%)
    final levelScore = _scoreFitnessLevel(program.primaryLevel, profile.fitnessLevel);
    score += levelScore * 0.25;

    // 2. Goal Match (Weight: 30%)
    final goalScore = _scoreGoals(program.primaryGoal, profile.goals);
    score += goalScore * 0.30;

    // 3. Equipment Match (Weight: 20%)
    final equipmentScore = _scoreEquipment(program.equipment, profile.equipment);
    score += equipmentScore * 0.20;

    // 4. Time Preference Match (Weight: 15%)
    if (profile.preferredDuration != null) {
      final durationScore = _scoreDuration(
        program.timePerWorkout,
        profile.preferredDuration!,
      );
      score += durationScore * 0.15;
    } else {
      // No preference = slight bonus to shorter workouts
      final durationScore = program.timePerWorkout <= 45 ? 0.8 : 0.6;
      score += durationScore * 0.15;
    }

    // 5. Frequency Preference Match (Weight: 10%)
    if (profile.preferredFrequency != null) {
      final frequencyScore = _scoreFrequency(
        program.workoutFrequency,
        profile.preferredFrequency!,
      );
      score += frequencyScore * 0.10;
    } else {
      // Default: 3-4 days is optimal for most
      final frequencyScore = (program.workoutFrequency >= 3 && program.workoutFrequency <= 4) ? 1.0 : 0.7;
      score += frequencyScore * 0.10;
    }

    // Bonus: Programs with more exercises (comprehensive programs)
    if (program.totalExercises > 200) {
      score += 0.03;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Score fitness level match
  double _scoreFitnessLevel(String programLevel, String userLevel) {
    // Exact match
    if (programLevel.toLowerCase() == userLevel.toLowerCase()) {
      return 1.0;
    }

    // Define level hierarchy
    final levels = ['beginner', 'novice', 'intermediate', 'advanced'];
    final programLevelIndex = levels.indexWhere((l) => programLevel.toLowerCase().contains(l));
    final userLevelIndex = levels.indexWhere((l) => userLevel.toLowerCase().contains(l));

    if (programLevelIndex == -1 || userLevelIndex == -1) {
      return 0.5; // Unknown level
    }

    // One level difference (e.g., Intermediate program for Beginner)
    final diff = (programLevelIndex - userLevelIndex).abs();
    if (diff == 1) {
      // Slightly easier program is good
      if (programLevelIndex < userLevelIndex) return 0.7;
      // Slightly harder is okay too
      return 0.6;
    }

    // Two levels difference
    if (diff == 2) return 0.3;

    // Too far apart
    return 0.1;
  }

  /// Score goal match
  double _scoreGoals(String programGoal, List<String> userGoals) {
    if (userGoals.isEmpty) return 0.5;

    final programGoalLower = programGoal.toLowerCase();

    // Check for exact matches
    for (var userGoal in userGoals) {
      final userGoalLower = userGoal.toLowerCase();

      // Exact match
      if (programGoalLower.contains(userGoalLower) || userGoalLower.contains(programGoalLower)) {
        return 1.0;
      }
    }

    // Check for related goals
    final relatedGoals = {
      'strength': ['muscle building', 'powerlifting', 'bodybuilding', 'performance'],
      'muscle building': ['strength', 'bodybuilding', 'mass'],
      'weight loss': ['endurance', 'general fitness', 'cardio'],
      'endurance': ['cardio', 'weight loss', 'general fitness'],
      'flexibility': ['mobility', 'yoga', 'recovery'],
      'general fitness': ['weight loss', 'endurance', 'health'],
    };

    for (var userGoal in userGoals) {
      final userGoalLower = userGoal.toLowerCase();
      final related = relatedGoals[userGoalLower] ?? [];

      for (var relatedGoal in related) {
        if (programGoalLower.contains(relatedGoal)) {
          return 0.7; // Related goal match
        }
      }
    }

    // No match
    return 0.3;
  }

  /// Score equipment match
  double _scoreEquipment(String programEquipment, String userEquipment) {
    final programEq = programEquipment.toLowerCase();
    final userEq = userEquipment.toLowerCase();

    // Exact match
    if (programEq == userEq) return 1.0;

    // Equipment hierarchy (what can be used where)
    final equipmentCompatibility = {
      'bodyweight only': ['bodyweight only', 'minimal equipment', 'full gym'],
      'minimal equipment': ['minimal equipment', 'full gym'],
      'full gym': ['full gym'],
      'at home': ['bodyweight only', 'minimal equipment', 'at home'],
      'dumbbell only': ['minimal equipment', 'full gym', 'dumbbell only'],
    };

    final userCompatible = equipmentCompatibility[userEq] ?? [userEq];

    if (userCompatible.any((eq) => programEq.contains(eq))) {
      return 0.9;
    }

    // User has more equipment than needed (always okay)
    if (userEq.contains('full gym') && !programEq.contains('full gym')) {
      return 0.85;
    }

    if (userEq.contains('minimal') && programEq.contains('bodyweight')) {
      return 0.85;
    }

    // Partial match
    return 0.4;
  }

  /// Score duration match
  double _scoreDuration(int programMinutes, String preferredDuration) {
    // Parse preferred duration
    final durationRanges = {
      '< 30 mins': (0, 30),
      '30-45 mins': (30, 45),
      '45-60 mins': (45, 60),
      '60-75 mins': (60, 75),
      '75-90 mins': (75, 90),
      '90+ mins': (90, 999),
    };

    final range = durationRanges[preferredDuration];
    if (range == null) return 0.5;

    final (min, max) = range;

    // Within range
    if (programMinutes >= min && programMinutes <= max) {
      return 1.0;
    }

    // Calculate distance from range
    if (programMinutes < min) {
      final diff = min - programMinutes;
      if (diff <= 10) return 0.8; // Close enough
      if (diff <= 20) return 0.6;
      return 0.4;
    } else {
      final diff = programMinutes - max;
      if (diff <= 10) return 0.8;
      if (diff <= 20) return 0.6;
      return 0.4;
    }
  }

  /// Score frequency match
  double _scoreFrequency(int programFrequency, int preferredFrequency) {
    // Exact match
    if (programFrequency == preferredFrequency) return 1.0;

    // One day difference
    if ((programFrequency - preferredFrequency).abs() == 1) {
      return 0.8;
    }

    // Two days difference
    if ((programFrequency - preferredFrequency).abs() == 2) {
      return 0.6;
    }

    // Too different
    return 0.3;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  int get programCount => _programDatabase.length;
  List<Recommendation> get allPrograms => List.unmodifiable(_programDatabase);
}

/// Helper class to store program with score
class _ScoredProgram {
  final Recommendation program;
  final double score;

  _ScoredProgram(this.program, this.score);
}
