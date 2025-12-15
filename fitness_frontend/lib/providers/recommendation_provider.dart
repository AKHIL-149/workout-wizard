import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/recommendation.dart';
import '../services/hybrid_recommender_service.dart';
import '../utils/exceptions.dart';

/// State management for recommendations using Provider pattern.
///
/// Manages the state of recommendations including loading, error, and data states.
/// Provides centralized access to recommendation functionality across the app.
class RecommendationProvider with ChangeNotifier {
  final HybridRecommenderService _recommenderService = HybridRecommenderService();

  // State
  List<Recommendation> _recommendations = [];
  UserProfile? _currentProfile;
  bool _isLoading = false;
  AppException? _error;

  // Getters
  List<Recommendation> get recommendations => _recommendations;
  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  AppException? get error => _error;
  bool get hasRecommendations => _recommendations.isNotEmpty;
  bool get hasError => _error != null;

  /// Get recommendations for a user profile.
  ///
  /// This method fetches recommendations using the hybrid recommender service
  /// and updates the provider state accordingly.
  Future<void> fetchRecommendations(UserProfile profile, {int numRecommendations = 5}) async {
    _isLoading = true;
    _error = null;
    _currentProfile = profile;
    notifyListeners();

    try {
      final results = await _recommenderService.getRecommendations(
        profile,
        numRecommendations: numRecommendations,
      );

      _recommendations = results;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } on AppException catch (e) {
      _isLoading = false;
      _error = e;
      _recommendations = [];
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _error = UnknownException(
        'Failed to fetch recommendations',
        details: e.toString(),
      );
      _recommendations = [];
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh recommendations with the current profile.
  Future<void> refresh() async {
    if (_currentProfile != null) {
      await fetchRecommendations(_currentProfile!);
    }
  }

  /// Clear all recommendations and reset state.
  void clear() {
    _recommendations = [];
    _currentProfile = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Clear error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
