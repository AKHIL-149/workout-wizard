import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

/// Platform-specific performance configuration for pose detection
/// Optimizes frame rates, resolution, and processing settings per platform
class PlatformPerformanceConfig {
  final String platformName;
  final int frameSkipCount;
  final ResolutionPreset cameraResolution;
  final int maxFPS;
  final bool enableGPUAcceleration;
  final int imageProcessingThreads;
  final PerformanceProfile profile;
  final String description;

  const PlatformPerformanceConfig({
    required this.platformName,
    required this.frameSkipCount,
    required this.cameraResolution,
    required this.maxFPS,
    required this.enableGPUAcceleration,
    required this.imageProcessingThreads,
    required this.profile,
    required this.description,
  });

  /// Get optimized configuration for current platform
  static PlatformPerformanceConfig getOptimizedConfig() {
    if (kIsWeb) {
      return _getWebConfig();
    }

    try {
      if (Platform.isAndroid) {
        return _getAndroidConfig();
      } else if (Platform.isIOS) {
        return _getIOSConfig();
      } else if (Platform.isWindows) {
        return _getWindowsConfig();
      } else if (Platform.isMacOS) {
        return _getMacOSConfig();
      } else if (Platform.isLinux) {
        return _getLinuxConfig();
      }
    } catch (e) {
      // Fallback for unknown platforms
    }

    return _getDefaultConfig();
  }

  /// Get configuration for specific performance profile
  static PlatformPerformanceConfig getConfigForProfile(
    PerformanceProfile profile,
  ) {
    final baseConfig = getOptimizedConfig();

    switch (profile) {
      case PerformanceProfile.lowPower:
        return PlatformPerformanceConfig(
          platformName: baseConfig.platformName,
          frameSkipCount: baseConfig.frameSkipCount + 2,
          cameraResolution: ResolutionPreset.low,
          maxFPS: 15,
          enableGPUAcceleration: false,
          imageProcessingThreads: 1,
          profile: PerformanceProfile.lowPower,
          description: 'Battery-saving mode with reduced accuracy',
        );

      case PerformanceProfile.balanced:
        return baseConfig; // Use optimized defaults

      case PerformanceProfile.highPerformance:
        return PlatformPerformanceConfig(
          platformName: baseConfig.platformName,
          frameSkipCount: baseConfig.frameSkipCount > 0
              ? baseConfig.frameSkipCount - 1
              : 0,
          cameraResolution: ResolutionPreset.high,
          maxFPS: 30,
          enableGPUAcceleration: true,
          imageProcessingThreads: baseConfig.imageProcessingThreads,
          profile: PerformanceProfile.highPerformance,
          description: 'Maximum accuracy with higher resource usage',
        );

      case PerformanceProfile.highAccuracy:
        return PlatformPerformanceConfig(
          platformName: baseConfig.platformName,
          frameSkipCount: 0, // Process every frame
          cameraResolution: ResolutionPreset.veryHigh,
          maxFPS: 60,
          enableGPUAcceleration: true,
          imageProcessingThreads: baseConfig.imageProcessingThreads,
          profile: PerformanceProfile.highAccuracy,
          description: 'Highest accuracy mode (requires powerful device)',
        );
    }
  }

  // Platform-specific configurations

  static PlatformPerformanceConfig _getWebConfig() {
    return const PlatformPerformanceConfig(
      platformName: 'Web',
      frameSkipCount: 3, // Skip more frames on web for performance
      cameraResolution: ResolutionPreset.medium,
      maxFPS: 15, // Lower FPS for web compatibility
      enableGPUAcceleration: false, // Limited GPU access in browser
      imageProcessingThreads: 1,
      profile: PerformanceProfile.balanced,
      description: 'Web browsers - prioritizes compatibility',
    );
  }

  static PlatformPerformanceConfig _getAndroidConfig() {
    return const PlatformPerformanceConfig(
      platformName: 'Android',
      frameSkipCount: 2,
      cameraResolution: ResolutionPreset.medium,
      maxFPS: 24,
      enableGPUAcceleration: true, // ML Kit uses GPU on Android
      imageProcessingThreads: 2,
      profile: PerformanceProfile.balanced,
      description: 'Android devices - uses ML Kit with GPU acceleration',
    );
  }

  static PlatformPerformanceConfig _getIOSConfig() {
    return const PlatformPerformanceConfig(
      platformName: 'iOS',
      frameSkipCount: 1, // iOS can handle more frames
      cameraResolution: ResolutionPreset.high,
      maxFPS: 30,
      enableGPUAcceleration: true, // ML Kit uses Neural Engine on iOS
      imageProcessingThreads: 2,
      profile: PerformanceProfile.balanced,
      description: 'iOS devices - uses ML Kit with Neural Engine',
    );
  }

  static PlatformPerformanceConfig _getWindowsConfig() {
    return const PlatformPerformanceConfig(
      platformName: 'Windows',
      frameSkipCount: 2,
      cameraResolution: ResolutionPreset.high,
      maxFPS: 24,
      enableGPUAcceleration: false, // TFLite on desktop
      imageProcessingThreads: 4, // Desktop can use more threads
      profile: PerformanceProfile.balanced,
      description: 'Windows desktop - uses TensorFlow Lite',
    );
  }

  static PlatformPerformanceConfig _getMacOSConfig() {
    return const PlatformPerformanceConfig(
      platformName: 'macOS',
      frameSkipCount: 2,
      cameraResolution: ResolutionPreset.high,
      maxFPS: 30,
      enableGPUAcceleration: false, // TFLite on desktop
      imageProcessingThreads: 4, // macOS can use more threads
      profile: PerformanceProfile.balanced,
      description: 'macOS desktop - uses TensorFlow Lite',
    );
  }

  static PlatformPerformanceConfig _getLinuxConfig() {
    return const PlatformPerformanceConfig(
      platformName: 'Linux',
      frameSkipCount: 2,
      cameraResolution: ResolutionPreset.medium,
      maxFPS: 24,
      enableGPUAcceleration: false, // TFLite on desktop
      imageProcessingThreads: 4, // Linux can use more threads
      profile: PerformanceProfile.balanced,
      description: 'Linux desktop - uses TensorFlow Lite',
    );
  }

  static PlatformPerformanceConfig _getDefaultConfig() {
    return const PlatformPerformanceConfig(
      platformName: 'Unknown',
      frameSkipCount: 3, // Conservative default
      cameraResolution: ResolutionPreset.medium,
      maxFPS: 15,
      enableGPUAcceleration: false,
      imageProcessingThreads: 1,
      profile: PerformanceProfile.balanced,
      description: 'Default fallback configuration',
    );
  }

  /// Get estimated frames per second based on configuration
  double getEstimatedFPS() {
    return maxFPS / (frameSkipCount + 1);
  }

  /// Get memory usage estimate (MB)
  double getEstimatedMemoryUsage() {
    // Rough estimate based on resolution and frame processing
    final resolutionMultiplier = _getResolutionMultiplier();
    final baseMemory = 50.0; // Base memory for app
    final cameraMemory = 20.0 * resolutionMultiplier;
    final processingMemory = 30.0 * imageProcessingThreads;

    return baseMemory + cameraMemory + processingMemory;
  }

  double _getResolutionMultiplier() {
    switch (cameraResolution) {
      case ResolutionPreset.low:
        return 0.5;
      case ResolutionPreset.medium:
        return 1.0;
      case ResolutionPreset.high:
        return 1.5;
      case ResolutionPreset.veryHigh:
        return 2.0;
      case ResolutionPreset.ultraHigh:
        return 3.0;
      case ResolutionPreset.max:
        return 4.0;
    }
  }

  @override
  String toString() {
    return '''
Platform Performance Config:
  Platform: $platformName
  Profile: ${profile.toString().split('.').last}
  Frame Skip: $frameSkipCount (Est. ${getEstimatedFPS().toStringAsFixed(1)} FPS)
  Resolution: ${cameraResolution.toString().split('.').last}
  GPU Acceleration: $enableGPUAcceleration
  Processing Threads: $imageProcessingThreads
  Est. Memory: ${getEstimatedMemoryUsage().toStringAsFixed(0)} MB
  Description: $description
''';
  }

  /// Generate performance report
  Map<String, dynamic> toMap() {
    return {
      'platformName': platformName,
      'profile': profile.toString().split('.').last,
      'frameSkipCount': frameSkipCount,
      'estimatedFPS': getEstimatedFPS(),
      'cameraResolution': cameraResolution.toString().split('.').last,
      'maxFPS': maxFPS,
      'gpuAcceleration': enableGPUAcceleration,
      'processingThreads': imageProcessingThreads,
      'estimatedMemoryMB': getEstimatedMemoryUsage(),
      'description': description,
    };
  }
}

/// Performance profiles for different use cases
enum PerformanceProfile {
  /// Battery saving mode - lower accuracy, higher efficiency
  lowPower,

  /// Balanced mode - good accuracy with reasonable performance
  balanced,

  /// High performance mode - better accuracy with higher resource usage
  highPerformance,

  /// Highest accuracy mode - maximum precision, highest resource usage
  highAccuracy,
}

/// Performance monitoring and recommendations
class PerformanceMonitor {
  static const Duration _monitoringInterval = Duration(seconds: 5);

  final List<double> _fpsHistory = [];
  final List<int> _processingTimeHistory = [];
  DateTime? _lastFrameTime;
  int _frameCount = 0;

  /// Add frame processing time
  void recordFrameProcessing(int milliseconds) {
    _processingTimeHistory.add(milliseconds);
    if (_processingTimeHistory.length > 100) {
      _processingTimeHistory.removeAt(0);
    }

    _frameCount++;
    final now = DateTime.now();

    if (_lastFrameTime != null) {
      final fps = 1000 / now.difference(_lastFrameTime!).inMilliseconds;
      _fpsHistory.add(fps);
      if (_fpsHistory.length > 100) {
        _fpsHistory.removeAt(0);
      }
    }

    _lastFrameTime = now;
  }

  /// Get average FPS
  double getAverageFPS() {
    if (_fpsHistory.isEmpty) return 0.0;
    return _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
  }

  /// Get average processing time
  double getAverageProcessingTime() {
    if (_processingTimeHistory.isEmpty) return 0.0;
    return _processingTimeHistory.reduce((a, b) => a + b) /
           _processingTimeHistory.length;
  }

  /// Get performance recommendation
  String getRecommendation(PlatformPerformanceConfig currentConfig) {
    final avgFPS = getAverageFPS();
    final avgProcessing = getAverageProcessingTime();

    if (avgFPS < 10) {
      return 'Performance is low. Consider switching to Low Power mode or reducing camera resolution.';
    } else if (avgFPS < 15) {
      return 'Performance is moderate. Current settings are near optimal for your device.';
    } else if (avgFPS > 25 && avgProcessing < 50) {
      return 'Performance is excellent. You can increase accuracy by switching to High Performance mode.';
    }

    return 'Performance is good. Current settings are working well.';
  }

  /// Get performance statistics
  Map<String, dynamic> getStatistics() {
    return {
      'averageFPS': getAverageFPS(),
      'averageProcessingTimeMs': getAverageProcessingTime(),
      'totalFramesProcessed': _frameCount,
      'recommendation': getRecommendation(
        PlatformPerformanceConfig.getOptimizedConfig()
      ),
    };
  }

  /// Reset statistics
  void reset() {
    _fpsHistory.clear();
    _processingTimeHistory.clear();
    _lastFrameTime = null;
    _frameCount = 0;
  }
}
