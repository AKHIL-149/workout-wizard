import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recommendation.dart';

/// Search intent types
enum SearchIntent {
  quickWorkout,
  strengthTraining,
  cardio,
  flexibility,
  timeSpecific,
  equipmentSpecific,
  bodyPartSpecific,
  goalSpecific,
  general,
}

/// Parsed search query with detected intent
class ParsedQuery {
  final String originalQuery;
  final SearchIntent intent;
  final List<String> keywords;
  final Map<String, dynamic> filters;
  final double confidence;

  ParsedQuery({
    required this.originalQuery,
    required this.intent,
    required this.keywords,
    required this.filters,
    required this.confidence,
  });
}

/// Smart search service with natural language processing
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  static const String _searchHistoryKey = 'search_history';
  static const String _popularSearchesKey = 'popular_searches';

  List<String> _searchHistory = [];
  Map<String, int> _searchFrequency = {};

  // Intent detection patterns
  static const Map<SearchIntent, List<String>> _intentPatterns = {
    SearchIntent.quickWorkout: [
      'quick',
      'fast',
      'short',
      '10 min',
      '15 min',
      '20 min',
      'express',
      'rapid',
    ],
    SearchIntent.strengthTraining: [
      'strength',
      'muscle',
      'build',
      'bulk',
      'weights',
      'lifting',
      'resistance',
      'mass',
      'power',
    ],
    SearchIntent.cardio: [
      'cardio',
      'running',
      'jogging',
      'aerobic',
      'endurance',
      'stamina',
      'hiit',
      'interval',
    ],
    SearchIntent.flexibility: [
      'flexibility',
      'stretch',
      'yoga',
      'mobility',
      'pilates',
      'recover',
    ],
    SearchIntent.timeSpecific: [
      'morning',
      'evening',
      'afternoon',
      'night',
      'before work',
      'after work',
    ],
    SearchIntent.equipmentSpecific: [
      'no equipment',
      'bodyweight',
      'dumbbell',
      'barbell',
      'machine',
      'band',
      'kettlebell',
    ],
    SearchIntent.bodyPartSpecific: [
      'legs',
      'arms',
      'chest',
      'back',
      'shoulders',
      'abs',
      'core',
      'glutes',
      'biceps',
      'triceps',
    ],
    SearchIntent.goalSpecific: [
      'weight loss',
      'lose weight',
      'burn fat',
      'tone',
      'shred',
      'lean',
      'cut',
    ],
  };

  // Time indicators
  static const Map<String, String> _timeIndicators = {
    'morning': '< 30 mins',
    'quick': '< 30 mins',
    'short': '< 30 mins',
    'long': '60+ mins',
    'extended': '60+ mins',
  };

  // Equipment mappings
  static const Map<String, String> _equipmentMappings = {
    'no equipment': 'Bodyweight Only',
    'bodyweight': 'Bodyweight Only',
    'home': 'Minimal Equipment',
    'gym': 'Full Gym',
    'dumbbell': 'Full Gym',
    'barbell': 'Full Gym',
  };

  /// Initialize search service
  Future<void> initialize() async {
    await _loadSearchHistory();
  }

  /// Load search history
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final historyJson = prefs.getString(_searchHistoryKey);
    if (historyJson != null) {
      try {
        _searchHistory = List<String>.from(json.decode(historyJson));
      } catch (e) {
        _searchHistory = [];
      }
    }

    final frequencyJson = prefs.getString(_popularSearchesKey);
    if (frequencyJson != null) {
      try {
        final decoded = json.decode(frequencyJson) as Map<String, dynamic>;
        _searchFrequency = decoded.map((k, v) => MapEntry(k, v as int));
      } catch (e) {
        _searchFrequency = {};
      }
    }
  }

  /// Save search history
  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchHistoryKey, json.encode(_searchHistory));
    await prefs.setString(_popularSearchesKey, json.encode(_searchFrequency));
  }

  /// Parse natural language query
  ParsedQuery parseQuery(String query) {
    final lowerQuery = query.toLowerCase().trim();
    final words = lowerQuery.split(RegExp(r'\s+'));

    // Detect intent
    SearchIntent detectedIntent = SearchIntent.general;
    double maxConfidence = 0.0;

    for (var entry in _intentPatterns.entries) {
      int matchCount = 0;
      for (var pattern in entry.value) {
        if (lowerQuery.contains(pattern.toLowerCase())) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        double confidence = matchCount / entry.value.length;
        if (confidence > maxConfidence) {
          maxConfidence = confidence;
          detectedIntent = entry.key;
        }
      }
    }

    // Extract keywords (remove common words)
    final commonWords = {'a', 'an', 'the', 'for', 'to', 'in', 'on', 'with', 'and', 'or'};
    final keywords = words
        .where((word) => word.length > 2 && !commonWords.contains(word))
        .toList();

    // Extract filters based on query
    final filters = <String, dynamic>{};

    // Time-based filters
    for (var entry in _timeIndicators.entries) {
      if (lowerQuery.contains(entry.key)) {
        filters['duration'] = entry.value;
        break;
      }
    }

    // Equipment filters
    for (var entry in _equipmentMappings.entries) {
      if (lowerQuery.contains(entry.key)) {
        filters['equipment'] = entry.value;
        break;
      }
    }

    // Fitness level hints
    if (lowerQuery.contains('beginner') || lowerQuery.contains('start')) {
      filters['fitness_level'] = 'Beginner';
    } else if (lowerQuery.contains('advanced') || lowerQuery.contains('expert')) {
      filters['fitness_level'] = 'Advanced';
    }

    return ParsedQuery(
      originalQuery: query,
      intent: detectedIntent,
      keywords: keywords,
      filters: filters,
      confidence: maxConfidence,
    );
  }

  /// Filter recommendations based on parsed query
  List<Recommendation> filterRecommendations(
    List<Recommendation> recommendations,
    ParsedQuery parsedQuery,
  ) {
    var filtered = recommendations.toList();

    // Apply intent-based filtering
    switch (parsedQuery.intent) {
      case SearchIntent.quickWorkout:
        filtered = filtered.where((r) {
          return r.timePerWorkout <= 45; // 45 minutes or less
        }).toList();
        break;

      case SearchIntent.strengthTraining:
        filtered = filtered.where((r) {
          return r.title.toLowerCase().contains('strength') ||
                 r.title.toLowerCase().contains('power') ||
                 r.title.toLowerCase().contains('muscle') ||
                 r.primaryGoal.toLowerCase().contains('strength');
        }).toList();
        break;

      case SearchIntent.cardio:
        filtered = filtered.where((r) {
          return r.title.toLowerCase().contains('cardio') ||
                 r.title.toLowerCase().contains('conditioning') ||
                 r.title.toLowerCase().contains('endurance') ||
                 r.primaryGoal.toLowerCase().contains('cardio');
        }).toList();
        break;

      case SearchIntent.flexibility:
        filtered = filtered.where((r) {
          return r.title.toLowerCase().contains('flexibility') ||
                 r.title.toLowerCase().contains('mobility') ||
                 r.title.toLowerCase().contains('yoga') ||
                 r.primaryGoal.toLowerCase().contains('flexibility');
        }).toList();
        break;

      default:
        break;
    }

    // Apply filter constraints
    if (parsedQuery.filters.containsKey('duration')) {
      final duration = parsedQuery.filters['duration'] as String;
      filtered = filtered.where((r) {
        if (duration == '< 30 mins') return r.timePerWorkout < 30;
        if (duration == '30-45 mins') return r.timePerWorkout >= 30 && r.timePerWorkout <= 45;
        if (duration == '45-60 mins') return r.timePerWorkout > 45 && r.timePerWorkout <= 60;
        if (duration == '60+ mins') return r.timePerWorkout > 60;
        return true;
      }).toList();
    }

    if (parsedQuery.filters.containsKey('equipment')) {
      final equipment = parsedQuery.filters['equipment'] as String;
      filtered = filtered.where((r) => r.equipment == equipment).toList();
    }

    if (parsedQuery.filters.containsKey('fitness_level')) {
      final level = parsedQuery.filters['fitness_level'] as String;
      filtered = filtered.where((r) => r.primaryLevel == level).toList();
    }

    // Apply keyword matching
    if (parsedQuery.keywords.isNotEmpty) {
      filtered = filtered.where((r) {
        final searchText = '${r.title} ${r.primaryLevel} ${r.primaryGoal} ${r.equipment}'.toLowerCase();
        return parsedQuery.keywords.any((keyword) => searchText.contains(keyword));
      }).toList();
    }

    // Sort by relevance (match percentage)
    filtered.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

    return filtered;
  }

  /// Record search query
  Future<void> recordSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Add to history
    _searchHistory.remove(query); // Remove if exists
    _searchHistory.insert(0, query);

    // Keep only last 50 searches
    if (_searchHistory.length > 50) {
      _searchHistory = _searchHistory.take(50).toList();
    }

    // Update frequency
    _searchFrequency[query] = (_searchFrequency[query] ?? 0) + 1;

    await _saveSearchHistory();
  }

  /// Get search suggestions based on query
  List<String> getSuggestions(String query) {
    if (query.trim().isEmpty) {
      return getPopularSearches().take(5).toList();
    }

    final lowerQuery = query.toLowerCase();
    final suggestions = <String>[];

    // Add matching history items
    final historyMatches = _searchHistory
        .where((h) => h.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
    suggestions.addAll(historyMatches);

    // Add common search templates
    final templates = [
      'quick morning workout',
      'strength training',
      'cardio workout',
      'no equipment workout',
      'full body workout',
      'abs workout',
      'weight loss program',
      'beginner workout',
    ];

    final templateMatches = templates
        .where((t) => t.contains(lowerQuery) && !suggestions.contains(t))
        .take(3)
        .toList();
    suggestions.addAll(templateMatches);

    return suggestions.take(5).toList();
  }

  /// Get popular searches
  List<String> getPopularSearches() {
    final sorted = _searchFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  /// Get recent searches
  List<String> getRecentSearches({int limit = 10}) {
    return _searchHistory.take(limit).toList();
  }

  /// Clear search history
  Future<void> clearHistory() async {
    _searchHistory.clear();
    _searchFrequency.clear();
    await _saveSearchHistory();
  }

  // Getters
  List<String> get searchHistory => _searchHistory;
  Map<String, int> get searchFrequency => _searchFrequency;
}
