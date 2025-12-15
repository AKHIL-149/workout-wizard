import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/session_service.dart';

/// State management for user data using Provider pattern.
///
/// Manages user profile, preferences, and session state.
/// Provides centralized access to user data across the app.
class UserProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final SessionService _sessionService = SessionService();

  // State
  UserProfile? _profile;
  List<String> _favorites = [];
  List<String> _viewedPrograms = [];
  List<String> _completedPrograms = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;

  // Getters
  UserProfile? get profile => _profile;
  List<String> get favorites => _favorites;
  List<String> get viewedPrograms => _viewedPrograms;
  List<String> get completedPrograms => _completedPrograms;
  List<String> get searchHistory => _searchHistory;
  bool get isLoading => _isLoading;
  bool get hasProfile => _profile != null;
  String get userId => _sessionService.userId;
  int get sessionCount => _sessionService.sessionCount;
  bool get isNewUser => _sessionService.isNewUser;

  /// Initialize user provider with stored data.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load user profile
      _profile = await _storageService.getLastUserProfile();

      // Load user data
      _favorites = await _storageService.getFavorites();
      _viewedPrograms = await _storageService.getViewedPrograms();
      _completedPrograms = await _storageService.getCompletedPrograms();
      _searchHistory = await _storageService.getSearchHistory();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update user profile.
  Future<void> updateProfile(UserProfile profile) async {
    await _storageService.saveUserProfile(profile);
    _profile = profile;
    notifyListeners();
  }

  /// Add program to favorites.
  Future<void> addFavorite(String programId) async {
    await _storageService.addToFavorites(programId);
    _favorites = await _storageService.getFavorites();
    notifyListeners();
  }

  /// Remove program from favorites.
  Future<void> removeFavorite(String programId) async {
    await _storageService.removeFromFavorites(programId);
    _favorites = await _storageService.getFavorites();
    notifyListeners();
  }

  /// Check if program is favorite.
  bool isFavorite(String programId) {
    return _favorites.contains(programId);
  }

  /// Track viewed program.
  Future<void> trackView(String programId) async {
    await _storageService.trackViewedProgram(programId);
    _viewedPrograms = await _storageService.getViewedPrograms();
    notifyListeners();
  }

  /// Mark program as completed.
  Future<void> markCompleted(String programId) async {
    await _storageService.markProgramCompleted(programId);
    _completedPrograms = await _storageService.getCompletedPrograms();
    notifyListeners();
  }

  /// Check if program is completed.
  bool isCompleted(String programId) {
    return _completedPrograms.contains(programId);
  }

  /// Add search query to history.
  Future<void> addSearchQuery(String query) async {
    await _storageService.addToSearchHistory(query);
    _searchHistory = await _storageService.getSearchHistory();
    notifyListeners();
  }

  /// Clear search history.
  Future<void> clearSearchHistory() async {
    await _storageService.clearSearchHistory();
    _searchHistory = [];
    notifyListeners();
  }

  /// Clear all user data.
  Future<void> clearAllData() async {
    await _storageService.clearAllData();
    _profile = null;
    _favorites = [];
    _viewedPrograms = [];
    _completedPrograms = [];
    _searchHistory = [];
    notifyListeners();
  }
}
