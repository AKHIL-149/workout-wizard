import 'package:hive/hive.dart';

part 'deload_settings.g.dart';

/// User preferences for deload and recovery
@HiveType(typeId: 19)
class DeloadSettings {
  @HiveField(0)
  final bool autoDeloadEnabled;

  @HiveField(1)
  final int deloadFrequencyWeeks; // Deload every N weeks

  @HiveField(2)
  final DeloadIntensity defaultIntensity;

  @HiveField(3)
  final bool trackRecoveryMetrics;

  @HiveField(4)
  final bool showDeloadReminders;

  DeloadSettings({
    this.autoDeloadEnabled = true,
    this.deloadFrequencyWeeks = 4,
    this.defaultIntensity = DeloadIntensity.moderate,
    this.trackRecoveryMetrics = true,
    this.showDeloadReminders = true,
  });

  DeloadSettings copyWith({
    bool? autoDeloadEnabled,
    int? deloadFrequencyWeeks,
    DeloadIntensity? defaultIntensity,
    bool? trackRecoveryMetrics,
    bool? showDeloadReminders,
  }) {
    return DeloadSettings(
      autoDeloadEnabled: autoDeloadEnabled ?? this.autoDeloadEnabled,
      deloadFrequencyWeeks: deloadFrequencyWeeks ?? this.deloadFrequencyWeeks,
      defaultIntensity: defaultIntensity ?? this.defaultIntensity,
      trackRecoveryMetrics: trackRecoveryMetrics ?? this.trackRecoveryMetrics,
      showDeloadReminders: showDeloadReminders ?? this.showDeloadReminders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoDeloadEnabled': autoDeloadEnabled,
      'deloadFrequencyWeeks': deloadFrequencyWeeks,
      'defaultIntensity': defaultIntensity.toString(),
      'trackRecoveryMetrics': trackRecoveryMetrics,
      'showDeloadReminders': showDeloadReminders,
    };
  }

  factory DeloadSettings.fromJson(Map<String, dynamic> json) {
    return DeloadSettings(
      autoDeloadEnabled: json['autoDeloadEnabled'] as bool? ?? true,
      deloadFrequencyWeeks: json['deloadFrequencyWeeks'] as int? ?? 4,
      defaultIntensity: DeloadIntensity.values.firstWhere(
        (e) => e.toString() == json['defaultIntensity'],
        orElse: () => DeloadIntensity.moderate,
      ),
      trackRecoveryMetrics: json['trackRecoveryMetrics'] as bool? ?? true,
      showDeloadReminders: json['showDeloadReminders'] as bool? ?? true,
    );
  }
}

/// Deload intensity levels
@HiveType(typeId: 20)
enum DeloadIntensity {
  @HiveField(0)
  light, // 40-50% reduction

  @HiveField(1)
  moderate, // 30-40% reduction

  @HiveField(2)
  minimal, // 20-30% reduction
}

extension DeloadIntensityExtension on DeloadIntensity {
  String get displayName {
    switch (this) {
      case DeloadIntensity.light:
        return 'Light (40-50% reduction)';
      case DeloadIntensity.moderate:
        return 'Moderate (30-40% reduction)';
      case DeloadIntensity.minimal:
        return 'Minimal (20-30% reduction)';
    }
  }

  double get volumeReduction {
    switch (this) {
      case DeloadIntensity.light:
        return 0.45; // 45% reduction
      case DeloadIntensity.moderate:
        return 0.35; // 35% reduction
      case DeloadIntensity.minimal:
        return 0.25; // 25% reduction
    }
  }

  String get description {
    switch (this) {
      case DeloadIntensity.light:
        return 'Significant reduction for high fatigue or after intense blocks';
      case DeloadIntensity.moderate:
        return 'Standard deload for regular training cycles';
      case DeloadIntensity.minimal:
        return 'Light reduction for maintaining momentum';
    }
  }
}

/// Recovery metrics tracking
@HiveType(typeId: 21)
class RecoveryMetrics {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int sleepQuality; // 1-5

  @HiveField(3)
  final int energyLevel; // 1-5

  @HiveField(4)
  final int muscleSoreness; // 1-5

  @HiveField(5)
  final int stressLevel; // 1-5

  @HiveField(6)
  final String? notes;

  RecoveryMetrics({
    required this.id,
    required this.date,
    required this.sleepQuality,
    required this.energyLevel,
    required this.muscleSoreness,
    required this.stressLevel,
    this.notes,
  });

  /// Calculate overall recovery score (1-5)
  double get recoveryScore {
    // Weight different factors
    final score = (sleepQuality * 0.3) +
        (energyLevel * 0.3) +
        ((6 - muscleSoreness) * 0.2) + // Invert soreness
        ((6 - stressLevel) * 0.2); // Invert stress
    return score;
  }

  bool get needsDeload => recoveryScore < 2.5;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'sleepQuality': sleepQuality,
      'energyLevel': energyLevel,
      'muscleSoreness': muscleSoreness,
      'stressLevel': stressLevel,
      'notes': notes,
    };
  }

  factory RecoveryMetrics.fromJson(Map<String, dynamic> json) {
    return RecoveryMetrics(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      sleepQuality: json['sleepQuality'] as int,
      energyLevel: json['energyLevel'] as int,
      muscleSoreness: json['muscleSoreness'] as int,
      stressLevel: json['stressLevel'] as int,
      notes: json['notes'] as String?,
    );
  }
}
