import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'pose_detection_service.dart';
// import 'tensorflow_lite_pose_service.dart';  // Disabled: tflite_flutter has FFI issues

/// Factory for creating platform-specific pose detection services
class PoseDetectionFactory {
  /// Create the appropriate pose detection service based on the current platform
  static PoseDetectionService createPoseDetectionService({
    int frameSkipCount = 2,
  }) {
    // Check if running on web
    if (kIsWeb) {
      throw UnsupportedError('TensorFlow Lite not available. Web support requires tflite_flutter package.');
    }

    // Check if running on desktop platforms
    if (_isDesktop()) {
      throw UnsupportedError('TensorFlow Lite not available. Desktop support requires tflite_flutter package.');
    }

    // Default to ML Kit for mobile platforms (iOS/Android)
    return MLKitPoseDetectionService(
      frameSkipCount: frameSkipCount,
    );
  }

  /// Check if the current platform is desktop (Windows, macOS, or Linux)
  static bool _isDesktop() {
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      // Platform.isX throws on web, so we catch and return false
      return false;
    }
  }

  /// Check if the current platform is mobile (iOS or Android)
  static bool isMobile() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Check if the current platform is web
  static bool isWeb() {
    return kIsWeb;
  }

  /// Check if the current platform is desktop
  static bool isDesktop() {
    return _isDesktop();
  }

  /// Get a human-readable platform name
  static String getPlatformName() {
    if (kIsWeb) return 'Web';

    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      // Ignore platform detection errors
    }

    return 'Unknown';
  }

  /// Get recommended settings for the current platform
  static PoseDetectionSettings getRecommendedSettings() {
    if (kIsWeb) {
      return PoseDetectionSettings(
        frameSkipCount: 3, // Skip more frames on web for performance
        mode: PoseDetectionMode.base,
        useTensorFlowLite: true,
        description: 'Optimized for web browsers',
      );
    }

    if (_isDesktop()) {
      return PoseDetectionSettings(
        frameSkipCount: 2,
        mode: PoseDetectionMode.base,
        useTensorFlowLite: true,
        description: 'Optimized for desktop platforms',
      );
    }

    // Mobile settings
    return PoseDetectionSettings(
      frameSkipCount: 2,
      mode: PoseDetectionMode.base,
      useTensorFlowLite: false,
      description: 'Optimized for mobile devices using ML Kit',
    );
  }

  /// Create a high-accuracy pose detection service
  /// Note: This may be slower but more accurate
  static PoseDetectionService createHighAccuracyService() {
    if (kIsWeb || _isDesktop()) {
      throw UnsupportedError('TensorFlow Lite not available. Web/Desktop support requires tflite_flutter package.');
    }

    // Mobile: use fewer frame skips for higher accuracy
    return MLKitPoseDetectionService(
      frameSkipCount: 1,
    );
  }

  /// Create a performance-optimized pose detection service
  /// Note: This prioritizes speed over accuracy
  static PoseDetectionService createPerformanceOptimizedService() {
    if (kIsWeb || _isDesktop()) {
      throw UnsupportedError('TensorFlow Lite not available. Web/Desktop support requires tflite_flutter package.');
    }

    // Mobile: use more frame skipping for better performance
    return MLKitPoseDetectionService(
      frameSkipCount: 4,
    );
  }
}

/// Settings for pose detection configuration
class PoseDetectionSettings {
  final int frameSkipCount;
  final PoseDetectionMode mode;
  final bool useTensorFlowLite;
  final String description;

  PoseDetectionSettings({
    required this.frameSkipCount,
    required this.mode,
    required this.useTensorFlowLite,
    required this.description,
  });

  @override
  String toString() {
    return 'PoseDetectionSettings('
        'frameSkipCount: $frameSkipCount, '
        'mode: $mode, '
        'useTensorFlowLite: $useTensorFlowLite, '
        'description: $description'
        ')';
  }
}
