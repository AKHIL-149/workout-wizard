import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'undulating_periodization.g.dart';

/// Undulating periodization program with daily or weekly variation
@HiveType(typeId: 46)
class UndulatingPeriodizationProgram extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<UndulatingCycle> cycles;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final DateTime? endDate;

  @HiveField(6)
  final int currentWeek;

  @HiveField(7)
  final int currentDayInCycle;

  @HiveField(8)
  final String currentCycleId;

  @HiveField(9)
  final bool isActive;

  @HiveField(10)
  final Map<String, double> baselineMaxes;

  @HiveField(11)
  final String undulationType; // 'daily', 'weekly'

  @HiveField(12)
  final double progressionRate; // % increase per cycle completion

  @HiveField(13)
  final Map<String, dynamic> settings;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime? completedAt;

  UndulatingPeriodizationProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.cycles,
    required this.startDate,
    this.endDate,
    this.currentWeek = 1,
    this.currentDayInCycle = 0,
    required this.currentCycleId,
    this.isActive = false,
    required this.baselineMaxes,
    this.undulationType = 'daily',
    this.progressionRate = 0.025, // 2.5% default
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    this.completedAt,
  })  : settings = settings ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// Get current cycle
  UndulatingCycle? get currentCycle {
    try {
      return cycles.firstWhere((c) => c.id == currentCycleId);
    } catch (e) {
      return cycles.isNotEmpty ? cycles.first : null;
    }
  }

  /// Get current workout day
  UndulatingWorkoutDay? get currentWorkoutDay {
    final cycle = currentCycle;
    if (cycle == null) return null;
    if (currentDayInCycle >= cycle.workoutDays.length) return null;
    return cycle.workoutDays[currentDayInCycle];
  }

  /// Calculate current training max for an exercise
  double getTrainingMax(String exercise) {
    final baseMax = baselineMaxes[exercise];
    if (baseMax == null) return 0.0;

    // Calculate number of completed cycles
    int completedCycles = 0;
    for (var cycle in cycles) {
      if (cycle.id == currentCycleId) break;
      if (cycle.status == 'completed') completedCycles++;
    }

    // Apply progression
    return baseMax * (1 + completedCycles * progressionRate);
  }

  /// Calculate overall progress
  double get overallProgress {
    if (cycles.isEmpty) return 0.0;

    int totalDays = 0;
    int completedDays = 0;

    for (var cycle in cycles) {
      totalDays += cycle.workoutDays.length * cycle.repeatCount;
      if (cycle.status == 'completed') {
        completedDays += cycle.workoutDays.length * cycle.repeatCount;
      } else if (cycle.id == currentCycleId) {
        completedDays += currentDayInCycle;
      }
    }

    return totalDays > 0 ? completedDays / totalDays : 0.0;
  }

  /// Total weeks in program
  int get totalWeeks {
    int totalDays = 0;
    for (var cycle in cycles) {
      totalDays += cycle.workoutDays.length * cycle.repeatCount;
    }
    // Assuming 3-4 workouts per week average
    return (totalDays / 3.5).ceil();
  }

  /// Check if program is completed
  bool get isCompleted => completedAt != null;

  UndulatingPeriodizationProgram copyWith({
    String? name,
    String? description,
    List<UndulatingCycle>? cycles,
    DateTime? startDate,
    DateTime? endDate,
    int? currentWeek,
    int? currentDayInCycle,
    String? currentCycleId,
    bool? isActive,
    Map<String, double>? baselineMaxes,
    String? undulationType,
    double? progressionRate,
    Map<String, dynamic>? settings,
    DateTime? completedAt,
  }) {
    return UndulatingPeriodizationProgram(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      cycles: cycles ?? this.cycles,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentDayInCycle: currentDayInCycle ?? this.currentDayInCycle,
      currentCycleId: currentCycleId ?? this.currentCycleId,
      isActive: isActive ?? this.isActive,
      baselineMaxes: baselineMaxes ?? this.baselineMaxes,
      undulationType: undulationType ?? this.undulationType,
      progressionRate: progressionRate ?? this.progressionRate,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Create beginner DUP template
  static UndulatingPeriodizationProgram createBeginnerTemplate({
    required String name,
    required Map<String, double> baselineMaxes,
  }) {
    const uuid = Uuid();
    final programId = uuid.v4();

    // Create 3-day DUP cycle: Heavy, Light, Moderate
    final cycle = UndulatingCycle(
      id: uuid.v4(),
      name: 'DUP Cycle',
      description: 'Daily undulating pattern',
      workoutDays: [
        UndulatingWorkoutDay(
          id: uuid.v4(),
          name: 'Heavy Day',
          dayType: 'heavy',
          intensityPercent: 0.85,
          repsMin: 3,
          repsMax: 5,
          setsPerExercise: 5,
          restSeconds: 180,
          focusExercises: baselineMaxes.keys.toList(),
        ),
        UndulatingWorkoutDay(
          id: uuid.v4(),
          name: 'Light Day',
          dayType: 'light',
          intensityPercent: 0.65,
          repsMin: 10,
          repsMax: 12,
          setsPerExercise: 3,
          restSeconds: 90,
          focusExercises: baselineMaxes.keys.toList(),
        ),
        UndulatingWorkoutDay(
          id: uuid.v4(),
          name: 'Moderate Day',
          dayType: 'moderate',
          intensityPercent: 0.75,
          repsMin: 6,
          repsMax: 8,
          setsPerExercise: 4,
          restSeconds: 120,
          focusExercises: baselineMaxes.keys.toList(),
        ),
      ],
      repeatCount: 12, // 12 weeks
      status: 'pending',
    );

    return UndulatingPeriodizationProgram(
      id: programId,
      name: name,
      description: '12-week beginner DUP program with 3-day cycle',
      cycles: [cycle],
      startDate: DateTime.now(),
      currentCycleId: cycle.id,
      baselineMaxes: baselineMaxes,
      undulationType: 'daily',
      progressionRate: 0.025,
    );
  }

  /// Create advanced DUP template
  static UndulatingPeriodizationProgram createAdvancedTemplate({
    required String name,
    required Map<String, double> baselineMaxes,
  }) {
    const uuid = Uuid();
    final programId = uuid.v4();

    // Create 4-day DUP cycle with more variation
    final cycle = UndulatingCycle(
      id: uuid.v4(),
      name: 'Advanced DUP Cycle',
      description: '4-day undulating pattern',
      workoutDays: [
        UndulatingWorkoutDay(
          id: uuid.v4(),
          name: 'Max Strength',
          dayType: 'heavy',
          intensityPercent: 0.90,
          repsMin: 1,
          repsMax: 3,
          setsPerExercise: 6,
          restSeconds: 240,
          focusExercises: baselineMaxes.keys.toList(),
        ),
        UndulatingWorkoutDay(
          id: uuid.v4(),
          name: 'Hypertrophy',
          dayType: 'moderate',
          intensityPercent: 0.70,
          repsMin: 8,
          repsMax: 12,
          setsPerExercise: 4,
          restSeconds: 90,
          focusExercises: baselineMaxes.keys.toList(),
        ),
        UndulatingWorkoutDay(
          id: uuid.v4(),
          name: 'Power',
          dayType: 'heavy',
          intensityPercent: 0.80,
          repsMin: 3,
          repsMax: 5,
          setsPerExercise: 5,
          restSeconds: 180,
          focusExercises: baselineMaxes.keys.toList(),
        ),
        UndulatingWorkoutDay(
          id: uuid.v4(),
          name: 'Active Recovery',
          dayType: 'light',
          intensityPercent: 0.60,
          repsMin: 12,
          repsMax: 15,
          setsPerExercise: 3,
          restSeconds: 60,
          focusExercises: baselineMaxes.keys.toList(),
        ),
      ],
      repeatCount: 8, // 8 weeks
      status: 'pending',
    );

    return UndulatingPeriodizationProgram(
      id: programId,
      name: name,
      description: '8-week advanced DUP with 4-day cycle',
      cycles: [cycle],
      startDate: DateTime.now(),
      currentCycleId: cycle.id,
      baselineMaxes: baselineMaxes,
      undulationType: 'daily',
      progressionRate: 0.02,
    );
  }

  /// Create weekly undulating template
  static UndulatingPeriodizationProgram createWeeklyTemplate({
    required String name,
    required Map<String, double> baselineMaxes,
  }) {
    const uuid = Uuid();
    final programId = uuid.v4();

    // Create 3 weekly cycles with different focuses
    final cycles = [
      UndulatingCycle(
        id: uuid.v4(),
        name: 'Volume Week',
        description: 'High volume, moderate intensity',
        workoutDays: [
          UndulatingWorkoutDay(
            id: uuid.v4(),
            name: 'Session 1',
            dayType: 'moderate',
            intensityPercent: 0.70,
            repsMin: 8,
            repsMax: 10,
            setsPerExercise: 5,
            restSeconds: 120,
            focusExercises: baselineMaxes.keys.toList(),
          ),
          UndulatingWorkoutDay(
            id: uuid.v4(),
            name: 'Session 2',
            dayType: 'moderate',
            intensityPercent: 0.72,
            repsMin: 8,
            repsMax: 10,
            setsPerExercise: 5,
            restSeconds: 120,
            focusExercises: baselineMaxes.keys.toList(),
          ),
          UndulatingWorkoutDay(
            id: uuid.v4(),
            name: 'Session 3',
            dayType: 'moderate',
            intensityPercent: 0.75,
            repsMin: 6,
            repsMax: 8,
            setsPerExercise: 4,
            restSeconds: 120,
            focusExercises: baselineMaxes.keys.toList(),
          ),
        ],
        repeatCount: 2,
        status: 'pending',
      ),
      UndulatingCycle(
        id: uuid.v4(),
        name: 'Intensity Week',
        description: 'High intensity, lower volume',
        workoutDays: [
          UndulatingWorkoutDay(
            id: uuid.v4(),
            name: 'Session 1',
            dayType: 'heavy',
            intensityPercent: 0.85,
            repsMin: 3,
            repsMax: 5,
            setsPerExercise: 4,
            restSeconds: 180,
            focusExercises: baselineMaxes.keys.toList(),
          ),
          UndulatingWorkoutDay(
            id: uuid.v4(),
            name: 'Session 2',
            dayType: 'heavy',
            intensityPercent: 0.87,
            repsMin: 3,
            repsMax: 5,
            setsPerExercise: 4,
            restSeconds: 180,
            focusExercises: baselineMaxes.keys.toList(),
          ),
          UndulatingWorkoutDay(
            id: uuid.v4(),
            name: 'Session 3',
            dayType: 'heavy',
            intensityPercent: 0.90,
            repsMin: 1,
            repsMax: 3,
            setsPerExercise: 5,
            restSeconds: 240,
            focusExercises: baselineMaxes.keys.toList(),
          ),
        ],
        repeatCount: 2,
        status: 'pending',
      ),
      UndulatingCycle(
        id: uuid.v4(),
        name: 'Deload Week',
        description: 'Recovery and adaptation',
        workoutDays: [
          UndulatingWorkoutDay(
            id: uuid.v4(),
            name: 'Session 1',
            dayType: 'light',
            intensityPercent: 0.60,
            repsMin: 10,
            repsMax: 12,
            setsPerExercise: 3,
            restSeconds: 90,
            focusExercises: baselineMaxes.keys.toList(),
          ),
          UndulatingWorkoutDay(
            id: uuid.v4(),
            name: 'Session 2',
            dayType: 'light',
            intensityPercent: 0.65,
            repsMin: 8,
            repsMax: 10,
            setsPerExercise: 3,
            restSeconds: 90,
            focusExercises: baselineMaxes.keys.toList(),
          ),
        ],
        repeatCount: 1,
        status: 'pending',
      ),
    ];

    return UndulatingPeriodizationProgram(
      id: programId,
      name: name,
      description: '10-week weekly undulating program',
      cycles: cycles,
      startDate: DateTime.now(),
      currentCycleId: cycles.first.id,
      baselineMaxes: baselineMaxes,
      undulationType: 'weekly',
      progressionRate: 0.03,
    );
  }
}

/// Undulating cycle - a repeating pattern of workouts
@HiveType(typeId: 47)
class UndulatingCycle {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<UndulatingWorkoutDay> workoutDays;

  @HiveField(4)
  final int repeatCount; // How many times to repeat this cycle

  @HiveField(5)
  final String status; // 'pending', 'active', 'completed'

  @HiveField(6)
  final DateTime? startDate;

  @HiveField(7)
  final DateTime? endDate;

  UndulatingCycle({
    required this.id,
    required this.name,
    required this.description,
    required this.workoutDays,
    this.repeatCount = 1,
    this.status = 'pending',
    this.startDate,
    this.endDate,
  });

  UndulatingCycle copyWith({
    String? name,
    String? description,
    List<UndulatingWorkoutDay>? workoutDays,
    int? repeatCount,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return UndulatingCycle(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      workoutDays: workoutDays ?? this.workoutDays,
      repeatCount: repeatCount ?? this.repeatCount,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// Individual workout day configuration
@HiveType(typeId: 48)
class UndulatingWorkoutDay {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String dayType; // 'heavy', 'moderate', 'light'

  @HiveField(3)
  final double intensityPercent; // % of 1RM

  @HiveField(4)
  final int repsMin;

  @HiveField(5)
  final int repsMax;

  @HiveField(6)
  final int setsPerExercise;

  @HiveField(7)
  final int restSeconds;

  @HiveField(8)
  final List<String> focusExercises;

  @HiveField(9)
  final Map<String, dynamic> notes;

  UndulatingWorkoutDay({
    required this.id,
    required this.name,
    required this.dayType,
    required this.intensityPercent,
    required this.repsMin,
    required this.repsMax,
    required this.setsPerExercise,
    required this.restSeconds,
    required this.focusExercises,
    Map<String, dynamic>? notes,
  }) : notes = notes ?? {};

  UndulatingWorkoutDay copyWith({
    String? name,
    String? dayType,
    double? intensityPercent,
    int? repsMin,
    int? repsMax,
    int? setsPerExercise,
    int? restSeconds,
    List<String>? focusExercises,
    Map<String, dynamic>? notes,
  }) {
    return UndulatingWorkoutDay(
      id: id,
      name: name ?? this.name,
      dayType: dayType ?? this.dayType,
      intensityPercent: intensityPercent ?? this.intensityPercent,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      setsPerExercise: setsPerExercise ?? this.setsPerExercise,
      restSeconds: restSeconds ?? this.restSeconds,
      focusExercises: focusExercises ?? this.focusExercises,
      notes: notes ?? this.notes,
    );
  }
}

/// Progress tracking entry
@HiveType(typeId: 49)
class UndulatingProgressionEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String programId;

  @HiveField(2)
  final String cycleId;

  @HiveField(3)
  final String workoutDayId;

  @HiveField(4)
  final int weekNumber;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final Map<String, double> workingMaxes;

  @HiveField(7)
  final Map<String, double> actualPerformance; // exercise -> weight lifted

  @HiveField(8)
  final double plannedIntensity;

  @HiveField(9)
  final double actualIntensity;

  @HiveField(10)
  final int plannedVolume; // total reps

  @HiveField(11)
  final int actualVolume;

  @HiveField(12)
  final String? notes;

  UndulatingProgressionEntry({
    required this.id,
    required this.programId,
    required this.cycleId,
    required this.workoutDayId,
    required this.weekNumber,
    required this.timestamp,
    required this.workingMaxes,
    this.actualPerformance = const {},
    required this.plannedIntensity,
    this.actualIntensity = 0.0,
    required this.plannedVolume,
    this.actualVolume = 0,
    this.notes,
  });
}
