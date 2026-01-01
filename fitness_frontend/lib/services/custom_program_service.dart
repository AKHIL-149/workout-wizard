import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_program.dart';

/// Service for managing user-created and customized workout programs
class CustomProgramService {
  static final CustomProgramService _instance = CustomProgramService._internal();
  factory CustomProgramService() => _instance;
  CustomProgramService._internal();

  static const String _boxName = 'custom_programs';
  bool _initialized = false;

  Box<WorkoutProgram> get _getBox {
    if (!Hive.isBoxOpen(_boxName)) {
      throw Exception('CustomProgramService: Box not initialized');
    }
    return Hive.box<WorkoutProgram>(_boxName);
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<WorkoutProgram>(_boxName);
      }

      _initialized = true;
      debugPrint('CustomProgramService: Initialized successfully');
    } catch (e) {
      debugPrint('CustomProgramService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Create a new custom program
  Future<WorkoutProgram> createProgram(WorkoutProgram program) async {
    try {
      // Ensure unique ID with custom prefix
      final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      final customProgram = program.copyWith(
        id: customId,
        author: 'You',
        isBuiltIn: false,
        createdAt: DateTime.now(),
      );

      await _getBox.put(customId, customProgram);
      debugPrint('CustomProgramService: Created program ${customProgram.name}');

      return customProgram;
    } catch (e) {
      debugPrint('CustomProgramService: Error creating program: $e');
      rethrow;
    }
  }

  /// Clone an existing program for customization
  Future<WorkoutProgram> cloneProgram(
    WorkoutProgram source, {
    String? customName,
  }) async {
    try {
      final clonedProgram = source.copyWith(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: customName ?? '${source.name} (Custom)',
        author: 'You',
        isBuiltIn: false,
        createdAt: DateTime.now(),
      );

      await _getBox.put(clonedProgram.id, clonedProgram);
      debugPrint('CustomProgramService: Cloned program ${clonedProgram.name}');

      return clonedProgram;
    } catch (e) {
      debugPrint('CustomProgramService: Error cloning program: $e');
      rethrow;
    }
  }

  /// Update an existing custom program
  Future<void> updateProgram(WorkoutProgram program) async {
    try {
      if (!program.id.startsWith('custom_')) {
        throw Exception('Cannot update non-custom program');
      }

      await _getBox.put(program.id, program);
      debugPrint('CustomProgramService: Updated program ${program.name}');
    } catch (e) {
      debugPrint('CustomProgramService: Error updating program: $e');
      rethrow;
    }
  }

  /// Delete a custom program
  Future<void> deleteProgram(String programId) async {
    try {
      if (!programId.startsWith('custom_')) {
        throw Exception('Cannot delete non-custom program');
      }

      await _getBox.delete(programId);
      debugPrint('CustomProgramService: Deleted program $programId');
    } catch (e) {
      debugPrint('CustomProgramService: Error deleting program: $e');
      rethrow;
    }
  }

  /// Get a custom program by ID
  WorkoutProgram? getProgramById(String programId) {
    try {
      return _getBox.get(programId);
    } catch (e) {
      debugPrint('CustomProgramService: Error getting program: $e');
      return null;
    }
  }

  /// Get all custom programs
  List<WorkoutProgram> getAllCustomPrograms() {
    try {
      return _getBox.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('CustomProgramService: Error getting programs: $e');
      return [];
    }
  }

  /// Check if a program is custom
  bool isCustomProgram(String programId) {
    return programId.startsWith('custom_');
  }

  /// Get programs by difficulty
  List<WorkoutProgram> getProgramsByDifficulty(String difficulty) {
    try {
      return _getBox.values
          .where((p) => p.difficulty.toLowerCase() == difficulty.toLowerCase())
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('CustomProgramService: Error filtering by difficulty: $e');
      return [];
    }
  }

  /// Get programs by goal
  List<WorkoutProgram> getProgramsByGoal(String goal) {
    try {
      return _getBox.values
          .where((p) => p.goals.contains(goal))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('CustomProgramService: Error filtering by goal: $e');
      return [];
    }
  }

  /// Export custom programs for backup
  Map<String, dynamic> exportCustomPrograms() {
    try {
      final programs = getAllCustomPrograms();
      return {
        'programs': programs.map((p) => p.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'count': programs.length,
      };
    } catch (e) {
      debugPrint('CustomProgramService: Error exporting: $e');
      return {
        'programs': [],
        'exportDate': DateTime.now().toIso8601String(),
        'count': 0
      };
    }
  }

  /// Import custom programs from backup
  Future<void> importCustomPrograms(
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      if (!merge) {
        await _getBox.clear();
      }

      final programsList = data['programs'] as List;
      for (final programJson in programsList) {
        final program =
            WorkoutProgram.fromJson(programJson as Map<String, dynamic>);

        // Ensure it has custom prefix and is not built-in
        if (!program.id.startsWith('custom_')) {
          final customProgram = program.copyWith(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            isBuiltIn: false,
            createdAt: DateTime.now(),
          );
          await _getBox.put(customProgram.id, customProgram);
        } else {
          if (merge) {
            final existing = _getBox.get(program.id);
            if (existing == null) {
              await _getBox.put(program.id, program);
            }
          } else {
            await _getBox.put(program.id, program);
          }
        }
      }

      debugPrint(
          'CustomProgramService: Imported ${programsList.length} programs');
    } catch (e) {
      debugPrint('CustomProgramService: Error importing: $e');
      rethrow;
    }
  }

  /// Create a blank program template
  WorkoutProgram createBlankProgram() {
    return WorkoutProgram(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      name: 'New Program',
      description: 'Custom workout program',
      difficulty: 'Intermediate',
      durationWeeks: 4,
      daysPerWeek: 3,
      goals: ['Strength'],
      weeks: List.generate(
        4,
        (weekIndex) => ProgramWeek(
          weekNumber: weekIndex + 1,
          days: List.generate(
            3,
            (dayIndex) => ProgramDay(
              dayNumber: dayIndex + 1,
              dayName: 'Day ${dayIndex + 1}',
              exercises: [],
              isRestDay: false,
            ),
          ),
        ),
      ),
      author: 'You',
      tags: ['Custom'],
      isBuiltIn: false,
      createdAt: DateTime.now(),
    );
  }
}
