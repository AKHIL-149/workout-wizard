import 'package:hive/hive.dart';
import 'workout_template.dart';

part 'workout_program.g.dart';

/// A structured workout program with multiple weeks/phases
@HiveType(typeId: 15)
class WorkoutProgram {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String difficulty; // Beginner, Intermediate, Advanced

  @HiveField(4)
  final int durationWeeks;

  @HiveField(5)
  final int daysPerWeek;

  @HiveField(6)
  final List<String> goals; // e.g., ["Strength", "Hypertrophy", "Fat Loss"]

  @HiveField(7)
  final List<ProgramWeek> weeks;

  @HiveField(8)
  final String author;

  @HiveField(9)
  final bool isBuiltIn; // True for pre-defined programs

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final String? imageUrl;

  @HiveField(12)
  final List<String> tags; // e.g., ["Powerlifting", "3-Day", "Linear"]

  @HiveField(13)
  final String? notes; // Additional program notes

  WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.durationWeeks,
    required this.daysPerWeek,
    required this.goals,
    required this.weeks,
    required this.author,
    this.isBuiltIn = false,
    required this.createdAt,
    this.imageUrl,
    this.tags = const [],
    this.notes,
  });

  /// Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'durationWeeks': durationWeeks,
      'daysPerWeek': daysPerWeek,
      'goals': goals,
      'weeks': weeks.map((w) => w.toJson()).toList(),
      'author': author,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'tags': tags,
      'notes': notes,
    };
  }

  /// Create from JSON
  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    return WorkoutProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      durationWeeks: json['durationWeeks'] as int,
      daysPerWeek: json['daysPerWeek'] as int,
      goals: (json['goals'] as List).cast<String>(),
      weeks: (json['weeks'] as List)
          .map((w) => ProgramWeek.fromJson(w as Map<String, dynamic>))
          .toList(),
      author: json['author'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
    );
  }

  /// Create a copy with optional modifications
  WorkoutProgram copyWith({
    String? id,
    String? name,
    String? description,
    String? difficulty,
    int? durationWeeks,
    int? daysPerWeek,
    List<String>? goals,
    List<ProgramWeek>? weeks,
    String? author,
    bool? isBuiltIn,
    DateTime? createdAt,
    String? imageUrl,
    List<String>? tags,
    String? notes,
  }) {
    return WorkoutProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      goals: goals ?? this.goals,
      weeks: weeks ?? this.weeks,
      author: author ?? this.author,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }

  /// Check if this is a custom program
  bool get isCustom => !isBuiltIn;
}

/// A week within a program
@HiveType(typeId: 16)
class ProgramWeek {
  @HiveField(0)
  final int weekNumber;

  @HiveField(1)
  final String? weekName; // e.g., "Hypertrophy Phase", "Deload Week"

  @HiveField(2)
  final List<ProgramDay> days;

  @HiveField(3)
  final String? notes;

  ProgramWeek({
    required this.weekNumber,
    this.weekName,
    required this.days,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'weekName': weekName,
      'days': days.map((d) => d.toJson()).toList(),
      'notes': notes,
    };
  }

  factory ProgramWeek.fromJson(Map<String, dynamic> json) {
    return ProgramWeek(
      weekNumber: json['weekNumber'] as int,
      weekName: json['weekName'] as String?,
      days: (json['days'] as List)
          .map((d) => ProgramDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }
}

/// A training day within a program week
@HiveType(typeId: 17)
class ProgramDay {
  @HiveField(0)
  final int dayNumber; // 1-7 (Monday-Sunday)

  @HiveField(1)
  final String dayName; // e.g., "Push Day", "Upper Body", "Workout A"

  @HiveField(2)
  final List<TemplateExercise> exercises;

  @HiveField(3)
  final bool isRestDay;

  @HiveField(4)
  final String? notes;

  ProgramDay({
    required this.dayNumber,
    required this.dayName,
    required this.exercises,
    this.isRestDay = false,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'dayName': dayName,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'isRestDay': isRestDay,
      'notes': notes,
    };
  }

  factory ProgramDay.fromJson(Map<String, dynamic> json) {
    return ProgramDay(
      dayNumber: json['dayNumber'] as int,
      dayName: json['dayName'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => TemplateExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      isRestDay: json['isRestDay'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

/// User's active program enrollment
@HiveType(typeId: 18)
class ProgramEnrollment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String programId;

  @HiveField(2)
  final String programName;

  @HiveField(3)
  final DateTime startDate;

  @HiveField(4)
  final int currentWeek;

  @HiveField(5)
  final int currentDay;

  @HiveField(6)
  final bool isActive;

  @HiveField(7)
  final DateTime? completedDate;

  @HiveField(8)
  final Map<String, bool> completedWorkouts; // "week_day" -> completed

  ProgramEnrollment({
    required this.id,
    required this.programId,
    required this.programName,
    required this.startDate,
    this.currentWeek = 1,
    this.currentDay = 1,
    this.isActive = true,
    this.completedDate,
    this.completedWorkouts = const {},
  });

  String getWorkoutKey(int week, int day) => '${week}_$day';

  bool isWorkoutCompleted(int week, int day) {
    return completedWorkouts[getWorkoutKey(week, day)] ?? false;
  }

  ProgramEnrollment copyWith({
    String? id,
    String? programId,
    String? programName,
    DateTime? startDate,
    int? currentWeek,
    int? currentDay,
    bool? isActive,
    DateTime? completedDate,
    Map<String, bool>? completedWorkouts,
  }) {
    return ProgramEnrollment(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      startDate: startDate ?? this.startDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentDay: currentDay ?? this.currentDay,
      isActive: isActive ?? this.isActive,
      completedDate: completedDate ?? this.completedDate,
      completedWorkouts: completedWorkouts ?? this.completedWorkouts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'programId': programId,
      'programName': programName,
      'startDate': startDate.toIso8601String(),
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'isActive': isActive,
      'completedDate': completedDate?.toIso8601String(),
      'completedWorkouts': completedWorkouts,
    };
  }

  factory ProgramEnrollment.fromJson(Map<String, dynamic> json) {
    return ProgramEnrollment(
      id: json['id'] as String,
      programId: json['programId'] as String,
      programName: json['programName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      currentWeek: json['currentWeek'] as int? ?? 1,
      currentDay: json['currentDay'] as int? ?? 1,
      isActive: json['isActive'] as bool? ?? true,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      completedWorkouts:
          (json['completedWorkouts'] as Map<String, dynamic>?)?.cast<String, bool>() ?? {},
    );
  }
}
