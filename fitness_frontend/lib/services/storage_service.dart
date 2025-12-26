import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/recommendation.dart';
import '../utils/constants.dart';

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

  /// Initialize storage service by preloading SharedPreferences
  Future<void> initialize() async {
    // Pre-initialize SharedPreferences to improve first-access performance
    await SharedPreferences.getInstance();
  }

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

    // Use more efficient approach: filter and rebuild list
    final updatedHistory = [
      query,
      ...history.where((item) => item != query),
    ];

    // Limit to most recent items
    final limitedHistory = updatedHistory.length > AppConstants.maxSearchHistoryItems
        ? updatedHistory.sublist(0, AppConstants.maxSearchHistoryItems)
        : updatedHistory;

    await prefs.setStringList(_searchHistoryKey, limitedHistory);
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

  /// Export storage data for backup
  Future<Map<String, dynamic>> exportData() async {
    final profile = await getLastUserProfile();
    final favorites = await getFavorites();
    final searchHistory = await getSearchHistory();
    final viewedPrograms = await getViewedPrograms();
    final completedPrograms = await getCompletedPrograms();

    return {
      'profile': profile?.toJson(),
      'favorites': favorites,
      'search_history': searchHistory,
      'viewed_programs': viewedPrograms,
      'completed_programs': completedPrograms,
    };
  }

  /// Import storage data from backup
  Future<void> importData(Map<String, dynamic> data, {bool merge = false}) async {
    // Import user profile (always replace)
    if (data['user_profile'] != null) {
      final profileData = data['user_profile'] as Map<String, dynamic>;
      final profile = UserProfile.fromJson(profileData);
      await saveUserProfile(profile);
    }

    // Import favorites
    if (data['favorites'] != null) {
      final backupFavorites = List<String>.from(data['favorites'] as List);
      if (merge) {
        final currentFavorites = await getFavorites();
        final mergedFavorites = {...currentFavorites, ...backupFavorites}.toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_favoriteProgramsKey, mergedFavorites);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_favoriteProgramsKey, backupFavorites);
      }
    }

    // Import search history
    if (data['search_history'] != null) {
      final backupHistory = List<String>.from(data['search_history'] as List);
      if (merge) {
        final currentHistory = await getSearchHistory();
        final mergedHistory = [...backupHistory, ...currentHistory]
            .toSet()
            .toList()
            .take(AppConstants.maxSearchHistoryItems)
            .toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_searchHistoryKey, mergedHistory);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_searchHistoryKey, backupHistory);
      }
    }

    // Import viewed programs
    if (data['viewed_programs'] != null) {
      final backupViewed = List<String>.from(data['viewed_programs'] as List);
      if (merge) {
        final currentViewed = await getViewedPrograms();
        final mergedViewed = {...currentViewed, ...backupViewed}.toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_viewedProgramsKey, mergedViewed);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_viewedProgramsKey, backupViewed);
      }
    }

    // Import completed programs
    if (data['completed_programs'] != null) {
      final backupCompleted = List<String>.from(data['completed_programs'] as List);
      if (merge) {
        final currentCompleted = await getCompletedPrograms();
        final mergedCompleted = {...currentCompleted, ...backupCompleted}.toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_completedProgramsKey, mergedCompleted);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_completedProgramsKey, backupCompleted);
      }
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
