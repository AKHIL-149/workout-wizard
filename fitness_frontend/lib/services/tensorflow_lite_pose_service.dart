import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/pose_data.dart';
import 'pose_detection_service.dart';

/// TensorFlow Lite-based pose detection service for web/desktop
/// Uses MoveNet model for cross-platform pose detection
class TensorFlowLitePoseService implements PoseDetectionService {
  final _poseController = StreamController<PoseSnapshot>.broadcast();
  Interpreter? _interpreter;
  bool _isProcessing = false;
  bool _isInitialized = false;

  // Frame skipping for performance (process every Nth frame)
  int _frameSkipCount = 2;
  int _currentFrame = 0;

  // Model input/output dimensions
  static const int _inputWidth = 192;
  static const int _inputHeight = 192;
  static const int _numKeypoints = 17; // MoveNet detects 17 keypoints

  // MoveNet keypoint order (COCO format)
  static const List<String> _keypointNames = [
    'NOSE',
    'LEFT_EYE',
    'RIGHT_EYE',
    'LEFT_EAR',
    'RIGHT_EAR',
    'LEFT_SHOULDER',
    'RIGHT_SHOULDER',
    'LEFT_ELBOW',
    'RIGHT_ELBOW',
    'LEFT_WRIST',
    'RIGHT_WRIST',
    'LEFT_HIP',
    'RIGHT_HIP',
    'LEFT_KNEE',
    'RIGHT_KNEE',
    'LEFT_ANKLE',
    'RIGHT_ANKLE',
  ];

  // Model path
  final String _modelPath;

  TensorFlowLitePoseService({
    String modelPath = 'assets/models/movenet_lightning.tflite',
    int frameSkipCount = 2,
  })  : _modelPath = modelPath,
        _frameSkipCount = frameSkipCount;

  @override
  Stream<PoseSnapshot> get poseStream => _poseController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Allocate tensors
      _interpreter!.allocateTensors();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize TensorFlow Lite Pose Detector: $e');
    }
  }

  @override
  Future<void> startDetection(CameraImage image) async {
    if (!_isInitialized || _interpreter == null) {
      throw StateError('TensorFlowLitePoseService not initialized');
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
      // Convert CameraImage to preprocessed tensor
      final inputTensor = await _preprocessImage(image);
      if (inputTensor == null) {
        _isProcessing = false;
        return;
      }

      // Prepare output buffer
      // MoveNet output shape: [1, 1, 17, 3] (y, x, confidence)
      final outputBuffer = List.generate(
        1,
        (_) => List.generate(
          1,
          (_) => List.generate(
            _numKeypoints,
            (_) => List.filled(3, 0.0),
          ),
        ),
      );

      // Run inference
      _interpreter!.run(inputTensor, outputBuffer);

      // Convert output to PoseSnapshot
      final snapshot = _convertToPoseSnapshot(outputBuffer[0][0]);

      // Emit to stream
      if (!_poseController.isClosed) {
        _poseController.add(snapshot);
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
    _interpreter?.close();
    _poseController.close();
    _isInitialized = false;
  }

  /// Preprocess CameraImage for model input
  Future<List<List<List<List<double>>>>?> _preprocessImage(
      CameraImage image) async {
    try {
      // Convert CameraImage to img.Image
      img.Image? imageData = _convertCameraImage(image);
      if (imageData == null) return null;

      // Resize to model input size
      final resized = img.copyResize(
        imageData,
        width: _inputWidth,
        height: _inputHeight,
        interpolation: img.Interpolation.linear,
      );

      // Normalize and convert to tensor format [1, height, width, 3]
      final inputTensor = List.generate(
        1,
        (_) => List.generate(
          _inputHeight,
          (y) => List.generate(
            _inputWidth,
            (x) {
              final pixel = resized.getPixel(x, y);
              // Normalize to [0, 1] range
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      return inputTensor;
    } catch (e) {
      return null;
    }
  }

  /// Convert CameraImage to img.Image
  img.Image? _convertCameraImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToImage(image);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Convert YUV420 to img.Image
  img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final img.Image imgData = img.Image(width: width, height: height);

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        // Convert YUV to RGB
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        imgData.setPixelRgb(x, y, r, g, b);
      }
    }

    return imgData;
  }

  /// Convert BGRA8888 to img.Image
  img.Image _convertBGRA8888ToImage(CameraImage image) {
    final img.Image imgData =
        img.Image(width: image.width, height: image.height);

    final Uint8List bytes = image.planes[0].bytes;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final int index = y * image.planes[0].bytesPerRow + x * 4;

        final b = bytes[index];
        final g = bytes[index + 1];
        final r = bytes[index + 2];

        imgData.setPixelRgb(x, y, r, g, b);
      }
    }

    return imgData;
  }

  /// Convert MoveNet output to PoseSnapshot
  PoseSnapshot _convertToPoseSnapshot(List<List<double>> keypoints) {
    final landmarks = <PoseLandmark>[];
    double totalConfidence = 0.0;

    for (int i = 0; i < _numKeypoints && i < keypoints.length; i++) {
      final keypoint = keypoints[i];

      // MoveNet output format: [y, x, confidence]
      final y = keypoint[0]; // Normalized [0, 1]
      final x = keypoint[1]; // Normalized [0, 1]
      final confidence = keypoint[2]; // [0, 1]

      landmarks.add(PoseLandmark(
        name: _keypointNames[i],
        x: x,
        y: y,
        z: 0.0, // MoveNet doesn't provide Z coordinate
        confidence: confidence,
      ));

      totalConfidence += confidence;
    }

    final overallConfidence =
        landmarks.isNotEmpty ? totalConfidence / landmarks.length : 0.0;

    // Add additional landmarks not detected by MoveNet but needed by our system
    // These are estimated or set to low confidence
    _addMissingLandmarks(landmarks);

    return PoseSnapshot(
      timestamp: DateTime.now(),
      landmarks: landmarks,
      overallConfidence: overallConfidence,
    );
  }

  /// Add landmarks that MoveNet doesn't detect but our system expects
  void _addMissingLandmarks(List<PoseLandmark> landmarks) {
    // MoveNet has 17 keypoints, but ML Kit has 33
    // We need to add missing landmarks with low confidence

    // Try to estimate missing landmarks based on existing ones
    final leftEye = landmarks.firstWhere(
      (l) => l.name == 'LEFT_EYE',
      orElse: () => PoseLandmark(name: 'LEFT_EYE', x: 0.5, y: 0.3, z: 0.0, confidence: 0.0),
    );
    final rightEye = landmarks.firstWhere(
      (l) => l.name == 'RIGHT_EYE',
      orElse: () => PoseLandmark(name: 'RIGHT_EYE', x: 0.5, y: 0.3, z: 0.0, confidence: 0.0),
    );
    final leftWrist = landmarks.firstWhere(
      (l) => l.name == 'LEFT_WRIST',
      orElse: () => PoseLandmark(name: 'LEFT_WRIST', x: 0.3, y: 0.5, z: 0.0, confidence: 0.0),
    );
    final rightWrist = landmarks.firstWhere(
      (l) => l.name == 'RIGHT_WRIST',
      orElse: () => PoseLandmark(name: 'RIGHT_WRIST', x: 0.7, y: 0.5, z: 0.0, confidence: 0.0),
    );
    final leftAnkle = landmarks.firstWhere(
      (l) => l.name == 'LEFT_ANKLE',
      orElse: () => PoseLandmark(name: 'LEFT_ANKLE', x: 0.4, y: 0.9, z: 0.0, confidence: 0.0),
    );
    final rightAnkle = landmarks.firstWhere(
      (l) => l.name == 'RIGHT_ANKLE',
      orElse: () => PoseLandmark(name: 'RIGHT_ANKLE', x: 0.6, y: 0.9, z: 0.0, confidence: 0.0),
    );

    // Add estimated landmarks
    landmarks.addAll([
      // Eye landmarks (estimate based on eye positions)
      PoseLandmark(
        name: 'LEFT_EYE_INNER',
        x: leftEye.x + 0.01,
        y: leftEye.y,
        z: 0.0,
        confidence: leftEye.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'LEFT_EYE_OUTER',
        x: leftEye.x - 0.01,
        y: leftEye.y,
        z: 0.0,
        confidence: leftEye.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'RIGHT_EYE_INNER',
        x: rightEye.x - 0.01,
        y: rightEye.y,
        z: 0.0,
        confidence: rightEye.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'RIGHT_EYE_OUTER',
        x: rightEye.x + 0.01,
        y: rightEye.y,
        z: 0.0,
        confidence: rightEye.confidence * 0.5,
      ),
      // Mouth landmarks (estimate based on eyes and nose)
      PoseLandmark(
        name: 'LEFT_MOUTH',
        x: leftEye.x,
        y: leftEye.y + 0.05,
        z: 0.0,
        confidence: leftEye.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'RIGHT_MOUTH',
        x: rightEye.x,
        y: rightEye.y + 0.05,
        z: 0.0,
        confidence: rightEye.confidence * 0.5,
      ),
      // Hand landmarks (estimate based on wrist)
      PoseLandmark(
        name: 'LEFT_PINKY',
        x: leftWrist.x - 0.02,
        y: leftWrist.y + 0.02,
        z: 0.0,
        confidence: leftWrist.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'RIGHT_PINKY',
        x: rightWrist.x + 0.02,
        y: rightWrist.y + 0.02,
        z: 0.0,
        confidence: rightWrist.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'LEFT_INDEX',
        x: leftWrist.x,
        y: leftWrist.y + 0.02,
        z: 0.0,
        confidence: leftWrist.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'RIGHT_INDEX',
        x: rightWrist.x,
        y: rightWrist.y + 0.02,
        z: 0.0,
        confidence: rightWrist.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'LEFT_THUMB',
        x: leftWrist.x + 0.01,
        y: leftWrist.y + 0.02,
        z: 0.0,
        confidence: leftWrist.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'RIGHT_THUMB',
        x: rightWrist.x - 0.01,
        y: rightWrist.y + 0.02,
        z: 0.0,
        confidence: rightWrist.confidence * 0.5,
      ),
      // Foot landmarks (estimate based on ankle)
      PoseLandmark(
        name: 'LEFT_HEEL',
        x: leftAnkle.x - 0.01,
        y: leftAnkle.y + 0.01,
        z: 0.0,
        confidence: leftAnkle.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'RIGHT_HEEL',
        x: rightAnkle.x + 0.01,
        y: rightAnkle.y + 0.01,
        z: 0.0,
        confidence: rightAnkle.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'LEFT_FOOT_INDEX',
        x: leftAnkle.x + 0.01,
        y: leftAnkle.y + 0.01,
        z: 0.0,
        confidence: leftAnkle.confidence * 0.5,
      ),
      PoseLandmark(
        name: 'RIGHT_FOOT_INDEX',
        x: rightAnkle.x - 0.01,
        y: rightAnkle.y + 0.01,
        z: 0.0,
        confidence: rightAnkle.confidence * 0.5,
      ),
    ]);
  }

  /// Update frame skip count for performance tuning
  void setFrameSkipCount(int count) {
    _frameSkipCount = count.clamp(0, 10);
  }
}
