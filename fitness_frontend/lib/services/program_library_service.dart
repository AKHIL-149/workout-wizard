import 'package:uuid/uuid.dart';
import '../models/workout_program.dart';
import '../models/workout_template.dart';

/// Service providing pre-built workout programs
class ProgramLibraryService {
  static final ProgramLibraryService _instance =
      ProgramLibraryService._internal();
  factory ProgramLibraryService() => _instance;
  ProgramLibraryService._internal();

  /// Get all built-in programs
  List<WorkoutProgram> getAllPrograms() {
    return [
      _createStrongLifts5x5(),
      _createPPL(),
      _createUpperLower(),
      _createStartingStrength(),
      _createnSuns531(),
    ];
  }

  /// Get program by ID
  WorkoutProgram? getProgramById(String id) {
    try {
      return getAllPrograms().firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Filter programs by difficulty
  List<WorkoutProgram> getProgramsByDifficulty(String difficulty) {
    return getAllPrograms().where((p) => p.difficulty == difficulty).toList();
  }

  /// Filter programs by goal
  List<WorkoutProgram> getProgramsByGoal(String goal) {
    return getAllPrograms().where((p) => p.goals.contains(goal)).toList();
  }

  /// StrongLifts 5x5 Program
  WorkoutProgram _createStrongLifts5x5() {
    return WorkoutProgram(
      id: 'stronglifts_5x5',
      name: 'StrongLifts 5×5',
      description:
          'A simple and effective strength training program for beginners. Workout A and B alternate 3 days per week, focusing on compound lifts with linear progression.',
      difficulty: 'Beginner',
      durationWeeks: 12,
      daysPerWeek: 3,
      goals: ['Strength', 'Muscle Building'],
      author: 'Mehdi Hadim',
      isBuiltIn: true,
      createdAt: DateTime.now(),
      tags: ['Powerlifting', '3-Day', 'Linear', 'Full Body'],
      notes:
          'Add 5lbs to upper body exercises and 10lbs to lower body exercises each workout. Deload by 10% if you fail 3 workouts in a row.',
      weeks: List.generate(
        12,
        (weekIndex) => ProgramWeek(
          weekNumber: weekIndex + 1,
          days: [
            // Workout A (Monday)
            ProgramDay(
              dayNumber: 1,
              dayName: 'Workout A',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 5,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'bench_press',
                  exerciseName: 'Barbell Bench Press',
                  sets: 5,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'barbell_row',
                  exerciseName: 'Barbell Row',
                  sets: 5,
                  targetReps: 5,
                  restSeconds: 120,
                  orderIndex: 2,
                ),
              ],
            ),
            // Rest (Tuesday)
            ProgramDay(
              dayNumber: 2,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            // Workout B (Wednesday)
            ProgramDay(
              dayNumber: 3,
              dayName: 'Workout B',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 5,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'overhead_press',
                  exerciseName: 'Barbell Overhead Press',
                  sets: 5,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'deadlift',
                  exerciseName: 'Barbell Deadlift',
                  sets: 1,
                  targetReps: 5,
                  restSeconds: 240,
                  orderIndex: 2,
                ),
              ],
            ),
            // Rest (Thursday)
            ProgramDay(
              dayNumber: 4,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            // Workout A (Friday)
            ProgramDay(
              dayNumber: 5,
              dayName: 'Workout A',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 5,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'bench_press',
                  exerciseName: 'Barbell Bench Press',
                  sets: 5,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'barbell_row',
                  exerciseName: 'Barbell Row',
                  sets: 5,
                  targetReps: 5,
                  restSeconds: 120,
                  orderIndex: 2,
                ),
              ],
            ),
            // Rest (Weekend)
            ProgramDay(
              dayNumber: 6,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            ProgramDay(
              dayNumber: 7,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Push/Pull/Legs Program
  WorkoutProgram _createPPL() {
    return WorkoutProgram(
      id: 'ppl_6day',
      name: 'Push/Pull/Legs (PPL)',
      description:
          'A 6-day split focusing on push movements (chest, shoulders, triceps), pull movements (back, biceps), and legs. Each muscle group is trained twice per week.',
      difficulty: 'Intermediate',
      durationWeeks: 8,
      daysPerWeek: 6,
      goals: ['Hypertrophy', 'Strength'],
      author: 'Community',
      isBuiltIn: true,
      createdAt: DateTime.now(),
      tags: ['Hypertrophy', '6-Day', 'Volume', 'Split'],
      notes:
          'Focus on progressive overload and maintain proper form. Rest on Sunday or as needed.',
      weeks: List.generate(
        8,
        (weekIndex) => ProgramWeek(
          weekNumber: weekIndex + 1,
          days: [
            // Monday - Push
            ProgramDay(
              dayNumber: 1,
              dayName: 'Push',
              exercises: [
                TemplateExercise(
                  exerciseId: 'bench_press',
                  exerciseName: 'Barbell Bench Press',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 120,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'overhead_press',
                  exerciseName: 'Barbell Overhead Press',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 120,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'incline_db_press',
                  exerciseName: 'Incline Dumbbell Press',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 90,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'lateral_raises',
                  exerciseName: 'Dumbbell Lateral Raises',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 60,
                  orderIndex: 3,
                ),
                TemplateExercise(
                  exerciseId: 'tricep_dips',
                  exerciseName: 'Tricep Dips',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 90,
                  orderIndex: 4,
                ),
              ],
            ),
            // Tuesday - Pull
            ProgramDay(
              dayNumber: 2,
              dayName: 'Pull',
              exercises: [
                TemplateExercise(
                  exerciseId: 'deadlift',
                  exerciseName: 'Barbell Deadlift',
                  sets: 3,
                  targetReps: 6,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'pull_ups',
                  exerciseName: 'Pull-Ups',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 120,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'barbell_row',
                  exerciseName: 'Barbell Row',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 90,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'face_pulls',
                  exerciseName: 'Face Pulls',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 60,
                  orderIndex: 3,
                ),
                TemplateExercise(
                  exerciseId: 'barbell_curl',
                  exerciseName: 'Barbell Bicep Curl',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 60,
                  orderIndex: 4,
                ),
              ],
            ),
            // Wednesday - Legs
            ProgramDay(
              dayNumber: 3,
              dayName: 'Legs',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'romanian_deadlift',
                  exerciseName: 'Romanian Deadlift',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 120,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'leg_press',
                  exerciseName: 'Leg Press',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 90,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'lunges',
                  exerciseName: 'Walking Lunges',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 90,
                  orderIndex: 3,
                ),
                TemplateExercise(
                  exerciseId: 'calf_raises',
                  exerciseName: 'Calf Raises',
                  sets: 4,
                  targetReps: 15,
                  restSeconds: 60,
                  orderIndex: 4,
                ),
              ],
            ),
            // Thursday - Push
            ProgramDay(
              dayNumber: 4,
              dayName: 'Push',
              exercises: [
                TemplateExercise(
                  exerciseId: 'bench_press',
                  exerciseName: 'Barbell Bench Press',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 120,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'overhead_press',
                  exerciseName: 'Barbell Overhead Press',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 120,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'incline_db_press',
                  exerciseName: 'Incline Dumbbell Press',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 90,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'lateral_raises',
                  exerciseName: 'Dumbbell Lateral Raises',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 60,
                  orderIndex: 3,
                ),
                TemplateExercise(
                  exerciseId: 'tricep_dips',
                  exerciseName: 'Tricep Dips',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 90,
                  orderIndex: 4,
                ),
              ],
            ),
            // Friday - Pull
            ProgramDay(
              dayNumber: 5,
              dayName: 'Pull',
              exercises: [
                TemplateExercise(
                  exerciseId: 'deadlift',
                  exerciseName: 'Barbell Deadlift',
                  sets: 3,
                  targetReps: 6,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'pull_ups',
                  exerciseName: 'Pull-Ups',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 120,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'barbell_row',
                  exerciseName: 'Barbell Row',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 90,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'face_pulls',
                  exerciseName: 'Face Pulls',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 60,
                  orderIndex: 3,
                ),
                TemplateExercise(
                  exerciseId: 'barbell_curl',
                  exerciseName: 'Barbell Bicep Curl',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 60,
                  orderIndex: 4,
                ),
              ],
            ),
            // Saturday - Legs
            ProgramDay(
              dayNumber: 6,
              dayName: 'Legs',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'romanian_deadlift',
                  exerciseName: 'Romanian Deadlift',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 120,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'leg_press',
                  exerciseName: 'Leg Press',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 90,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'lunges',
                  exerciseName: 'Walking Lunges',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 90,
                  orderIndex: 3,
                ),
                TemplateExercise(
                  exerciseId: 'calf_raises',
                  exerciseName: 'Calf Raises',
                  sets: 4,
                  targetReps: 15,
                  restSeconds: 60,
                  orderIndex: 4,
                ),
              ],
            ),
            // Sunday - Rest
            ProgramDay(
              dayNumber: 7,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Upper/Lower Split
  WorkoutProgram _createUpperLower() {
    return WorkoutProgram(
      id: 'upper_lower_4day',
      name: 'Upper/Lower Split',
      description:
          'A 4-day split alternating between upper body and lower body workouts. Great for intermediate lifters looking for a balanced approach to strength and hypertrophy.',
      difficulty: 'Intermediate',
      durationWeeks: 8,
      daysPerWeek: 4,
      goals: ['Strength', 'Hypertrophy'],
      author: 'Community',
      isBuiltIn: true,
      createdAt: DateTime.now(),
      tags: ['4-Day', 'Split', 'Balanced'],
      notes:
          'Monday/Thursday: Upper Body, Tuesday/Friday: Lower Body. Adjust days as needed.',
      weeks: List.generate(
        8,
        (weekIndex) => ProgramWeek(
          weekNumber: weekIndex + 1,
          days: [
            // Monday - Upper A
            ProgramDay(
              dayNumber: 1,
              dayName: 'Upper A',
              exercises: [
                TemplateExercise(
                  exerciseId: 'bench_press',
                  exerciseName: 'Barbell Bench Press',
                  sets: 4,
                  targetReps: 6,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'barbell_row',
                  exerciseName: 'Barbell Row',
                  sets: 4,
                  targetReps: 6,
                  restSeconds: 120,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'overhead_press',
                  exerciseName: 'Barbell Overhead Press',
                  sets: 3,
                  targetReps: 8,
                  restSeconds: 120,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'pull_ups',
                  exerciseName: 'Pull-Ups',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 90,
                  orderIndex: 3,
                ),
                TemplateExercise(
                  exerciseId: 'barbell_curl',
                  exerciseName: 'Barbell Bicep Curl',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 60,
                  orderIndex: 4,
                ),
              ],
            ),
            // Tuesday - Lower A
            ProgramDay(
              dayNumber: 2,
              dayName: 'Lower A',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 4,
                  targetReps: 6,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'romanian_deadlift',
                  exerciseName: 'Romanian Deadlift',
                  sets: 3,
                  targetReps: 8,
                  restSeconds: 120,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'leg_press',
                  exerciseName: 'Leg Press',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 90,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'leg_curl',
                  exerciseName: 'Leg Curls',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 60,
                  orderIndex: 3,
                ),
              ],
            ),
            // Wednesday - Rest
            ProgramDay(
              dayNumber: 3,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            // Thursday - Upper B
            ProgramDay(
              dayNumber: 4,
              dayName: 'Upper B',
              exercises: [
                TemplateExercise(
                  exerciseId: 'incline_bench',
                  exerciseName: 'Incline Barbell Bench Press',
                  sets: 4,
                  targetReps: 8,
                  restSeconds: 120,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'lat_pulldown',
                  exerciseName: 'Lat Pulldown',
                  sets: 4,
                  targetReps: 10,
                  restSeconds: 90,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'db_shoulder_press',
                  exerciseName: 'Dumbbell Shoulder Press',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 90,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'cable_row',
                  exerciseName: 'Cable Row',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 60,
                  orderIndex: 3,
                ),
                TemplateExercise(
                  exerciseId: 'tricep_dips',
                  exerciseName: 'Tricep Dips',
                  sets: 3,
                  targetReps: 10,
                  restSeconds: 60,
                  orderIndex: 4,
                ),
              ],
            ),
            // Friday - Lower B
            ProgramDay(
              dayNumber: 5,
              dayName: 'Lower B',
              exercises: [
                TemplateExercise(
                  exerciseId: 'deadlift',
                  exerciseName: 'Barbell Deadlift',
                  sets: 3,
                  targetReps: 5,
                  restSeconds: 240,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'front_squat',
                  exerciseName: 'Front Squat',
                  sets: 3,
                  targetReps: 8,
                  restSeconds: 180,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'lunges',
                  exerciseName: 'Walking Lunges',
                  sets: 3,
                  targetReps: 12,
                  restSeconds: 90,
                  orderIndex: 2,
                ),
                TemplateExercise(
                  exerciseId: 'calf_raises',
                  exerciseName: 'Calf Raises',
                  sets: 4,
                  targetReps: 15,
                  restSeconds: 60,
                  orderIndex: 3,
                ),
              ],
            ),
            // Weekend - Rest
            ProgramDay(
              dayNumber: 6,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            ProgramDay(
              dayNumber: 7,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Starting Strength
  WorkoutProgram _createStartingStrength() {
    return WorkoutProgram(
      id: 'starting_strength',
      name: 'Starting Strength',
      description:
          'Mark Rippetoe\'s classic strength program focusing on the main compound lifts. Simple, effective linear progression for beginners.',
      difficulty: 'Beginner',
      durationWeeks: 12,
      daysPerWeek: 3,
      goals: ['Strength'],
      author: 'Mark Rippetoe',
      isBuiltIn: true,
      createdAt: DateTime.now(),
      tags: ['Powerlifting', '3-Day', 'Linear', 'Beginner'],
      notes:
          'Add 5-10lbs each workout. Focus on perfect form before increasing weight.',
      weeks: List.generate(12, (weekIndex) {
        return ProgramWeek(
          weekNumber: weekIndex + 1,
          days: [
            // Monday - Workout A
            ProgramDay(
              dayNumber: 1,
              dayName: 'Workout A',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 3,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'bench_press',
                  exerciseName: 'Barbell Bench Press',
                  sets: 3,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'deadlift',
                  exerciseName: 'Barbell Deadlift',
                  sets: 1,
                  targetReps: 5,
                  restSeconds: 240,
                  orderIndex: 2,
                ),
              ],
            ),
            ProgramDay(
              dayNumber: 2,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            // Wednesday - Workout B
            ProgramDay(
              dayNumber: 3,
              dayName: 'Workout B',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 3,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'overhead_press',
                  exerciseName: 'Barbell Overhead Press',
                  sets: 3,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'power_clean',
                  exerciseName: 'Power Clean',
                  sets: 5,
                  targetReps: 3,
                  restSeconds: 180,
                  orderIndex: 2,
                ),
              ],
            ),
            ProgramDay(
              dayNumber: 4,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            // Friday - Workout A
            ProgramDay(
              dayNumber: 5,
              dayName: 'Workout A',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 3,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'bench_press',
                  exerciseName: 'Barbell Bench Press',
                  sets: 3,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 1,
                ),
                TemplateExercise(
                  exerciseId: 'deadlift',
                  exerciseName: 'Barbell Deadlift',
                  sets: 1,
                  targetReps: 5,
                  restSeconds: 240,
                  orderIndex: 2,
                ),
              ],
            ),
            ProgramDay(
              dayNumber: 6,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            ProgramDay(
              dayNumber: 7,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
          ],
        );
      }),
    );
  }

  /// nSuns 5/3/1
  WorkoutProgram _createnSuns531() {
    return WorkoutProgram(
      id: 'nsuns_531',
      name: 'nSuns 5/3/1',
      description:
          'A high-volume powerlifting program based on Wendler\'s 5/3/1. Features progressive overload with AMRAP (As Many Reps As Possible) sets.',
      difficulty: 'Advanced',
      durationWeeks: 8,
      daysPerWeek: 4,
      goals: ['Strength', 'Powerlifting'],
      author: 'nSuns',
      isBuiltIn: true,
      createdAt: DateTime.now(),
      tags: ['Powerlifting', '4-Day', 'Volume', 'Advanced'],
      notes:
          'Adjust training maxes based on AMRAP performance. This is a high-volume program - ensure adequate recovery.',
      weeks: List.generate(8, (weekIndex) {
        return ProgramWeek(
          weekNumber: weekIndex + 1,
          weekName: weekIndex % 4 == 3 ? 'Deload Week' : null,
          days: [
            // Monday - Bench/OHP Focus
            ProgramDay(
              dayNumber: 1,
              dayName: 'Bench/OHP Day',
              exercises: [
                TemplateExercise(
                  exerciseId: 'bench_press',
                  exerciseName: 'Barbell Bench Press',
                  sets: 9,
                  targetReps: 5,
                  restSeconds: 120,
                  notes: '9 sets with varying percentages',
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'overhead_press',
                  exerciseName: 'Barbell Overhead Press',
                  sets: 8,
                  targetReps: 5,
                  restSeconds: 90,
                  notes: '8 sets with varying percentages',
                  orderIndex: 1,
                ),
              ],
            ),
            // Tuesday - Squat Focus
            ProgramDay(
              dayNumber: 2,
              dayName: 'Squat Day',
              exercises: [
                TemplateExercise(
                  exerciseId: 'squat',
                  exerciseName: 'Barbell Back Squat',
                  sets: 9,
                  targetReps: 5,
                  restSeconds: 180,
                  notes: '9 sets with varying percentages',
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'front_squat',
                  exerciseName: 'Front Squat',
                  sets: 8,
                  targetReps: 5,
                  restSeconds: 120,
                  orderIndex: 1,
                ),
              ],
            ),
            ProgramDay(
              dayNumber: 3,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            // Thursday - OHP/Bench Focus
            ProgramDay(
              dayNumber: 4,
              dayName: 'OHP/Bench Day',
              exercises: [
                TemplateExercise(
                  exerciseId: 'overhead_press',
                  exerciseName: 'Barbell Overhead Press',
                  sets: 9,
                  targetReps: 5,
                  restSeconds: 120,
                  notes: '9 sets with varying percentages',
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'incline_bench',
                  exerciseName: 'Incline Barbell Bench Press',
                  sets: 8,
                  targetReps: 5,
                  restSeconds: 90,
                  orderIndex: 1,
                ),
              ],
            ),
            // Friday - Deadlift Focus
            ProgramDay(
              dayNumber: 5,
              dayName: 'Deadlift Day',
              exercises: [
                TemplateExercise(
                  exerciseId: 'deadlift',
                  exerciseName: 'Barbell Deadlift',
                  sets: 9,
                  targetReps: 5,
                  restSeconds: 240,
                  notes: '9 sets with varying percentages',
                  orderIndex: 0,
                ),
                TemplateExercise(
                  exerciseId: 'front_squat',
                  exerciseName: 'Front Squat',
                  sets: 8,
                  targetReps: 5,
                  restSeconds: 180,
                  orderIndex: 1,
                ),
              ],
            ),
            ProgramDay(
              dayNumber: 6,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
            ProgramDay(
              dayNumber: 7,
              dayName: 'Rest',
              exercises: [],
              isRestDay: true,
            ),
          ],
        );
      }),
    );
  }
}
