import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_program.dart';

/// Service for managing user program enrollments
class ProgramEnrollmentService {
  static final ProgramEnrollmentService _instance =
      ProgramEnrollmentService._internal();
  factory ProgramEnrollmentService() => _instance;
  ProgramEnrollmentService._internal();

  static const String _boxName = 'program_enrollments';
  bool _initialized = false;

  Box<ProgramEnrollment> get _getBox {
    if (!Hive.isBoxOpen(_boxName)) {
      throw Exception('ProgramEnrollmentService: Box not initialized');
    }
    return Hive.box<ProgramEnrollment>(_boxName);
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<ProgramEnrollment>(_boxName);
      }

      _initialized = true;
      debugPrint('ProgramEnrollmentService: Initialized successfully');
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Enroll in a program
  Future<ProgramEnrollment> enrollInProgram(
    String programId,
    String programName,
  ) async {
    try {
      // Check if already enrolled in this program
      final existing = getEnrollmentByProgramId(programId);
      if (existing != null && existing.isActive) {
        throw Exception('Already enrolled in this program');
      }

      // Deactivate any other active enrollments
      final activeEnrollments = getActiveEnrollments();
      for (final enrollment in activeEnrollments) {
        final updated = enrollment.copyWith(isActive: false);
        await _getBox.put(enrollment.id, updated);
      }

      // Create new enrollment
      final enrollment = ProgramEnrollment(
        id: '${programId}_${DateTime.now().millisecondsSinceEpoch}',
        programId: programId,
        programName: programName,
        startDate: DateTime.now(),
      );

      await _getBox.put(enrollment.id, enrollment);
      debugPrint('ProgramEnrollmentService: Enrolled in $programName');

      return enrollment;
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error enrolling: $e');
      rethrow;
    }
  }

  /// Get active enrollment (only one can be active at a time)
  ProgramEnrollment? getActiveEnrollment() {
    try {
      final enrollments = _getBox.values.where((e) => e.isActive).toList();
      return enrollments.isNotEmpty ? enrollments.first : null;
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error getting active enrollment: $e');
      return null;
    }
  }

  /// Get all active enrollments
  List<ProgramEnrollment> getActiveEnrollments() {
    try {
      return _getBox.values.where((e) => e.isActive).toList();
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error getting active enrollments: $e');
      return [];
    }
  }

  /// Get enrollment by program ID
  ProgramEnrollment? getEnrollmentByProgramId(String programId) {
    try {
      final enrollments = _getBox.values
          .where((e) => e.programId == programId && e.isActive)
          .toList();
      return enrollments.isNotEmpty ? enrollments.first : null;
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error getting enrollment: $e');
      return null;
    }
  }

  /// Get all enrollments (including completed)
  List<ProgramEnrollment> getAllEnrollments() {
    try {
      return _getBox.values.toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error getting all enrollments: $e');
      return [];
    }
  }

  /// Mark workout as completed
  Future<void> completeWorkout(String enrollmentId, int week, int day) async {
    try {
      final enrollment = _getBox.get(enrollmentId);
      if (enrollment == null) return;

      final updatedWorkouts = Map<String, bool>.from(enrollment.completedWorkouts);
      updatedWorkouts[enrollment.getWorkoutKey(week, day)] = true;

      final updated = enrollment.copyWith(
        completedWorkouts: updatedWorkouts,
      );

      await _getBox.put(enrollmentId, updated);
      debugPrint('ProgramEnrollmentService: Workout completed W$week D$day');
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error completing workout: $e');
      rethrow;
    }
  }

  /// Advance to next workout
  Future<void> advanceToNextWorkout(
    String enrollmentId,
    int totalWeeks,
    int daysPerWeek,
  ) async {
    try {
      final enrollment = _getBox.get(enrollmentId);
      if (enrollment == null) return;

      int nextWeek = enrollment.currentWeek;
      int nextDay = enrollment.currentDay + 1;

      // Move to next week if needed
      if (nextDay > daysPerWeek) {
        nextDay = 1;
        nextWeek++;
      }

      // Check if program is completed
      bool isComplete = nextWeek > totalWeeks;

      final updated = enrollment.copyWith(
        currentWeek: nextWeek,
        currentDay: nextDay,
        isActive: !isComplete,
        completedDate: isComplete ? DateTime.now() : null,
      );

      await _getBox.put(enrollmentId, updated);
      debugPrint(
          'ProgramEnrollmentService: Advanced to W$nextWeek D$nextDay');
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error advancing: $e');
      rethrow;
    }
  }

  /// Set current week and day manually
  Future<void> setCurrentPosition(
    String enrollmentId,
    int week,
    int day,
  ) async {
    try {
      final enrollment = _getBox.get(enrollmentId);
      if (enrollment == null) return;

      final updated = enrollment.copyWith(
        currentWeek: week,
        currentDay: day,
      );

      await _getBox.put(enrollmentId, updated);
      debugPrint('ProgramEnrollmentService: Set position to W$week D$day');
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error setting position: $e');
      rethrow;
    }
  }

  /// Complete program
  Future<void> completeProgram(String enrollmentId) async {
    try {
      final enrollment = _getBox.get(enrollmentId);
      if (enrollment == null) return;

      final updated = enrollment.copyWith(
        isActive: false,
        completedDate: DateTime.now(),
      );

      await _getBox.put(enrollmentId, updated);
      debugPrint('ProgramEnrollmentService: Program completed');
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error completing program: $e');
      rethrow;
    }
  }

  /// Quit/abandon program
  Future<void> quitProgram(String enrollmentId) async {
    try {
      final enrollment = _getBox.get(enrollmentId);
      if (enrollment == null) return;

      final updated = enrollment.copyWith(isActive: false);

      await _getBox.put(enrollmentId, updated);
      debugPrint('ProgramEnrollmentService: Program quit');
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error quitting program: $e');
      rethrow;
    }
  }

  /// Delete enrollment
  Future<void> deleteEnrollment(String enrollmentId) async {
    try {
      await _getBox.delete(enrollmentId);
      debugPrint('ProgramEnrollmentService: Enrollment deleted');
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error deleting enrollment: $e');
      rethrow;
    }
  }

  /// Get completion percentage
  double getCompletionPercentage(ProgramEnrollment enrollment, int totalWeeks) {
    final totalWorkouts = enrollment.completedWorkouts.length;
    final weeksPassed = enrollment.currentWeek - 1;

    if (totalWeeks == 0) return 0;

    // Calculate based on current week
    return (weeksPassed / totalWeeks * 100).clamp(0, 100);
  }

  /// Export enrollments for backup
  Map<String, dynamic> exportAllEnrollments() {
    try {
      final enrollments = getAllEnrollments();
      return {
        'enrollments': enrollments.map((e) => e.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'count': enrollments.length,
      };
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error exporting: $e');
      return {
        'enrollments': [],
        'exportDate': DateTime.now().toIso8601String(),
        'count': 0
      };
    }
  }

  /// Import enrollments from backup
  Future<void> importEnrollments(
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      if (!merge) {
        await _getBox.clear();
      }

      final enrollmentsList = data['enrollments'] as List;
      for (final enrollmentJson in enrollmentsList) {
        final enrollment =
            ProgramEnrollment.fromJson(enrollmentJson as Map<String, dynamic>);

        if (merge) {
          final existing = _getBox.get(enrollment.id);
          if (existing == null) {
            await _getBox.put(enrollment.id, enrollment);
          }
        } else {
          await _getBox.put(enrollment.id, enrollment);
        }
      }

      debugPrint(
          'ProgramEnrollmentService: Imported ${enrollmentsList.length} enrollments');
    } catch (e) {
      debugPrint('ProgramEnrollmentService: Error importing: $e');
      rethrow;
    }
  }
}
