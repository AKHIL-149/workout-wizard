import 'dart:math';
import 'package:vector_math/vector_math.dart' as vm;
import '../models/pose_data.dart';

/// Utility class for calculating angles and geometric properties from pose landmarks
class AngleCalculator {
  /// Calculate angle between three points (in degrees)
  /// The angle is measured at the middle point (vertex)
  ///
  /// Example: For knee angle, pass [hip, knee, ankle]
  /// Returns angle in degrees (0-180)
  static double calculateAngle(
    PoseLandmark point1,
    PoseLandmark vertex,
    PoseLandmark point2,
  ) {
    // Create vectors from vertex to each point
    final vector1 = vm.Vector2(
      point1.x - vertex.x,
      point1.y - vertex.y,
    );

    final vector2 = vm.Vector2(
      point2.x - vertex.x,
      point2.y - vertex.y,
    );

    // Calculate angle using dot product and magnitudes
    final dotProduct = vector1.dot(vector2);
    final magnitude1 = vector1.length;
    final magnitude2 = vector2.length;

    if (magnitude1 == 0 || magnitude2 == 0) {
      return 0.0;
    }

    // cos(θ) = (a · b) / (|a| * |b|)
    final cosAngle = dotProduct / (magnitude1 * magnitude2);

    // Clamp to [-1, 1] to handle floating point errors
    final clampedCos = cosAngle.clamp(-1.0, 1.0);

    // Convert to degrees
    final angleRadians = acos(clampedCos);
    final angleDegrees = angleRadians * 180 / pi;

    return angleDegrees;
  }

  /// Calculate angle using 3D coordinates (more accurate)
  static double calculateAngle3D(
    PoseLandmark point1,
    PoseLandmark vertex,
    PoseLandmark point2,
  ) {
    // Create 3D vectors from vertex to each point
    final vector1 = vm.Vector3(
      point1.x - vertex.x,
      point1.y - vertex.y,
      point1.z - vertex.z,
    );

    final vector2 = vm.Vector3(
      point2.x - vertex.x,
      point2.y - vertex.y,
      point2.z - vertex.z,
    );

    // Calculate angle using dot product
    final dotProduct = vector1.dot(vector2);
    final magnitude1 = vector1.length;
    final magnitude2 = vector2.length;

    if (magnitude1 == 0 || magnitude2 == 0) {
      return 0.0;
    }

    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final clampedCos = cosAngle.clamp(-1.0, 1.0);
    final angleRadians = acos(clampedCos);
    final angleDegrees = angleRadians * 180 / pi;

    return angleDegrees;
  }

  /// Calculate angle from pose snapshot using landmark names
  static double calculateAngleFromNames(
    PoseSnapshot pose,
    String point1Name,
    String vertexName,
    String point2Name,
    {bool use3D = false}
  ) {
    final point1 = pose.getLandmark(point1Name);
    final vertex = pose.getLandmark(vertexName);
    final point2 = pose.getLandmark(point2Name);

    if (point1 == null || vertex == null || point2 == null) {
      return 0.0;
    }

    // Check confidence
    if (point1.confidence < 0.5 || vertex.confidence < 0.5 || point2.confidence < 0.5) {
      return 0.0;
    }

    return use3D
      ? calculateAngle3D(point1, vertex, point2)
      : calculateAngle(point1, vertex, point2);
  }

  /// Calculate vertical distance between two landmarks (normalized)
  static double calculateVerticalDistance(
    PoseLandmark point1,
    PoseLandmark point2,
  ) {
    return (point2.y - point1.y).abs();
  }

  /// Calculate horizontal distance between two landmarks (normalized)
  static double calculateHorizontalDistance(
    PoseLandmark point1,
    PoseLandmark point2,
  ) {
    return (point2.x - point1.x).abs();
  }

  /// Calculate Euclidean distance between two landmarks (normalized)
  static double calculateDistance(
    PoseLandmark point1,
    PoseLandmark point2,
  ) {
    final dx = point2.x - point1.x;
    final dy = point2.y - point1.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Calculate 3D Euclidean distance
  static double calculateDistance3D(
    PoseLandmark point1,
    PoseLandmark point2,
  ) {
    final dx = point2.x - point1.x;
    final dy = point2.y - point1.y;
    final dz = point2.z - point1.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Check if point A is aligned vertically with point B
  /// Returns true if horizontal distance is below threshold
  static bool isVerticallyAligned(
    PoseLandmark point1,
    PoseLandmark point2,
    {double threshold = 0.05}
  ) {
    final horizontalDist = calculateHorizontalDistance(point1, point2);
    return horizontalDist < threshold;
  }

  /// Check if point A is aligned horizontally with point B
  /// Returns true if vertical distance is below threshold
  static bool isHorizontallyAligned(
    PoseLandmark point1,
    PoseLandmark point2,
    {double threshold = 0.05}
  ) {
    final verticalDist = calculateVerticalDistance(point1, point2);
    return verticalDist < threshold;
  }

  /// Calculate slope of line between two points (rise/run)
  static double calculateSlope(
    PoseLandmark point1,
    PoseLandmark point2,
  ) {
    final dx = point2.x - point1.x;
    if (dx == 0) return double.infinity;

    final dy = point2.y - point1.y;
    return dy / dx;
  }

  /// Check if three points are collinear (on the same line)
  /// Used to check if joints are locked out or body is straight
  static bool areCollinear(
    PoseLandmark point1,
    PoseLandmark point2,
    PoseLandmark point3,
    {double threshold = 10.0} // degrees from 180
  ) {
    final angle = calculateAngle(point1, point2, point3);
    return (180 - angle).abs() < threshold;
  }

  /// Calculate center point between two landmarks
  static PoseLandmark calculateMidpoint(
    PoseLandmark point1,
    PoseLandmark point2,
  ) {
    return PoseLandmark(
      name: '${point1.name}_${point2.name}_MID',
      x: (point1.x + point2.x) / 2,
      y: (point1.y + point2.y) / 2,
      z: (point1.z + point2.z) / 2,
      confidence: min(point1.confidence, point2.confidence),
    );
  }

  /// Get the side with higher confidence (left or right)
  /// Useful for single-side analysis when user is turned sideways
  static String getPreferredSide(PoseSnapshot pose) {
    final leftShoulder = pose.getLandmark('LEFT_SHOULDER');
    final rightShoulder = pose.getLandmark('RIGHT_SHOULDER');
    final leftHip = pose.getLandmark('LEFT_HIP');
    final rightHip = pose.getLandmark('RIGHT_HIP');
    final leftKnee = pose.getLandmark('LEFT_KNEE');
    final rightKnee = pose.getLandmark('RIGHT_KNEE');

    double leftConfidence = 0.0;
    double rightConfidence = 0.0;
    int leftCount = 0;
    int rightCount = 0;

    if (leftShoulder != null) {
      leftConfidence += leftShoulder.confidence;
      leftCount++;
    }
    if (leftHip != null) {
      leftConfidence += leftHip.confidence;
      leftCount++;
    }
    if (leftKnee != null) {
      leftConfidence += leftKnee.confidence;
      leftCount++;
    }

    if (rightShoulder != null) {
      rightConfidence += rightShoulder.confidence;
      rightCount++;
    }
    if (rightHip != null) {
      rightConfidence += rightHip.confidence;
      rightCount++;
    }
    if (rightKnee != null) {
      rightConfidence += rightKnee.confidence;
      rightCount++;
    }

    final leftAvg = leftCount > 0 ? leftConfidence / leftCount : 0.0;
    final rightAvg = rightCount > 0 ? rightConfidence / rightCount : 0.0;

    return leftAvg > rightAvg ? 'LEFT' : 'RIGHT';
  }

  /// Check if body is facing camera (both sides visible)
  /// or sideways (one side visible)
  static bool isFacingCamera(PoseSnapshot pose) {
    final leftShoulder = pose.getLandmark('LEFT_SHOULDER');
    final rightShoulder = pose.getLandmark('RIGHT_SHOULDER');

    if (leftShoulder == null || rightShoulder == null) {
      return false;
    }

    // If shoulders are far apart horizontally, user is facing camera
    final shoulderWidth = calculateHorizontalDistance(leftShoulder, rightShoulder);

    // Threshold: if shoulders > 0.2 normalized distance apart, facing camera
    return shoulderWidth > 0.2;
  }

  /// Normalize angle to 0-360 range
  static double normalizeAngle(double angle) {
    double normalized = angle % 360;
    if (normalized < 0) {
      normalized += 360;
    }
    return normalized;
  }

  /// Calculate body tilt angle (how much user is leaning forward/backward)
  static double calculateBodyTilt(PoseSnapshot pose, String side) {
    final shoulder = pose.getLandmark('${side}_SHOULDER');
    final hip = pose.getLandmark('${side}_HIP');

    if (shoulder == null || hip == null) {
      return 0.0;
    }

    // Calculate angle from vertical
    final dx = hip.x - shoulder.x;
    final dy = hip.y - shoulder.y;

    if (dy == 0) return 90.0;

    final angleRadians = atan(dx.abs() / dy.abs());
    return angleRadians * 180 / pi;
  }

  /// Check if knees are caving inward (valgus collapse)
  /// Compares knee position to hip and ankle alignment
  static bool isKneeCaving(PoseSnapshot pose, String side) {
    final hip = pose.getLandmark('${side}_HIP');
    final knee = pose.getLandmark('${side}_KNEE');
    final ankle = pose.getLandmark('${side}_ANKLE');

    if (hip == null || knee == null || ankle == null) {
      return false;
    }

    // Calculate vertical line from hip to ankle
    final hipAnkleMidX = (hip.x + ankle.x) / 2;

    // If knee is significantly displaced inward, it's caving
    final kneeDisplacement = (knee.x - hipAnkleMidX).abs();

    // Threshold: 0.05 normalized distance
    return kneeDisplacement > 0.05 && knee.x < hipAnkleMidX;
  }

  /// Calculate depth ratio for squats/lunges
  /// Returns ratio of hip drop (0.0 = standing, 1.0 = deep squat)
  static double calculateSquatDepth(
    PoseSnapshot currentPose,
    PoseSnapshot? standingPose,
    String side,
  ) {
    final currentHip = currentPose.getLandmark('${side}_HIP');

    if (currentHip == null) return 0.0;

    if (standingPose == null) {
      // Estimate based on knee-hip relationship
      final knee = currentPose.getLandmark('${side}_KNEE');
      if (knee == null) return 0.0;

      // Deep squat: hip below knee
      // Parallel: hip at knee level
      // Quarter squat: hip above knee
      final hipKneeDistance = currentHip.y - knee.y;

      // Normalize to 0-1 scale
      // Positive = hip above knee, negative = hip below knee
      if (hipKneeDistance > 0) {
        return 0.3; // Shallow
      } else {
        return 0.7 + (hipKneeDistance.abs() * 2).clamp(0.0, 0.3);
      }
    }

    final standingHip = standingPose.getLandmark('${side}_HIP');
    if (standingHip == null) return 0.0;

    // Calculate vertical drop
    final drop = currentHip.y - standingHip.y;

    // Estimate max drop as ~40% of body height
    final shoulder = currentPose.getLandmark('${side}_SHOULDER');
    final ankle = currentPose.getLandmark('${side}_ANKLE');

    if (shoulder != null && ankle != null) {
      final bodyHeight = ankle.y - shoulder.y;
      final maxDrop = bodyHeight * 0.4;

      return (drop / maxDrop).clamp(0.0, 1.0);
    }

    return 0.0;
  }
}
