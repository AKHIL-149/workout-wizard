import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/recommendation.dart';

/// Service for local data persistence and offline capabilities
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Keys
  static const String _lastProfileKey = 'last_user_profile';
  static const String _recentRecommendationsKey = 'recent_recommendations';
  static const String _favoriteProgramsKey = 'favorite_programs';
  static const String _searchHistoryKey = 'search_history';
  static const String _viewedProgramsKey = 'viewed_programs';
  static const String _completedProgramsKey = 'completed_programs';

  /// Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = json.encode(profile.toJson());
    await prefs.setString(_lastProfileKey, profileJson);
  }

  /// Get last saved user profile
  Future<UserProfile?> getLastUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_lastProfileKey);
    if (profileJson == null) return null;

    try {
      final profileData = json.decode(profileJson) as Map<String, dynamic>;
      return UserProfile(
        fitnessLevel: profileData['fitness_level'] as String,
        goals: List<String>.from(profileData['goals']),
        equipment: profileData['equipment'] as String,
        preferredDuration: profileData['preferred_duration'] as String?,
        preferredFrequency: profileData['preferred_frequency'] as int?,
        preferredStyle: profileData['preferred_style'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  /// Save recent recommendations
  Future<void> saveRecommendations(List<Recommendation> recommendations) async {
    final prefs = await SharedPreferences.getInstance();
    final recsJson = json.encode(
      recommendations.map((r) => r.toJson()).toList(),
    );
    await prefs.setString(_recentRecommendationsKey, recsJson);
  }

  /// Get recent recommendations
  Future<List<Recommendation>?> getRecentRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final recsJson = prefs.getString(_recentRecommendationsKey);
    if (recsJson == null) return null;

    try {
      final recsList = json.decode(recsJson) as List;
      return recsList.map((data) {
        final programData = data as Map<String, dynamic>;
        final programId = programData['program_id'] as String? ?? 'UNKNOWN';
        return Recommendation.fromJson(programId, programData);
      }).toList();
    } catch (e) {
      return null;
    }
  }

  /// Add to favorites
  Future<void> addToFavorites(String programId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    if (!favorites.contains(programId)) {
      favorites.add(programId);
      await prefs.setStringList(_favoriteProgramsKey, favorites);
    }
  }

  /// Remove from favorites
  Future<void> removeFromFavorites(String programId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(programId);
    await prefs.setStringList(_favoriteProgramsKey, favorites);
  }

  /// Get favorites
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteProgramsKey) ?? [];
  }

  /// Check if program is favorite
  Future<bool> isFavorite(String programId) async {
    final favorites = await getFavorites();
    return favorites.contains(programId);
  }

  /// Add to search history
  Future<void> addToSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    history.remove(query); // Remove if already exists
    history.insert(0, query); // Add to beginning
    if (history.length > 10) {
      history.removeLast(); // Keep only last 10
    }
    await prefs.setStringList(_searchHistoryKey, history);
  }

  /// Get search history
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryKey) ?? [];
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  /// Track viewed program
  Future<void> trackViewedProgram(String programId) async {
    final prefs = await SharedPreferences.getInstance();
    final viewed = await getViewedPrograms();
    if (!viewed.contains(programId)) {
      viewed.add(programId);
      await prefs.setStringList(_viewedProgramsKey, viewed);
    }
  }

  /// Get viewed programs
  Future<List<String>> getViewedPrograms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_viewedProgramsKey) ?? [];
  }

  /// Mark program as completed
  Future<void> markProgramCompleted(String programId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await getCompletedPrograms();
    if (!completed.contains(programId)) {
      completed.add(programId);
      await prefs.setStringList(_completedProgramsKey, completed);
    }
  }

  /// Get completed programs
  Future<List<String>> getCompletedPrograms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedProgramsKey) ?? [];
  }

  /// Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
