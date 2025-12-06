/// Represents an exercise parsed from markdown
class ParsedExercise {
  final String name;
  final String? muscleGroup;
  final String movementType;
  final String dayType;

  const ParsedExercise({
    required this.name,
    this.muscleGroup,
    required this.movementType,
    required this.dayType,
  });
}

/// Volume guidelines extracted from markdown
class VolumeGuidelines {
  final int minSets;
  final int maxSets;
  final int minReps;
  final int maxReps;
  final int restSeconds;

  const VolumeGuidelines({
    required this.minSets,
    required this.maxSets,
    required this.minReps,
    required this.maxReps,
    required this.restSeconds,
  });

  /// Default guidelines when none can be parsed
  factory VolumeGuidelines.defaultGuidelines() {
    return const VolumeGuidelines(
      minSets: 3,
      maxSets: 5,
      minReps: 6,
      maxReps: 12,
      restSeconds: 90,
    );
  }
}

/// Service to parse exercise guidance from markdown text
class ExerciseParserService {
  static final ExerciseParserService _instance =
      ExerciseParserService._internal();
  factory ExerciseParserService() => _instance;
  ExerciseParserService._internal();

  /// Parse markdown to extract exercises
  List<ParsedExercise> parseExerciseGuidance(String markdownText) {
    final exercises = <ParsedExercise>[];
    final lines = markdownText.split('\n');

    String? currentDayType;
    String? currentMovementType;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Detect day type from #### headers
      if (line.startsWith('#### ')) {
        final header = line.substring(5).trim();
        if (header.contains('Day')) {
          currentDayType = header;
          currentMovementType = null;
        }
      }
      // Detect movement type from ** bold **
      else if (line.startsWith('**') && line.endsWith('**')) {
        final text = line.substring(2, line.length - 2).toLowerCase();
        if (text.contains('compound')) {
          currentMovementType = 'Compound';
        } else if (text.contains('isolation')) {
          currentMovementType = 'Isolation';
        }
      }
      // Parse exercise from list item
      else if ((line.startsWith('- ') || line.startsWith('* ')) &&
          currentDayType != null &&
          currentMovementType != null) {
        final exerciseLine = line.substring(2).trim();
        final muscleGroup = extractMuscleGroup(exerciseLine);
        final exerciseName = _cleanExerciseName(exerciseLine);

        if (exerciseName.isNotEmpty) {
          exercises.add(ParsedExercise(
            name: exerciseName,
            muscleGroup: muscleGroup,
            movementType: currentMovementType,
            dayType: currentDayType,
          ));
        }
      }
    }

    return exercises;
  }

  /// Organize exercises by day type
  Map<String, List<ParsedExercise>> organizeByDayType(
      List<ParsedExercise> exercises) {
    final organized = <String, List<ParsedExercise>>{};

    for (final exercise in exercises) {
      if (!organized.containsKey(exercise.dayType)) {
        organized[exercise.dayType] = [];
      }
      organized[exercise.dayType]!.add(exercise);
    }

    return organized;
  }

  /// Extract volume guidelines from markdown
  VolumeGuidelines extractVolumeGuidelines(String markdownText) {
    final lines = markdownText.split('\n');

    int? minSets;
    int? maxSets;
    int? minReps;
    int? maxReps;
    int? restSeconds;

    for (var line in lines) {
      line = line.trim().toLowerCase();

      // Parse sets
      if (line.contains('sets per exercise') || line.contains('sets:')) {
        final setMatch = RegExp(r'(\d+)-(\d+)').firstMatch(line);
        if (setMatch != null) {
          minSets = int.tryParse(setMatch.group(1)!);
          maxSets = int.tryParse(setMatch.group(2)!);
        } else {
          final singleMatch = RegExp(r'(\d+)\s*sets').firstMatch(line);
          if (singleMatch != null) {
            minSets = maxSets = int.tryParse(singleMatch.group(1)!);
          }
        }
      }

      // Parse reps
      if (line.contains('repetition range') || line.contains('reps:')) {
        final repsMatch = RegExp(r'(\d+)-(\d+)').firstMatch(line);
        if (repsMatch != null) {
          minReps = int.tryParse(repsMatch.group(1)!);
          maxReps = int.tryParse(repsMatch.group(2)!);
        }
      }

      // Parse rest
      if (line.contains('rest between sets') || line.contains('rest:')) {
        final restMatch = RegExp(r'(\d+)-(\d+)\s*seconds').firstMatch(line);
        if (restMatch != null) {
          final rest1 = int.tryParse(restMatch.group(1)!);
          final rest2 = int.tryParse(restMatch.group(2)!);
          if (rest1 != null && rest2 != null) {
            restSeconds = ((rest1 + rest2) / 2).round();
          }
        }
      }
    }

    return VolumeGuidelines(
      minSets: minSets ?? 3,
      maxSets: maxSets ?? 5,
      minReps: minReps ?? 6,
      maxReps: maxReps ?? 12,
      restSeconds: restSeconds ?? 90,
    );
  }

  /// Extract muscle group from parentheses
  String? extractMuscleGroup(String exerciseLine) {
    final muscleMatch = RegExp(r'\(([^)]+)\)').firstMatch(exerciseLine);
    return muscleMatch?.group(1)?.trim();
  }

  /// Detect movement type from exercise name
  String detectMovementType(String exerciseName) {
    final compoundKeywords = [
      'squat',
      'deadlift',
      'press',
      'row',
      'pull-up',
      'chin-up',
      'dip',
      'lunge',
      'clean',
      'snatch'
    ];

    final nameLower = exerciseName.toLowerCase();

    for (final keyword in compoundKeywords) {
      if (nameLower.contains(keyword)) {
        return 'Compound';
      }
    }

    return 'Isolation';
  }

  /// Clean exercise name by removing muscle group and extra text
  String _cleanExerciseName(String exerciseLine) {
    // Remove muscle group in parentheses
    var name = exerciseLine.replaceAll(RegExp(r'\s*\([^)]*\)'), '');

    // Remove any trailing colons or dashes
    name = name.replaceAll(RegExp(r'[:–-]\s*$'), '');

    return name.trim();
  }

  /// Generate fallback exercises when parsing fails
  List<ParsedExercise> generateFallbackExercises(
      String dayType, String equipment) {
    // Simple fallback based on day type
    final exercises = <ParsedExercise>[];

    if (dayType.toLowerCase().contains('push') ||
        dayType.toLowerCase().contains('upper')) {
      exercises.addAll([
        const ParsedExercise(
          name: 'Barbell Bench Press',
          muscleGroup: 'Chest',
          movementType: 'Compound',
          dayType: 'Push Day',
        ),
        const ParsedExercise(
          name: 'Dumbbell Shoulder Press',
          muscleGroup: 'Shoulders',
          movementType: 'Compound',
          dayType: 'Push Day',
        ),
        const ParsedExercise(
          name: 'Cable Flyes',
          muscleGroup: 'Chest',
          movementType: 'Isolation',
          dayType: 'Push Day',
        ),
        const ParsedExercise(
          name: 'Lateral Raises',
          muscleGroup: 'Shoulders',
          movementType: 'Isolation',
          dayType: 'Push Day',
        ),
      ]);
    } else if (dayType.toLowerCase().contains('pull') ||
        dayType.toLowerCase().contains('back')) {
      exercises.addAll([
        const ParsedExercise(
          name: 'Pull-ups',
          muscleGroup: 'Back',
          movementType: 'Compound',
          dayType: 'Pull Day',
        ),
        const ParsedExercise(
          name: 'Barbell Rows',
          muscleGroup: 'Back',
          movementType: 'Compound',
          dayType: 'Pull Day',
        ),
        const ParsedExercise(
          name: 'Face Pulls',
          muscleGroup: 'Rear Delts',
          movementType: 'Isolation',
          dayType: 'Pull Day',
        ),
        const ParsedExercise(
          name: 'Bicep Curls',
          muscleGroup: 'Biceps',
          movementType: 'Isolation',
          dayType: 'Pull Day',
        ),
      ]);
    } else if (dayType.toLowerCase().contains('leg') ||
        dayType.toLowerCase().contains('lower')) {
      exercises.addAll([
        const ParsedExercise(
          name: 'Barbell Squats',
          muscleGroup: 'Quads',
          movementType: 'Compound',
          dayType: 'Leg Day',
        ),
        const ParsedExercise(
          name: 'Romanian Deadlifts',
          muscleGroup: 'Hamstrings',
          movementType: 'Compound',
          dayType: 'Leg Day',
        ),
        const ParsedExercise(
          name: 'Leg Extensions',
          muscleGroup: 'Quads',
          movementType: 'Isolation',
          dayType: 'Leg Day',
        ),
        const ParsedExercise(
          name: 'Leg Curls',
          muscleGroup: 'Hamstrings',
          movementType: 'Isolation',
          dayType: 'Leg Day',
        ),
      ]);
    } else {
      // Full body default
      exercises.addAll([
        const ParsedExercise(
          name: 'Squats',
          muscleGroup: 'Legs',
          movementType: 'Compound',
          dayType: 'Full Body',
        ),
        const ParsedExercise(
          name: 'Bench Press',
          muscleGroup: 'Chest',
          movementType: 'Compound',
          dayType: 'Full Body',
        ),
        const ParsedExercise(
          name: 'Rows',
          muscleGroup: 'Back',
          movementType: 'Compound',
          dayType: 'Full Body',
        ),
        const ParsedExercise(
          name: 'Shoulder Press',
          muscleGroup: 'Shoulders',
          movementType: 'Compound',
          dayType: 'Full Body',
        ),
      ]);
    }

    return exercises;
  }
}
