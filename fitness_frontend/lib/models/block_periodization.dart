import 'package:hive/hive.dart';

part 'block_periodization.g.dart';

/// Block periodization program configuration
@HiveType(typeId: 40)
class BlockPeriodizationProgram extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<TrainingBlock> blocks;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  final DateTime? endDate;

  @HiveField(6)
  final String currentBlockId;

  @HiveField(7)
  final int currentBlockIndex;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final bool autoProgress;

  @HiveField(10)
  final Map<String, dynamic> settings;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime? completedAt;

  BlockPeriodizationProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.blocks,
    required this.startDate,
    this.endDate,
    required this.currentBlockId,
    this.currentBlockIndex = 0,
    this.isActive = false,
    this.autoProgress = true,
    Map<String, dynamic>? settings,
    required this.createdAt,
    this.completedAt,
  }) : settings = settings ?? {};

  BlockPeriodizationProgram copyWith({
    String? id,
    String? name,
    String? description,
    List<TrainingBlock>? blocks,
    DateTime? startDate,
    DateTime? endDate,
    String? currentBlockId,
    int? currentBlockIndex,
    bool? isActive,
    bool? autoProgress,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return BlockPeriodizationProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      blocks: blocks ?? this.blocks,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentBlockId: currentBlockId ?? this.currentBlockId,
      currentBlockIndex: currentBlockIndex ?? this.currentBlockIndex,
      isActive: isActive ?? this.isActive,
      autoProgress: autoProgress ?? this.autoProgress,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  TrainingBlock? get currentBlock {
    try {
      return blocks.firstWhere((b) => b.id == currentBlockId);
    } catch (e) {
      return null;
    }
  }

  double get overallProgress {
    if (blocks.isEmpty) return 0.0;
    return (currentBlockIndex + 1) / blocks.length;
  }

  int get totalWeeks {
    return blocks.fold(0, (sum, block) => sum + block.durationWeeks);
  }

  bool get isCompleted => completedAt != null;
}

/// Training block within a periodization program
@HiveType(typeId: 41)
class TrainingBlock extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String blockType; // 'hypertrophy', 'strength', 'power'

  @HiveField(3)
  final int durationWeeks;

  @HiveField(4)
  final int sessionsPerWeek;

  @HiveField(5)
  final double intensityMin; // % of 1RM

  @HiveField(6)
  final double intensityMax; // % of 1RM

  @HiveField(7)
  final int repsMin;

  @HiveField(8)
  final int repsMax;

  @HiveField(9)
  final int setsPerExercise;

  @HiveField(10)
  final int restSeconds;

  @HiveField(11)
  final List<String> focusExercises;

  @HiveField(12)
  final Map<String, dynamic> progressionRules;

  @HiveField(13)
  final bool includeDeload;

  @HiveField(14)
  final DateTime? startDate;

  @HiveField(15)
  final DateTime? endDate;

  @HiveField(16)
  final String status; // 'pending', 'active', 'completed'

  TrainingBlock({
    required this.id,
    required this.name,
    required this.blockType,
    required this.durationWeeks,
    this.sessionsPerWeek = 3,
    required this.intensityMin,
    required this.intensityMax,
    required this.repsMin,
    required this.repsMax,
    required this.setsPerExercise,
    required this.restSeconds,
    List<String>? focusExercises,
    Map<String, dynamic>? progressionRules,
    this.includeDeload = true,
    this.startDate,
    this.endDate,
    this.status = 'pending',
  })  : focusExercises = focusExercises ?? [],
        progressionRules = progressionRules ?? {};

  TrainingBlock copyWith({
    String? id,
    String? name,
    String? blockType,
    int? durationWeeks,
    int? sessionsPerWeek,
    double? intensityMin,
    double? intensityMax,
    int? repsMin,
    int? repsMax,
    int? setsPerExercise,
    int? restSeconds,
    List<String>? focusExercises,
    Map<String, dynamic>? progressionRules,
    bool? includeDeload,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return TrainingBlock(
      id: id ?? this.id,
      name: name ?? this.name,
      blockType: blockType ?? this.blockType,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      intensityMin: intensityMin ?? this.intensityMin,
      intensityMax: intensityMax ?? this.intensityMax,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      setsPerExercise: setsPerExercise ?? this.setsPerExercise,
      restSeconds: restSeconds ?? this.restSeconds,
      focusExercises: focusExercises ?? this.focusExercises,
      progressionRules: progressionRules ?? this.progressionRules,
      includeDeload: includeDeload ?? this.includeDeload,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

  String get blockTypeDisplay {
    switch (blockType) {
      case 'hypertrophy':
        return 'Hypertrophy';
      case 'strength':
        return 'Strength';
      case 'power':
        return 'Power';
      default:
        return blockType;
    }
  }

  String get description {
    switch (blockType) {
      case 'hypertrophy':
        return 'Focus on muscle growth with higher volume';
      case 'strength':
        return 'Build maximal strength with heavy weights';
      case 'power':
        return 'Develop explosive power and peak strength';
      default:
        return '';
    }
  }

  double get averageIntensity => (intensityMin + intensityMax) / 2;

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
}

/// Progression entry for tracking block performance
@HiveType(typeId: 42)
class BlockProgressionEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String programId;

  @HiveField(2)
  final String blockId;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final int weekNumber;

  @HiveField(5)
  final String eventType; // 'started', 'completed', 'progressed', 'adjusted'

  @HiveField(6)
  final Map<String, dynamic> metrics;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final Map<String, double> performanceData; // exercise -> performance score

  BlockProgressionEntry({
    required this.id,
    required this.programId,
    required this.blockId,
    required this.timestamp,
    required this.weekNumber,
    required this.eventType,
    Map<String, dynamic>? metrics,
    this.notes,
    Map<String, double>? performanceData,
  })  : metrics = metrics ?? {},
        performanceData = performanceData ?? {};

  BlockProgressionEntry copyWith({
    String? id,
    String? programId,
    String? blockId,
    DateTime? timestamp,
    int? weekNumber,
    String? eventType,
    Map<String, dynamic>? metrics,
    String? notes,
    Map<String, double>? performanceData,
  }) {
    return BlockProgressionEntry(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      blockId: blockId ?? this.blockId,
      timestamp: timestamp ?? this.timestamp,
      weekNumber: weekNumber ?? this.weekNumber,
      eventType: eventType ?? this.eventType,
      metrics: metrics ?? this.metrics,
      notes: notes ?? this.notes,
      performanceData: performanceData ?? this.performanceData,
    );
  }

  double? get averagePerformance {
    if (performanceData.isEmpty) return null;
    final sum = performanceData.values.fold(0.0, (a, b) => a + b);
    return sum / performanceData.length;
  }
}

/// Helper class for block periodization templates
class BlockPeriodizationTemplate {
  static BlockPeriodizationProgram createClassicTemplate({
    required String id,
    required String name,
  }) {
    final blocks = [
      TrainingBlock(
        id: '$id-hypertrophy',
        name: 'Hypertrophy Block',
        blockType: 'hypertrophy',
        durationWeeks: 4,
        sessionsPerWeek: 4,
        intensityMin: 0.60,
        intensityMax: 0.75,
        repsMin: 8,
        repsMax: 12,
        setsPerExercise: 4,
        restSeconds: 90,
        includeDeload: true,
      ),
      TrainingBlock(
        id: '$id-strength',
        name: 'Strength Block',
        blockType: 'strength',
        durationWeeks: 4,
        sessionsPerWeek: 4,
        intensityMin: 0.75,
        intensityMax: 0.85,
        repsMin: 4,
        repsMax: 6,
        setsPerExercise: 5,
        restSeconds: 180,
        includeDeload: true,
      ),
      TrainingBlock(
        id: '$id-power',
        name: 'Power Block',
        blockType: 'power',
        durationWeeks: 3,
        sessionsPerWeek: 3,
        intensityMin: 0.85,
        intensityMax: 0.95,
        repsMin: 1,
        repsMax: 3,
        setsPerExercise: 5,
        restSeconds: 240,
        includeDeload: false,
      ),
    ];

    return BlockPeriodizationProgram(
      id: id,
      name: name,
      description: 'Classic block periodization: Hypertrophy → Strength → Power',
      blocks: blocks,
      startDate: DateTime.now(),
      currentBlockId: blocks.first.id,
      currentBlockIndex: 0,
      isActive: false,
      autoProgress: true,
      createdAt: DateTime.now(),
    );
  }

  static BlockPeriodizationProgram createPowerbuildingTemplate({
    required String id,
    required String name,
  }) {
    final blocks = [
      TrainingBlock(
        id: '$id-hypertrophy-1',
        name: 'Hypertrophy Block 1',
        blockType: 'hypertrophy',
        durationWeeks: 3,
        sessionsPerWeek: 4,
        intensityMin: 0.65,
        intensityMax: 0.75,
        repsMin: 8,
        repsMax: 12,
        setsPerExercise: 4,
        restSeconds: 90,
        includeDeload: false,
      ),
      TrainingBlock(
        id: '$id-strength-1',
        name: 'Strength Block 1',
        blockType: 'strength',
        durationWeeks: 3,
        sessionsPerWeek: 4,
        intensityMin: 0.75,
        intensityMax: 0.85,
        repsMin: 5,
        repsMax: 8,
        setsPerExercise: 4,
        restSeconds: 150,
        includeDeload: false,
      ),
      TrainingBlock(
        id: '$id-hypertrophy-2',
        name: 'Hypertrophy Block 2',
        blockType: 'hypertrophy',
        durationWeeks: 3,
        sessionsPerWeek: 5,
        intensityMin: 0.60,
        intensityMax: 0.70,
        repsMin: 10,
        repsMax: 15,
        setsPerExercise: 5,
        restSeconds: 75,
        includeDeload: true,
      ),
      TrainingBlock(
        id: '$id-strength-2',
        name: 'Strength Block 2',
        blockType: 'strength',
        durationWeeks: 4,
        sessionsPerWeek: 4,
        intensityMin: 0.80,
        intensityMax: 0.90,
        repsMin: 3,
        repsMax: 5,
        setsPerExercise: 5,
        restSeconds: 210,
        includeDeload: true,
      ),
    ];

    return BlockPeriodizationProgram(
      id: id,
      name: name,
      description: 'Powerbuilding: Alternating hypertrophy and strength blocks',
      blocks: blocks,
      startDate: DateTime.now(),
      currentBlockId: blocks.first.id,
      currentBlockIndex: 0,
      isActive: false,
      autoProgress: true,
      createdAt: DateTime.now(),
    );
  }

  static BlockPeriodizationProgram createStrengthFocusedTemplate({
    required String id,
    required String name,
  }) {
    final blocks = [
      TrainingBlock(
        id: '$id-hypertrophy',
        name: 'Foundation Block',
        blockType: 'hypertrophy',
        durationWeeks: 3,
        sessionsPerWeek: 3,
        intensityMin: 0.65,
        intensityMax: 0.75,
        repsMin: 8,
        repsMax: 10,
        setsPerExercise: 4,
        restSeconds: 120,
        includeDeload: false,
      ),
      TrainingBlock(
        id: '$id-strength-1',
        name: 'Strength Block 1',
        blockType: 'strength',
        durationWeeks: 4,
        sessionsPerWeek: 4,
        intensityMin: 0.75,
        intensityMax: 0.85,
        repsMin: 4,
        repsMax: 6,
        setsPerExercise: 5,
        restSeconds: 180,
        includeDeload: true,
      ),
      TrainingBlock(
        id: '$id-strength-2',
        name: 'Strength Block 2',
        blockType: 'strength',
        durationWeeks: 4,
        sessionsPerWeek: 4,
        intensityMin: 0.80,
        intensityMax: 0.90,
        repsMin: 3,
        repsMax: 5,
        setsPerExercise: 5,
        restSeconds: 210,
        includeDeload: true,
      ),
      TrainingBlock(
        id: '$id-power',
        name: 'Peak Block',
        blockType: 'power',
        durationWeeks: 2,
        sessionsPerWeek: 3,
        intensityMin: 0.90,
        intensityMax: 0.97,
        repsMin: 1,
        repsMax: 2,
        setsPerExercise: 6,
        restSeconds: 300,
        includeDeload: false,
      ),
    ];

    return BlockPeriodizationProgram(
      id: id,
      name: name,
      description: 'Strength-focused: Extended strength blocks leading to peak',
      blocks: blocks,
      startDate: DateTime.now(),
      currentBlockId: blocks.first.id,
      currentBlockIndex: 0,
      isActive: false,
      autoProgress: true,
      createdAt: DateTime.now(),
    );
  }
}
