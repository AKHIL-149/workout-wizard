import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deload_settings.dart';
import '../models/workout_program.dart';
import 'program_enrollment_service.dart';

/// Service for managing deload weeks and recovery
class DeloadService {
  static final DeloadService _instance = DeloadService._internal();
  factory DeloadService() => _instance;
  DeloadService._internal();

  static const String _boxName = 'recovery_metrics';
  static const String _settingsKey = 'deload_settings';
  bool _initialized = false;

  Box<RecoveryMetrics> get _getBox {
    if (!Hive.isBoxOpen(_boxName)) {
      throw Exception('DeloadService: Box not initialized');
    }
    return Hive.box<RecoveryMetrics>(_boxName);
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<RecoveryMetrics>(_boxName);
      }

      _initialized = true;
      debugPrint('DeloadService: Initialized successfully');
    } catch (e) {
      debugPrint('DeloadService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Get deload settings
  Future<DeloadSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString != null) {
      try {
        return DeloadSettings.fromJson(
          Map<String, dynamic>.from(
            Uri.splitQueryString(jsonString),
          ),
        );
      } catch (e) {
        debugPrint('DeloadService: Error loading settings: $e');
      }
    }

    return DeloadSettings();
  }

  /// Save deload settings
  Future<void> saveSettings(DeloadSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = settings.toJson();
      await prefs.setString(_settingsKey, json.toString());
      debugPrint('DeloadService: Settings saved');
    } catch (e) {
      debugPrint('DeloadService: Error saving settings: $e');
      rethrow;
    }
  }

  /// Save recovery metrics
  Future<void> saveRecoveryMetrics(RecoveryMetrics metrics) async {
    try {
      await _getBox.put(metrics.id, metrics);
      debugPrint('DeloadService: Recovery metrics saved');
    } catch (e) {
      debugPrint('DeloadService: Error saving metrics: $e');
      rethrow;
    }
  }

  /// Get recovery metrics for date
  RecoveryMetrics? getMetricsForDate(DateTime date) {
    try {
      final normalized = DateTime(date.year, date.month, date.day);
      final dateKey = normalized.toIso8601String().split('T')[0];

      return _getBox.values.firstWhere(
        (m) => m.date.toIso8601String().split('T')[0] == dateKey,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get recent recovery metrics
  List<RecoveryMetrics> getRecentMetrics({int days = 7}) {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      return _getBox.values
          .where((m) => m.date.isAfter(cutoffDate))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('DeloadService: Error getting recent metrics: $e');
      return [];
    }
  }

  /// Calculate average recovery score
  double getAverageRecoveryScore({int days = 7}) {
    final metrics = getRecentMetrics(days: days);

    if (metrics.isEmpty) return 3.0; // Neutral score

    final totalScore =
        metrics.fold<double>(0, (sum, m) => sum + m.recoveryScore);
    return totalScore / metrics.length;
  }

  /// Check if deload is needed
  bool shouldDeload(ProgramEnrollment enrollment, DeloadSettings settings) {
    if (!settings.autoDeloadEnabled) return false;

    // Check if it's time for scheduled deload
    final weeksSinceStart = enrollment.currentWeek;
    final isScheduledDeloadWeek =
        weeksSinceStart % settings.deloadFrequencyWeeks == 0;

    if (isScheduledDeloadWeek) return true;

    // Check recovery metrics if tracking enabled
    if (settings.trackRecoveryMetrics) {
      final avgRecovery = getAverageRecoveryScore(days: 7);
      if (avgRecovery < 2.5) return true; // Poor recovery
    }

    return false;
  }

  /// Get deload recommendation
  DeloadRecommendation? getDeloadRecommendation(
    ProgramEnrollment enrollment,
    DeloadSettings settings,
  ) {
    if (!shouldDeload(enrollment, settings)) return null;

    final avgRecovery = getAverageRecoveryScore(days: 7);
    final weeksSinceStart = enrollment.currentWeek;

    String reason;
    DeloadIntensity recommendedIntensity;

    if (weeksSinceStart % settings.deloadFrequencyWeeks == 0) {
      reason = 'Scheduled deload week (every ${settings.deloadFrequencyWeeks} weeks)';
      recommendedIntensity = settings.defaultIntensity;
    } else if (avgRecovery < 2.0) {
      reason = 'Poor recovery metrics (score: ${avgRecovery.toStringAsFixed(1)}/5)';
      recommendedIntensity = DeloadIntensity.light;
    } else if (avgRecovery < 2.5) {
      reason = 'Below-average recovery (score: ${avgRecovery.toStringAsFixed(1)}/5)';
      recommendedIntensity = DeloadIntensity.moderate;
    } else {
      reason = 'Scheduled maintenance deload';
      recommendedIntensity = settings.defaultIntensity;
    }

    return DeloadRecommendation(
      reason: reason,
      recommendedIntensity: recommendedIntensity,
      currentWeek: weeksSinceStart,
      recoveryScore: avgRecovery,
    );
  }

  /// Apply deload to exercises (reduce volume/intensity)
  Map<String, dynamic> applyDeloadToExercise({
    required int sets,
    required int reps,
    required double? weight,
    required DeloadIntensity intensity,
  }) {
    final reduction = intensity.volumeReduction;

    // Reduce sets (minimum 1)
    final deloadSets = (sets * (1 - reduction)).round().clamp(1, sets);

    // Keep reps the same or slightly reduce
    final deloadReps = (reps * 0.9).round().clamp(3, reps);

    // Reduce weight if specified
    final deloadWeight = weight != null ? weight * (1 - reduction * 0.5) : null;

    return {
      'sets': deloadSets,
      'reps': deloadReps,
      'weight': deloadWeight,
      'reduction': '${(reduction * 100).toStringAsFixed(0)}%',
    };
  }

  /// Export recovery metrics
  Map<String, dynamic> exportRecoveryMetrics() {
    try {
      final metrics = _getBox.values.toList();
      return {
        'metrics': metrics.map((m) => m.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'count': metrics.length,
      };
    } catch (e) {
      debugPrint('DeloadService: Error exporting: $e');
      return {
        'metrics': [],
        'exportDate': DateTime.now().toIso8601String(),
        'count': 0
      };
    }
  }

  /// Import recovery metrics
  Future<void> importRecoveryMetrics(
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      if (!merge) {
        await _getBox.clear();
      }

      final metricsList = data['metrics'] as List;
      for (final metricsJson in metricsList) {
        final metrics =
            RecoveryMetrics.fromJson(metricsJson as Map<String, dynamic>);

        if (merge) {
          final existing = _getBox.get(metrics.id);
          if (existing == null) {
            await _getBox.put(metrics.id, metrics);
          }
        } else {
          await _getBox.put(metrics.id, metrics);
        }
      }

      debugPrint('DeloadService: Imported ${metricsList.length} metrics');
    } catch (e) {
      debugPrint('DeloadService: Error importing: $e');
      rethrow;
    }
  }
}

/// Deload recommendation
class DeloadRecommendation {
  final String reason;
  final DeloadIntensity recommendedIntensity;
  final int currentWeek;
  final double recoveryScore;

  DeloadRecommendation({
    required this.reason,
    required this.recommendedIntensity,
    required this.currentWeek,
    required this.recoveryScore,
  });
}
