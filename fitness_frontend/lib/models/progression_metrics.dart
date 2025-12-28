/// Progression metrics for an exercise over time
class ProgressionMetrics {
  final String exerciseName;
  final DateTime startDate;
  final DateTime endDate;

  // Volume metrics
  final double totalVolume;
  final double averageVolume;
  final double volumeChange; // Percentage change
  final List<VolumeDataPoint> volumeHistory;

  // Weight metrics
  final double currentMaxWeight;
  final double previousMaxWeight;
  final double weightChange; // Percentage change
  final List<WeightDataPoint> weightHistory;

  // Reps metrics
  final int currentMaxReps; // Max reps at current weight
  final int previousMaxReps;
  final int repsChange;

  // Personal Records
  final PersonalRecord? volumePR; // Highest volume in single workout
  final PersonalRecord? weightPR; // Heaviest weight lifted
  final PersonalRecord? repsPR; // Most reps at a given weight

  // Form tracking
  final double? averageFormScore;
  final double? formImprovement; // Percentage change in form score

  // Frequency
  final int totalSessions;
  final double sessionsPerWeek;

  // Progression trend
  final ProgressionTrend trend;

  // Recommended next workout
  final WorkoutRecommendation? recommendation;

  const ProgressionMetrics({
    required this.exerciseName,
    required this.startDate,
    required this.endDate,
    required this.totalVolume,
    required this.averageVolume,
    required this.volumeChange,
    required this.volumeHistory,
    required this.currentMaxWeight,
    required this.previousMaxWeight,
    required this.weightChange,
    required this.weightHistory,
    required this.currentMaxReps,
    required this.previousMaxReps,
    required this.repsChange,
    this.volumePR,
    this.weightPR,
    this.repsPR,
    this.averageFormScore,
    this.formImprovement,
    required this.totalSessions,
    required this.sessionsPerWeek,
    required this.trend,
    this.recommendation,
  });

  /// Check if progression is positive
  bool get isProgressing =>
      trend == ProgressionTrend.increasing ||
      trend == ProgressionTrend.stable;

  /// Get summary text
  String get summary {
    if (volumeChange > 10) {
      return 'Excellent progress! Volume up ${volumeChange.toStringAsFixed(1)}%';
    } else if (volumeChange > 0) {
      return 'Good progress! Volume up ${volumeChange.toStringAsFixed(1)}%';
    } else if (volumeChange > -5) {
      return 'Maintaining current level';
    } else {
      return 'Volume down ${volumeChange.abs().toStringAsFixed(1)}%';
    }
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'exercise_name': exerciseName,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_volume': totalVolume,
        'average_volume': averageVolume,
        'volume_change': volumeChange,
        'volume_history': volumeHistory.map((v) => v.toJson()).toList(),
        'current_max_weight': currentMaxWeight,
        'previous_max_weight': previousMaxWeight,
        'weight_change': weightChange,
        'weight_history': weightHistory.map((w) => w.toJson()).toList(),
        'current_max_reps': currentMaxReps,
        'previous_max_reps': previousMaxReps,
        'reps_change': repsChange,
        'volume_pr': volumePR?.toJson(),
        'weight_pr': weightPR?.toJson(),
        'reps_pr': repsPR?.toJson(),
        'average_form_score': averageFormScore,
        'form_improvement': formImprovement,
        'total_sessions': totalSessions,
        'sessions_per_week': sessionsPerWeek,
        'trend': trend.toString(),
        'recommendation': recommendation?.toJson(),
      };
}

/// Data point for volume tracking
class VolumeDataPoint {
  final DateTime date;
  final double volume;

  const VolumeDataPoint({
    required this.date,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'volume': volume,
      };

  factory VolumeDataPoint.fromJson(Map<String, dynamic> json) =>
      VolumeDataPoint(
        date: DateTime.parse(json['date'] as String),
        volume: (json['volume'] as num).toDouble(),
      );
}

/// Data point for weight tracking
class WeightDataPoint {
  final DateTime date;
  final double weight;
  final int reps;

  const WeightDataPoint({
    required this.date,
    required this.weight,
    required this.reps,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weight': weight,
        'reps': reps,
      };

  factory WeightDataPoint.fromJson(Map<String, dynamic> json) =>
      WeightDataPoint(
        date: DateTime.parse(json['date'] as String),
        weight: (json['weight'] as num).toDouble(),
        reps: json['reps'] as int,
      );
}

/// Personal record
class PersonalRecord {
  final double value; // Weight, volume, or reps
  final DateTime achievedDate;
  final String? notes;

  const PersonalRecord({
    required this.value,
    required this.achievedDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'achieved_date': achievedDate.toIso8601String(),
        'notes': notes,
      };

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
        value: (json['value'] as num).toDouble(),
        achievedDate: DateTime.parse(json['achieved_date'] as String),
        notes: json['notes'] as String?,
      );
}

/// Workout recommendation for next session
class WorkoutRecommendation {
  final double recommendedWeight;
  final int recommendedSets;
  final int recommendedReps;
  final String rationale;

  const WorkoutRecommendation({
    required this.recommendedWeight,
    required this.recommendedSets,
    required this.recommendedReps,
    required this.rationale,
  });

  Map<String, dynamic> toJson() => {
        'recommended_weight': recommendedWeight,
        'recommended_sets': recommendedSets,
        'recommended_reps': recommendedReps,
        'rationale': rationale,
      };

  factory WorkoutRecommendation.fromJson(Map<String, dynamic> json) =>
      WorkoutRecommendation(
        recommendedWeight: (json['recommended_weight'] as num).toDouble(),
        recommendedSets: json['recommended_sets'] as int,
        recommendedReps: json['recommended_reps'] as int,
        rationale: json['rationale'] as String,
      );
}

/// Progression trend
enum ProgressionTrend {
  increasing, // Making consistent progress
  stable, // Maintaining current level
  decreasing, // Regressing
  inconsistent, // Variable performance
}
