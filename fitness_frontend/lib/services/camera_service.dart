import 'dart:async';
import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for managing camera access and streaming with platform-specific handling
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  StreamSubscription? _imageStreamSubscription;

  /// Get the camera controller
  CameraController? get controller => _controller;

  /// Check if camera is initialized
  bool get isInitialized => _isInitialized && _controller != null;

  /// Get current camera description
  CameraDescription? get currentCamera =>
      _cameras.isNotEmpty ? _cameras[_currentCameraIndex] : null;

  /// Initialize the camera service
  Future<void> initialize({
    CameraLensDirection direction = CameraLensDirection.front,
    ResolutionPreset resolution = ResolutionPreset.medium,
  }) async {
    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw CameraException(
          'NO_CAMERA',
          'No camera available on this device',
        );
      }

      // Find camera with desired direction
      _currentCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == direction,
      );

      // If not found, use first available camera
      if (_currentCameraIndex == -1) {
        _currentCameraIndex = 0;
      }

      // Create controller with platform-specific settings
      _controller = CameraController(
        _cameras[_currentCameraIndex],
        resolution,
        enableAudio: false,
        imageFormatGroup: _getPlatformImageFormat(),
      );

      // Initialize controller
      await _controller!.initialize();

      // Lock orientation to portrait for consistency (mobile only)
      if (_isMobilePlatform()) {
        try {
          await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
        } catch (e) {
          // Orientation locking might not be supported on all platforms
          if (kDebugMode) {
            print('Orientation locking not supported: $e');
          }
        }
      }

      _isInitialized = true;
    } on CameraException catch (e) {
      _handleCameraError(e);
      rethrow;
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }

  /// Start streaming camera images
  Future<void> startImageStream(
    Function(CameraImage image) onImage,
  ) async {
    if (!isInitialized || _controller == null) {
      throw StateError('Camera not initialized');
    }

    try {
      await _controller!.startImageStream((image) {
        onImage(image);
      });
    } catch (e) {
      throw Exception('Failed to start image stream: $e');
    }
  }

  /// Stop streaming camera images
  Future<void> stopImageStream() async {
    if (_controller == null) return;

    try {
      await _controller!.stopImageStream();
    } catch (e) {
      // Silently handle errors when stopping stream
      if (kDebugMode) {
        print('Error stopping image stream: $e');
      }
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) {
      throw Exception('Only one camera available');
    }

    try {
      // Stop current stream
      await stopImageStream();

      // Dispose current controller
      await _controller?.dispose();

      // Switch to next camera
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;

      // Reinitialize with new camera
      _controller = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: _getPlatformImageFormat(),
      );

      await _controller!.initialize();

      // Lock orientation (mobile only)
      if (_isMobilePlatform()) {
        try {
          await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
        } catch (e) {
          if (kDebugMode) {
            print('Orientation locking not supported: $e');
          }
        }
      }

      _isInitialized = true;
    } on CameraException catch (e) {
      _handleCameraError(e);
      rethrow;
    } catch (e) {
      throw Exception('Failed to switch camera: $e');
    }
  }

  /// Take a picture
  Future<XFile> takePicture() async {
    if (!isInitialized || _controller == null) {
      throw StateError('Camera not initialized');
    }

    try {
      final image = await _controller!.takePicture();
      return image;
    } on CameraException catch (e) {
      _handleCameraError(e);
      rethrow;
    } catch (e) {
      throw Exception('Failed to take picture: $e');
    }
  }

  /// Set camera flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (!isInitialized || _controller == null) return;

    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set flash mode: $e');
      }
    }
  }

  /// Set camera zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (!isInitialized || _controller == null) return;

    try {
      final maxZoom = await _controller!.getMaxZoomLevel();
      final minZoom = await _controller!.getMinZoomLevel();
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(clampedZoom);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set zoom level: $e');
      }
    }
  }

  /// Pause camera preview
  Future<void> pausePreview() async {
    if (!isInitialized || _controller == null) return;

    try {
      await _controller!.pausePreview();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to pause preview: $e');
      }
    }
  }

  /// Resume camera preview
  Future<void> resumePreview() async {
    if (!isInitialized || _controller == null) return;

    try {
      await _controller!.resumePreview();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to resume preview: $e');
      }
    }
  }

  /// Get camera lens direction (front or back)
  CameraLensDirection get lensDirection {
    return currentCamera?.lensDirection ?? CameraLensDirection.front;
  }

  /// Check if camera is front-facing
  bool get isFrontCamera =>
      lensDirection == CameraLensDirection.front;

  /// Dispose camera resources
  void dispose() {
    _imageStreamSubscription?.cancel();
    stopImageStream();
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  /// Handle camera errors
  void _handleCameraError(CameraException e) {
    if (kDebugMode) {
      print('Camera error: ${e.code} - ${e.description}');
    }

    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        throw CameraException(
          'PERMISSION_DENIED',
          'Camera permission denied. Please enable camera access in settings.',
        );
      case 'AudioAccessDenied':
      case 'AudioAccessDeniedWithoutPrompt':
      case 'AudioAccessRestricted':
        // Audio not needed for pose detection
        break;
      case 'cameraNotFound':
        throw CameraException(
          'NO_CAMERA',
          'No camera found on this device',
        );
      default:
        throw CameraException(
          'CAMERA_ERROR',
          'Camera error: ${e.description ?? 'Unknown error'}',
        );
    }
  }

  /// Get platform-specific image format for camera
  ImageFormatGroup _getPlatformImageFormat() {
    if (kIsWeb) {
      // Web typically uses BGRA8888
      return ImageFormatGroup.bgra8888;
    }

    try {
      if (Platform.isIOS) {
        // iOS works well with bgra8888
        return ImageFormatGroup.bgra8888;
      } else if (Platform.isAndroid) {
        // Android prefers yuv420 for ML processing
        return ImageFormatGroup.yuv420;
      } else {
        // Desktop platforms (Windows, macOS, Linux)
        return ImageFormatGroup.bgra8888;
      }
    } catch (e) {
      // Fallback for unknown platforms
      return ImageFormatGroup.bgra8888;
    }
  }

  /// Check if running on mobile platform
  bool _isMobilePlatform() {
    if (kIsWeb) return false;

    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Check if running on desktop platform
  bool _isDesktopPlatform() {
    if (kIsWeb) return false;

    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  /// Get platform-specific camera features availability
  Map<String, bool> getPlatformFeatures() {
    return {
      'flashMode': _isMobilePlatform(),
      'zoomLevel': _isMobilePlatform() || _isDesktopPlatform(),
      'orientationLock': _isMobilePlatform(),
      'multipleCameras': _isMobilePlatform(),
      'videoRecording': true, // Available on all platforms
    };
  }

  /// Get recommended resolution for current platform
  ResolutionPreset getRecommendedResolution() {
    if (kIsWeb) {
      // Web: lower resolution for better performance
      return ResolutionPreset.medium;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: medium resolution balances quality and performance
        return ResolutionPreset.medium;
      } else {
        // Desktop: can handle higher resolution
        return ResolutionPreset.high;
      }
    } catch (e) {
      return ResolutionPreset.medium;
    }
  }

  /// Get platform name for debugging
  String getPlatformName() {
    if (kIsWeb) return 'Web';

    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      // Ignore
    }

    return 'Unknown';
  }
}

/// Camera error types for easier error handling
class CameraErrorType {
  static const String permissionDenied = 'PERMISSION_DENIED';
  static const String noCamera = 'NO_CAMERA';
  static const String cameraInUse = 'CAMERA_IN_USE';
  static const String unknown = 'CAMERA_ERROR';
}
