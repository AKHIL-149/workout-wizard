import 'package:flutter/material.dart';

/// Represents a single pose landmark (joint) in 3D space
class PoseLandmark {
  final String name; // e.g., "LEFT_SHOULDER", "RIGHT_KNEE"
  final double x; // Normalized x-coordinate (0-1)
  final double y; // Normalized y-coordinate (0-1)
  final double z; // Normalized z-coordinate (depth)
  final double confidence; // Detection confidence (0-1)

  const PoseLandmark({
    required this.name,
    required this.x,
    required this.y,
    required this.z,
    required this.confidence,
  });

  /// Convert to screen coordinates
  Offset toOffset(Size screenSize) {
    return Offset(
      x * screenSize.width,
      y * screenSize.height,
    );
  }

  /// Create from JSON
  factory PoseLandmark.fromJson(Map<String, dynamic> json) {
    return PoseLandmark(
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'x': x,
        'y': y,
        'z': z,
        'confidence': confidence,
      };

  @override
  String toString() =>
      'PoseLandmark($name, x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, conf: ${confidence.toStringAsFixed(2)})';
}

/// Complete pose snapshot at a specific point in time
class PoseSnapshot {
  final DateTime timestamp;
  final List<PoseLandmark> landmarks;
  final double overallConfidence;

  const PoseSnapshot({
    required this.timestamp,
    required this.landmarks,
    required this.overallConfidence,
  });

  /// Get a landmark by name
  PoseLandmark? getLandmark(String name) {
    try {
      return landmarks.firstWhere((l) => l.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Check if all required landmarks are present with good confidence
  bool hasRequiredLandmarks(List<String> requiredNames,
      {double minConfidence = 0.5}) {
    for (final name in requiredNames) {
      final landmark = getLandmark(name);
      if (landmark == null || landmark.confidence < minConfidence) {
        return false;
      }
    }
    return true;
  }

  /// Create from JSON
  factory PoseSnapshot.fromJson(Map<String, dynamic> json) {
    return PoseSnapshot(
      timestamp: DateTime.parse(json['timestamp'] as String),
      landmarks: (json['landmarks'] as List)
          .map((l) => PoseLandmark.fromJson(l as Map<String, dynamic>))
          .toList(),
      overallConfidence: (json['overallConfidence'] as num).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'landmarks': landmarks.map((l) => l.toJson()).toList(),
        'overallConfidence': overallConfidence,
      };

  @override
  String toString() =>
      'PoseSnapshot(${timestamp.toIso8601String()}, ${landmarks.length} landmarks, conf: ${overallConfidence.toStringAsFixed(2)})';
}

/// Calculated angle between three joints
class JointAngle {
  final String name; // e.g., "elbow_angle_left", "knee_angle_right"
  final double degrees; // Angle in degrees (0-360)
  final DateTime timestamp;
  final List<String> joints; // [point1, vertex, point2]

  const JointAngle({
    required this.name,
    required this.degrees,
    required this.timestamp,
    required this.joints,
  });

  /// Check if angle is within acceptable range
  bool isInRange(double minDegrees, double maxDegrees) {
    return degrees >= minDegrees && degrees <= maxDegrees;
  }

  /// Create from JSON
  factory JointAngle.fromJson(Map<String, dynamic> json) {
    return JointAngle(
      name: json['name'] as String,
      degrees: (json['degrees'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      joints: List<String>.from(json['joints'] as List),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'degrees': degrees,
        'timestamp': timestamp.toIso8601String(),
        'joints': joints,
      };

  @override
  String toString() =>
      'JointAngle($name, ${degrees.toStringAsFixed(1)}°, joints: ${joints.join("-")})';
}

/// Enum for exercise phases
enum ExercisePhase {
  bottom, // Bottom position (e.g., squat depth)
  top, // Top position (e.g., standing)
  eccentric, // Lowering phase
  concentric, // Lifting phase
  all, // Applies to all phases
}

/// Common pose landmark names for ML Kit
class PoseLandmarkType {
  static const String nose = 'NOSE';
  static const String leftEyeInner = 'LEFT_EYE_INNER';
  static const String leftEye = 'LEFT_EYE';
  static const String leftEyeOuter = 'LEFT_EYE_OUTER';
  static const String rightEyeInner = 'RIGHT_EYE_INNER';
  static const String rightEye = 'RIGHT_EYE';
  static const String rightEyeOuter = 'RIGHT_EYE_OUTER';
  static const String leftEar = 'LEFT_EAR';
  static const String rightEar = 'RIGHT_EAR';
  static const String leftMouth = 'LEFT_MOUTH';
  static const String rightMouth = 'RIGHT_MOUTH';

  static const String leftShoulder = 'LEFT_SHOULDER';
  static const String rightShoulder = 'RIGHT_SHOULDER';
  static const String leftElbow = 'LEFT_ELBOW';
  static const String rightElbow = 'RIGHT_ELBOW';
  static const String leftWrist = 'LEFT_WRIST';
  static const String rightWrist = 'RIGHT_WRIST';
  static const String leftPinky = 'LEFT_PINKY';
  static const String rightPinky = 'RIGHT_PINKY';
  static const String leftIndex = 'LEFT_INDEX';
  static const String rightIndex = 'RIGHT_INDEX';
  static const String leftThumb = 'LEFT_THUMB';
  static const String rightThumb = 'RIGHT_THUMB';

  static const String leftHip = 'LEFT_HIP';
  static const String rightHip = 'RIGHT_HIP';
  static const String leftKnee = 'LEFT_KNEE';
  static const String rightKnee = 'RIGHT_KNEE';
  static const String leftAnkle = 'LEFT_ANKLE';
  static const String rightAnkle = 'RIGHT_ANKLE';
  static const String leftHeel = 'LEFT_HEEL';
  static const String rightHeel = 'RIGHT_HEEL';
  static const String leftFootIndex = 'LEFT_FOOT_INDEX';
  static const String rightFootIndex = 'RIGHT_FOOT_INDEX';

  /// Get all landmark names
  static List<String> get all => [
        nose,
        leftEyeInner,
        leftEye,
        leftEyeOuter,
        rightEyeInner,
        rightEye,
        rightEyeOuter,
        leftEar,
        rightEar,
        leftMouth,
        rightMouth,
        leftShoulder,
        rightShoulder,
        leftElbow,
        rightElbow,
        leftWrist,
        rightWrist,
        leftPinky,
        rightPinky,
        leftIndex,
        rightIndex,
        leftThumb,
        rightThumb,
        leftHip,
        rightHip,
        leftKnee,
        rightKnee,
        leftAnkle,
        rightAnkle,
        leftHeel,
        rightHeel,
        leftFootIndex,
        rightFootIndex,
      ];

  /// Get key body landmarks for most exercises
  static List<String> get keyLandmarks => [
        leftShoulder,
        rightShoulder,
        leftElbow,
        rightElbow,
        leftWrist,
        rightWrist,
        leftHip,
        rightHip,
        leftKnee,
        rightKnee,
        leftAnkle,
        rightAnkle,
      ];
}
