import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/recommendation.dart';
import '../models/user_profile.dart';
import 'on_device_recommender.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'analytics_service.dart';

/// Hybrid recommendation service
/// PRIMARY: On-device ML-like algorithm (instant, offline, private)
/// FALLBACK: Backend API (for model updates and data collection)
class HybridRecommenderService {
  static final HybridRecommenderService _instance = HybridRecommenderService._internal();
  factory HybridRecommenderService() => _instance;
  HybridRecommenderService._internal();

  final OnDeviceRecommender _onDeviceRecommender = OnDeviceRecommender();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isInitialized = false;
  bool _useBackendPrimary = false; // Set to true to use backend as primary

  /// Initialize the hybrid recommender
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize on-device recommender
    await _onDeviceRecommender.initialize();

    _isInitialized = true;
  }

  /// Get recommendations using hybrid approach
  /// Strategy: On-device FIRST, backend as fallback/enhancement
  Future<RecommendationResult> getRecommendations(UserProfile profile) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    RecommendationResult result;

    if (_useBackendPrimary && isOnline) {
      // Strategy 1: Backend Primary (current behavior)
      result = await _getWithBackendPrimary(profile, isOnline);
    } else {
      // Strategy 2: On-Device Primary (recommended for your app)
      result = await _getWithOnDevicePrimary(profile, isOnline);
    }

    // Save to cache
    await _storageService.saveRecommendations(result.recommendations);
    await _storageService.saveUserProfile(profile);

    // Track analytics
    await _analyticsService.trackEvent(
      AnalyticsEvent.recommendationsViewed,
      metadata: {
        'source': result.source.name,
        'count': result.recommendations.length,
        'online': isOnline,
      },
    );

    return result;
  }

  /// Get recommendations with on-device as primary
  Future<RecommendationResult> _getWithOnDevicePrimary(
    UserProfile profile,
    bool isOnline,
  ) async {
    try {
      // Get on-device recommendations (instant, always works)
      final onDeviceRecs = await _onDeviceRecommender.getRecommendations(profile);

      if (isOnline) {
        // Try to get backend recommendations in background for comparison/improvement
        _getBackendRecommendationsInBackground(profile);
      }

      return RecommendationResult(
        recommendations: onDeviceRecs,
        source: RecommendationSource.onDevice,
        isOffline: !isOnline,
      );
    } catch (e) {
      // On-device failed, try backend
      if (isOnline) {
        try {
          final backendRecs = await _apiService.getRecommendations(profile);
          return RecommendationResult(
            recommendations: backendRecs,
            source: RecommendationSource.backend,
            isOffline: false,
          );
        } catch (backendError) {
          // Both failed, try cache
          return await _getFromCache();
        }
      } else {
        // Offline and on-device failed, use cache
        return await _getFromCache();
      }
    }
  }

  /// Get recommendations with backend as primary
  Future<RecommendationResult> _getWithBackendPrimary(
    UserProfile profile,
    bool isOnline,
  ) async {
    if (isOnline) {
      try {
        // Try backend first
        final backendRecs = await _apiService.getRecommendations(profile);
        return RecommendationResult(
          recommendations: backendRecs,
          source: RecommendationSource.backend,
          isOffline: false,
        );
      } catch (e) {
        // Backend failed, use on-device
        final onDeviceRecs = await _onDeviceRecommender.getRecommendations(profile);
        return RecommendationResult(
          recommendations: onDeviceRecs,
          source: RecommendationSource.onDeviceFallback,
          isOffline: false,
          error: e.toString(),
        );
      }
    } else {
      // Offline, use on-device
      try {
        final onDeviceRecs = await _onDeviceRecommender.getRecommendations(profile);
        return RecommendationResult(
          recommendations: onDeviceRecs,
          source: RecommendationSource.onDevice,
          isOffline: true,
        );
      } catch (e) {
        // On-device failed, use cache
        return await _getFromCache();
      }
    }
  }

  /// Get backend recommendations in background (for analytics/improvement)
  Future<void> _getBackendRecommendationsInBackground(UserProfile profile) async {
    try {
      final backendRecs = await _apiService.getRecommendations(profile);

      // Compare with on-device results for improvement
      // This data can be sent to analytics to improve the on-device model
      await _analyticsService.trackEvent(
        AnalyticsEvent.recommendationsViewed,
        metadata: {
          'backend_comparison': true,
          'backend_count': backendRecs.length,
          'backend_top_program': backendRecs.isNotEmpty ? backendRecs.first.programId : null,
        },
      );
    } catch (e) {
      // Silent fail - this is just for background improvement
    }
  }

  /// Get from cache as last resort
  Future<RecommendationResult> _getFromCache() async {
    final cachedRecs = await _storageService.getRecentRecommendations();

    if (cachedRecs != null && cachedRecs.isNotEmpty) {
      return RecommendationResult(
        recommendations: cachedRecs,
        source: RecommendationSource.cache,
        isOffline: true,
      );
    }

    throw Exception('No recommendations available. Please connect to the internet and try again.');
  }

  /// Toggle between on-device and backend primary
  void setBackendPrimary(bool usePrimary) {
    _useBackendPrimary = usePrimary;
  }

  /// Get current strategy
  String get currentStrategy => _useBackendPrimary ? 'Backend Primary' : 'On-Device Primary';

  /// Check if on-device recommender is ready
  bool get isOnDeviceReady => _onDeviceRecommender.isInitialized;

  /// Get program count in on-device database
  int get onDeviceProgramCount => _onDeviceRecommender.programCount;
}

/// Result of recommendation query
class RecommendationResult {
  final List<Recommendation> recommendations;
  final RecommendationSource source;
  final bool isOffline;
  final String? error;

  RecommendationResult({
    required this.recommendations,
    required this.source,
    required this.isOffline,
    this.error,
  });

  /// Get user-friendly source description
  String get sourceDescription {
    switch (source) {
      case RecommendationSource.onDevice:
        return isOffline
            ? 'Offline Mode - On-Device Algorithm'
            : 'On-Device Algorithm (Instant)';
      case RecommendationSource.backend:
        return 'Backend ML Model (Latest)';
      case RecommendationSource.onDeviceFallback:
        return 'On-Device Algorithm (Backend Unavailable)';
      case RecommendationSource.cache:
        return 'Cached Results (Previously Fetched)';
    }
  }

  /// Get icon for source
  String get sourceIcon {
    switch (source) {
      case RecommendationSource.onDevice:
        return '📱';
      case RecommendationSource.backend:
        return '☁️';
      case RecommendationSource.onDeviceFallback:
        return '📱';
      case RecommendationSource.cache:
        return '💾';
    }
  }
}

/// Source of recommendations
enum RecommendationSource {
  onDevice,           // On-device algorithm (primary)
  backend,            // Backend API
  onDeviceFallback,   // On-device used because backend failed
  cache,              // From local storage cache
}
