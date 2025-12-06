import 'dart:math';
import '../models/exercise.dart';
import '../models/workout_day.dart';
import '../models/recommendation.dart';
import 'exercise_parser_service.dart' show ExerciseParserService, ParsedExercise, VolumeGuidelines;

/// Service to generate workout days with phase-based progression
class WorkoutDayGenerator {
  static final WorkoutDayGenerator _instance =
      WorkoutDayGenerator._internal();
  factory WorkoutDayGenerator() => _instance;
  WorkoutDayGenerator._internal();

  final ExerciseParserService _parser = ExerciseParserService();

  /// Generate workout day for a specific day number
  Future<WorkoutDay> generateWorkoutDay({
    required Recommendation program,
    required int dayNumber,
    required String dayName,
    int? weekNumber,
  }) async {
    final week = weekNumber ?? 1;
    final phase = getPhaseForWeek(week, program.programLength);

    // Parse exercises from markdown
    final parsed = _parser.parseExerciseGuidance(program.exerciseGuidance);

    // Organize by day type
    final byDay = _parser.organizeByDayType(parsed);

    // Get exercises for this specific day type
    var exercisesForDay = byDay[dayName] ?? [];

    // If no exercises found, generate fallback
    if (exercisesForDay.isEmpty) {
      exercisesForDay =
          _parser.generateFallbackExercises(dayName, program.equipment);
    }

    // Extract volume guidelines
    final guidelines = _parser.extractVolumeGuidelines(program.exerciseGuidance);

    // Convert parsed exercises to Exercise objects
    final exercises = _convertParsedExercises(exercisesForDay, guidelines);

    // Apply phase-based progression
    final progressedExercises = exercises
        .map((e) => applyPhaseProgression(e, phase))
        .toList();

    return WorkoutDay(
      dayNumber: dayNumber,
      dayName: dayName,
      phase: phase,
      weekNumber: week,
      duration: program.timePerWorkout,
      exercises: progressedExercises,
    );
  }

  /// Convert ParsedExercise to Exercise with volume guidelines
  List<Exercise> _convertParsedExercises(
    List<ParsedExercise> parsedExercises,
    VolumeGuidelines guidelines,
  ) {
    return parsedExercises.map((parsed) {
      // Generate a simple ID
      final id = '${parsed.name.toLowerCase().replaceAll(' ', '_')}_${Random().nextInt(10000)}';

      return Exercise(
        id: id,
        name: parsed.name,
        primaryMuscle: parsed.muscleGroup ?? 'Unknown',
        secondaryMuscles: [],
        equipment: _inferEquipment(parsed.name),
        movementType: parsed.movementType,
        difficulty: 'Intermediate',
        minSets: guidelines.minSets,
        maxSets: guidelines.maxSets,
        minReps: guidelines.minReps,
        maxReps: guidelines.maxReps,
        restSeconds: guidelines.restSeconds,
      );
    }).toList();
  }

  /// Infer equipment from exercise name
  String _inferEquipment(String exerciseName) {
    final nameLower = exerciseName.toLowerCase();

    if (nameLower.contains('barbell')) return 'Barbell';
    if (nameLower.contains('dumbbell')) return 'Dumbbells';
    if (nameLower.contains('cable')) return 'Cable Machine';
    if (nameLower.contains('machine')) return 'Machine';
    if (nameLower.contains('bodyweight') ||
        nameLower.contains('pull-up') ||
        nameLower.contains('push-up') ||
        nameLower.contains('dip')) {
      return 'Bodyweight';
    }

    return 'Various';
  }

  /// Apply phase-based progression to exercise volume
  Exercise applyPhaseProgression(Exercise exercise, String phase) {
    switch (phase) {
      case 'Foundation':
        // Higher reps, same sets (hypertrophy focus, learning phase)
        return exercise.copyWith(
          minReps: min(exercise.minReps + 3, 20),
          maxReps: min(exercise.maxReps + 3, 20),
          restSeconds: max(exercise.restSeconds - 15, 60),
        );

      case 'Growth':
        // Standard hypertrophy range
        return exercise; // Use base values

      case 'Peak':
        // Higher sets, lower reps (strength focus)
        return exercise.copyWith(
          minSets: min(exercise.minSets + 1, 6),
          maxSets: min(exercise.maxSets + 1, 6),
          minReps: max(exercise.minReps - 2, 4),
          maxReps: max(exercise.maxReps - 2, 6),
          restSeconds: min(exercise.restSeconds + 30, 180),
        );

      default:
        return exercise;
    }
  }

  /// Get phase for a given week number
  String getPhaseForWeek(int weekNumber, int totalWeeks) {
    // Divide program into thirds
    final phaseLength = (totalWeeks / 3).ceil();

    if (weekNumber <= phaseLength) {
      return 'Foundation';
    } else if (weekNumber <= phaseLength * 2) {
      return 'Growth';
    } else {
      return 'Peak';
    }
  }

  /// Get phase description
  String getPhaseDescription(String phase) {
    switch (phase) {
      case 'Foundation':
        return 'Building strength base with higher reps and controlled rest periods';
      case 'Growth':
        return 'Maximizing muscle growth with optimal volume and intensity';
      case 'Peak':
        return 'Strength and power development with heavier loads and longer rest';
      default:
        return 'Balanced training approach';
    }
  }

  /// Get week range for a phase
  String getPhaseWeekRange(String phase, int totalWeeks) {
    final phaseLength = (totalWeeks / 3).ceil();

    switch (phase) {
      case 'Foundation':
        return 'Weeks 1-$phaseLength';
      case 'Growth':
        final start = phaseLength + 1;
        final end = phaseLength * 2;
        return 'Weeks $start-$end';
      case 'Peak':
        final start = phaseLength * 2 + 1;
        return 'Weeks $start-$totalWeeks';
      default:
        return '';
    }
  }
}
