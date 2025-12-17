import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as mlkit;
import '../models/pose_data.dart' as models;

/// Abstract interface for pose detection services
abstract class PoseDetectionService {
  Stream<models.PoseSnapshot> get poseStream;
  Future<void> initialize();
  Future<void> startDetection(CameraImage image);
  Future<void> stopDetection();
  void dispose();
}

/// ML Kit-based pose detection service for iOS/Android
class MLKitPoseDetectionService implements PoseDetectionService {
  final _poseController = StreamController<models.PoseSnapshot>.broadcast();
  mlkit.PoseDetector? _poseDetector;
  bool _isProcessing = false;
  bool _isInitialized = false;

  // Frame skipping for performance (process every Nth frame)
  int _frameSkipCount = 2;
  int _currentFrame = 0;

  // Performance mode: base (faster) or accurate (more precise)
  final PoseDetectionMode _mode;

  MLKitPoseDetectionService({
    PoseDetectionMode mode = PoseDetectionMode.base,
    int frameSkipCount = 2,
  })  : _mode = mode,
        _frameSkipCount = frameSkipCount;

  @override
  Stream<models.PoseSnapshot> get poseStream => _poseController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _poseDetector = mlkit.PoseDetector(
        options: mlkit.PoseDetectorOptions(),
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize ML Kit Pose Detector: $e');
    }
  }

  @override
  Future<void> startDetection(CameraImage image) async {
    if (!_isInitialized || _poseDetector == null) {
      throw StateError('PoseDetectionService not initialized');
    }

    // Frame skipping for performance
    _currentFrame++;
    if (_currentFrame % (_frameSkipCount + 1) != 0) {
      return;
    }

    // Prevent concurrent processing
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Convert CameraImage to InputImage
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // Perform pose detection
      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty) {
        // Take the first detected pose (single person detection)
        final pose = poses.first;

        // Convert to our PoseSnapshot model
        final snapshot = _convertToPoseSnapshot(pose);

        // Emit to stream
        if (!_poseController.isClosed) {
          _poseController.add(snapshot);
        }
      }
    } catch (e) {
      // Silently handle errors during detection
      // Could add logging here
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Future<void> stopDetection() async {
    _isProcessing = false;
    _currentFrame = 0;
  }

  @override
  void dispose() {
    stopDetection();
    _poseDetector?.close();
    _poseController.close();
    _isInitialized = false;
  }

  /// Convert CameraImage to ML Kit InputImage
  mlkit.InputImage? _convertToInputImage(CameraImage image) {
    try {
      // For now, return null to skip complex conversion
      // This will be implemented when camera integration is added
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert ML Kit Pose to our PoseSnapshot model
  models.PoseSnapshot _convertToPoseSnapshot(mlkit.Pose pose) {
    final landmarks = <models.PoseLandmark>[];

    // Map ML Kit landmarks to our model
    final landmarkMap = {
      mlkit.PoseLandmarkType.nose: pose.landmarks[mlkit.PoseLandmarkType.nose],
      mlkit.PoseLandmarkType.leftEyeInner:
          pose.landmarks[mlkit.PoseLandmarkType.leftEyeInner],
      mlkit.PoseLandmarkType.leftEye: pose.landmarks[mlkit.PoseLandmarkType.leftEye],
      mlkit.PoseLandmarkType.leftEyeOuter:
          pose.landmarks[mlkit.PoseLandmarkType.leftEyeOuter],
      mlkit.PoseLandmarkType.rightEyeInner:
          pose.landmarks[mlkit.PoseLandmarkType.rightEyeInner],
      mlkit.PoseLandmarkType.rightEye: pose.landmarks[mlkit.PoseLandmarkType.rightEye],
      mlkit.PoseLandmarkType.rightEyeOuter:
          pose.landmarks[mlkit.PoseLandmarkType.rightEyeOuter],
      mlkit.PoseLandmarkType.leftEar: pose.landmarks[mlkit.PoseLandmarkType.leftEar],
      mlkit.PoseLandmarkType.rightEar: pose.landmarks[mlkit.PoseLandmarkType.rightEar],
      mlkit.PoseLandmarkType.leftMouth: pose.landmarks[mlkit.PoseLandmarkType.leftMouth],
      mlkit.PoseLandmarkType.rightMouth: pose.landmarks[mlkit.PoseLandmarkType.rightMouth],
      mlkit.PoseLandmarkType.leftShoulder:
          pose.landmarks[mlkit.PoseLandmarkType.leftShoulder],
      mlkit.PoseLandmarkType.rightShoulder:
          pose.landmarks[mlkit.PoseLandmarkType.rightShoulder],
      mlkit.PoseLandmarkType.leftElbow: pose.landmarks[mlkit.PoseLandmarkType.leftElbow],
      mlkit.PoseLandmarkType.rightElbow: pose.landmarks[mlkit.PoseLandmarkType.rightElbow],
      mlkit.PoseLandmarkType.leftWrist: pose.landmarks[mlkit.PoseLandmarkType.leftWrist],
      mlkit.PoseLandmarkType.rightWrist: pose.landmarks[mlkit.PoseLandmarkType.rightWrist],
      mlkit.PoseLandmarkType.leftPinky: pose.landmarks[mlkit.PoseLandmarkType.leftPinky],
      mlkit.PoseLandmarkType.rightPinky: pose.landmarks[mlkit.PoseLandmarkType.rightPinky],
      mlkit.PoseLandmarkType.leftIndex: pose.landmarks[mlkit.PoseLandmarkType.leftIndex],
      mlkit.PoseLandmarkType.rightIndex: pose.landmarks[mlkit.PoseLandmarkType.rightIndex],
      mlkit.PoseLandmarkType.leftThumb: pose.landmarks[mlkit.PoseLandmarkType.leftThumb],
      mlkit.PoseLandmarkType.rightThumb: pose.landmarks[mlkit.PoseLandmarkType.rightThumb],
      mlkit.PoseLandmarkType.leftHip: pose.landmarks[mlkit.PoseLandmarkType.leftHip],
      mlkit.PoseLandmarkType.rightHip: pose.landmarks[mlkit.PoseLandmarkType.rightHip],
      mlkit.PoseLandmarkType.leftKnee: pose.landmarks[mlkit.PoseLandmarkType.leftKnee],
      mlkit.PoseLandmarkType.rightKnee: pose.landmarks[mlkit.PoseLandmarkType.rightKnee],
      mlkit.PoseLandmarkType.leftAnkle: pose.landmarks[mlkit.PoseLandmarkType.leftAnkle],
      mlkit.PoseLandmarkType.rightAnkle: pose.landmarks[mlkit.PoseLandmarkType.rightAnkle],
      mlkit.PoseLandmarkType.leftHeel: pose.landmarks[mlkit.PoseLandmarkType.leftHeel],
      mlkit.PoseLandmarkType.rightHeel: pose.landmarks[mlkit.PoseLandmarkType.rightHeel],
      mlkit.PoseLandmarkType.leftFootIndex:
          pose.landmarks[mlkit.PoseLandmarkType.leftFootIndex],
      mlkit.PoseLandmarkType.rightFootIndex:
          pose.landmarks[mlkit.PoseLandmarkType.rightFootIndex],
    };

    double totalConfidence = 0.0;
    int confidenceCount = 0;

    landmarkMap.forEach((type, landmark) {
      if (landmark != null) {
        // Normalize coordinates (ML Kit gives pixel coordinates)
        // Note: We'll need image dimensions to properly normalize
        // For now, we'll store raw values and normalize in painter
        landmarks.add(models.PoseLandmark(
          name: _getLandmarkName(type),
          x: landmark.x,
          y: landmark.y,
          z: landmark.z,
          confidence: landmark.likelihood,
        ));

        totalConfidence += landmark.likelihood;
        confidenceCount++;
      }
    });

    final overallConfidence =
        confidenceCount > 0 ? totalConfidence / confidenceCount : 0.0;

    return models.PoseSnapshot(
      timestamp: DateTime.now(),
      landmarks: landmarks,
      overallConfidence: overallConfidence,
    );
  }

  /// Get landmark name string from ML Kit type
  String _getLandmarkName(mlkit.PoseLandmarkType type) {
    // Map ML Kit types to our string names
    final typeMap = {
      mlkit.PoseLandmarkType.nose: 'NOSE',
      mlkit.PoseLandmarkType.leftEyeInner: 'LEFT_EYE_INNER',
      mlkit.PoseLandmarkType.leftEye: 'LEFT_EYE',
      mlkit.PoseLandmarkType.leftEyeOuter: 'LEFT_EYE_OUTER',
      mlkit.PoseLandmarkType.rightEyeInner: 'RIGHT_EYE_INNER',
      mlkit.PoseLandmarkType.rightEye: 'RIGHT_EYE',
      mlkit.PoseLandmarkType.rightEyeOuter: 'RIGHT_EYE_OUTER',
      mlkit.PoseLandmarkType.leftEar: 'LEFT_EAR',
      mlkit.PoseLandmarkType.rightEar: 'RIGHT_EAR',
      mlkit.PoseLandmarkType.leftMouth: 'LEFT_MOUTH',
      mlkit.PoseLandmarkType.rightMouth: 'RIGHT_MOUTH',
      mlkit.PoseLandmarkType.leftShoulder: 'LEFT_SHOULDER',
      mlkit.PoseLandmarkType.rightShoulder: 'RIGHT_SHOULDER',
      mlkit.PoseLandmarkType.leftElbow: 'LEFT_ELBOW',
      mlkit.PoseLandmarkType.rightElbow: 'RIGHT_ELBOW',
      mlkit.PoseLandmarkType.leftWrist: 'LEFT_WRIST',
      mlkit.PoseLandmarkType.rightWrist: 'RIGHT_WRIST',
      mlkit.PoseLandmarkType.leftPinky: 'LEFT_PINKY',
      mlkit.PoseLandmarkType.rightPinky: 'RIGHT_PINKY',
      mlkit.PoseLandmarkType.leftIndex: 'LEFT_INDEX',
      mlkit.PoseLandmarkType.rightIndex: 'RIGHT_INDEX',
      mlkit.PoseLandmarkType.leftThumb: 'LEFT_THUMB',
      mlkit.PoseLandmarkType.rightThumb: 'RIGHT_THUMB',
      mlkit.PoseLandmarkType.leftHip: 'LEFT_HIP',
      mlkit.PoseLandmarkType.rightHip: 'RIGHT_HIP',
      mlkit.PoseLandmarkType.leftKnee: 'LEFT_KNEE',
      mlkit.PoseLandmarkType.rightKnee: 'RIGHT_KNEE',
      mlkit.PoseLandmarkType.leftAnkle: 'LEFT_ANKLE',
      mlkit.PoseLandmarkType.rightAnkle: 'RIGHT_ANKLE',
      mlkit.PoseLandmarkType.leftHeel: 'LEFT_HEEL',
      mlkit.PoseLandmarkType.rightHeel: 'RIGHT_HEEL',
      mlkit.PoseLandmarkType.leftFootIndex: 'LEFT_FOOT_INDEX',
      mlkit.PoseLandmarkType.rightFootIndex: 'RIGHT_FOOT_INDEX',
    };

    return typeMap[type] ?? 'UNKNOWN';
  }

  /// Update frame skip count for performance tuning
  void setFrameSkipCount(int count) {
    _frameSkipCount = count.clamp(0, 10);
  }
}

/// Enum for detection mode
enum PoseDetectionMode {
  base, // Faster, less accurate
  accurate, // Slower, more accurate
}
