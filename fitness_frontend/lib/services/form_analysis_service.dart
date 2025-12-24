import 'dart:async';
import '../models/pose_data.dart';
import '../models/form_analysis.dart';
import '../models/exercise_form_rules.dart';
import '../utils/angle_calculator.dart';
import '../utils/constants.dart';

/// Service for analyzing exercise form and detecting reps
class FormAnalysisService {
  final ExerciseFormRules _exerciseRules;

  // Rep detection state
  int _repCount = 0;
  ExercisePhase _currentPhase = ExercisePhase.top;
  DateTime? _phaseStartTime;
  double? _startingPosition;
  double? _bottomPosition;
  double? _topPosition;

  // History for analysis
  final List<FormFeedback> _feedbackHistory = [];
  final List<RepAnalysis> _repHistory = [];
  final List<PoseSnapshot> _poseHistory = [];
  final int _maxHistorySize = AppConstants.maxHistorySize;

  // Streaming
  final _feedbackController = StreamController<FormFeedback>.broadcast();
  final _repController = StreamController<RepEvent>.broadcast();

  // Analysis settings
  final double minConfidenceThreshold;
  final int feedbackCooldownMs; // Prevent spam
  DateTime? _lastFeedbackTime;

  FormAnalysisService({
    required ExerciseFormRules exerciseRules,
    this.minConfidenceThreshold = AppConstants.minLandmarkConfidence,
    this.feedbackCooldownMs = AppConstants.defaultFeedbackCooldownMs,
  }) : _exerciseRules = exerciseRules;

  /// Stream of real-time form feedback
  Stream<FormFeedback> get feedbackStream => _feedbackController.stream;

  /// Stream of rep events
  Stream<RepEvent> get repStream => _repController.stream;

  /// Current rep count
  int get repCount => _repCount;

  /// Current exercise phase
  ExercisePhase get currentPhase => _currentPhase;

  /// Analyze a pose snapshot and provide form feedback
  Future<FormFeedback> analyzePose(PoseSnapshot pose) async {
    // Add to history
    _addPoseToHistory(pose);

    // Check overall confidence
    if (pose.overallConfidence < minConfidenceThreshold) {
      final feedback = FormFeedback.lowConfidence(
        message: 'Position yourself so full body is visible',
      );
      _emitFeedback(feedback);
      return feedback;
    }

    // Determine which side to analyze (left or right)
    final side = AngleCalculator.getPreferredSide(pose);

    // Detect current exercise phase
    _updatePhase(pose, side);

    // Check angle rules
    final angleViolations = _checkAngleRules(pose, side);

    // Check alignment rules
    final alignmentViolations = _checkAlignmentRules(pose, side);

    // Combine violations
    final allViolations = [...angleViolations, ...alignmentViolations];

    // Calculate form score
    final score = _calculateFormScore(allViolations, pose);

    // Generate text instructions
    final textInstructions = _generateInstructions(allViolations);

    // Generate audio message (prioritize critical violations)
    final audioMessage = _generateAudioMessage(allViolations);

    // Create feedback
    final feedback = FormFeedback(
      score: score,
      violations: allViolations,
      textInstructions: textInstructions,
      audioMessage: audioMessage,
      timestamp: DateTime.now(),
    );

    // Add to history
    _addFeedbackToHistory(feedback);

    // Emit feedback (with cooldown)
    _emitFeedback(feedback);

    // Detect rep completion
    _detectRep(pose, side);

    return feedback;
  }

  /// Check all angle rules for violations
  List<FormViolation> _checkAngleRules(PoseSnapshot pose, String side) {
    final violations = <FormViolation>[];

    for (final rule in _exerciseRules.angleRules) {
      // Skip if rule doesn't apply to current phase
      if (rule.phase != ExercisePhase.all && rule.phase != _currentPhase) {
        continue;
      }

      // Replace LEFT/RIGHT with preferred side
      final joints = rule.joints.map((j) => j.replaceAll('LEFT', side)).toList();

      // Get landmarks
      final point1 = pose.getLandmark(joints[0]);
      final vertex = pose.getLandmark(joints[1]);
      final point2 = pose.getLandmark(joints[2]);

      if (point1 == null || vertex == null || point2 == null) {
        continue; // Skip if landmarks not detected
      }

      // Check confidence
      if (point1.confidence < AppConstants.minPoseConfidence ||
          vertex.confidence < AppConstants.minPoseConfidence ||
          point2.confidence < AppConstants.minPoseConfidence) {
        continue;
      }

      // Calculate angle
      final angle = AngleCalculator.calculateAngle(point1, vertex, point2);

      // Check if angle is within acceptable range
      if (!rule.isAngleValid(angle)) {
        violations.add(FormViolation(
          type: rule.violationType,
          description: rule.message,
          correction: rule.message,
          severity: rule.severity,
          affectedJoint: joints[1],
          timestamp: DateTime.now(),
        ));
      }
    }

    return violations;
  }

  /// Check all alignment rules for violations
  List<FormViolation> _checkAlignmentRules(PoseSnapshot pose, String side) {
    final violations = <FormViolation>[];

    for (final rule in _exerciseRules.alignmentRules) {
      // Replace LEFT/RIGHT with preferred side
      final points = rule.points.map((p) => p.replaceAll('LEFT', side)).toList();

      // Get landmarks
      final landmarks = points
          .map((name) => pose.getLandmark(name))
          .whereType<PoseLandmark>()
          .toList();

      if (landmarks.length < points.length) {
        continue; // Skip if any landmark missing
      }

      // Check confidence
      if (landmarks.any((l) => l.confidence < AppConstants.minPoseConfidence)) {
        continue;
      }

      // Check alignment based on type
      bool isViolated = false;

      switch (rule.alignmentType) {
        case AlignmentType.vertical:
          final horizontalDist = AngleCalculator.calculateHorizontalDistance(
            landmarks[0],
            landmarks[1],
          );
          isViolated = horizontalDist > rule.maxDeviationNormalized;
          break;

        case AlignmentType.horizontal:
          final verticalDist = AngleCalculator.calculateVerticalDistance(
            landmarks[0],
            landmarks[1],
          );
          isViolated = verticalDist > rule.maxDeviationNormalized;
          break;

        case AlignmentType.straight:
          // Check if points form a straight line (collinear)
          if (landmarks.length >= 3) {
            isViolated = !AngleCalculator.areCollinear(
              landmarks[0],
              landmarks[1],
              landmarks[2],
              threshold: rule.maxDeviationNormalized * 100,
            );
          }
          break;

        case AlignmentType.parallel:
          // Not implemented yet
          break;
      }

      if (isViolated) {
        violations.add(FormViolation(
          type: rule.violationType,
          description: rule.message,
          correction: rule.message,
          severity: rule.severity,
          affectedJoint: points.isNotEmpty ? points[0] : null,
          timestamp: DateTime.now(),
        ));
      }
    }

    // Additional checks: knee cave detection
    if (AngleCalculator.isKneeCaving(pose, side)) {
      violations.add(FormViolation(
        type: ViolationType.kneeCave,
        description: 'Knees caving inward',
        correction: 'Push knees outward, engage glutes',
        severity: Severity.critical,
        affectedJoint: '${side}_KNEE',
        timestamp: DateTime.now(),
      ));
    }

    return violations;
  }

  /// Calculate overall form score (0-100)
  FormScore _calculateFormScore(List<FormViolation> violations, PoseSnapshot pose) {
    double score = 100.0;

    // Deduct points for violations
    for (final violation in violations) {
      switch (violation.severity) {
        case Severity.critical:
          score -= 20.0;
          break;
        case Severity.warning:
          score -= 10.0;
          break;
        case Severity.info:
          score -= 5.0;
          break;
      }
    }

    // Bonus for high confidence
    if (pose.overallConfidence > 0.8) {
      score += 5.0;
    }

    // Clamp to 0-100
    score = score.clamp(0.0, 100.0);

    return FormScore.fromPercentage(score);
  }

  /// Generate user-friendly text instructions
  List<String> _generateInstructions(List<FormViolation> violations) {
    if (violations.isEmpty) {
      return ['Excellent form! Keep it up!'];
    }

    // Prioritize critical violations
    final critical = violations.where((v) => v.severity == Severity.critical);
    final warnings = violations.where((v) => v.severity == Severity.warning);

    final instructions = <String>[];

    // Add critical violations first
    for (final violation in critical) {
      instructions.add('⚠️ ${violation.correction}');
      if (instructions.length >= 3) break;
    }

    // Add warnings if space
    if (instructions.length < 3) {
      for (final violation in warnings) {
        instructions.add('• ${violation.correction}');
        if (instructions.length >= 3) break;
      }
    }

    return instructions;
  }

  /// Generate audio message (single most important message)
  String? _generateAudioMessage(List<FormViolation> violations) {
    if (violations.isEmpty) {
      return null; // Don't spam with positive feedback
    }

    // Find most severe violation
    final mostSevere = violations.reduce((a, b) {
      final severityOrder = {
        Severity.critical: 3,
        Severity.warning: 2,
        Severity.info: 1,
      };
      return (severityOrder[a.severity] ?? 0) > (severityOrder[b.severity] ?? 0)
          ? a
          : b;
    });

    return mostSevere.correction;
  }

  /// Emit feedback to stream (with cooldown)
  void _emitFeedback(FormFeedback feedback) {
    final now = DateTime.now();

    // Check cooldown for audio messages
    if (_lastFeedbackTime != null) {
      final elapsed = now.difference(_lastFeedbackTime!).inMilliseconds;
      if (elapsed < feedbackCooldownMs) {
        // Still in cooldown - emit feedback without audio
        final silentFeedback = FormFeedback(
          score: feedback.score,
          violations: feedback.violations,
          textInstructions: feedback.textInstructions,
          audioMessage: null, // Mute audio
          timestamp: feedback.timestamp,
        );
        _feedbackController.add(silentFeedback);
        return;
      }
    }

    _lastFeedbackTime = now;
    _feedbackController.add(feedback);
  }

  /// Update current exercise phase (eccentric, concentric, top, bottom)
  void _updatePhase(PoseSnapshot pose, String side) {
    final rule = _exerciseRules.repDetection;
    final keyJoint = pose.getLandmark(rule.keyJoint.replaceAll('LEFT', side));

    if (keyJoint == null || keyJoint.confidence < AppConstants.minPoseConfidence) {
      return;
    }

    // Get position based on axis
    double currentPosition;
    switch (rule.axis) {
      case MovementAxis.x:
        currentPosition = keyJoint.x;
        break;
      case MovementAxis.y:
        currentPosition = keyJoint.y;
        break;
      case MovementAxis.z:
        currentPosition = keyJoint.z;
        break;
    }

    // Initialize if first frame
    if (_startingPosition == null) {
      _startingPosition = currentPosition;
      _topPosition = currentPosition;
      _bottomPosition = currentPosition;
      return;
    }

    // Update min/max positions
    if (currentPosition < _bottomPosition!) {
      _bottomPosition = currentPosition;
    }
    if (currentPosition > _topPosition!) {
      _topPosition = currentPosition;
    }

    // Determine phase based on movement direction
    final distanceFromTop = (currentPosition - _topPosition!).abs();
    final distanceFromBottom = (currentPosition - _bottomPosition!).abs();

    if (distanceFromBottom < rule.threshold / 2) {
      if (_currentPhase != ExercisePhase.bottom) {
        _currentPhase = ExercisePhase.bottom;
        _phaseStartTime = DateTime.now();
      }
    } else if (distanceFromTop < rule.threshold / 2) {
      if (_currentPhase != ExercisePhase.top) {
        _currentPhase = ExercisePhase.top;
        _phaseStartTime = DateTime.now();
      }
    } else if (currentPosition < _startingPosition!) {
      _currentPhase = ExercisePhase.eccentric; // Lowering
    } else {
      _currentPhase = ExercisePhase.concentric; // Lifting
    }
  }

  /// Detect rep completion
  void _detectRep(PoseSnapshot pose, String side) {
    final rule = _exerciseRules.repDetection;
    final keyJoint = pose.getLandmark(rule.keyJoint.replaceAll('LEFT', side));

    if (keyJoint == null || keyJoint.confidence < AppConstants.minPoseConfidence) {
      return;
    }

    // Check if we're at top position and held for required time
    if (_currentPhase == ExercisePhase.top && _phaseStartTime != null) {
      final holdTime = DateTime.now().difference(_phaseStartTime!).inMilliseconds;

      if (holdTime >= rule.holdTimeMs) {
        // Check if we completed a full range of motion
        final rangeOfMotion = (_topPosition! - _bottomPosition!).abs();

        if (rangeOfMotion >= rule.threshold) {
          // Rep completed!
          _repCount++;

          // Create rep analysis
          final repAnalysis = _createRepAnalysis(pose);
          _repHistory.add(repAnalysis);

          // Emit rep event
          _repController.add(RepEvent(
            type: RepEventType.completed,
            timestamp: DateTime.now(),
            pose: pose,
          ));

          // Reset for next rep
          _startingPosition = keyJoint.y;
          _bottomPosition = keyJoint.y;
          _topPosition = keyJoint.y;
        }
      }
    }
  }

  /// Create analysis for completed rep
  RepAnalysis _createRepAnalysis(PoseSnapshot pose) {
    // Calculate average form score for this rep
    final recentFeedback = _feedbackHistory.take(10).toList();
    double avgScore = 0.0;
    if (recentFeedback.isNotEmpty) {
      avgScore = recentFeedback
          .map((f) => f.score.percentage)
          .reduce((a, b) => a + b) / recentFeedback.length;
    }

    // Collect violations from this rep
    final violations = <FormViolation>[];
    for (final feedback in recentFeedback) {
      violations.addAll(feedback.violations);
    }

    // Deduplicate violations
    final uniqueViolations = <String, FormViolation>{};
    for (final violation in violations) {
      uniqueViolations[violation.type] = violation;
    }

    return RepAnalysis(
      repNumber: _repCount,
      formScore: avgScore,
      duration: const Duration(seconds: 3), // Placeholder
      violations: uniqueViolations.values.toList(),
      bottomPosition: pose,
      topPosition: pose,
      timestamp: DateTime.now(),
    );
  }

  /// Add pose to history
  void _addPoseToHistory(PoseSnapshot pose) {
    _poseHistory.add(pose);
    if (_poseHistory.length > _maxHistorySize) {
      _poseHistory.removeAt(0);
    }
  }

  /// Add feedback to history
  void _addFeedbackToHistory(FormFeedback feedback) {
    _feedbackHistory.add(feedback);
    if (_feedbackHistory.length > _maxHistorySize) {
      _feedbackHistory.removeAt(0);
    }
  }

  /// Get rep history
  List<RepAnalysis> getRepHistory() => List.unmodifiable(_repHistory);

  /// Get feedback history
  List<FormFeedback> getFeedbackHistory() => List.unmodifiable(_feedbackHistory);

  /// Get average form score across all reps
  double getAverageFormScore() {
    if (_repHistory.isEmpty) return 0.0;

    final total = _repHistory
        .map((r) => r.formScore)
        .reduce((a, b) => a + b);

    return total / _repHistory.length;
  }

  /// Get most common violations
  Map<String, int> getViolationFrequency() {
    final frequency = <String, int>{};

    for (final rep in _repHistory) {
      for (final violation in rep.violations) {
        frequency[violation.type] = (frequency[violation.type] ?? 0) + 1;
      }
    }

    return frequency;
  }

  /// Reset session (start new workout)
  void resetSession() {
    _repCount = 0;
    _currentPhase = ExercisePhase.top;
    _phaseStartTime = null;
    _startingPosition = null;
    _bottomPosition = null;
    _topPosition = null;
    _feedbackHistory.clear();
    _repHistory.clear();
    _poseHistory.clear();
    _lastFeedbackTime = null;
  }

  /// Dispose resources
  void dispose() {
    _feedbackController.close();
    _repController.close();
  }
}
