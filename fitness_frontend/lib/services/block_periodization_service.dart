import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/block_periodization.dart';
import '../models/workout_session.dart';
import 'workout_session_service.dart';

/// Service for managing block periodization programs
class BlockPeriodizationService {
  static final BlockPeriodizationService _instance =
      BlockPeriodizationService._internal();
  factory BlockPeriodizationService() => _instance;
  BlockPeriodizationService._internal();

  static const String _programsBoxName = 'block_periodization_programs';
  static const String _progressionBoxName = 'block_progression_entries';

  final Uuid _uuid = const Uuid();
  final WorkoutSessionService _sessionService = WorkoutSessionService();

  /// Initialize Hive boxes
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_programsBoxName)) {
        await Hive.openBox<BlockPeriodizationProgram>(_programsBoxName);
      }
      if (!Hive.isBoxOpen(_progressionBoxName)) {
        await Hive.openBox<BlockProgressionEntry>(_progressionBoxName);
      }

      debugPrint('BlockPeriodizationService: Initialized');
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error initializing: $e');
      rethrow;
    }
  }

  /// Get all programs
  List<BlockPeriodizationProgram> getAllPrograms() {
    try {
      final box = Hive.box<BlockPeriodizationProgram>(_programsBoxName);
      return box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error getting programs: $e');
      return [];
    }
  }

  /// Get program by ID
  BlockPeriodizationProgram? getProgram(String programId) {
    try {
      final box = Hive.box<BlockPeriodizationProgram>(_programsBoxName);
      return box.get(programId);
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error getting program: $e');
      return null;
    }
  }

  /// Get active program
  BlockPeriodizationProgram? getActiveProgram() {
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
  Future<BlockPeriodizationProgram> createProgramFromTemplate({
    required String templateType,
    required String name,
  }) async {
    try {
      final id = _uuid.v4();

      BlockPeriodizationProgram program;
      switch (templateType) {
        case 'classic':
          program = BlockPeriodizationTemplate.createClassicTemplate(
            id: id,
            name: name,
          );
          break;
        case 'powerbuilding':
          program = BlockPeriodizationTemplate.createPowerbuildingTemplate(
            id: id,
            name: name,
          );
          break;
        case 'strength':
          program = BlockPeriodizationTemplate.createStrengthFocusedTemplate(
            id: id,
            name: name,
          );
          break;
        default:
          throw ArgumentError('Unknown template type: $templateType');
      }

      await saveProgram(program);
      debugPrint('BlockPeriodizationService: Created program from $templateType template');
      return program;
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error creating program: $e');
      rethrow;
    }
  }

  /// Create custom program
  Future<BlockPeriodizationProgram> createCustomProgram({
    required String name,
    required String description,
    required List<TrainingBlock> blocks,
  }) async {
    try {
      final program = BlockPeriodizationProgram(
        id: _uuid.v4(),
        name: name,
        description: description,
        blocks: blocks,
        startDate: DateTime.now(),
        currentBlockId: blocks.isNotEmpty ? blocks.first.id : '',
        currentBlockIndex: 0,
        isActive: false,
        autoProgress: true,
        createdAt: DateTime.now(),
      );

      await saveProgram(program);
      debugPrint('BlockPeriodizationService: Created custom program');
      return program;
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error creating custom program: $e');
      rethrow;
    }
  }

  /// Save program
  Future<void> saveProgram(BlockPeriodizationProgram program) async {
    try {
      final box = Hive.box<BlockPeriodizationProgram>(_programsBoxName);
      await box.put(program.id, program);
      debugPrint('BlockPeriodizationService: Saved program ${program.id}');
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error saving program: $e');
      rethrow;
    }
  }

  /// Delete program
  Future<void> deleteProgram(String programId) async {
    try {
      final box = Hive.box<BlockPeriodizationProgram>(_programsBoxName);
      await box.delete(programId);

      // Delete associated progression entries
      await _deleteProgressionEntries(programId);

      debugPrint('BlockPeriodizationService: Deleted program $programId');
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error deleting program: $e');
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

      // Activate this program and start first block
      final firstBlock = program.blocks.first.copyWith(
        status: 'active',
        startDate: DateTime.now(),
      );

      final updatedBlocks = List<TrainingBlock>.from(program.blocks);
      updatedBlocks[0] = firstBlock;

      final updatedProgram = program.copyWith(
        isActive: true,
        startDate: DateTime.now(),
        blocks: updatedBlocks,
        currentBlockId: firstBlock.id,
        currentBlockIndex: 0,
      );

      await saveProgram(updatedProgram);

      // Record progression entry
      await _addProgressionEntry(
        programId: programId,
        blockId: firstBlock.id,
        eventType: 'started',
        weekNumber: 1,
      );

      debugPrint('BlockPeriodizationService: Started program $programId');
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error starting program: $e');
      rethrow;
    }
  }

  /// Complete current block and progress to next
  Future<bool> progressToNextBlock(String programId) async {
    try {
      final program = getProgram(programId);
      if (program == null) {
        throw Exception('Program not found');
      }

      final currentBlock = program.currentBlock;
      if (currentBlock == null) {
        throw Exception('Current block not found');
      }

      // Mark current block as completed
      final completedBlock = currentBlock.copyWith(
        status: 'completed',
        endDate: DateTime.now(),
      );

      final updatedBlocks = List<TrainingBlock>.from(program.blocks);
      updatedBlocks[program.currentBlockIndex] = completedBlock;

      // Record completion
      await _addProgressionEntry(
        programId: programId,
        blockId: currentBlock.id,
        eventType: 'completed',
        weekNumber: currentBlock.durationWeeks,
      );

      // Check if there's a next block
      final nextIndex = program.currentBlockIndex + 1;
      if (nextIndex >= program.blocks.length) {
        // Program completed
        final completedProgram = program.copyWith(
          blocks: updatedBlocks,
          isActive: false,
          completedAt: DateTime.now(),
        );
        await saveProgram(completedProgram);
        debugPrint('BlockPeriodizationService: Program completed');
        return false;
      }

      // Start next block
      final nextBlock = program.blocks[nextIndex].copyWith(
        status: 'active',
        startDate: DateTime.now(),
      );
      updatedBlocks[nextIndex] = nextBlock;

      final updatedProgram = program.copyWith(
        blocks: updatedBlocks,
        currentBlockId: nextBlock.id,
        currentBlockIndex: nextIndex,
      );

      await saveProgram(updatedProgram);

      // Record next block start
      await _addProgressionEntry(
        programId: programId,
        blockId: nextBlock.id,
        eventType: 'started',
        weekNumber: 1,
      );

      debugPrint('BlockPeriodizationService: Progressed to next block');
      return true;
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error progressing to next block: $e');
      rethrow;
    }
  }

  /// Check if automatic progression should occur
  Future<bool> shouldAutoProgress(String programId) async {
    try {
      final program = getProgram(programId);
      if (program == null || !program.autoProgress) {
        return false;
      }

      final currentBlock = program.currentBlock;
      if (currentBlock == null || currentBlock.startDate == null) {
        return false;
      }

      // Calculate if block duration has passed
      final weeksPassed = DateTime.now()
          .difference(currentBlock.startDate!)
          .inDays ~/
          7;

      if (weeksPassed >= currentBlock.durationWeeks) {
        // Check performance metrics to confirm readiness
        final performance = await _evaluateBlockPerformance(
          programId,
          currentBlock.id,
        );

        // Auto-progress if performance is adequate (>70%)
        return performance >= 0.70;
      }

      return false;
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error checking auto-progress: $e');
      return false;
    }
  }

  /// Evaluate block performance
  Future<double> _evaluateBlockPerformance(
    String programId,
    String blockId,
  ) async {
    try {
      // Get recent workout sessions for this block
      final sessions = _sessionService.getAllSessions();
      final program = getProgram(programId);
      if (program == null) return 0.0;

      final block = program.blocks.firstWhere(
        (b) => b.id == blockId,
        orElse: () => throw StateError('Block not found'),
      );

      final blockSessions = sessions.where((s) {
        if (block.startDate == null) return false;
        return s.startTime.isAfter(block.startDate!) &&
            (block.endDate == null || s.startTime.isBefore(block.endDate!));
      }).toList();

      if (blockSessions.isEmpty) return 0.5; // Default neutral score

      // Calculate performance based on:
      // 1. Completion rate
      // 2. Volume progression
      // 3. Intensity adherence

      double completionRate = blockSessions
          .where((s) => s.status == 'completed')
          .length /
          blockSessions.length;

      double volumeScore = _calculateVolumeProgression(blockSessions);
      double intensityScore = _calculateIntensityAdherence(blockSessions, block);

      // Weighted average
      return (completionRate * 0.4) + (volumeScore * 0.3) + (intensityScore * 0.3);
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error evaluating performance: $e');
      return 0.5;
    }
  }

  /// Calculate volume progression across sessions
  double _calculateVolumeProgression(List<WorkoutSession> sessions) {
    if (sessions.length < 2) return 0.7; // Default if insufficient data

    try {
      // Compare first half to second half of block
      final midpoint = sessions.length ~/ 2;
      final firstHalf = sessions.take(midpoint);
      final secondHalf = sessions.skip(midpoint);

      final firstVolume = firstHalf.fold(0.0, (sum, s) {
        return sum + s.exercises.fold(0.0, (eSum, e) {
          return eSum + e.sets.fold(0.0, (sSum, set) {
            return sSum + (set.weight * set.reps);
          });
        });
      });

      final secondVolume = secondHalf.fold(0.0, (sum, s) {
        return sum + s.exercises.fold(0.0, (eSum, e) {
          return eSum + e.sets.fold(0.0, (sSum, set) {
            return sSum + (set.weight * set.reps);
          });
        });
      });

      if (firstVolume == 0) return 0.7;

      // Calculate progression ratio
      final progression = secondVolume / firstVolume;

      // Score based on progression (ideal is 1.05-1.15, i.e., 5-15% increase)
      if (progression >= 1.05 && progression <= 1.20) {
        return 1.0; // Excellent
      } else if (progression >= 1.0 && progression < 1.05) {
        return 0.8; // Good
      } else if (progression >= 0.95) {
        return 0.6; // Acceptable
      } else {
        return 0.4; // Needs improvement
      }
    } catch (e) {
      return 0.7;
    }
  }

  /// Calculate intensity adherence to block parameters
  double _calculateIntensityAdherence(
    List<WorkoutSession> sessions,
    TrainingBlock block,
  ) {
    if (sessions.isEmpty) return 0.7;

    try {
      int adherentSets = 0;
      int totalSets = 0;

      for (var session in sessions) {
        for (var exercise in session.exercises) {
          for (var set in exercise.sets) {
            totalSets++;

            // Check if reps are within block range
            if (set.reps >= block.repsMin && set.reps <= block.repsMax) {
              adherentSets++;
            }
          }
        }
      }

      if (totalSets == 0) return 0.7;

      return adherentSets / totalSets;
    } catch (e) {
      return 0.7;
    }
  }

  /// Get progression entries for a program
  List<BlockProgressionEntry> getProgressionEntries({
    String? programId,
    String? blockId,
  }) {
    try {
      final box = Hive.box<BlockProgressionEntry>(_progressionBoxName);
      var entries = box.values.toList();

      if (programId != null) {
        entries = entries.where((e) => e.programId == programId).toList();
      }

      if (blockId != null) {
        entries = entries.where((e) => e.blockId == blockId).toList();
      }

      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error getting progression entries: $e');
      return [];
    }
  }

  /// Add progression entry
  Future<void> _addProgressionEntry({
    required String programId,
    required String blockId,
    required String eventType,
    required int weekNumber,
    Map<String, dynamic>? metrics,
    String? notes,
  }) async {
    try {
      final entry = BlockProgressionEntry(
        id: _uuid.v4(),
        programId: programId,
        blockId: blockId,
        timestamp: DateTime.now(),
        weekNumber: weekNumber,
        eventType: eventType,
        metrics: metrics,
        notes: notes,
      );

      final box = Hive.box<BlockProgressionEntry>(_progressionBoxName);
      await box.put(entry.id, entry);

      debugPrint('BlockPeriodizationService: Added progression entry');
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error adding progression entry: $e');
    }
  }

  /// Delete progression entries for a program
  Future<void> _deleteProgressionEntries(String programId) async {
    try {
      final box = Hive.box<BlockProgressionEntry>(_progressionBoxName);
      final entries = box.values.where((e) => e.programId == programId).toList();

      for (var entry in entries) {
        await box.delete(entry.id);
      }

      debugPrint('BlockPeriodizationService: Deleted progression entries for $programId');
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error deleting progression entries: $e');
    }
  }

  /// Get statistics
  Map<String, dynamic> getStats() {
    try {
      final programs = getAllPrograms();
      final activeProgram = getActiveProgram();

      return {
        'totalPrograms': programs.length,
        'activePrograms': programs.where((p) => p.isActive).length,
        'completedPrograms': programs.where((p) => p.isCompleted).length,
        'currentBlock': activeProgram?.currentBlock?.blockTypeDisplay,
        'currentWeek': activeProgram != null
            ? _getCurrentWeek(activeProgram)
            : 0,
        'totalWeeks': activeProgram?.totalWeeks ?? 0,
      };
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error getting stats: $e');
      return {
        'totalPrograms': 0,
        'activePrograms': 0,
        'completedPrograms': 0,
        'currentBlock': null,
        'currentWeek': 0,
        'totalWeeks': 0,
      };
    }
  }

  /// Get current week number in active block
  int _getCurrentWeek(BlockPeriodizationProgram program) {
    final block = program.currentBlock;
    if (block == null || block.startDate == null) return 0;

    final weeksPassed = DateTime.now()
        .difference(block.startDate!)
        .inDays ~/
        7;

    return (weeksPassed + 1).clamp(1, block.durationWeeks);
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await Hive.box<BlockPeriodizationProgram>(_programsBoxName).clear();
      await Hive.box<BlockProgressionEntry>(_progressionBoxName).clear();
      debugPrint('BlockPeriodizationService: All data cleared');
    } catch (e) {
      debugPrint('BlockPeriodizationService: Error clearing data: $e');
      rethrow;
    }
  }
}
