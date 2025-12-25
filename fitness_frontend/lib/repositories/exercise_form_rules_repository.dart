import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise_form_rules.dart';
import '../models/form_analysis.dart';
import '../models/pose_data.dart';
import '../utils/exercise_name_mapper.dart';

/// Repository for loading and caching exercise form rules
class ExerciseFormRulesRepository {
  ExerciseFormRulesDatabase? _database;
  bool _isLoaded = false;

  /// Load exercise rules from JSON asset
  Future<void> loadRules() async {
    if (_isLoaded && _database != null) {
      return; // Already loaded
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/exercise_form_rules.json',
      );

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _database = ExerciseFormRulesDatabase.fromJson(jsonMap);
      _isLoaded = true;
    } catch (e) {
      throw Exception('Failed to load exercise form rules: $e');
    }
  }

  /// Get all exercise rules
  List<ExerciseFormRules> getAllExercises() {
    final db = _ensureLoaded();
    return db.exercises;
  }

  /// Find exercise rules by name (fuzzy matching with ExerciseNameMapper)
  ExerciseFormRules? findExerciseByName(String name) {
    final db = _ensureLoaded();

    // Use ExerciseNameMapper for intelligent fuzzy matching
    final matchResult = ExerciseNameMapper.findBestMatch(
      name,
      db.exercises,
      minSimilarity: 60.0,
    );

    if (matchResult.hasMatch) {
      return matchResult.match;
    }

    // Fallback to old method if no match found
    return db.findExercise(name);
  }

  /// Find exercise with detailed match information
  ExerciseMatchResult findExerciseWithConfidence(String name) {
    final db = _ensureLoaded();
    return ExerciseNameMapper.findBestMatch(
      name,
      db.exercises,
      minSimilarity: 50.0,
    );
  }

  /// Get multiple potential matches for an exercise name
  List<ExerciseMatchResult> findAllPotentialMatches(
    String name, {
    int maxResults = 5,
  }) {
    final db = _ensureLoaded();
    return ExerciseNameMapper.findAllMatches(
      name,
      db.exercises,
      minSimilarity: 40.0,
      maxResults: maxResults,
    );
  }

  /// Get exercise rules by ID
  ExerciseFormRules? getExerciseById(String id) {
    final db = _ensureLoaded();
    try {
      return db.exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get violation definition
  ViolationDefinition? getViolationDefinition(String violationType) {
    final db = _ensureLoaded();
    return db.getViolationDefinition(violationType);
  }

  /// Get all exercises of a specific type
  List<ExerciseFormRules> getExercisesByType(ExerciseType type) {
    final db = _ensureLoaded();
    return db.exercises.where((e) => e.type == type).toList();
  }

  /// Get all exercises by category
  List<ExerciseFormRules> getExercisesByCategory(String category) {
    final db = _ensureLoaded();
    return ExerciseNameMapper.filterByCategory(
      db.exercises,
      category,
    );
  }

  /// Get all unique categories
  List<String> getAllCategories() {
    final db = _ensureLoaded();
    return ExerciseNameMapper.getAllCategories(db.exercises);
  }

  /// Get exercises grouped by category
  Map<String, List<ExerciseFormRules>> getExercisesGroupedByCategory() {
    _ensureLoaded();

    final groups = <String, List<ExerciseFormRules>>{};
    final categories = getAllCategories();

    for (final category in categories) {
      groups[category] = getExercisesByCategory(category);
    }

    return groups;
  }

  /// Search exercises by partial name match
  List<ExerciseFormRules> searchExercises(String query) {
    final db = _ensureLoaded();
    final lowerQuery = query.toLowerCase();

    return db.exercises.where((exercise) {
      return exercise.matchesName(lowerQuery);
    }).toList();
  }

  /// Get fallback rules for unsupported exercises
  /// Returns intelligent fallback based on exercise name/category
  ExerciseFormRules getFallbackRules(String exerciseName) {
    // Try to infer category from name
    String category = 'other';
    ExerciseType type = ExerciseType.other;

    final lowerName = exerciseName.toLowerCase();

    // Detect category from name keywords
    if (lowerName.contains('squat') || lowerName.contains('lunge')) {
      category = 'squat';
      type = ExerciseType.squat;
    } else if (lowerName.contains('deadlift') || lowerName.contains('hinge') ||
        lowerName.contains('good morning')) {
      category = 'hinge';
      type = ExerciseType.deadlift;
    } else if (lowerName.contains('push') || lowerName.contains('press') ||
        lowerName.contains('bench')) {
      if (lowerName.contains('shoulder') || lowerName.contains('overhead') ||
          lowerName.contains('military')) {
        category = 'vertical_push';
        type = ExerciseType.overheadPress;
      } else {
        category = 'horizontal_push';
        type = ExerciseType.benchPress;
      }
    } else if (lowerName.contains('pull') || lowerName.contains('row')) {
      if (lowerName.contains('up') || lowerName.contains('chin') ||
          lowerName.contains('lat')) {
        category = 'vertical_pull';
      } else {
        category = 'horizontal_pull';
      }
    } else if (lowerName.contains('plank') || lowerName.contains('core') ||
        lowerName.contains('crunch') || lowerName.contains('sit')) {
      category = 'core';
    } else if (lowerName.contains('curl') || lowerName.contains('extension') ||
        lowerName.contains('raise') || lowerName.contains('fly')) {
      category = 'accessory';
    }

    // Create category-specific fallback rules
    final angleRules = <AngleRule>[];
    final alignmentRules = <AlignmentRule>[];
    RepDetectionRule repDetection;

    switch (category) {
      case 'squat':
        angleRules.addAll([
          const AngleRule(
            name: 'knee_angle',
            joints: ['LEFT_HIP', 'LEFT_KNEE', 'LEFT_ANKLE'],
            minDegrees: 70,
            maxDegrees: 100,
            phase: ExercisePhase.bottom,
            violationType: 'SHALLOW_SQUAT',
            message: 'Squat to at least parallel depth',
            severity: Severity.warning,
          ),
          const AngleRule(
            name: 'back_angle',
            joints: ['LEFT_SHOULDER', 'LEFT_HIP', 'LEFT_KNEE'],
            minDegrees: 140,
            maxDegrees: 185,
            phase: ExercisePhase.all,
            violationType: 'BACK_ROUNDING',
            message: 'Keep back straight and chest up',
            severity: Severity.critical,
          ),
        ]);
        repDetection = const RepDetectionRule(
          keyJoint: 'LEFT_HIP',
          axis: MovementAxis.y,
          threshold: 0.15,
          direction: MovementDirection.downThenUp,
          holdTimeMs: 200,
        );
        break;

      case 'hinge':
        angleRules.addAll([
          const AngleRule(
            name: 'back_straight',
            joints: ['LEFT_SHOULDER', 'LEFT_HIP', 'LEFT_KNEE'],
            minDegrees: 150,
            maxDegrees: 185,
            phase: ExercisePhase.all,
            violationType: 'BACK_ROUNDING',
            message: 'Maintain neutral spine throughout',
            severity: Severity.critical,
          ),
        ]);
        repDetection = const RepDetectionRule(
          keyJoint: 'LEFT_HIP',
          axis: MovementAxis.y,
          threshold: 0.18,
          direction: MovementDirection.upThenDown,
          holdTimeMs: 300,
        );
        break;

      case 'horizontal_push':
      case 'vertical_push':
        angleRules.addAll([
          const AngleRule(
            name: 'elbow_extension',
            joints: ['LEFT_SHOULDER', 'LEFT_ELBOW', 'LEFT_WRIST'],
            minDegrees: 165,
            maxDegrees: 185,
            phase: ExercisePhase.top,
            violationType: 'LOCKOUT_ISSUE',
            message: 'Fully extend arms at top',
            severity: Severity.info,
          ),
        ]);
        repDetection = RepDetectionRule(
          keyJoint: category == 'horizontal_push' ? 'LEFT_WRIST' : 'LEFT_WRIST',
          axis: MovementAxis.y,
          threshold: 0.12,
          direction: category == 'horizontal_push'
              ? MovementDirection.downThenUp
              : MovementDirection.upThenDown,
          holdTimeMs: 250,
        );
        break;

      case 'core':
        angleRules.addAll([
          const AngleRule(
            name: 'body_alignment',
            joints: ['LEFT_ANKLE', 'LEFT_HIP', 'LEFT_SHOULDER'],
            minDegrees: 165,
            maxDegrees: 185,
            phase: ExercisePhase.all,
            violationType: 'HIP_SAG',
            message: 'Maintain straight body line',
            severity: Severity.critical,
          ),
        ]);
        repDetection = const RepDetectionRule(
          keyJoint: 'LEFT_HIP',
          axis: MovementAxis.y,
          threshold: 0.05,
          direction: MovementDirection.downThenUp,
          holdTimeMs: 1000,
        );
        break;

      default:
        // Generic fallback for unknown exercises
        angleRules.add(
          const AngleRule(
            name: 'back_straight',
            joints: ['LEFT_SHOULDER', 'LEFT_HIP', 'LEFT_KNEE'],
            minDegrees: 140,
            maxDegrees: 185,
            phase: ExercisePhase.all,
            violationType: 'BACK_ROUNDING',
            message: 'Keep your back straight',
            severity: Severity.warning,
          ),
        );
        repDetection = const RepDetectionRule(
          keyJoint: 'LEFT_HIP',
          axis: MovementAxis.y,
          threshold: 0.1,
          direction: MovementDirection.downThenUp,
          holdTimeMs: 200,
        );
    }

    return ExerciseFormRules(
      id: 'fallback_${category}_${exerciseName.toLowerCase().replaceAll(' ', '_')}',
      name: exerciseName,
      aliases: [exerciseName.toLowerCase()],
      type: type,
      category: category,
      description: 'Auto-generated form rules for $exerciseName ($category)',
      angleRules: angleRules,
      alignmentRules: alignmentRules,
      repDetection: repDetection,
    );
  }

  /// Get suggested corrections for misspelled exercise name
  List<String> getSuggestedCorrections(String exerciseName, {int max = 3}) {
    final db = _ensureLoaded();
    return ExerciseNameMapper.suggestCorrections(
      exerciseName,
      db.exercises,
      maxSuggestions: max,
    );
  }

  /// Check if repository has been loaded
  bool get isLoaded => _isLoaded;

  /// Get total number of supported exercises
  int get exerciseCount {
    final db = _ensureLoaded();
    return db.exercises.length;
  }

  /// Get all violation types
  List<String> getAllViolationTypes() {
    final db = _ensureLoaded();
    return db.violations.keys.toList();
  }

  /// Clear cached data (for testing or forcing reload)
  void clearCache() {
    _database = null;
    _isLoaded = false;
  }

  /// Ensure rules are loaded before accessing
  ExerciseFormRulesDatabase _ensureLoaded() {
    if (!_isLoaded || _database == null) {
      throw StateError(
        'Exercise form rules not loaded. Call loadRules() first.',
      );
    }
    return _database!;
  }

  /// Get exercise suggestions based on partial input
  /// Useful for autocomplete or search
  List<String> getSuggestions(String partialName, {int limit = 5}) {
    _ensureLoaded();

    final matches = searchExercises(partialName);
    final suggestions = <String>[];

    for (final exercise in matches) {
      suggestions.add(exercise.name);
      if (suggestions.length >= limit) break;
    }

    return suggestions;
  }

  /// Get exercises that match multiple keywords
  List<ExerciseFormRules> findExercisesByKeywords(List<String> keywords) {
    final db = _ensureLoaded();

    return db.exercises.where((exercise) {
      final searchableText = '${exercise.name} ${exercise.aliases.join(' ')}'
          .toLowerCase();

      // Check if all keywords are present
      return keywords.every((keyword) =>
          searchableText.contains(keyword.toLowerCase()));
    }).toList();
  }

  /// Get detailed statistics about rules database
  Map<String, dynamic> getStatistics() {
    final db = _ensureLoaded();

    final stats = <String, dynamic>{};
    stats['totalExercises'] = db.exercises.length;
    stats['totalViolations'] = db.violations.length;

    final typeCounts = <String, int>{};
    for (final exercise in db.exercises) {
      final typeName = exercise.type.toString().split('.').last;
      typeCounts[typeName] = (typeCounts[typeName] ?? 0) + 1;
    }
    stats['exercisesByType'] = typeCounts;

    int totalAngleRules = 0;
    int totalAlignmentRules = 0;
    for (final exercise in db.exercises) {
      totalAngleRules += exercise.angleRules.length;
      totalAlignmentRules += exercise.alignmentRules.length;
    }
    stats['totalAngleRules'] = totalAngleRules;
    stats['totalAlignmentRules'] = totalAlignmentRules;

    return stats;
  }
}
