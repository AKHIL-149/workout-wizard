import '../models/exercise_form_rules.dart';

/// Utility for fuzzy matching exercise names to form rules
class ExerciseNameMapper {
  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final m = s1.length;
    final n = s2.length;

    // Create matrix
    final List<List<int>> matrix = List.generate(
      m + 1,
      (i) => List.filled(n + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= m; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      matrix[0][j] = j;
    }

    // Fill matrix
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[m][n];
  }

  /// Normalize exercise name for comparison
  static String _normalize(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Calculate similarity score (0-100)
  static double _calculateSimilarity(String s1, String s2) {
    final norm1 = _normalize(s1);
    final norm2 = _normalize(s2);

    if (norm1 == norm2) return 100.0;

    // Check for substring match
    if (norm1.contains(norm2) || norm2.contains(norm1)) {
      final longer = norm1.length > norm2.length ? norm1 : norm2;
      final shorter = norm1.length > norm2.length ? norm2 : norm1;
      return (shorter.length / longer.length) * 90.0;
    }

    // Calculate based on Levenshtein distance
    final maxLen = norm1.length > norm2.length ? norm1.length : norm2.length;
    final distance = _levenshteinDistance(norm1, norm2);
    final similarity = (1 - distance / maxLen) * 100;

    return similarity.clamp(0.0, 100.0);
  }

  /// Find best matching exercise from rules
  static ExerciseMatchResult findBestMatch(
    String exerciseName,
    List<ExerciseFormRules> allRules, {
    double minSimilarity = 60.0,
  }) {
    if (exerciseName.isEmpty) {
      return ExerciseMatchResult(
        match: null,
        confidence: 0.0,
        isExactMatch: false,
      );
    }

    ExerciseFormRules? bestMatch;
    double bestScore = 0.0;

    for (final rules in allRules) {
      // Check exact match with name
      if (_normalize(rules.name) == _normalize(exerciseName)) {
        return ExerciseMatchResult(
          match: rules,
          confidence: 100.0,
          isExactMatch: true,
        );
      }

      // Check exact match with aliases
      for (final alias in rules.aliases) {
        if (_normalize(alias) == _normalize(exerciseName)) {
          return ExerciseMatchResult(
            match: rules,
            confidence: 100.0,
            isExactMatch: true,
          );
        }
      }

      // Calculate fuzzy match scores
      final nameScore = _calculateSimilarity(exerciseName, rules.name);

      double aliasScore = 0.0;
      for (final alias in rules.aliases) {
        final score = _calculateSimilarity(exerciseName, alias);
        if (score > aliasScore) {
          aliasScore = score;
        }
      }

      final maxScore = nameScore > aliasScore ? nameScore : aliasScore;

      if (maxScore > bestScore) {
        bestScore = maxScore;
        bestMatch = rules;
      }
    }

    if (bestScore >= minSimilarity && bestMatch != null) {
      return ExerciseMatchResult(
        match: bestMatch,
        confidence: bestScore,
        isExactMatch: false,
      );
    }

    return ExerciseMatchResult(
      match: null,
      confidence: bestScore,
      isExactMatch: false,
    );
  }

  /// Find all potential matches above threshold
  static List<ExerciseMatchResult> findAllMatches(
    String exerciseName,
    List<ExerciseFormRules> allRules, {
    double minSimilarity = 50.0,
    int maxResults = 5,
  }) {
    final results = <ExerciseMatchResult>[];

    for (final rules in allRules) {
      // Check name
      final nameScore = _calculateSimilarity(exerciseName, rules.name);

      // Check aliases
      double aliasScore = 0.0;
      for (final alias in rules.aliases) {
        final score = _calculateSimilarity(exerciseName, alias);
        if (score > aliasScore) {
          aliasScore = score;
        }
      }

      final maxScore = nameScore > aliasScore ? nameScore : aliasScore;

      if (maxScore >= minSimilarity) {
        final isExact = _normalize(rules.name) == _normalize(exerciseName) ||
            rules.aliases.any(
              (alias) => _normalize(alias) == _normalize(exerciseName),
            );

        results.add(
          ExerciseMatchResult(
            match: rules,
            confidence: maxScore,
            isExactMatch: isExact,
          ),
        );
      }
    }

    // Sort by confidence (descending)
    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Return top N results
    return results.take(maxResults).toList();
  }

  /// Suggest corrections for misspelled exercise names
  static List<String> suggestCorrections(
    String exerciseName,
    List<ExerciseFormRules> allRules, {
    int maxSuggestions = 3,
  }) {
    final matches = findAllMatches(
      exerciseName,
      allRules,
      minSimilarity: 40.0,
      maxResults: maxSuggestions,
    );

    return matches.map((m) => m.match!.name).toList();
  }

  /// Get exercises by category
  static List<ExerciseFormRules> filterByCategory(
    List<ExerciseFormRules> allRules,
    String category,
  ) {
    return allRules
        .where((r) => _normalize(r.category) == _normalize(category))
        .toList();
  }

  /// Get all unique categories
  static List<String> getAllCategories(List<ExerciseFormRules> allRules) {
    final categories = allRules.map((r) => r.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Search exercises by keyword
  static List<ExerciseFormRules> searchByKeyword(
    List<ExerciseFormRules> allRules,
    String keyword,
  ) {
    final normalizedKeyword = _normalize(keyword);
    final results = <ExerciseFormRules>[];

    for (final rules in allRules) {
      // Check name
      if (_normalize(rules.name).contains(normalizedKeyword)) {
        results.add(rules);
        continue;
      }

      // Check aliases
      if (rules.aliases.any(
        (alias) => _normalize(alias).contains(normalizedKeyword),
      )) {
        results.add(rules);
        continue;
      }

      // Check description
      if (rules.description != null &&
          _normalize(rules.description!).contains(normalizedKeyword)) {
        results.add(rules);
        continue;
      }

      // Check category
      if (_normalize(rules.category).contains(normalizedKeyword)) {
        results.add(rules);
      }
    }

    return results;
  }

  /// Extract exercise type from name (e.g., "barbell" from "Barbell Squat")
  static String extractEquipmentType(String exerciseName) {
    final normalized = _normalize(exerciseName);

    final equipmentKeywords = {
      'barbell': 'barbell',
      'dumbbell': 'dumbbell',
      'db': 'dumbbell',
      'kettlebell': 'kettlebell',
      'kb': 'kettlebell',
      'cable': 'cable',
      'machine': 'machine',
      'bodyweight': 'bodyweight',
      'band': 'resistance band',
    };

    for (final entry in equipmentKeywords.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'bodyweight'; // Default assumption
  }

  /// Get category display name
  static String getCategoryDisplayName(String category) {
    final categoryNames = {
      'squat': 'Squat Variations',
      'hinge': 'Hip Hinge Movements',
      'horizontal_push': 'Horizontal Push',
      'vertical_push': 'Vertical Push',
      'horizontal_pull': 'Horizontal Pull',
      'vertical_pull': 'Vertical Pull',
      'core': 'Core & Stability',
      'accessory': 'Accessory Exercises',
    };

    return categoryNames[_normalize(category)] ?? category;
  }
}

/// Result of exercise name matching
class ExerciseMatchResult {
  final ExerciseFormRules? match;
  final double confidence; // 0-100
  final bool isExactMatch;

  ExerciseMatchResult({
    required this.match,
    required this.confidence,
    required this.isExactMatch,
  });

  bool get hasMatch => match != null;

  String get confidenceLevel {
    if (confidence >= 95) return 'Excellent';
    if (confidence >= 80) return 'High';
    if (confidence >= 65) return 'Medium';
    if (confidence >= 50) return 'Low';
    return 'Very Low';
  }

  @override
  String toString() {
    if (match == null) {
      return 'No match found (confidence: ${confidence.toStringAsFixed(1)}%)';
    }
    return '${match!.name} (${isExactMatch ? 'Exact' : confidenceLevel} - ${confidence.toStringAsFixed(1)}%)';
  }
}
