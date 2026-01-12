import 'package:hive/hive.dart';

part 'linear_periodization.g.dart';

/// Linear periodization program configuration
@HiveType(typeId: 43)
class LinearPeriodizationProgram extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<LinearPhase> phases;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final DateTime? endDate;

  @HiveField(6)
  final int currentWeek;

  @HiveField(7)
  final String currentPhaseId;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final Map<String, double> baselineMaxes; // exercise -> 1RM

  @HiveField(10)
  final String progressionScheme; // 'weekly', 'biweekly', 'session'

  @HiveField(11)
  final double progressionRate; // % increase per progression

  @HiveField(12)
  final Map<String, dynamic> settings;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime? completedAt;

  LinearPeriodizationProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.phases,
    required this.startDate,
    this.endDate,
    this.currentWeek = 1,
    required this.currentPhaseId,
    this.isActive = false,
    Map<String, double>? baselineMaxes,
    this.progressionScheme = 'weekly',
    this.progressionRate = 0.025, // 2.5% default
    Map<String, dynamic>? settings,
    required this.createdAt,
    this.completedAt,
  })  : baselineMaxes = baselineMaxes ?? {},
        settings = settings ?? {};

  LinearPeriodizationProgram copyWith({
    String? id,
    String? name,
    String? description,
    List<LinearPhase>? phases,
    DateTime? startDate,
    DateTime? endDate,
    int? currentWeek,
    String? currentPhaseId,
    bool? isActive,
    Map<String, double>? baselineMaxes,
    String? progressionScheme,
    double? progressionRate,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return LinearPeriodizationProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      phases: phases ?? this.phases,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentPhaseId: currentPhaseId ?? this.currentPhaseId,
      isActive: isActive ?? this.isActive,
      baselineMaxes: baselineMaxes ?? this.baselineMaxes,
      progressionScheme: progressionScheme ?? this.progressionScheme,
      progressionRate: progressionRate ?? this.progressionRate,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  LinearPhase? get currentPhase {
    try {
      return phases.firstWhere((p) => p.id == currentPhaseId);
    } catch (e) {
      return null;
    }
  }

  double get overallProgress {
    if (totalWeeks == 0) return 0.0;
    return currentWeek / totalWeeks;
  }

  int get totalWeeks {
    return phases.fold(0, (sum, phase) => sum + phase.durationWeeks);
  }

  bool get isCompleted => completedAt != null;

  /// Calculate current training max for an exercise
  double getTrainingMax(String exercise) {
    final baseMax = baselineMaxes[exercise];
    if (baseMax == null) return 0.0;

    // Calculate weeks of progression
    int weeksProgressed = currentWeek - 1;

    // Apply progression rate based on scheme
    double totalIncrease = 0.0;
    if (progressionScheme == 'weekly') {
      totalIncrease = weeksProgressed * progressionRate;
    } else if (progressionScheme == 'biweekly') {
      totalIncrease = (weeksProgressed ~/ 2) * progressionRate;
    }

    return baseMax * (1 + totalIncrease);
  }
}

/// Linear progression phase
@HiveType(typeId: 44)
class LinearPhase extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phaseType; // 'hypertrophy', 'strength', 'power', 'peaking'

  @HiveField(3)
  final int durationWeeks;

  @HiveField(4)
  final double startingIntensity; // % of training max at start

  @HiveField(5)
  final double endingIntensity; // % of training max at end

  @HiveField(6)
  final int startingVolume; // total sets per week

  @HiveField(7)
  final int endingVolume; // total sets per week

  @HiveField(8)
  final int repsPerSet;

  @HiveField(9)
  final int sessionsPerWeek;

  @HiveField(10)
  final List<String> focusExercises;

  @HiveField(11)
  final Map<String, dynamic> progressionRules;

  @HiveField(12)
  final bool includeDeload;

  @HiveField(13)
  final DateTime? startDate;

  @HiveField(14)
  final DateTime? endDate;

  @HiveField(15)
  final String status; // 'pending', 'active', 'completed'

  LinearPhase({
    required this.id,
    required this.name,
    required this.phaseType,
    required this.durationWeeks,
    required this.startingIntensity,
    required this.endingIntensity,
    required this.startingVolume,
    required this.endingVolume,
    required this.repsPerSet,
    this.sessionsPerWeek = 3,
    List<String>? focusExercises,
    Map<String, dynamic>? progressionRules,
    this.includeDeload = true,
    this.startDate,
    this.endDate,
    this.status = 'pending',
  })  : focusExercises = focusExercises ?? [],
        progressionRules = progressionRules ?? {};

  LinearPhase copyWith({
    String? id,
    String? name,
    String? phaseType,
    int? durationWeeks,
    double? startingIntensity,
    double? endingIntensity,
    int? startingVolume,
    int? endingVolume,
    int? repsPerSet,
    int? sessionsPerWeek,
    List<String>? focusExercises,
    Map<String, dynamic>? progressionRules,
    bool? includeDeload,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return LinearPhase(
      id: id ?? this.id,
      name: name ?? this.name,
      phaseType: phaseType ?? this.phaseType,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      startingIntensity: startingIntensity ?? this.startingIntensity,
      endingIntensity: endingIntensity ?? this.endingIntensity,
      startingVolume: startingVolume ?? this.startingVolume,
      endingVolume: endingVolume ?? this.endingVolume,
      repsPerSet: repsPerSet ?? this.repsPerSet,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      focusExercises: focusExercises ?? this.focusExercises,
      progressionRules: progressionRules ?? this.progressionRules,
      includeDeload: includeDeload ?? this.includeDeload,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

  String get phaseTypeDisplay {
    switch (phaseType) {
      case 'hypertrophy':
        return 'Hypertrophy';
      case 'strength':
        return 'Strength';
      case 'power':
        return 'Power';
      case 'peaking':
        return 'Peaking';
      default:
        return phaseType;
    }
  }

  String get description {
    switch (phaseType) {
      case 'hypertrophy':
        return 'Build muscle with higher volume';
      case 'strength':
        return 'Increase maximal strength';
      case 'power':
        return 'Develop explosive power';
      case 'peaking':
        return 'Peak for competition or testing';
      default:
        return '';
    }
  }

  /// Calculate intensity for a specific week within this phase
  double getIntensityForWeek(int weekInPhase) {
    if (weekInPhase < 1 || weekInPhase > durationWeeks) {
      return startingIntensity;
    }

    final intensityRange = endingIntensity - startingIntensity;
    final increment = intensityRange / (durationWeeks - 1);
    return startingIntensity + (increment * (weekInPhase - 1));
  }

  /// Calculate volume for a specific week within this phase
  int getVolumeForWeek(int weekInPhase) {
    if (weekInPhase < 1 || weekInPhase > durationWeeks) {
      return startingVolume;
    }

    final volumeRange = endingVolume - startingVolume;
    final increment = volumeRange / (durationWeeks - 1);
    return (startingVolume + (increment * (weekInPhase - 1))).round();
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
}

/// Progression entry for tracking weekly progress
@HiveType(typeId: 45)
class LinearProgressionEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String programId;

  @HiveField(2)
  final String phaseId;

  @HiveField(3)
  final int weekNumber;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final Map<String, double> workingMaxes; // exercise -> calculated max

  @HiveField(6)
  final Map<String, double> actualPerformance; // exercise -> actual weight lifted

  @HiveField(7)
  final double plannedIntensity;

  @HiveField(8)
  final double actualIntensity;

  @HiveField(9)
  final int plannedVolume;

  @HiveField(10)
  final int actualVolume;

  @HiveField(11)
  final String? notes;

  @HiveField(12)
  final bool deloadWeek;

  LinearProgressionEntry({
    required this.id,
    required this.programId,
    required this.phaseId,
    required this.weekNumber,
    required this.timestamp,
    Map<String, double>? workingMaxes,
    Map<String, double>? actualPerformance,
    required this.plannedIntensity,
    required this.actualIntensity,
    required this.plannedVolume,
    required this.actualVolume,
    this.notes,
    this.deloadWeek = false,
  })  : workingMaxes = workingMaxes ?? {},
        actualPerformance = actualPerformance ?? {};

  LinearProgressionEntry copyWith({
    String? id,
    String? programId,
    String? phaseId,
    int? weekNumber,
    DateTime? timestamp,
    Map<String, double>? workingMaxes,
    Map<String, double>? actualPerformance,
    double? plannedIntensity,
    double? actualIntensity,
    int? plannedVolume,
    int? actualVolume,
    String? notes,
    bool? deloadWeek,
  }) {
    return LinearProgressionEntry(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      phaseId: phaseId ?? this.phaseId,
      weekNumber: weekNumber ?? this.weekNumber,
      timestamp: timestamp ?? this.timestamp,
      workingMaxes: workingMaxes ?? this.workingMaxes,
      actualPerformance: actualPerformance ?? this.actualPerformance,
      plannedIntensity: plannedIntensity ?? this.plannedIntensity,
      actualIntensity: actualIntensity ?? this.actualIntensity,
      plannedVolume: plannedVolume ?? this.plannedVolume,
      actualVolume: actualVolume ?? this.actualVolume,
      notes: notes ?? this.notes,
      deloadWeek: deloadWeek ?? this.deloadWeek,
    );
  }

  /// Calculate adherence score (0.0 - 1.0)
  double get adherenceScore {
    final intensityAdherence = actualIntensity / plannedIntensity;
    final volumeAdherence = actualVolume / plannedVolume;

    // Average adherence, clamped to realistic range
    final avgAdherence = (intensityAdherence + volumeAdherence) / 2;
    return avgAdherence.clamp(0.0, 1.2); // Allow up to 120% for overperformance
  }

  bool get isOnTrack => adherenceScore >= 0.85; // 85% adherence threshold
}

/// Helper class for linear periodization templates
class LinearPeriodizationTemplate {
  static LinearPeriodizationProgram createBeginnerTemplate({
    required String id,
    required String name,
    required Map<String, double> baselineMaxes,
  }) {
    final phases = [
      LinearPhase(
        id: '$id-phase1',
        name: 'Foundation Phase',
        phaseType: 'hypertrophy',
        durationWeeks: 4,
        startingIntensity: 0.65,
        endingIntensity: 0.75,
        startingVolume: 15,
        endingVolume: 18,
        repsPerSet: 10,
        sessionsPerWeek: 3,
      ),
      LinearPhase(
        id: '$id-phase2',
        name: 'Strength Building',
        phaseType: 'strength',
        durationWeeks: 4,
        startingIntensity: 0.75,
        endingIntensity: 0.85,
        startingVolume: 15,
        endingVolume: 12,
        repsPerSet: 6,
        sessionsPerWeek: 3,
      ),
      LinearPhase(
        id: '$id-phase3',
        name: 'Strength Peaking',
        phaseType: 'strength',
        durationWeeks: 4,
        startingIntensity: 0.85,
        endingIntensity: 0.92,
        startingVolume: 12,
        endingVolume: 9,
        repsPerSet: 4,
        sessionsPerWeek: 3,
      ),
    ];

    return LinearPeriodizationProgram(
      id: id,
      name: name,
      description: 'Beginner linear progression: 12-week strength program',
      phases: phases,
      startDate: DateTime.now(),
      currentPhaseId: phases.first.id,
      currentWeek: 1,
      baselineMaxes: baselineMaxes,
      progressionScheme: 'weekly',
      progressionRate: 0.025,
      createdAt: DateTime.now(),
    );
  }

  static LinearPeriodizationProgram createIntermediateTemplate({
    required String id,
    required String name,
    required Map<String, double> baselineMaxes,
  }) {
    final phases = [
      LinearPhase(
        id: '$id-phase1',
        name: 'Accumulation',
        phaseType: 'hypertrophy',
        durationWeeks: 3,
        startingIntensity: 0.70,
        endingIntensity: 0.78,
        startingVolume: 18,
        endingVolume: 20,
        repsPerSet: 8,
        sessionsPerWeek: 4,
      ),
      LinearPhase(
        id: '$id-phase2',
        name: 'Intensification',
        phaseType: 'strength',
        durationWeeks: 3,
        startingIntensity: 0.78,
        endingIntensity: 0.88,
        startingVolume: 16,
        endingVolume: 12,
        repsPerSet: 5,
        sessionsPerWeek: 4,
      ),
      LinearPhase(
        id: '$id-phase3',
        name: 'Realization',
        phaseType: 'power',
        durationWeeks: 2,
        startingIntensity: 0.88,
        endingIntensity: 0.95,
        startingVolume: 10,
        endingVolume: 8,
        repsPerSet: 3,
        sessionsPerWeek: 3,
      ),
    ];

    return LinearPeriodizationProgram(
      id: id,
      name: name,
      description: 'Intermediate linear progression: 8-week program',
      phases: phases,
      startDate: DateTime.now(),
      currentPhaseId: phases.first.id,
      currentWeek: 1,
      baselineMaxes: baselineMaxes,
      progressionScheme: 'weekly',
      progressionRate: 0.0175,
      createdAt: DateTime.now(),
    );
  }

  static LinearPeriodizationProgram createStrengthTemplate({
    required String id,
    required String name,
    required Map<String, double> baselineMaxes,
  }) {
    final phases = [
      LinearPhase(
        id: '$id-phase1',
        name: 'Base Strength',
        phaseType: 'strength',
        durationWeeks: 3,
        startingIntensity: 0.75,
        endingIntensity: 0.82,
        startingVolume: 15,
        endingVolume: 14,
        repsPerSet: 5,
        sessionsPerWeek: 4,
      ),
      LinearPhase(
        id: '$id-phase2',
        name: 'Peak Strength',
        phaseType: 'power',
        durationWeeks: 2,
        startingIntensity: 0.85,
        endingIntensity: 0.92,
        startingVolume: 12,
        endingVolume: 10,
        repsPerSet: 3,
        sessionsPerWeek: 4,
      ),
      LinearPhase(
        id: '$id-phase3',
        name: 'Competition Prep',
        phaseType: 'peaking',
        durationWeeks: 1,
        startingIntensity: 0.95,
        endingIntensity: 0.97,
        startingVolume: 8,
        endingVolume: 6,
        repsPerSet: 2,
        sessionsPerWeek: 3,
      ),
    ];

    return LinearPeriodizationProgram(
      id: id,
      name: name,
      description: 'Strength-focused: 6-week peaking program',
      phases: phases,
      startDate: DateTime.now(),
      currentPhaseId: phases.first.id,
      currentWeek: 1,
      baselineMaxes: baselineMaxes,
      progressionScheme: 'biweekly',
      progressionRate: 0.015,
      createdAt: DateTime.now(),
    );
  }
}
