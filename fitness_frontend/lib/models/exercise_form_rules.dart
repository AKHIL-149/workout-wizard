import 'form_analysis.dart';
import 'pose_data.dart';

/// Rules that define correct form for a specific exercise
class ExerciseFormRules {
  final String id;
  final String name;
  final List<String> aliases; // Alternative names for matching
  final ExerciseType type;
  final String category; // Exercise category (squat, hinge, push, pull, etc.)
  final List<AngleRule> angleRules;
  final List<AlignmentRule> alignmentRules;
  final RepDetectionRule repDetection;
  final String? description;

  const ExerciseFormRules({
    required this.id,
    required this.name,
    required this.aliases,
    required this.type,
    required this.category,
    required this.angleRules,
    required this.alignmentRules,
    required this.repDetection,
    this.description,
  });

  factory ExerciseFormRules.fromJson(Map<String, dynamic> json) {
    return ExerciseFormRules(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: List<String>.from(json['aliases'] as List),
      type: ExerciseType.values.firstWhere(
        (e) => e.toString() == 'ExerciseType.${json['type']}',
        orElse: () => ExerciseType.other,
      ),
      category: json['category'] as String? ?? 'other',
      angleRules: (json['angleRules'] as List)
          .map((r) => AngleRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      alignmentRules: (json['alignmentRules'] as List)
          .map((r) => AlignmentRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      repDetection: RepDetectionRule.fromJson(
        json['repDetection'] as Map<String, dynamic>,
      ),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'aliases': aliases,
        'type': type.toString().split('.').last,
        'category': category,
        'angleRules': angleRules.map((r) => r.toJson()).toList(),
        'alignmentRules': alignmentRules.map((r) => r.toJson()).toList(),
        'repDetection': repDetection.toJson(),
        'description': description,
      };

  /// Check if this exercise matches a given name
  bool matchesName(String searchName) {
    final lowerSearch = searchName.toLowerCase();
    final lowerName = name.toLowerCase();

    if (lowerName.contains(lowerSearch) || lowerSearch.contains(lowerName)) {
      return true;
    }

    for (final alias in aliases) {
      if (alias.toLowerCase().contains(lowerSearch) ||
          lowerSearch.contains(alias.toLowerCase())) {
        return true;
      }
    }

    return false;
  }
}

/// Rule for checking joint angles
class AngleRule {
  final String name; // e.g., "knee_angle_bottom"
  final List<String> joints; // [point1, vertex, point2]
  final double minDegrees;
  final double maxDegrees;
  final ExercisePhase phase; // When to check this rule
  final String violationType; // Type of violation if rule fails
  final String message; // User-friendly message
  final Severity severity;

  const AngleRule({
    required this.name,
    required this.joints,
    required this.minDegrees,
    required this.maxDegrees,
    required this.phase,
    required this.violationType,
    required this.message,
    required this.severity,
  });

  factory AngleRule.fromJson(Map<String, dynamic> json) {
    return AngleRule(
      name: json['name'] as String,
      joints: List<String>.from(json['joints'] as List),
      minDegrees: (json['minDegrees'] as num).toDouble(),
      maxDegrees: (json['maxDegrees'] as num).toDouble(),
      phase: ExercisePhase.values.firstWhere(
        (e) => e.toString() == 'ExercisePhase.${json['phase']}',
        orElse: () => ExercisePhase.all,
      ),
      violationType: json['violationType'] as String,
      message: json['message'] as String,
      severity: Severity.values.firstWhere(
        (e) => e.toString() == 'Severity.${json['severity']}',
        orElse: () => Severity.warning,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'joints': joints,
        'minDegrees': minDegrees,
        'maxDegrees': maxDegrees,
        'phase': phase.toString().split('.').last,
        'violationType': violationType,
        'message': message,
        'severity': severity.toString().split('.').last,
      };

  /// Check if angle is within acceptable range
  bool isAngleValid(double angle) {
    return angle >= minDegrees && angle <= maxDegrees;
  }

  /// Get affected joint (the vertex in the angle calculation)
  String get affectedJoint => joints.length >= 2 ? joints[1] : '';
}

/// Rule for checking body part alignment
class AlignmentRule {
  final String name; // e.g., "knee_over_toes"
  final List<String> points; // Points that should align
  final AlignmentType alignmentType;
  final double maxDeviationNormalized; // Max deviation in normalized coordinates
  final String violationType;
  final String message;
  final Severity severity;

  const AlignmentRule({
    required this.name,
    required this.points,
    required this.alignmentType,
    required this.maxDeviationNormalized,
    required this.violationType,
    required this.message,
    required this.severity,
  });

  factory AlignmentRule.fromJson(Map<String, dynamic> json) {
    return AlignmentRule(
      name: json['name'] as String,
      points: List<String>.from(json['points'] as List),
      alignmentType: AlignmentType.values.firstWhere(
        (e) => e.toString() == 'AlignmentType.${json['alignmentType']}',
        orElse: () => AlignmentType.vertical,
      ),
      maxDeviationNormalized: (json['maxDeviationNormalized'] as num).toDouble(),
      violationType: json['violationType'] as String,
      message: json['message'] as String,
      severity: Severity.values.firstWhere(
        (e) => e.toString() == 'Severity.${json['severity']}',
        orElse: () => Severity.warning,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'points': points,
        'alignmentType': alignmentType.toString().split('.').last,
        'maxDeviationNormalized': maxDeviationNormalized,
        'violationType': violationType,
        'message': message,
        'severity': severity.toString().split('.').last,
      };
}

/// Rule for detecting rep completion
class RepDetectionRule {
  final String keyJoint; // Joint to track for rep counting
  final MovementAxis axis; // X, Y, or Z axis
  final double threshold; // Minimum movement threshold (normalized)
  final MovementDirection direction; // Up-down, left-right, etc.
  final int holdTimeMs; // Time to hold position before counting

  const RepDetectionRule({
    required this.keyJoint,
    required this.axis,
    required this.threshold,
    required this.direction,
    required this.holdTimeMs,
  });

  factory RepDetectionRule.fromJson(Map<String, dynamic> json) {
    return RepDetectionRule(
      keyJoint: json['keyJoint'] as String,
      axis: MovementAxis.values.firstWhere(
        (e) => e.toString() == 'MovementAxis.${json['axis']}',
        orElse: () => MovementAxis.y,
      ),
      threshold: (json['threshold'] as num).toDouble(),
      direction: MovementDirection.values.firstWhere(
        (e) => e.toString() == 'MovementDirection.${json['direction']}',
        orElse: () => MovementDirection.downThenUp,
      ),
      holdTimeMs: json['holdTimeMs'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'keyJoint': keyJoint,
        'axis': axis.toString().split('.').last,
        'threshold': threshold,
        'direction': direction.toString().split('.').last,
        'holdTimeMs': holdTimeMs,
      };
}

/// Type of exercise (for categorization)
enum ExerciseType {
  squat,
  deadlift,
  benchPress,
  overheadPress,
  row,
  lunge,
  pullUp,
  pushUp,
  plank,
  bicepCurl,
  other,
}

/// Type of alignment check
enum AlignmentType {
  vertical, // Points should be vertically aligned
  horizontal, // Points should be horizontally aligned
  straight, // Points should form a straight line
  parallel, // Lines should be parallel
}

/// Movement axis for rep detection
enum MovementAxis {
  x, // Horizontal (left-right)
  y, // Vertical (up-down)
  z, // Depth (forward-backward)
}

/// Movement direction for rep detection
enum MovementDirection {
  downThenUp, // Squat, pushup
  upThenDown, // Pull-up, deadlift
  leftThenRight, // Side lunge
  rightThenLeft,
  forwardThenBack, // Forward lunge
  backThenForward,
}

/// Database of all exercise form rules
class ExerciseFormRulesDatabase {
  final List<ExerciseFormRules> exercises;
  final Map<String, ViolationDefinition> violations;

  const ExerciseFormRulesDatabase({
    required this.exercises,
    required this.violations,
  });

  factory ExerciseFormRulesDatabase.fromJson(Map<String, dynamic> json) {
    return ExerciseFormRulesDatabase(
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseFormRules.fromJson(e as Map<String, dynamic>))
          .toList(),
      violations: (json['violations'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          ViolationDefinition.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'violations': violations.map((key, value) => MapEntry(key, value.toJson())),
      };

  /// Find exercise rules by name (with fuzzy matching)
  ExerciseFormRules? findExercise(String name) {
    for (final exercise in exercises) {
      if (exercise.matchesName(name)) {
        return exercise;
      }
    }
    return null;
  }

  /// Get violation definition
  ViolationDefinition? getViolationDefinition(String violationType) {
    return violations[violationType];
  }
}

/// Definition of a violation type
class ViolationDefinition {
  final String description;
  final String correction;
  final Severity severity;

  const ViolationDefinition({
    required this.description,
    required this.correction,
    required this.severity,
  });

  factory ViolationDefinition.fromJson(Map<String, dynamic> json) {
    return ViolationDefinition(
      description: json['description'] as String,
      correction: json['correction'] as String,
      severity: Severity.values.firstWhere(
        (e) => e.toString() == 'Severity.${json['severity']}',
        orElse: () => Severity.warning,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'correction': correction,
        'severity': severity.toString().split('.').last,
      };
}
