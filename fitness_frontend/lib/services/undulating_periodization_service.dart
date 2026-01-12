import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/undulating_periodization.dart';

/// Service for managing undulating periodization programs
class UndulatingPeriodizationService {
  static final UndulatingPeriodizationService _instance =
      UndulatingPeriodizationService._internal();
  factory UndulatingPeriodizationService() => _instance;
  UndulatingPeriodizationService._internal();

  static const String _boxName = 'undulating_periodization_programs';
  static const String _progressBoxName = 'undulating_progression_entries';

  Box<UndulatingPeriodizationProgram>? _programBox;
  Box<UndulatingProgressionEntry>? _progressBox;

  /// Initialize service
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _programBox = await Hive.openBox<UndulatingPeriodizationProgram>(_boxName);
      } else {
        _programBox = Hive.box<UndulatingPeriodizationProgram>(_boxName);
      }

      if (!Hive.isBoxOpen(_progressBoxName)) {
        _progressBox = await Hive.openBox<UndulatingProgressionEntry>(_progressBoxName);
      } else {
        _progressBox = Hive.box<UndulatingProgressionEntry>(_progressBoxName);
      }

      debugPrint('UndulatingPeriodizationService initialized');
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error initializing: $e');
      rethrow;
    }
  }

  /// Get all programs
  List<UndulatingPeriodizationProgram> getAllPrograms() {
    try {
      return _programBox?.values.toList() ?? [];
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error getting programs: $e');
      return [];
    }
  }

  /// Get program by ID
  UndulatingPeriodizationProgram? getProgram(String id) {
    try {
      return _programBox?.get(id);
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error getting program: $e');
      return null;
    }
  }

  /// Get active program
  UndulatingPeriodizationProgram? getActiveProgram() {
    try {
      final programs = getAllPrograms();
      return programs.where((p) => p.isActive).firstOrNull;
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error getting active program: $e');
      return null;
    }
  }

  /// Save program
  Future<void> saveProgram(UndulatingPeriodizationProgram program) async {
    try {
      await _programBox?.put(program.id, program);
      debugPrint('UndulatingPeriodizationService: Program saved: ${program.name}');
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error saving program: $e');
      rethrow;
    }
  }

  /// Delete program
  Future<void> deleteProgram(String id) async {
    try {
      await _programBox?.delete(id);
      // Delete associated progress entries
      final entries = getProgressionEntries(programId: id);
      for (var entry in entries) {
        await _progressBox?.delete(entry.id);
      }
      debugPrint('UndulatingPeriodizationService: Program deleted: $id');
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error deleting program: $e');
      rethrow;
    }
  }

  /// Create program from template
  Future<UndulatingPeriodizationProgram> createProgramFromTemplate({
    required String templateType,
    required String name,
    required Map<String, double> baselineMaxes,
  }) async {
    try {
      UndulatingPeriodizationProgram program;

      switch (templateType) {
        case 'beginner':
          program = UndulatingPeriodizationProgram.createBeginnerTemplate(
            name: name,
            baselineMaxes: baselineMaxes,
          );
          break;
        case 'advanced':
          program = UndulatingPeriodizationProgram.createAdvancedTemplate(
            name: name,
            baselineMaxes: baselineMaxes,
          );
          break;
        case 'weekly':
          program = UndulatingPeriodizationProgram.createWeeklyTemplate(
            name: name,
            baselineMaxes: baselineMaxes,
          );
          break;
        default:
          throw ArgumentError('Unknown template type: $templateType');
      }

      await saveProgram(program);
      return program;
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error creating program: $e');
      rethrow;
    }
  }

  /// Start program
  Future<void> startProgram(String programId) async {
    try {
      // Deactivate all other programs
      final allPrograms = getAllPrograms();
      for (var p in allPrograms) {
        if (p.isActive) {
          await saveProgram(p.copyWith(isActive: false));
        }
      }

      // Activate this program
      final program = getProgram(programId);
      if (program == null) throw Exception('Program not found');

      final updatedProgram = program.copyWith(
        isActive: true,
        startDate: DateTime.now(),
      );

      // Update first cycle status
      final cycles = List<UndulatingCycle>.from(updatedProgram.cycles);
      if (cycles.isNotEmpty) {
        cycles[0] = cycles[0].copyWith(
          status: 'active',
          startDate: DateTime.now(),
        );
      }

      await saveProgram(updatedProgram.copyWith(cycles: cycles));

      // Record start event
      await _recordProgressionEntry(
        programId: updatedProgram.id,
        cycleId: updatedProgram.currentCycleId,
        workoutDayId: updatedProgram.currentWorkoutDay?.id ?? '',
        weekNumber: 1,
        workingMaxes: _calculateWorkingMaxes(updatedProgram),
        plannedIntensity: updatedProgram.currentWorkoutDay?.intensityPercent ?? 0.0,
        plannedVolume: _calculatePlannedVolume(updatedProgram),
      );

      debugPrint('UndulatingPeriodizationService: Program started: $programId');
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error starting program: $e');
      rethrow;
    }
  }

  /// Progress to next workout day
  Future<bool> progressToNextWorkout(String programId) async {
    try {
      final program = getProgram(programId);
      if (program == null) throw Exception('Program not found');
      if (!program.isActive) throw Exception('Program not active');

      final currentCycle = program.currentCycle;
      if (currentCycle == null) throw Exception('No current cycle');

      // Check if we're at the end of this cycle repetition
      final nextDayIndex = program.currentDayInCycle + 1;

      if (nextDayIndex >= currentCycle.workoutDays.length) {
        // Cycle repetition completed, check if we need to repeat or move to next cycle
        return await _progressCycle(program);
      }

      // Progress within current cycle
      final updatedProgram = program.copyWith(
        currentDayInCycle: nextDayIndex,
      );

      await saveProgram(updatedProgram);

      // Record progression
      await _recordProgressionEntry(
        programId: updatedProgram.id,
        cycleId: updatedProgram.currentCycleId,
        workoutDayId: updatedProgram.currentWorkoutDay?.id ?? '',
        weekNumber: updatedProgram.currentWeek,
        workingMaxes: _calculateWorkingMaxes(updatedProgram),
        plannedIntensity: updatedProgram.currentWorkoutDay?.intensityPercent ?? 0.0,
        plannedVolume: _calculatePlannedVolume(updatedProgram),
      );

      return true;
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error progressing workout: $e');
      rethrow;
    }
  }

  /// Progress cycle (handle repetitions and cycle transitions)
  Future<bool> _progressCycle(UndulatingPeriodizationProgram program) async {
    final currentCycle = program.currentCycle;
    if (currentCycle == null) return false;

    // Calculate how many times we've completed this cycle
    final totalDaysInCycle = currentCycle.workoutDays.length;
    final completedRepetitions = (program.currentDayInCycle + 1) ~/ totalDaysInCycle;

    if (completedRepetitions < currentCycle.repeatCount) {
      // Repeat the cycle
      final updatedProgram = program.copyWith(
        currentDayInCycle: 0,
        currentWeek: program.currentWeek + 1,
      );
      await saveProgram(updatedProgram);
      return true;
    }

    // Cycle fully completed, move to next cycle
    final currentCycleIndex = program.cycles.indexOf(currentCycle);
    if (currentCycleIndex < program.cycles.length - 1) {
      // Move to next cycle
      final nextCycle = program.cycles[currentCycleIndex + 1];

      // Update cycle statuses
      final cycles = List<UndulatingCycle>.from(program.cycles);
      cycles[currentCycleIndex] = currentCycle.copyWith(
        status: 'completed',
        endDate: DateTime.now(),
      );
      cycles[currentCycleIndex + 1] = nextCycle.copyWith(
        status: 'active',
        startDate: DateTime.now(),
      );

      final updatedProgram = program.copyWith(
        currentCycleId: nextCycle.id,
        currentDayInCycle: 0,
        currentWeek: program.currentWeek + 1,
        cycles: cycles,
      );

      await saveProgram(updatedProgram);
      return true;
    }

    // Program completed
    final cycles = List<UndulatingCycle>.from(program.cycles);
    cycles[currentCycleIndex] = currentCycle.copyWith(
      status: 'completed',
      endDate: DateTime.now(),
    );

    final completedProgram = program.copyWith(
      isActive: false,
      completedAt: DateTime.now(),
      endDate: DateTime.now(),
      cycles: cycles,
    );

    await saveProgram(completedProgram);
    return false;
  }

  /// Calculate working maxes for current workout
  Map<String, double> _calculateWorkingMaxes(UndulatingPeriodizationProgram program) {
    final workingMaxes = <String, double>{};
    for (var exercise in program.baselineMaxes.keys) {
      workingMaxes[exercise] = program.getTrainingMax(exercise);
    }
    return workingMaxes;
  }

  /// Calculate planned volume for current workout
  int _calculatePlannedVolume(UndulatingPeriodizationProgram program) {
    final currentDay = program.currentWorkoutDay;
    if (currentDay == null) return 0;

    return currentDay.setsPerExercise *
        ((currentDay.repsMin + currentDay.repsMax) / 2).round() *
        currentDay.focusExercises.length;
  }

  /// Get current workout day parameters
  Map<String, dynamic>? getCurrentWorkoutParameters(String programId) {
    try {
      final program = getProgram(programId);
      if (program == null || !program.isActive) return null;

      final currentDay = program.currentWorkoutDay;
      if (currentDay == null) return null;

      final workingMaxes = _calculateWorkingMaxes(program);

      return {
        'programId': program.id,
        'cycleId': program.currentCycleId,
        'cycleName': program.currentCycle?.name ?? '',
        'dayId': currentDay.id,
        'dayName': currentDay.name,
        'dayType': currentDay.dayType,
        'week': program.currentWeek,
        'dayInCycle': program.currentDayInCycle + 1,
        'totalDaysInCycle': program.currentCycle?.workoutDays.length ?? 0,
        'intensity': currentDay.intensityPercent,
        'repsMin': currentDay.repsMin,
        'repsMax': currentDay.repsMax,
        'sets': currentDay.setsPerExercise,
        'restSeconds': currentDay.restSeconds,
        'exercises': currentDay.focusExercises,
        'workingMaxes': workingMaxes,
      };
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error getting workout parameters: $e');
      return null;
    }
  }

  /// Record progression entry
  Future<void> _recordProgressionEntry({
    required String programId,
    required String cycleId,
    required String workoutDayId,
    required int weekNumber,
    required Map<String, double> workingMaxes,
    Map<String, double>? actualPerformance,
    required double plannedIntensity,
    double? actualIntensity,
    required int plannedVolume,
    int? actualVolume,
    String? notes,
  }) async {
    try {
      const uuid = Uuid();
      final entry = UndulatingProgressionEntry(
        id: uuid.v4(),
        programId: programId,
        cycleId: cycleId,
        workoutDayId: workoutDayId,
        weekNumber: weekNumber,
        timestamp: DateTime.now(),
        workingMaxes: workingMaxes,
        actualPerformance: actualPerformance ?? {},
        plannedIntensity: plannedIntensity,
        actualIntensity: actualIntensity ?? 0.0,
        plannedVolume: plannedVolume,
        actualVolume: actualVolume ?? 0,
        notes: notes,
      );

      await _progressBox?.put(entry.id, entry);
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error recording entry: $e');
    }
  }

  /// Get progression entries
  List<UndulatingProgressionEntry> getProgressionEntries({
    String? programId,
    String? cycleId,
  }) {
    try {
      var entries = _progressBox?.values.toList() ?? [];

      if (programId != null) {
        entries = entries.where((e) => e.programId == programId).toList();
      }

      if (cycleId != null) {
        entries = entries.where((e) => e.cycleId == cycleId).toList();
      }

      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error getting entries: $e');
      return [];
    }
  }

  /// Calculate adherence score
  double calculateAdherenceScore(String programId) {
    try {
      final entries = getProgressionEntries(programId: programId)
          .where((e) => e.actualVolume > 0)
          .toList();

      if (entries.isEmpty) return 0.0;

      double totalScore = 0.0;
      for (var entry in entries) {
        final volumeScore = entry.actualVolume / entry.plannedVolume;
        final intensityScore = entry.actualIntensity / entry.plannedIntensity;
        final entryScore = (volumeScore + intensityScore) / 2;
        totalScore += entryScore.clamp(0.0, 1.0);
      }

      return totalScore / entries.length;
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error calculating adherence: $e');
      return 0.0;
    }
  }

  /// Get program statistics
  Map<String, dynamic> getProgramStatistics(String programId) {
    try {
      final program = getProgram(programId);
      if (program == null) return {};

      final entries = getProgressionEntries(programId: programId);
      final workoutsCompleted = entries.where((e) => e.actualVolume > 0).length;
      final adherence = calculateAdherenceScore(programId);

      return {
        'workoutsCompleted': workoutsCompleted,
        'currentWeek': program.currentWeek,
        'totalWeeks': program.totalWeeks,
        'progress': program.overallProgress,
        'adherence': adherence,
        'isActive': program.isActive,
        'isCompleted': program.isCompleted,
      };
    } catch (e) {
      debugPrint('UndulatingPeriodizationService: Error getting statistics: $e');
      return {};
    }
  }
}
