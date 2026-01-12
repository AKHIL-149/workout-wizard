import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/linear_periodization.dart';
import '../models/workout_session.dart';
import 'workout_session_service.dart';

/// Service for managing linear periodization programs
class LinearPeriodizationService {
  static final LinearPeriodizationService _instance =
      LinearPeriodizationService._internal();
  factory LinearPeriodizationService() => _instance;
  LinearPeriodizationService._internal();

  static const String _programsBoxName = 'linear_periodization_programs';
  static const String _progressionBoxName = 'linear_progression_entries';

  final Uuid _uuid = const Uuid();
  final WorkoutSessionService _sessionService = WorkoutSessionService();

  /// Initialize Hive boxes
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_programsBoxName)) {
        await Hive.openBox<LinearPeriodizationProgram>(_programsBoxName);
      }
      if (!Hive.isBoxOpen(_progressionBoxName)) {
        await Hive.openBox<LinearProgressionEntry>(_progressionBoxName);
      }

      debugPrint('LinearPeriodizationService: Initialized');
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error initializing: $e');
      rethrow;
    }
  }

  /// Get all programs
  List<LinearPeriodizationProgram> getAllPrograms() {
    try {
      final box = Hive.box<LinearPeriodizationProgram>(_programsBoxName);
      return box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error getting programs: $e');
      return [];
    }
  }

  /// Get program by ID
  LinearPeriodizationProgram? getProgram(String programId) {
    try {
      final box = Hive.box<LinearPeriodizationProgram>(_programsBoxName);
      return box.get(programId);
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error getting program: $e');
      return null;
    }
  }

  /// Get active program
  LinearPeriodizationProgram? getActiveProgram() {
    try {
      final programs = getAllPrograms();
      return programs.firstWhere(
        (p) => p.isActive,
        orElse: () => throw StateError('No active program'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Create program from template
  Future<LinearPeriodizationProgram> createProgramFromTemplate({
    required String templateType,
    required String name,
    required Map<String, double> baselineMaxes,
  }) async {
    try {
      final id = _uuid.v4();

      LinearPeriodizationProgram program;
      switch (templateType) {
        case 'beginner':
          program = LinearPeriodizationTemplate.createBeginnerTemplate(
            id: id,
            name: name,
            baselineMaxes: baselineMaxes,
          );
          break;
        case 'intermediate':
          program = LinearPeriodizationTemplate.createIntermediateTemplate(
            id: id,
            name: name,
            baselineMaxes: baselineMaxes,
          );
          break;
        case 'strength':
          program = LinearPeriodizationTemplate.createStrengthTemplate(
            id: id,
            name: name,
            baselineMaxes: baselineMaxes,
          );
          break;
        default:
          throw ArgumentError('Unknown template type: $templateType');
      }

      await saveProgram(program);
      debugPrint('LinearPeriodizationService: Created program from $templateType template');
      return program;
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error creating program: $e');
      rethrow;
    }
  }

  /// Create custom program
  Future<LinearPeriodizationProgram> createCustomProgram({
    required String name,
    required String description,
    required List<LinearPhase> phases,
    required Map<String, double> baselineMaxes,
    String progressionScheme = 'weekly',
    double progressionRate = 0.025,
  }) async {
    try {
      final program = LinearPeriodizationProgram(
        id: _uuid.v4(),
        name: name,
        description: description,
        phases: phases,
        startDate: DateTime.now(),
        currentPhaseId: phases.isNotEmpty ? phases.first.id : '',
        currentWeek: 1,
        baselineMaxes: baselineMaxes,
        progressionScheme: progressionScheme,
        progressionRate: progressionRate,
        createdAt: DateTime.now(),
      );

      await saveProgram(program);
      debugPrint('LinearPeriodizationService: Created custom program');
      return program;
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error creating custom program: $e');
      rethrow;
    }
  }

  /// Save program
  Future<void> saveProgram(LinearPeriodizationProgram program) async {
    try {
      final box = Hive.box<LinearPeriodizationProgram>(_programsBoxName);
      await box.put(program.id, program);
      debugPrint('LinearPeriodizationService: Saved program ${program.id}');
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error saving program: $e');
      rethrow;
    }
  }

  /// Delete program
  Future<void> deleteProgram(String programId) async {
    try {
      final box = Hive.box<LinearPeriodizationProgram>(_programsBoxName);
      await box.delete(programId);

      // Delete associated progression entries
      await _deleteProgressionEntries(programId);

      debugPrint('LinearPeriodizationService: Deleted program $programId');
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error deleting program: $e');
      rethrow;
    }
  }

  /// Start program
  Future<void> startProgram(String programId) async {
    try {
      final program = getProgram(programId);
      if (program == null) {
        throw Exception('Program not found');
      }

      // Deactivate other programs
      final allPrograms = getAllPrograms();
      for (var p in allPrograms) {
        if (p.isActive && p.id != programId) {
          await saveProgram(p.copyWith(isActive: false));
        }
      }

      // Activate this program and start first phase
      final firstPhase = program.phases.first.copyWith(
        status: 'active',
        startDate: DateTime.now(),
      );

      final updatedPhases = List<LinearPhase>.from(program.phases);
      updatedPhases[0] = firstPhase;

      final updatedProgram = program.copyWith(
        isActive: true,
        startDate: DateTime.now(),
        phases: updatedPhases,
        currentPhaseId: firstPhase.id,
        currentWeek: 1,
      );

      await saveProgram(updatedProgram);

      // Record initial progression entry
      await _recordWeeklyProgress(updatedProgram);

      debugPrint('LinearPeriodizationService: Started program $programId');
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error starting program: $e');
      rethrow;
    }
  }

  /// Progress to next week
  Future<bool> progressToNextWeek(String programId) async {
    try {
      final program = getProgram(programId);
      if (program == null) {
        throw Exception('Program not found');
      }

      final currentPhase = program.currentPhase;
      if (currentPhase == null) {
        throw Exception('Current phase not found');
      }

      // Calculate which week we're in within the current phase
      int weekInPhase = _getWeekInPhase(program);

      // Check if we're at the end of this phase
      if (weekInPhase >= currentPhase.durationWeeks) {
        // Try to move to next phase
        return await _progressToNextPhase(program);
      }

      // Progress within current phase
      final nextWeek = program.currentWeek + 1;
      final updatedProgram = program.copyWith(currentWeek: nextWeek);

      await saveProgram(updatedProgram);
      await _recordWeeklyProgress(updatedProgram);

      debugPrint('LinearPeriodizationService: Progressed to week $nextWeek');
      return true;
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error progressing to next week: $e');
      rethrow;
    }
  }

  /// Progress to next phase
  Future<bool> _progressToNextPhase(LinearPeriodizationProgram program) async {
    try {
      final currentPhaseIndex = program.phases.indexWhere(
        (p) => p.id == program.currentPhaseId,
      );

      if (currentPhaseIndex == -1) {
        throw Exception('Current phase not found in phases list');
      }

      // Mark current phase as completed
      final completedPhase = program.phases[currentPhaseIndex].copyWith(
        status: 'completed',
        endDate: DateTime.now(),
      );

      final updatedPhases = List<LinearPhase>.from(program.phases);
      updatedPhases[currentPhaseIndex] = completedPhase;

      // Check if there's a next phase
      final nextPhaseIndex = currentPhaseIndex + 1;
      if (nextPhaseIndex >= program.phases.length) {
        // Program completed
        final completedProgram = program.copyWith(
          phases: updatedPhases,
          isActive: false,
          completedAt: DateTime.now(),
        );
        await saveProgram(completedProgram);
        debugPrint('LinearPeriodizationService: Program completed');
        return false;
      }

      // Start next phase
      final nextPhase = program.phases[nextPhaseIndex].copyWith(
        status: 'active',
        startDate: DateTime.now(),
      );
      updatedPhases[nextPhaseIndex] = nextPhase;

      final updatedProgram = program.copyWith(
        phases: updatedPhases,
        currentPhaseId: nextPhase.id,
        currentWeek: program.currentWeek + 1,
      );

      await saveProgram(updatedProgram);
      await _recordWeeklyProgress(updatedProgram);

      debugPrint('LinearPeriodizationService: Progressed to next phase');
      return true;
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error progressing to next phase: $e');
      rethrow;
    }
  }

  /// Get week number within current phase
  int _getWeekInPhase(LinearPeriodizationProgram program) {
    int totalWeeksInPriorPhases = 0;

    for (var phase in program.phases) {
      if (phase.id == program.currentPhaseId) {
        break;
      }
      totalWeeksInPriorPhases += phase.durationWeeks;
    }

    return program.currentWeek - totalWeeksInPriorPhases;
  }

  /// Calculate current training parameters for the week
  Map<String, dynamic> getCurrentWeekParameters(String programId) {
    try {
      final program = getProgram(programId);
      if (program == null) return {};

      final phase = program.currentPhase;
      if (phase == null) return {};

      final weekInPhase = _getWeekInPhase(program);

      final intensity = phase.getIntensityForWeek(weekInPhase);
      final volume = phase.getVolumeForWeek(weekInPhase);

      // Calculate working maxes for each exercise
      final workingMaxes = <String, double>{};
      for (var exercise in program.baselineMaxes.keys) {
        workingMaxes[exercise] = program.getTrainingMax(exercise);
      }

      return {
        'week': program.currentWeek,
        'weekInPhase': weekInPhase,
        'phase': phase.name,
        'intensity': intensity,
        'volume': volume,
        'repsPerSet': phase.repsPerSet,
        'workingMaxes': workingMaxes,
      };
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error getting week parameters: $e');
      return {};
    }
  }

  /// Record weekly progress
  Future<void> _recordWeeklyProgress(
    LinearPeriodizationProgram program,
  ) async {
    try {
      final phase = program.currentPhase;
      if (phase == null) return;

      final weekInPhase = _getWeekInPhase(program);
      final plannedIntensity = phase.getIntensityForWeek(weekInPhase);
      final plannedVolume = phase.getVolumeForWeek(weekInPhase);

      // Calculate working maxes
      final workingMaxes = <String, double>{};
      for (var exercise in program.baselineMaxes.keys) {
        workingMaxes[exercise] = program.getTrainingMax(exercise);
      }

      final entry = LinearProgressionEntry(
        id: _uuid.v4(),
        programId: program.id,
        phaseId: phase.id,
        weekNumber: program.currentWeek,
        timestamp: DateTime.now(),
        workingMaxes: workingMaxes,
        plannedIntensity: plannedIntensity,
        actualIntensity: 0.0, // Will be updated after workouts
        plannedVolume: plannedVolume,
        actualVolume: 0, // Will be updated after workouts
        deloadWeek: _isDeloadWeek(program, weekInPhase),
      );

      final box = Hive.box<LinearProgressionEntry>(_progressionBoxName);
      await box.put(entry.id, entry);

      debugPrint('LinearPeriodizationService: Recorded weekly progress');
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error recording progress: $e');
    }
  }

  /// Check if current week is a deload week
  bool _isDeloadWeek(LinearPeriodizationProgram program, int weekInPhase) {
    final phase = program.currentPhase;
    if (phase == null || !phase.includeDeload) return false;

    // Deload on last week of phase if it has deload enabled
    return weekInPhase == phase.durationWeeks;
  }

  /// Update progression entry with actual performance
  Future<void> updateWeekPerformance({
    required String programId,
    required int weekNumber,
    required double actualIntensity,
    required int actualVolume,
    Map<String, double>? actualPerformance,
    String? notes,
  }) async {
    try {
      final entries = getProgressionEntries(programId: programId);
      final entry = entries.firstWhere(
        (e) => e.weekNumber == weekNumber,
        orElse: () => throw StateError('Entry not found'),
      );

      final updated = entry.copyWith(
        actualIntensity: actualIntensity,
        actualVolume: actualVolume,
        actualPerformance: actualPerformance,
        notes: notes,
      );

      final box = Hive.box<LinearProgressionEntry>(_progressionBoxName);
      await box.put(updated.id, updated);

      debugPrint('LinearPeriodizationService: Updated week performance');
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error updating performance: $e');
    }
  }

  /// Get progression entries
  List<LinearProgressionEntry> getProgressionEntries({
    String? programId,
    String? phaseId,
  }) {
    try {
      final box = Hive.box<LinearProgressionEntry>(_progressionBoxName);
      var entries = box.values.toList();

      if (programId != null) {
        entries = entries.where((e) => e.programId == programId).toList();
      }

      if (phaseId != null) {
        entries = entries.where((e) => e.phaseId == phaseId).toList();
      }

      entries.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
      return entries;
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error getting entries: $e');
      return [];
    }
  }

  /// Delete progression entries
  Future<void> _deleteProgressionEntries(String programId) async {
    try {
      final box = Hive.box<LinearProgressionEntry>(_progressionBoxName);
      final entries = box.values.where((e) => e.programId == programId).toList();

      for (var entry in entries) {
        await box.delete(entry.id);
      }

      debugPrint('LinearPeriodizationService: Deleted progression entries');
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error deleting entries: $e');
    }
  }

  /// Get statistics
  Map<String, dynamic> getStats() {
    try {
      final programs = getAllPrograms();
      final activeProgram = getActiveProgram();

      int completedWeeks = 0;
      double avgAdherence = 0.0;

      if (activeProgram != null) {
        final entries = getProgressionEntries(programId: activeProgram.id);
        completedWeeks = entries.where((e) => e.actualVolume > 0).length;

        if (entries.isNotEmpty) {
          final totalAdherence = entries
              .where((e) => e.actualVolume > 0)
              .fold(0.0, (sum, e) => sum + e.adherenceScore);
          avgAdherence = completedWeeks > 0
              ? totalAdherence / completedWeeks
              : 0.0;
        }
      }

      return {
        'totalPrograms': programs.length,
        'activePrograms': programs.where((p) => p.isActive).length,
        'completedPrograms': programs.where((p) => p.isCompleted).length,
        'currentWeek': activeProgram?.currentWeek ?? 0,
        'totalWeeks': activeProgram?.totalWeeks ?? 0,
        'completedWeeks': completedWeeks,
        'avgAdherence': avgAdherence,
      };
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error getting stats: $e');
      return {
        'totalPrograms': 0,
        'activePrograms': 0,
        'completedPrograms': 0,
        'currentWeek': 0,
        'totalWeeks': 0,
        'completedWeeks': 0,
        'avgAdherence': 0.0,
      };
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await Hive.box<LinearPeriodizationProgram>(_programsBoxName).clear();
      await Hive.box<LinearProgressionEntry>(_progressionBoxName).clear();
      debugPrint('LinearPeriodizationService: All data cleared');
    } catch (e) {
      debugPrint('LinearPeriodizationService: Error clearing data: $e');
      rethrow;
    }
  }
}
