import 'package:flutter/material.dart';
import 'pose_data.dart';

/// Severity level for form violations
enum Severity {
  critical, // Major safety issue (e.g., back rounding in deadlift)
  warning, // Form issue that should be corrected
  info, // Minor suggestion for improvement
}

/// Specific form violation detected
class FormViolation {
  final String type; // e.g., "KNEE_CAVE", "BACK_ROUNDING"
  final String description; // User-friendly description
  final String correction; // How to fix it
  final Severity severity;
  final String? affectedJoint; // Which joint/body part
  final DateTime timestamp;

  const FormViolation({
    required this.type,
    required this.description,
    required this.correction,
    required this.severity,
    this.affectedJoint,
    required this.timestamp,
  });

  /// Get color based on severity
  Color get severityColor {
    switch (severity) {
      case Severity.critical:
        return Colors.red;
      case Severity.warning:
        return Colors.orange;
      case Severity.info:
        return Colors.blue;
    }
  }

  /// Get icon based on severity
  IconData get severityIcon {
    switch (severity) {
      case Severity.critical:
        return Icons.error;
      case Severity.warning:
        return Icons.warning;
      case Severity.info:
        return Icons.info;
    }
  }

  factory FormViolation.fromJson(Map<String, dynamic> json) {
    return FormViolation(
      type: json['type'] as String,
      description: json['description'] as String,
      correction: json['correction'] as String,
      severity: Severity.values.firstWhere(
        (e) => e.toString() == 'Severity.${json['severity']}',
      ),
      affectedJoint: json['affectedJoint'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'correction': correction,
        'severity': severity.toString().split('.').last,
        'affectedJoint': affectedJoint,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'FormViolation($type, severity: $severity, $description)';
}

/// Overall form quality score
class FormScore {
  final double percentage; // 0-100
  final String grade; // A+, A, B, C, D, F
  final Color displayColor;

  const FormScore({
    required this.percentage,
    required this.grade,
    required this.displayColor,
  });

  /// Calculate grade from percentage
  factory FormScore.fromPercentage(double percentage) {
    String grade;
    Color color;

    if (percentage >= 95) {
      grade = 'A+';
      color = Colors.green[700]!;
    } else if (percentage >= 90) {
      grade = 'A';
      color = Colors.green;
    } else if (percentage >= 85) {
      grade = 'A-';
      color = Colors.green;
    } else if (percentage >= 80) {
      grade = 'B+';
      color = Colors.lightGreen;
    } else if (percentage >= 75) {
      grade = 'B';
      color = Colors.lime;
    } else if (percentage >= 70) {
      grade = 'B-';
      color = Colors.yellow[700]!;
    } else if (percentage >= 65) {
      grade = 'C+';
      color = Colors.orange;
    } else if (percentage >= 60) {
      grade = 'C';
      color = Colors.orange;
    } else if (percentage >= 55) {
      grade = 'C-';
      color = Colors.deepOrange;
    } else if (percentage >= 50) {
      grade = 'D';
      color = Colors.red[400]!;
    } else {
      grade = 'F';
      color = Colors.red;
    }

    return FormScore(
      percentage: percentage,
      grade: grade,
      displayColor: color,
    );
  }

  factory FormScore.fromJson(Map<String, dynamic> json) {
    return FormScore.fromPercentage((json['percentage'] as num).toDouble());
  }

  Map<String, dynamic> toJson() => {
        'percentage': percentage,
        'grade': grade,
        'displayColor': displayColor.value,
      };

  @override
  String toString() => 'FormScore($grade, ${percentage.toStringAsFixed(1)}%)';
}

/// Real-time form feedback
class FormFeedback {
  final FormScore score;
  final List<FormViolation> violations;
  final List<String> textInstructions;
  final String? audioMessage;
  final DateTime timestamp;

  const FormFeedback({
    required this.score,
    required this.violations,
    required this.textInstructions,
    this.audioMessage,
    required this.timestamp,
  });

  /// Create feedback for low confidence pose
  factory FormFeedback.lowConfidence({String? message}) {
    return FormFeedback(
      score: FormScore.fromPercentage(0),
      violations: [],
      textInstructions: [
        message ?? "Can't analyze form clearly. Adjust your position."
      ],
      audioMessage: null,
      timestamp: DateTime.now(),
    );
  }

  /// Create positive feedback
  factory FormFeedback.excellent() {
    return FormFeedback(
      score: FormScore.fromPercentage(100),
      violations: [],
      textInstructions: ['Excellent form! Keep it up!'],
      audioMessage: 'Excellent form!',
      timestamp: DateTime.now(),
    );
  }

  /// Check if feedback has critical issues
  bool get hasCriticalIssues =>
      violations.any((v) => v.severity == Severity.critical);

  /// Get most severe violation
  FormViolation? get mostSevereViolation {
    if (violations.isEmpty) return null;

    return violations.reduce((a, b) {
      final severityOrder = {
        Severity.critical: 3,
        Severity.warning: 2,
        Severity.info: 1,
      };
      return (severityOrder[a.severity] ?? 0) > (severityOrder[b.severity] ?? 0)
          ? a
          : b;
    });
  }

  factory FormFeedback.fromJson(Map<String, dynamic> json) {
    return FormFeedback(
      score: FormScore.fromJson(json['score'] as Map<String, dynamic>),
      violations: (json['violations'] as List)
          .map((v) => FormViolation.fromJson(v as Map<String, dynamic>))
          .toList(),
      textInstructions: List<String>.from(json['textInstructions'] as List),
      audioMessage: json['audioMessage'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score.toJson(),
        'violations': violations.map((v) => v.toJson()).toList(),
        'textInstructions': textInstructions,
        'audioMessage': audioMessage,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'FormFeedback($score, ${violations.length} violations)';
}

/// Analysis of a single rep
class RepAnalysis {
  final int repNumber;
  final double formScore; // Average score for this rep
  final Duration duration;
  final List<FormViolation> violations;
  final PoseSnapshot? bottomPosition;
  final PoseSnapshot? topPosition;
  final DateTime timestamp;

  const RepAnalysis({
    required this.repNumber,
    required this.formScore,
    required this.duration,
    required this.violations,
    this.bottomPosition,
    this.topPosition,
    required this.timestamp,
  });

  /// Check if rep was performed correctly (no critical violations)
  bool get isGoodRep =>
      !violations.any((v) => v.severity == Severity.critical);

  /// Get grade for this rep
  String get grade => FormScore.fromPercentage(formScore).grade;

  factory RepAnalysis.fromJson(Map<String, dynamic> json) {
    return RepAnalysis(
      repNumber: json['repNumber'] as int,
      formScore: (json['formScore'] as num).toDouble(),
      duration: Duration(milliseconds: json['durationMs'] as int),
      violations: (json['violations'] as List)
          .map((v) => FormViolation.fromJson(v as Map<String, dynamic>))
          .toList(),
      bottomPosition: json['bottomPosition'] != null
          ? PoseSnapshot.fromJson(json['bottomPosition'] as Map<String, dynamic>)
          : null,
      topPosition: json['topPosition'] != null
          ? PoseSnapshot.fromJson(json['topPosition'] as Map<String, dynamic>)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'repNumber': repNumber,
        'formScore': formScore,
        'durationMs': duration.inMilliseconds,
        'violations': violations.map((v) => v.toJson()).toList(),
        'bottomPosition': bottomPosition?.toJson(),
        'topPosition': topPosition?.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'RepAnalysis(#$repNumber, score: ${formScore.toStringAsFixed(1)}, ${violations.length} violations)';
}

/// Rep detection event
enum RepEventType {
  started, // Rep started (beginning descent/ascent)
  bottomReached, // Bottom position reached
  topReached, // Top position reached
  completed, // Rep completed
}

class RepEvent {
  final RepEventType type;
  final DateTime timestamp;
  final PoseSnapshot pose;

  const RepEvent({
    required this.type,
    required this.timestamp,
    required this.pose,
  });

  @override
  String toString() => 'RepEvent($type at ${timestamp.toIso8601String()})';
}

/// Common violation types
class ViolationType {
  static const String kneeCave = 'KNEE_CAVE';
  static const String backRounding = 'BACK_ROUNDING';
  static const String shallowSquat = 'SHALLOW_SQUAT';
  static const String kneeTooForward = 'KNEE_TOO_FORWARD';
  static const String insufficientDepth = 'INSUFFICIENT_DEPTH';
  static const String improperStartingPosition = 'IMPROPER_STARTING_POSITION';
  static const String elbowFlare = 'ELBOW_FLARE';
  static const String unbalancedBar = 'UNBALANCED_BAR';
  static const String heelLift = 'HEEL_LIFT';
  static const String headPosition = 'HEAD_POSITION';
  static const String asymmetricMovement = 'ASYMMETRIC_MOVEMENT';
  static const String tooFastEccentric = 'TOO_FAST_ECCENTRIC';
  static const String tooFastConcentric = 'TOO_FAST_CONCENTRIC';
  static const String lockoutIssue = 'LOCKOUT_ISSUE';
  static const String gripWidth = 'GRIP_WIDTH';
}
