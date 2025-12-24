import 'package:flutter/material.dart';
import '../models/pose_data.dart';
import '../models/form_analysis.dart';
import '../utils/constants.dart';

/// Custom painter that draws pose skeleton overlay on camera preview
class PoseSkeletonPainter extends CustomPainter {
  final PoseSnapshot? pose;
  final FormFeedback? feedback;
  final Size imageSize;
  final bool showLabels;

  PoseSkeletonPainter({
    required this.pose,
    this.feedback,
    required this.imageSize,
    this.showLabels = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final currentPose = pose;
    if (currentPose == null || currentPose.landmarks.isEmpty) return;

    // Calculate scale to fit image to canvas
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate offset to center image
    final offsetX = (size.width - imageSize.width * scale) / 2;
    final offsetY = (size.height - imageSize.height * scale) / 2;

    // Draw connections (bones) first, then landmarks (joints)
    _drawConnections(canvas, currentPose, scale, offsetX, offsetY);
    _drawLandmarks(canvas, currentPose, scale, offsetX, offsetY);
  }

  /// Draw connections between landmarks (bones)
  void _drawConnections(Canvas canvas, PoseSnapshot pose, double scale, double offsetX, double offsetY) {
    final paint = Paint()
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Define skeleton connections
    final connections = _getSkeletonConnections();

    for (final connection in connections) {
      final start = pose.getLandmark(connection.start);
      final end = pose.getLandmark(connection.end);

      if (start != null && end != null &&
          start.confidence > AppConstants.minPoseConfidence &&
          end.confidence > AppConstants.minPoseConfidence) {

        // Determine color based on form feedback
        paint.color = _getConnectionColor(connection.start, connection.end);

        // Calculate positions
        final startPos = Offset(
          start.x * scale + offsetX,
          start.y * scale + offsetY,
        );
        final endPos = Offset(
          end.x * scale + offsetX,
          end.y * scale + offsetY,
        );

        canvas.drawLine(startPos, endPos, paint);
      }
    }
  }

  /// Draw landmarks (joints)
  void _drawLandmarks(Canvas canvas, PoseSnapshot pose, double scale, double offsetX, double offsetY) {
    for (final landmark in pose.landmarks) {
      if (landmark.confidence < AppConstants.minPoseConfidence) continue;

      final position = Offset(
        landmark.x * scale + offsetX,
        landmark.y * scale + offsetY,
      );

      // Determine color and size based on confidence and feedback
      final color = _getLandmarkColor(landmark.name);
      final radius = landmark.confidence > AppConstants.highPoseConfidence ? 6.0 : 4.0;

      // Draw joint circle
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, radius, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(position, radius, borderPaint);

      // Draw label if enabled
      if (showLabels) {
        _drawLabel(canvas, landmark.name, position);
      }
    }
  }

  /// Draw label for landmark
  void _drawLabel(Canvas canvas, String name, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: name.split('_').last,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx + 8, position.dy - textPainter.height / 2),
    );
  }

  /// Get landmark color based on form feedback
  Color _getLandmarkColor(String landmarkName) {
    final currentFeedback = feedback;
    if (currentFeedback == null) {
      return Colors.green;
    }

    // Check if this landmark is affected by any violation
    for (final violation in currentFeedback.violations) {
      if (violation.affectedJoint == landmarkName) {
        return violation.severityColor;
      }
    }

    // Use overall form score for color
    if (currentFeedback.score.percentage >= 85) {
      return Colors.green;
    } else if (currentFeedback.score.percentage >= 70) {
      return Colors.yellow;
    } else {
      return Colors.orange;
    }
  }

  /// Get connection color based on form feedback
  Color _getConnectionColor(String start, String end) {
    final currentFeedback = feedback;
    if (currentFeedback == null) {
      return Colors.green.withOpacity(0.7);
    }

    // Check if either endpoint is affected by a violation
    final affectedJoints = currentFeedback.violations
        .map((v) => v.affectedJoint)
        .whereType<String>()
        .toList();

    if (affectedJoints.contains(start) || affectedJoints.contains(end)) {
      // Find the most severe violation affecting these joints
      final violations = currentFeedback.violations.where(
        (v) => v.affectedJoint == start || v.affectedJoint == end,
      );

      if (violations.isNotEmpty) {
        return violations.first.severityColor.withOpacity(0.7);
      }
    }

    // Use overall form score for color
    if (currentFeedback.score.percentage >= 85) {
      return Colors.green.withOpacity(0.7);
    } else if (currentFeedback.score.percentage >= 70) {
      return Colors.yellow.withOpacity(0.7);
    } else {
      return Colors.orange.withOpacity(0.7);
    }
  }

  /// Define skeleton connections
  List<_Connection> _getSkeletonConnections() {
    return [
      // Face
      _Connection('NOSE', 'LEFT_EYE'),
      _Connection('LEFT_EYE', 'LEFT_EAR'),
      _Connection('NOSE', 'RIGHT_EYE'),
      _Connection('RIGHT_EYE', 'RIGHT_EAR'),
      _Connection('LEFT_MOUTH', 'RIGHT_MOUTH'),

      // Torso
      _Connection('LEFT_SHOULDER', 'RIGHT_SHOULDER'),
      _Connection('LEFT_SHOULDER', 'LEFT_HIP'),
      _Connection('RIGHT_SHOULDER', 'RIGHT_HIP'),
      _Connection('LEFT_HIP', 'RIGHT_HIP'),

      // Left arm
      _Connection('LEFT_SHOULDER', 'LEFT_ELBOW'),
      _Connection('LEFT_ELBOW', 'LEFT_WRIST'),
      _Connection('LEFT_WRIST', 'LEFT_THUMB'),
      _Connection('LEFT_WRIST', 'LEFT_INDEX'),
      _Connection('LEFT_WRIST', 'LEFT_PINKY'),

      // Right arm
      _Connection('RIGHT_SHOULDER', 'RIGHT_ELBOW'),
      _Connection('RIGHT_ELBOW', 'RIGHT_WRIST'),
      _Connection('RIGHT_WRIST', 'RIGHT_THUMB'),
      _Connection('RIGHT_WRIST', 'RIGHT_INDEX'),
      _Connection('RIGHT_WRIST', 'RIGHT_PINKY'),

      // Left leg
      _Connection('LEFT_HIP', 'LEFT_KNEE'),
      _Connection('LEFT_KNEE', 'LEFT_ANKLE'),
      _Connection('LEFT_ANKLE', 'LEFT_HEEL'),
      _Connection('LEFT_ANKLE', 'LEFT_FOOT_INDEX'),

      // Right leg
      _Connection('RIGHT_HIP', 'RIGHT_KNEE'),
      _Connection('RIGHT_KNEE', 'RIGHT_ANKLE'),
      _Connection('RIGHT_ANKLE', 'RIGHT_HEEL'),
      _Connection('RIGHT_ANKLE', 'RIGHT_FOOT_INDEX'),
    ];
  }

  @override
  bool shouldRepaint(PoseSkeletonPainter oldDelegate) {
    // Only repaint if pose or feedback changed significantly
    if (oldDelegate.pose != pose) return true;
    if (oldDelegate.feedback != feedback) return true;
    return false;
  }
}

/// Helper class for defining connections between landmarks
class _Connection {
  final String start;
  final String end;

  _Connection(this.start, this.end);
}
