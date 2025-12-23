import 'package:flutter/material.dart';
import '../models/form_analysis.dart';

/// Overlay widget that displays real-time form feedback
class FormFeedbackOverlay extends StatelessWidget {
  final FormFeedback? feedback;
  final int repCount;
  final bool isDetecting;

  const FormFeedbackOverlay({
    super.key,
    this.feedback,
    required this.repCount,
    required this.isDetecting,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Form score badge
          if (feedback != null) _buildScoreBadge(context, feedback!),

          const SizedBox(height: 12),

          // Feedback messages
          if (feedback != null && feedback!.textInstructions.isNotEmpty)
            _buildFeedbackMessages(context, feedback!),

          const SizedBox(height: 12),

          // Rep counter
          _buildRepCounter(context),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(BuildContext context, FormFeedback feedback) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: feedback.score.displayColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getScoreIcon(feedback),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Form: ${feedback.score.grade}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${feedback.score.percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getScoreIcon(FormFeedback feedback) {
    if (feedback.score.percentage >= 90) {
      return Icons.check_circle;
    } else if (feedback.score.percentage >= 70) {
      return Icons.warning_amber;
    } else {
      return Icons.error;
    }
  }

  Widget _buildFeedbackMessages(BuildContext context, FormFeedback feedback) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: feedback.hasCriticalIssues
              ? Colors.red.withOpacity(0.5)
              : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                feedback.hasCriticalIssues
                    ? Icons.warning
                    : Icons.info_outline,
                color: feedback.hasCriticalIssues ? Colors.red : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                feedback.hasCriticalIssues
                    ? 'Form Issues Detected'
                    : 'Feedback',
                style: TextStyle(
                  color: feedback.hasCriticalIssues ? Colors.red : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Instructions
          ...feedback.textInstructions.map((instruction) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      instruction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRepCounter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            color: isDetecting ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Reps: $repCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
