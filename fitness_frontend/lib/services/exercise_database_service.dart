import '../models/exercise_database_item.dart';

/// Service for managing the exercise database
class ExerciseDatabaseService {
  static final ExerciseDatabaseService _instance =
      ExerciseDatabaseService._internal();
  factory ExerciseDatabaseService() => _instance;
  ExerciseDatabaseService._internal();

  // Static exercise database (would typically be loaded from JSON/API)
  final List<ExerciseDatabaseItem> _exercises = [
    // Chest Exercises
    ExerciseDatabaseItem(
      id: 'bench_press',
      name: 'Barbell Bench Press',
      category: 'Chest',
      primaryMuscles: ['Pectorals'],
      secondaryMuscles: ['Triceps', 'Anterior Deltoids'],
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      description:
          'The bench press is a compound exercise that primarily targets the chest muscles while also engaging the triceps and shoulders.',
      instructions: [
        'Lie flat on a bench with your feet firmly on the ground',
        'Grip the barbell slightly wider than shoulder-width',
        'Unrack the bar and position it above your chest',
        'Lower the bar to your mid-chest in a controlled manner',
        'Press the bar back up to the starting position',
        'Maintain a slight arch in your lower back throughout',
      ],
      tips: [
        'Keep your shoulder blades retracted throughout the movement',
        'Drive through your feet to create leg drive',
        'Touch the bar to your chest without bouncing',
        'Breathe in on the descent, breathe out on the press',
      ],
      commonMistakes: [
        'Flaring elbows out too wide (45-degree angle is optimal)',
        'Bouncing the bar off the chest',
        'Lifting hips off the bench',
        'Not using a full range of motion',
      ],
    ),
    ExerciseDatabaseItem(
      id: 'push_ups',
      name: 'Push-Ups',
      category: 'Chest',
      primaryMuscles: ['Pectorals'],
      secondaryMuscles: ['Triceps', 'Anterior Deltoids', 'Core'],
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      description:
          'A fundamental bodyweight exercise that builds upper body strength and core stability.',
      instructions: [
        'Start in a plank position with hands shoulder-width apart',
        'Keep your body in a straight line from head to heels',
        'Lower your body until your chest nearly touches the ground',
        'Push back up to the starting position',
        'Maintain core engagement throughout',
      ],
      tips: [
        'Keep elbows at a 45-degree angle from your body',
        'Engage your core to prevent sagging hips',
        'Look slightly ahead, not straight down',
        'Full range of motion is important',
      ],
      commonMistakes: [
        'Sagging hips or raising them too high',
        'Flaring elbows out to 90 degrees',
        'Not going low enough',
        'Holding your breath',
      ],
    ),

    // Back Exercises
    ExerciseDatabaseItem(
      id: 'deadlift',
      name: 'Barbell Deadlift',
      category: 'Back',
      primaryMuscles: ['Lower Back', 'Glutes', 'Hamstrings'],
      secondaryMuscles: ['Traps', 'Lats', 'Forearms', 'Core'],
      equipment: 'Barbell',
      difficulty: 'Advanced',
      description:
          'The king of compound exercises, the deadlift works nearly every muscle in your body and builds tremendous overall strength.',
      instructions: [
        'Stand with feet hip-width apart, barbell over mid-foot',
        'Bend down and grip the bar just outside your legs',
        'Keep chest up, back straight, and core braced',
        'Drive through your heels to lift the bar',
        'Extend hips and knees simultaneously',
        'Lower the bar back down with control',
      ],
      tips: [
        'Keep the bar close to your body throughout',
        'Maintain a neutral spine - no rounding',
        'Lead with your chest on the way up',
        'Lock out by squeezing glutes at the top',
      ],
      commonMistakes: [
        'Rounding the lower back',
        'Starting with hips too low or too high',
        'Bar drifting away from the body',
        'Hyperextending at the top',
      ],
    ),
    ExerciseDatabaseItem(
      id: 'pull_ups',
      name: 'Pull-Ups',
      category: 'Back',
      primaryMuscles: ['Lats', 'Upper Back'],
      secondaryMuscles: ['Biceps', 'Rear Deltoids', 'Core'],
      equipment: 'Pull-up Bar',
      difficulty: 'Intermediate',
      description:
          'A challenging upper body exercise that builds back width and strength.',
      instructions: [
        'Hang from a pull-up bar with palms facing away',
        'Grip slightly wider than shoulder-width',
        'Pull yourself up until chin is above the bar',
        'Lower yourself back down with control',
        'Maintain core engagement throughout',
      ],
      tips: [
        'Start from a dead hang position',
        'Think about pulling elbows down rather than just pulling up',
        'Avoid excessive swinging',
        'Engage lats before initiating the pull',
      ],
      commonMistakes: [
        'Using momentum or kipping',
        'Not achieving full range of motion',
        'Shrugging shoulders at the top',
        'Flaring elbows out excessively',
      ],
    ),

    // Leg Exercises
    ExerciseDatabaseItem(
      id: 'squat',
      name: 'Barbell Back Squat',
      category: 'Legs',
      primaryMuscles: ['Quadriceps', 'Glutes'],
      secondaryMuscles: ['Hamstrings', 'Core', 'Lower Back'],
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      description:
          'The squat is a fundamental compound movement that builds lower body strength and size.',
      instructions: [
        'Position the bar on your upper back/traps',
        'Stand with feet shoulder-width apart, toes slightly out',
        'Brace your core and maintain an upright chest',
        'Descend by breaking at hips and knees simultaneously',
        'Lower until thighs are at least parallel to ground',
        'Drive through heels to return to starting position',
      ],
      tips: [
        'Keep knees tracking over toes',
        'Maintain a neutral spine throughout',
        'Drive knees out to activate glutes',
        'Take a deep breath and brace before each rep',
      ],
      commonMistakes: [
        'Knees caving inward',
        'Heels lifting off the ground',
        'Leaning too far forward',
        'Not squatting deep enough',
      ],
    ),
    ExerciseDatabaseItem(
      id: 'lunges',
      name: 'Walking Lunges',
      category: 'Legs',
      primaryMuscles: ['Quadriceps', 'Glutes'],
      secondaryMuscles: ['Hamstrings', 'Calves', 'Core'],
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      description:
          'A unilateral leg exercise that improves balance, coordination, and leg strength.',
      instructions: [
        'Stand upright holding dumbbells at your sides',
        'Step forward with one leg',
        'Lower your hips until both knees are at 90 degrees',
        'Push through front heel to step forward with the other leg',
        'Alternate legs as you walk forward',
      ],
      tips: [
        'Keep torso upright throughout the movement',
        'Take a long enough step to avoid knee stress',
        'Back knee should hover just above the ground',
        'Engage core for stability',
      ],
      commonMistakes: [
        'Taking too short of a step',
        'Letting front knee go past toes',
        'Leaning too far forward',
        'Not lowering deep enough',
      ],
    ),

    // Shoulder Exercises
    ExerciseDatabaseItem(
      id: 'overhead_press',
      name: 'Barbell Overhead Press',
      category: 'Shoulders',
      primaryMuscles: ['Anterior Deltoids', 'Medial Deltoids'],
      secondaryMuscles: ['Triceps', 'Upper Chest', 'Core'],
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      description:
          'A fundamental pressing movement that builds shoulder strength and size.',
      instructions: [
        'Stand with feet shoulder-width apart',
        'Hold bar at shoulder height with hands just outside shoulders',
        'Brace core and squeeze glutes',
        'Press bar straight overhead',
        'Lock out arms at the top',
        'Lower bar back to shoulders with control',
      ],
      tips: [
        'Tuck chin slightly as bar passes face',
        'Keep elbows slightly in front of bar',
        'Maintain tight core throughout',
        'Bar path should be vertical',
      ],
      commonMistakes: [
        'Leaning back excessively',
        'Pressing bar forward instead of straight up',
        'Not achieving full lockout',
        'Flaring ribs out',
      ],
    ),
    ExerciseDatabaseItem(
      id: 'lateral_raises',
      name: 'Dumbbell Lateral Raises',
      category: 'Shoulders',
      primaryMuscles: ['Medial Deltoids'],
      secondaryMuscles: ['Anterior Deltoids', 'Traps'],
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      description:
          'An isolation exercise that targets the side delts for shoulder width.',
      instructions: [
        'Stand with dumbbells at your sides',
        'Keep a slight bend in elbows',
        'Raise arms out to the sides',
        'Lift until arms are parallel to ground',
        'Lower back down with control',
      ],
      tips: [
        'Lead with elbows, not hands',
        'Use lighter weight with strict form',
        'Avoid swinging or using momentum',
        'Slight forward lean can help target side delts',
      ],
      commonMistakes: [
        'Using too much weight',
        'Raising arms too high',
        'Bending elbows excessively',
        'Shrugging shoulders',
      ],
    ),

    // Arm Exercises
    ExerciseDatabaseItem(
      id: 'barbell_curl',
      name: 'Barbell Bicep Curl',
      category: 'Arms',
      primaryMuscles: ['Biceps'],
      secondaryMuscles: ['Forearms'],
      equipment: 'Barbell',
      difficulty: 'Beginner',
      description: 'A classic bicep building exercise for arm size and strength.',
      instructions: [
        'Stand holding a barbell with underhand grip',
        'Keep elbows close to your sides',
        'Curl the bar up toward your shoulders',
        'Squeeze biceps at the top',
        'Lower the bar back down with control',
      ],
      tips: [
        'Keep elbows stationary throughout',
        'Avoid swinging or using momentum',
        'Full range of motion is important',
        'Control the eccentric (lowering) phase',
      ],
      commonMistakes: [
        'Swinging the weight up',
        'Moving elbows forward',
        'Not fully extending arms at bottom',
        'Using too much weight',
      ],
    ),
    ExerciseDatabaseItem(
      id: 'tricep_dips',
      name: 'Tricep Dips',
      category: 'Arms',
      primaryMuscles: ['Triceps'],
      secondaryMuscles: ['Chest', 'Anterior Deltoids'],
      equipment: 'Parallel Bars',
      difficulty: 'Intermediate',
      description:
          'A bodyweight exercise that effectively targets the triceps.',
      instructions: [
        'Position yourself on parallel bars with arms extended',
        'Keep body upright with slight forward lean',
        'Lower yourself by bending elbows',
        'Descend until elbows are at 90 degrees',
        'Press back up to starting position',
      ],
      tips: [
        'Keep elbows tucked in, not flared out',
        'Maintain upright torso for tricep focus',
        'Engage core throughout movement',
        'Use full range of motion',
      ],
      commonMistakes: [
        'Leaning too far forward (shifts to chest)',
        'Not going deep enough',
        'Flaring elbows out',
        'Using momentum',
      ],
    ),
  ];

  /// Get all exercises
  List<ExerciseDatabaseItem> getAllExercises() => _exercises;

  /// Get exercise by ID
  ExerciseDatabaseItem? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search exercises by name or muscle
  List<ExerciseDatabaseItem> searchExercises(String query) {
    if (query.isEmpty) return _exercises;

    final lowerQuery = query.toLowerCase();
    return _exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(lowerQuery) ||
          exercise.category.toLowerCase().contains(lowerQuery) ||
          exercise.equipment.toLowerCase().contains(lowerQuery) ||
          exercise.primaryMuscles
              .any((muscle) => muscle.toLowerCase().contains(lowerQuery)) ||
          exercise.secondaryMuscles
              .any((muscle) => muscle.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Filter exercises by category
  List<ExerciseDatabaseItem> getExercisesByCategory(String category) {
    return _exercises.where((e) => e.category == category).toList();
  }

  /// Filter exercises by equipment
  List<ExerciseDatabaseItem> getExercisesByEquipment(String equipment) {
    return _exercises.where((e) => e.equipment == equipment).toList();
  }

  /// Filter exercises by difficulty
  List<ExerciseDatabaseItem> getExercisesByDifficulty(String difficulty) {
    return _exercises.where((e) => e.difficulty == difficulty).toList();
  }

  /// Filter exercises by muscle group
  List<ExerciseDatabaseItem> getExercisesByMuscle(String muscle) {
    return _exercises.where((exercise) {
      return exercise.primaryMuscles.contains(muscle) ||
          exercise.secondaryMuscles.contains(muscle);
    }).toList();
  }

  /// Get all unique categories
  List<String> getAllCategories() {
    return _exercises.map((e) => e.category).toSet().toList()..sort();
  }

  /// Get all unique equipment types
  List<String> getAllEquipment() {
    return _exercises.map((e) => e.equipment).toSet().toList()..sort();
  }

  /// Get all unique muscle groups
  List<String> getAllMuscles() {
    final muscles = <String>{};
    for (final exercise in _exercises) {
      muscles.addAll(exercise.primaryMuscles);
      muscles.addAll(exercise.secondaryMuscles);
    }
    return muscles.toList()..sort();
  }

  /// Get difficulty levels
  List<String> getDifficultyLevels() {
    return ['Beginner', 'Intermediate', 'Advanced'];
  }
}
