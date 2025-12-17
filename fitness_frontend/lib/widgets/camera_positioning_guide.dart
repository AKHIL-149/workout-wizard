import 'package:flutter/material.dart';
import '../models/pose_data.dart';

/// Widget that guides user to position themselves correctly for pose detection
class CameraPositioningGuide extends StatelessWidget {
  final PoseSnapshot? currentPose;
  final bool isReady;

  const CameraPositioningGuide({
    super.key,
    this.currentPose,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReady ? Colors.green : Colors.orange,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status icon
          Icon(
            isReady ? Icons.check_circle : Icons.person_outline,
            color: isReady ? Colors.green : Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),

          // Status text
          Text(
            isReady ? 'Ready!' : 'Position Yourself',
            style: TextStyle(
              color: isReady ? Colors.green : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Instructions
          if (!isReady) ..._buildInstructions() else ..._buildReadyMessage(),
        ],
      ),
    );
  }

  List<Widget> _buildInstructions() {
    return [
      _buildInstruction(
        icon: Icons.person_pin_circle,
        text: 'Stand sideways to the camera',
        isComplete: _checkSideways(),
      ),
      const SizedBox(height: 8),
      _buildInstruction(
        icon: Icons.fullscreen,
        text: 'Make sure full body is visible',
        isComplete: _checkFullBodyVisible(),
      ),
      const SizedBox(height: 8),
      _buildInstruction(
        icon: Icons.lightbulb_outline,
        text: 'Ensure good lighting',
        isComplete: currentPose != null && currentPose!.overallConfidence > 0.7,
      ),
      const SizedBox(height: 8),
      _buildInstruction(
        icon: Icons.straighten,
        text: 'Stand 6-8 feet from camera',
        isComplete: currentPose != null,
      ),
    ];
  }

  List<Widget> _buildReadyMessage() {
    return [
      const Text(
        'You\'re all set! Start your exercise when ready.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    ];
  }

  Widget _buildInstruction({
    required IconData icon,
    required String text,
    required bool isComplete,
  }) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isComplete ? Colors.green : Colors.grey,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isComplete ? Colors.white : Colors.grey[400],
              fontSize: 14,
              decoration: isComplete ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }

  bool _checkSideways() {
    if (currentPose == null) return false;

    // Check if only one side is prominently visible
    final leftShoulder = currentPose!.getLandmark('LEFT_SHOULDER');
    final rightShoulder = currentPose!.getLandmark('RIGHT_SHOULDER');

    if (leftShoulder == null || rightShoulder == null) return false;

    // If one shoulder has significantly higher confidence, user is sideways
    final confidenceDiff = (leftShoulder.confidence - rightShoulder.confidence).abs();
    return confidenceDiff > 0.2;
  }

  bool _checkFullBodyVisible() {
    if (currentPose == null) return false;

    // Check if key landmarks are detected
    final requiredLandmarks = [
      'LEFT_SHOULDER',
      'LEFT_HIP',
      'LEFT_KNEE',
      'LEFT_ANKLE',
    ];

    return currentPose!.hasRequiredLandmarks(requiredLandmarks, minConfidence: 0.6);
  }
}

/// Overlay showing body outline guide
class BodyOutlineGuide extends StatelessWidget {
  final Size screenSize;

  const BodyOutlineGuide({
    super.key,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: screenSize,
      painter: _BodyOutlinePainter(),
    );
  }
}

class _BodyOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dashedPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw a simple body outline in the center
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Head
    canvas.drawCircle(
      Offset(centerX, centerY - 120),
      30,
      paint,
    );

    // Torso
    final torsoPath = Path();
    torsoPath.moveTo(centerX, centerY - 90);
    torsoPath.lineTo(centerX, centerY + 40);
    canvas.drawPath(torsoPath, paint);

    // Arms (simplified)
    canvas.drawLine(
      Offset(centerX, centerY - 60),
      Offset(centerX - 60, centerY - 20),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - 60),
      Offset(centerX + 60, centerY - 20),
      paint,
    );

    // Legs
    canvas.drawLine(
      Offset(centerX, centerY + 40),
      Offset(centerX - 30, centerY + 140),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + 40),
      Offset(centerX + 30, centerY + 140),
      paint,
    );

    // Draw bounding box
    final boundingRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: size.width * 0.6,
      height: size.height * 0.8,
    );

    _drawDashedRect(canvas, boundingRect, dashedPaint);

    // Add text hint
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Stand within this area',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        boundingRect.top - 40,
      ),
    );
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 5.0;

    // Top
    _drawDashedLine(
      canvas,
      rect.topLeft,
      rect.topRight,
      dashWidth,
      dashSpace,
      paint,
    );

    // Right
    _drawDashedLine(
      canvas,
      rect.topRight,
      rect.bottomRight,
      dashWidth,
      dashSpace,
      paint,
    );

    // Bottom
    _drawDashedLine(
      canvas,
      rect.bottomRight,
      rect.bottomLeft,
      dashWidth,
      dashSpace,
      paint,
    );

    // Left
    _drawDashedLine(
      canvas,
      rect.bottomLeft,
      rect.topLeft,
      dashWidth,
      dashSpace,
      paint,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    double dashWidth,
    double dashSpace,
    Paint paint,
  ) {
    final path = Path();
    final distance = (end - start).distance;
    final normalizedDirection = (end - start) / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final dashEnd = currentDistance + dashWidth;
      path.moveTo(
        start.dx + normalizedDirection.dx * currentDistance,
        start.dy + normalizedDirection.dy * currentDistance,
      );
      path.lineTo(
        start.dx + normalizedDirection.dx * dashEnd.clamp(0, distance),
        start.dy + normalizedDirection.dy * dashEnd.clamp(0, distance),
      );
      currentDistance += dashWidth + dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BodyOutlinePainter oldDelegate) => false;
}
