/// Application-wide constants for consistent configuration
class AppConstants {
  // Pose Detection Confidence Thresholds
  static const double minPoseConfidence = 0.5;
  static const double highPoseConfidence = 0.8;
  static const double minLandmarkConfidence = 0.6;

  // Form Analysis
  static const int defaultFeedbackCooldownMs = 1000;
  static const int maxHistorySize = 100;

  // Search History
  static const int maxSearchHistoryItems = 10;

  // Timeouts
  static const Duration defaultCameraTimeout = Duration(seconds: 10);
  static const Duration defaultApiTimeout = Duration(seconds: 30);

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // UI Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Font Sizes
  static const double headingFontSize = 24.0;
  static const double titleFontSize = 18.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;

  // Border Radius
  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 24.0;

  // Form Score Thresholds (percentages)
  static const double excellentFormThreshold = 90.0;
  static const double goodFormThreshold = 85.0;
  static const double averageFormThreshold = 70.0;
  static const double poorFormThreshold = 60.0;

  // Knee Cave Detection
  static const double kneeCaveThreshold = 0.05;

  // Exercise Name Matching
  static const double highSimilarityThreshold = 60.0;
  static const double mediumSimilarityThreshold = 50.0;
  static const double lowSimilarityThreshold = 40.0;

  // Camera Settings
  static const int maxCameraRetries = 3;

  // Private constructor to prevent instantiation
  AppConstants._();
}
