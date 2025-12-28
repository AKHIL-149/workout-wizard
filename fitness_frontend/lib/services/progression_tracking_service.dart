import '../models/workout_session.dart';
import '../models/exercise_performance.dart';
import '../models/exercise_set.dart';
import '../models/progression_metrics.dart';
import 'workout_session_service.dart';

/// Service for analyzing workout progression and providing recommendations
class ProgressionTrackingService {
  static final ProgressionTrackingService _instance =
      ProgressionTrackingService._internal();
  factory ProgressionTrackingService() => _instance;
  ProgressionTrackingService._internal();

  final WorkoutSessionService _sessionService = WorkoutSessionService();

  /// Get progression metrics for a specific exercise
  ProgressionMetrics? getProgressionMetrics(
    String exerciseName, {
    int? lastNSessions,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Get all sessions with this exercise
    var sessions = _sessionService.getWorkoutSessionsWithExercise(exerciseName);

    if (sessions.isEmpty) return null;

    // Filter by date range if specified
    if (startDate != null || endDate != null) {
      final start = startDate ?? DateTime(2000);
      final end = endDate ?? DateTime.now();
      sessions = sessions
          .where((s) =>
              s.startTime.isAfter(start) && s.startTime.isBefore(end))
          .toList();
    }

    // Limit to last N sessions if specified
    if (lastNSessions != null && sessions.length > lastNSessions) {
      sessions = sessions.take(lastNSessions).toList();
    }

    if (sessions.isEmpty) return null;

    // Sort oldest to newest for trend analysis
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Extract exercise performances
    final performances = sessions
        .expand((session) => session.exercises)
        .where((ex) => ex.exerciseName == exerciseName)
        .toList();

    if (performances.isEmpty) return null;

    // Calculate metrics
    final startDateActual = sessions.first.startTime;
    final endDateActual = sessions.last.startTime;

    // Volume metrics
    final volumeHistory = _calculateVolumeHistory(performances);
    final totalVolume = volumeHistory.fold(0.0, (sum, v) => sum + v.volume);
    final averageVolume = totalVolume / volumeHistory.length;
    final volumeChange = _calculateVolumeChange(volumeHistory);

    // Weight metrics
    final weightHistory = _calculateWeightHistory(performances);
    final currentMaxWeight = weightHistory.isNotEmpty
        ? weightHistory.last.weight
        : 0.0;
    final previousMaxWeight = weightHistory.length > 1
        ? weightHistory[weightHistory.length - 2].weight
        : currentMaxWeight;
    final weightChange = previousMaxWeight > 0
        ? ((currentMaxWeight - previousMaxWeight) / previousMaxWeight * 100)
        : 0.0;

    // Reps metrics
    final currentMaxReps = _getMaxRepsAtWeight(performances, currentMaxWeight);
    final previousMaxReps =
        _getMaxRepsAtWeight(performances, previousMaxWeight);
    final repsChange = currentMaxReps - previousMaxReps;

    // Personal records
    final volumePR = _findVolumePR(performances);
    final weightPR = _findWeightPR(performances);
    final repsPR = _findRepsPR(performances);

    // Form tracking
    final averageFormScore = _calculateAverageFormScore(performances);
    final formImprovement = _calculateFormImprovement(performances);

    // Frequency
    final totalSessions = sessions.length;
    final daysDifference = endDateActual.difference(startDateActual).inDays + 1;
    final sessionsPerWeek = (totalSessions / daysDifference * 7);

    // Trend analysis
    final trend = _analyzeTrend(volumeHistory);

    // Recommendation
    final recommendation = _generateRecommendation(
      performances,
      currentMaxWeight,
      currentMaxReps,
      trend,
    );

    return ProgressionMetrics(
      exerciseName: exerciseName,
      startDate: startDateActual,
      endDate: endDateActual,
      totalVolume: totalVolume,
      averageVolume: averageVolume,
      volumeChange: volumeChange,
      volumeHistory: volumeHistory,
      currentMaxWeight: currentMaxWeight,
      previousMaxWeight: previousMaxWeight,
      weightChange: weightChange,
      weightHistory: weightHistory,
      currentMaxReps: currentMaxReps,
      previousMaxReps: previousMaxReps,
      repsChange: repsChange,
      volumePR: volumePR,
      weightPR: weightPR,
      repsPR: repsPR,
      averageFormScore: averageFormScore,
      formImprovement: formImprovement,
      totalSessions: totalSessions,
      sessionsPerWeek: sessionsPerWeek,
      trend: trend,
      recommendation: recommendation,
    );
  }

  /// Calculate volume history
  List<VolumeDataPoint> _calculateVolumeHistory(
      List<ExercisePerformance> performances) {
    return performances
        .map((p) => VolumeDataPoint(
              date: p.startTime,
              volume: p.totalVolume,
            ))
        .toList();
  }

  /// Calculate weight history (max weight per session)
  List<WeightDataPoint> _calculateWeightHistory(
      List<ExercisePerformance> performances) {
    return performances.map((p) {
      final maxWeightSet = p.sets
          .where((s) => !s.isWarmup)
          .reduce((a, b) => a.weight > b.weight ? a : b);
      return WeightDataPoint(
        date: p.startTime,
        weight: maxWeightSet.weight,
        reps: maxWeightSet.reps,
      );
    }).toList();
  }

  /// Calculate volume change (percentage)
  double _calculateVolumeChange(List<VolumeDataPoint> history) {
    if (history.length < 2) return 0.0;

    // Compare average of first half vs second half
    final midpoint = history.length ~/ 2;
    final firstHalf = history.sublist(0, midpoint);
    final secondHalf = history.sublist(midpoint);

    final firstAvg =
        firstHalf.fold(0.0, (sum, v) => sum + v.volume) / firstHalf.length;
    final secondAvg =
        secondHalf.fold(0.0, (sum, v) => sum + v.volume) / secondHalf.length;

    if (firstAvg == 0) return 0.0;
    return (secondAvg - firstAvg) / firstAvg * 100;
  }

  /// Get max reps achieved at a specific weight
  int _getMaxRepsAtWeight(
      List<ExercisePerformance> performances, double weight) {
    final setsAtWeight = performances
        .expand((p) => p.sets)
        .where((s) => !s.isWarmup && s.weight == weight)
        .toList();

    if (setsAtWeight.isEmpty) return 0;
    return setsAtWeight.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
  }

  /// Find volume personal record
  PersonalRecord? _findVolumePR(List<ExercisePerformance> performances) {
    if (performances.isEmpty) return null;

    final maxVolume = performances.reduce(
        (a, b) => a.totalVolume > b.totalVolume ? a : b);

    return PersonalRecord(
      value: maxVolume.totalVolume,
      achievedDate: maxVolume.startTime,
      notes: '${maxVolume.sets.length} sets',
    );
  }

  /// Find weight personal record
  PersonalRecord? _findWeightPR(List<ExercisePerformance> performances) {
    if (performances.isEmpty) return null;

    ExerciseSet? maxWeightSet;
    DateTime? achievedDate;

    for (final performance in performances) {
      for (final set in performance.sets.where((s) => !s.isWarmup)) {
        if (maxWeightSet == null || set.weight > maxWeightSet.weight) {
          maxWeightSet = set;
          achievedDate = performance.startTime;
        }
      }
    }

    if (maxWeightSet == null) return null;

    return PersonalRecord(
      value: maxWeightSet.weight,
      achievedDate: achievedDate!,
      notes: '${maxWeightSet.reps} reps',
    );
  }

  /// Find reps personal record (most reps at highest weight)
  PersonalRecord? _findRepsPR(List<ExercisePerformance> performances) {
    if (performances.isEmpty) return null;

    ExerciseSet? maxRepsSet;
    DateTime? achievedDate;

    for (final performance in performances) {
      for (final set in performance.sets.where((s) => !s.isWarmup)) {
        if (maxRepsSet == null || set.reps > maxRepsSet.reps) {
          maxRepsSet = set;
          achievedDate = performance.startTime;
        }
      }
    }

    if (maxRepsSet == null) return null;

    return PersonalRecord(
      value: maxRepsSet.reps.toDouble(),
      achievedDate: achievedDate!,
      notes: 'at ${maxRepsSet.weight} kg',
    );
  }

  /// Calculate average form score
  double? _calculateAverageFormScore(List<ExercisePerformance> performances) {
    final scores = performances
        .map((p) => p.averageFormScore)
        .where((s) => s != null)
        .cast<double>()
        .toList();

    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Calculate form improvement (percentage)
  double? _calculateFormImprovement(List<ExercisePerformance> performances) {
    final scoresWithDates = performances
        .where((p) => p.averageFormScore != null)
        .map((p) => MapEntry(p.startTime, p.averageFormScore!))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (scoresWithDates.length < 2) return null;

    final firstScore = scoresWithDates.first.value;
    final lastScore = scoresWithDates.last.value;

    return ((lastScore - firstScore) / firstScore * 100);
  }

  /// Analyze progression trend
  ProgressionTrend _analyzeTrend(List<VolumeDataPoint> history) {
    if (history.length < 3) return ProgressionTrend.inconsistent;

    // Calculate linear regression slope
    final n = history.length;
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumX2 = 0.0;

    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = history[i].volume;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    // Calculate coefficient of variation for consistency
    final mean = sumY / n;
    final variance = history.fold(
            0.0, (sum, v) => sum + (v.volume - mean) * (v.volume - mean)) /
        n;
    final cv = (variance.isNaN || mean == 0) ? 0.0 : (variance / mean);

    // Determine trend
    if (cv > 0.3) {
      return ProgressionTrend.inconsistent;
    } else if (slope > 0.05 * mean / n) {
      return ProgressionTrend.increasing;
    } else if (slope < -0.05 * mean / n) {
      return ProgressionTrend.decreasing;
    } else {
      return ProgressionTrend.stable;
    }
  }

  /// Generate workout recommendation
  WorkoutRecommendation? _generateRecommendation(
    List<ExercisePerformance> performances,
    double currentMaxWeight,
    int currentMaxReps,
    ProgressionTrend trend,
  ) {
    if (performances.isEmpty) return null;

    final lastPerformance = performances.last;
    final workingSets =
        lastPerformance.sets.where((s) => !s.isWarmup).toList();

    if (workingSets.isEmpty) return null;

    // Base recommendations on trend and recent performance
    double recommendedWeight;
    int recommendedSets;
    int recommendedReps;
    String rationale;

    if (trend == ProgressionTrend.increasing) {
      // Progressing well - increase weight
      if (currentMaxReps >= 12) {
        // High reps - increase weight, reduce reps
        recommendedWeight = currentMaxWeight * 1.05; // 5% increase
        recommendedReps = 8;
        rationale = 'Great progress! Time to increase weight.';
      } else if (currentMaxReps >= 8) {
        // Moderate reps - small weight increase
        recommendedWeight = currentMaxWeight * 1.025; // 2.5% increase
        recommendedReps = currentMaxReps;
        rationale = 'Steady progress. Small weight increase.';
      } else {
        // Low reps - maintain weight, increase reps
        recommendedWeight = currentMaxWeight;
        recommendedReps = currentMaxReps + 1;
        rationale = 'Focus on increasing reps before adding weight.';
      }
      recommendedSets = workingSets.length;
    } else if (trend == ProgressionTrend.stable) {
      // Maintaining - try to progress
      if (lastPerformance.allTargetsAchieved) {
        // Hitting targets - increase difficulty
        recommendedWeight = currentMaxWeight * 1.025;
        recommendedReps = currentMaxReps;
        rationale = 'Hitting all targets. Time to progress.';
      } else {
        // Not hitting targets - maintain
        recommendedWeight = currentMaxWeight;
        recommendedReps = currentMaxReps;
        rationale = 'Focus on hitting target reps consistently.';
      }
      recommendedSets = workingSets.length;
    } else if (trend == ProgressionTrend.decreasing) {
      // Regressing - reduce intensity
      recommendedWeight = currentMaxWeight * 0.95; // 5% decrease
      recommendedReps = currentMaxReps + 2;
      recommendedSets = workingSets.length;
      rationale = 'Deload recommended. Reduce weight, focus on form.';
    } else {
      // Inconsistent - maintain and focus on consistency
      recommendedWeight = currentMaxWeight;
      recommendedReps = currentMaxReps;
      recommendedSets = workingSets.length;
      rationale = 'Focus on consistency before progressing.';
    }

    // Round weight to nearest 2.5
    recommendedWeight = (recommendedWeight / 2.5).round() * 2.5;

    return WorkoutRecommendation(
      recommendedWeight: recommendedWeight,
      recommendedSets: recommendedSets,
      recommendedReps: recommendedReps,
      rationale: rationale,
    );
  }

  /// Get all exercises with progression data
  List<String> getAllTrackedExercises() {
    return _sessionService.getUniqueExerciseNames();
  }

  /// Compare current performance to previous workout for same exercise
  Map<String, dynamic>? compareWithPreviousWorkout(String exerciseName) {
    final sessions = _sessionService.getWorkoutSessionsWithExercise(exerciseName);
    if (sessions.length < 2) return null;

    final current = sessions[0];
    final previous = sessions[1];

    final currentEx = current.exercises
        .firstWhere((ex) => ex.exerciseName == exerciseName);
    final previousEx = previous.exercises
        .firstWhere((ex) => ex.exerciseName == exerciseName);

    final volumeChange = currentEx.totalVolume - previousEx.totalVolume;
    final volumeChangePercent =
        (volumeChange / previousEx.totalVolume * 100);

    return {
      'current_volume': currentEx.totalVolume,
      'previous_volume': previousEx.totalVolume,
      'volume_change': volumeChange,
      'volume_change_percent': volumeChangePercent,
      'current_max_weight': currentEx.maxWeight,
      'previous_max_weight': previousEx.maxWeight,
      'improved': volumeChange > 0,
    };
  }
}
