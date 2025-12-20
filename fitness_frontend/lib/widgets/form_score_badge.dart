import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/form_analysis.dart';

/// Animated badge that displays current form score
class FormScoreBadge extends StatefulWidget {
  final FormScore score;
  final bool showPercentage;
  final double size;

  const FormScoreBadge({
    super.key,
    required this.score,
    this.showPercentage = true,
    this.size = 120,
  });

  @override
  State<FormScoreBadge> createState() => _FormScoreBadgeState();
}

class _FormScoreBadgeState extends State<FormScoreBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousPercentage = 0;

  @override
  void initState() {
    super.initState();
    _previousPercentage = widget.score.percentage;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.score.percentage / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(FormScoreBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.score.percentage != _previousPercentage) {
      _progressAnimation = Tween<double>(
        begin: _previousPercentage / 100,
        end: widget.score.percentage / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));

      _controller.reset();
      _controller.forward();
      _previousPercentage = widget.score.percentage;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = 'Form score: ${widget.score.grade}, ${widget.score.percentage.toStringAsFixed(0)} percent';

    return Semantics(
      label: semanticsLabel,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
              // Background circle
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularProgressPainter(
                  progress: _progressAnimation.value,
                  color: widget.score.displayColor,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  strokeWidth: 8,
                ),
              ),

              // Score text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Grade
                  Text(
                    widget.score.grade,
                    style: TextStyle(
                      color: widget.score.displayColor,
                      fontSize: widget.size * 0.35,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),

                  // Percentage
                  if (widget.showPercentage) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.score.percentage).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: widget.size * 0.15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
      ),
    );
  }
}

/// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Compact version of form score badge
class CompactFormScoreBadge extends StatelessWidget {
  final FormScore score;

  const CompactFormScoreBadge({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: score.displayColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            score.grade,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${score.percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    if (score.percentage >= 90) {
      return Icons.check_circle;
    } else if (score.percentage >= 70) {
      return Icons.warning_amber;
    } else {
      return Icons.error;
    }
  }
}
