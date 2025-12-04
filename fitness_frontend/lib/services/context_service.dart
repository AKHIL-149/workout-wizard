import 'package:flutter/material.dart';
import '../models/recommendation.dart';

/// Time of day categories
enum TimeOfDay {
  earlyMorning, // 5-7 AM
  morning, // 7-11 AM
  midday, // 11 AM - 2 PM
  afternoon, // 2-5 PM
  evening, // 5-8 PM
  night, // 8 PM - 12 AM
  lateNight, // 12 AM - 5 AM
}

/// Energy level based on time
enum EnergyLevel {
  low,
  medium,
  high,
}

/// Workout recommendation context
class WorkoutContext {
  final TimeOfDay timeOfDay;
  final EnergyLevel energyLevel;
  final String greeting;
  final String workoutSuggestion;
  final List<String> idealWorkoutTypes;
  final Duration idealDuration;
  final IconData icon;
  final Color color;

  WorkoutContext({
    required this.timeOfDay,
    required this.energyLevel,
    required this.greeting,
    required this.workoutSuggestion,
    required this.idealWorkoutTypes,
    required this.idealDuration,
    required this.icon,
    required this.color,
  });
}

/// Contextual intelligence service for time and environment-aware recommendations
class ContextService {
  static final ContextService _instance = ContextService._internal();
  factory ContextService() => _instance;
  ContextService._internal();

  /// Get current time of day category
  TimeOfDay getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 7) return TimeOfDay.earlyMorning;
    if (hour >= 7 && hour < 11) return TimeOfDay.morning;
    if (hour >= 11 && hour < 14) return TimeOfDay.midday;
    if (hour >= 14 && hour < 17) return TimeOfDay.afternoon;
    if (hour >= 17 && hour < 20) return TimeOfDay.evening;
    if (hour >= 20 && hour < 24) return TimeOfDay.night;
    return TimeOfDay.lateNight;
  }

  /// Get energy level based on time
  EnergyLevel getEnergyLevelForTime(TimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case TimeOfDay.earlyMorning:
        return EnergyLevel.medium;
      case TimeOfDay.morning:
        return EnergyLevel.high;
      case TimeOfDay.midday:
        return EnergyLevel.medium;
      case TimeOfDay.afternoon:
        return EnergyLevel.medium;
      case TimeOfDay.evening:
        return EnergyLevel.high;
      case TimeOfDay.night:
        return EnergyLevel.medium;
      case TimeOfDay.lateNight:
        return EnergyLevel.low;
    }
  }

  /// Get workout context for current time
  WorkoutContext getCurrentWorkoutContext() {
    final timeOfDay = getCurrentTimeOfDay();
    final energyLevel = getEnergyLevelForTime(timeOfDay);

    switch (timeOfDay) {
      case TimeOfDay.earlyMorning:
        return WorkoutContext(
          timeOfDay: timeOfDay,
          energyLevel: energyLevel,
          greeting: 'Rise and Shine',
          workoutSuggestion: 'Light cardio or yoga to wake up your body',
          idealWorkoutTypes: ['Yoga', 'Light Cardio', 'Stretching', 'Walking'],
          idealDuration: const Duration(minutes: 20),
          icon: Icons.wb_twilight,
          color: Colors.orange.shade300,
        );

      case TimeOfDay.morning:
        return WorkoutContext(
          timeOfDay: timeOfDay,
          energyLevel: energyLevel,
          greeting: 'Good Morning',
          workoutSuggestion: 'Perfect time for high-intensity training',
          idealWorkoutTypes: ['HIIT', 'Strength Training', 'Running', 'CrossFit'],
          idealDuration: const Duration(minutes: 45),
          icon: Icons.wb_sunny,
          color: Colors.amber,
        );

      case TimeOfDay.midday:
        return WorkoutContext(
          timeOfDay: timeOfDay,
          energyLevel: energyLevel,
          greeting: 'Midday Break',
          workoutSuggestion: 'Quick energizing workout to break up your day',
          idealWorkoutTypes: ['Quick Cardio', 'Bodyweight', 'Core', 'Stretching'],
          idealDuration: const Duration(minutes: 30),
          icon: Icons.light_mode,
          color: Colors.yellow,
        );

      case TimeOfDay.afternoon:
        return WorkoutContext(
          timeOfDay: timeOfDay,
          energyLevel: energyLevel,
          greeting: 'Good Afternoon',
          workoutSuggestion: 'Beat the afternoon slump with a moderate workout',
          idealWorkoutTypes: ['Moderate Cardio', 'Circuit Training', 'Swimming', 'Cycling'],
          idealDuration: const Duration(minutes: 40),
          icon: Icons.wb_sunny_outlined,
          color: Colors.orange,
        );

      case TimeOfDay.evening:
        return WorkoutContext(
          timeOfDay: timeOfDay,
          energyLevel: energyLevel,
          greeting: 'Good Evening',
          workoutSuggestion: 'Peak performance time for most people',
          idealWorkoutTypes: ['Strength Training', 'Sports', 'HIIT', 'Weight Lifting'],
          idealDuration: const Duration(minutes: 60),
          icon: Icons.wb_twilight,
          color: Colors.deepOrange,
        );

      case TimeOfDay.night:
        return WorkoutContext(
          timeOfDay: timeOfDay,
          energyLevel: energyLevel,
          greeting: 'Good Evening',
          workoutSuggestion: 'Wind down with moderate to light exercise',
          idealWorkoutTypes: ['Yoga', 'Pilates', 'Light Cardio', 'Stretching'],
          idealDuration: const Duration(minutes: 30),
          icon: Icons.nightlight,
          color: Colors.indigo,
        );

      case TimeOfDay.lateNight:
        return WorkoutContext(
          timeOfDay: timeOfDay,
          energyLevel: energyLevel,
          greeting: 'Late Night',
          workoutSuggestion: 'Consider resting - recovery is important too',
          idealWorkoutTypes: ['Stretching', 'Meditation', 'Light Yoga'],
          idealDuration: const Duration(minutes: 15),
          icon: Icons.bedtime,
          color: Colors.deepPurple,
        );
    }
  }

  /// Score recommendations based on current context
  List<Recommendation> rankByContext(List<Recommendation> recommendations) {
    final context = getCurrentWorkoutContext();
    final scored = <MapEntry<Recommendation, double>>[];

    for (var rec in recommendations) {
      double score = rec.matchPercentage.toDouble();

      // Adjust score based on time per workout matching ideal duration
      final durationMatch = _getDurationMatch(
        rec.timePerWorkout,
        context.idealDuration.inMinutes,
      );
      score += durationMatch * 5; // Up to +5 points for duration match

      // Adjust score based on workout type matching ideal types
      final typeMatch = _getTypeMatch(
        rec.title,
        rec.primaryGoal,
        context.idealWorkoutTypes,
      );
      score += typeMatch * 3; // Up to +3 points for type match

      // Boost for appropriate energy level
      if (context.energyLevel == EnergyLevel.high) {
        // High-intensity programs get a boost
        if (rec.title.toLowerCase().contains('hiit') ||
            rec.title.toLowerCase().contains('intense')) {
          score += 2;
        }
      } else if (context.energyLevel == EnergyLevel.low) {
        // Low-intensity programs get a boost
        if (rec.title.toLowerCase().contains('yoga') ||
            rec.title.toLowerCase().contains('stretch') ||
            rec.title.toLowerCase().contains('light')) {
          score += 2;
        }
      }

      scored.add(MapEntry(rec, score));
    }

    // Sort by adjusted score
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  /// Calculate duration match score (0.0 to 1.0)
  double _getDurationMatch(int actualMinutes, int idealMinutes) {
    final difference = (actualMinutes - idealMinutes).abs();
    if (difference == 0) return 1.0;
    if (difference <= 10) return 0.8;
    if (difference <= 20) return 0.5;
    if (difference <= 30) return 0.3;
    return 0.0;
  }

  /// Calculate type match score (0.0 to 1.0)
  double _getTypeMatch(
    String title,
    String primaryGoal,
    List<String> idealTypes,
  ) {
    final searchText = '$title $primaryGoal'.toLowerCase();

    for (var type in idealTypes) {
      if (searchText.contains(type.toLowerCase())) {
        return 1.0;
      }
    }

    // Check for partial matches
    final keywords = idealTypes.map((t) => t.toLowerCase().split(' ')).expand((x) => x);
    for (var keyword in keywords) {
      if (keyword.length > 3 && searchText.contains(keyword)) {
        return 0.5;
      }
    }

    return 0.0;
  }

  /// Get time-specific insights
  String getTimeInsight() {
    final context = getCurrentWorkoutContext();

    if (context.timeOfDay == TimeOfDay.earlyMorning) {
      return 'Early bird gets the gains! Morning workouts boost metabolism for the day.';
    } else if (context.timeOfDay == TimeOfDay.morning) {
      return 'Studies show peak strength performance occurs in the morning for most people.';
    } else if (context.timeOfDay == TimeOfDay.midday) {
      return 'A midday workout can boost afternoon productivity by up to 21%.';
    } else if (context.timeOfDay == TimeOfDay.afternoon) {
      return 'Afternoon is ideal for skill-based training - coordination peaks at this time.';
    } else if (context.timeOfDay == TimeOfDay.evening) {
      return 'Evening workouts: body temperature peaks, reducing injury risk.';
    } else if (context.timeOfDay == TimeOfDay.night) {
      return 'Late evening workouts can aid sleep if finished 2+ hours before bed.';
    } else {
      return 'Rest and recovery are just as important as training.';
    }
  }

  /// Get day of week insights
  String getDayOfWeekInsight() {
    final dayOfWeek = DateTime.now().weekday;

    switch (dayOfWeek) {
      case DateTime.monday:
        return 'Start the week strong! Monday motivation is real.';
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
        return 'Mid-week is perfect for peak performance training.';
      case DateTime.friday:
        return 'Finish the week strong - you\'re almost there!';
      case DateTime.saturday:
        return 'Weekend warrior mode activated!';
      case DateTime.sunday:
        return 'Sunday: active recovery or prepare for the week ahead.';
      default:
        return 'Every day is a good day to move your body.';
    }
  }

  /// Check if it's a good time to workout
  bool isGoodTimeToWorkout() {
    final timeOfDay = getCurrentTimeOfDay();
    return timeOfDay != TimeOfDay.lateNight;
  }

  /// Get alternative workout time suggestion
  String getAlternativeTimeSuggestion() {
    final timeOfDay = getCurrentTimeOfDay();

    if (timeOfDay == TimeOfDay.lateNight) {
      return 'Consider working out tomorrow morning (7-11 AM) for peak energy';
    } else if (timeOfDay == TimeOfDay.earlyMorning) {
      return 'Or try evening (5-8 PM) when body temperature peaks';
    } else {
      return 'Morning (7-11 AM) and evening (5-8 PM) are ideal workout times';
    }
  }

  /// Get workout intensity recommendation
  String getIntensityRecommendation() {
    final energyLevel = getEnergyLevelForTime(getCurrentTimeOfDay());

    switch (energyLevel) {
      case EnergyLevel.high:
        return 'High-intensity workouts are ideal right now';
      case EnergyLevel.medium:
        return 'Moderate-intensity workouts are recommended';
      case EnergyLevel.low:
        return 'Light activity or rest is recommended';
    }
  }

  /// Get rest day recommendation
  bool shouldConsiderRestDay() {
    // Sunday late evening/night - suggest rest
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday && now.hour >= 19) {
      return true;
    }
    return false;
  }

  /// Get contextual badge/tag for a recommendation
  String? getContextualBadge(Recommendation rec) {
    final context = getCurrentWorkoutContext();

    // Check if workout duration matches current context
    final durationDiff = (rec.timePerWorkout - context.idealDuration.inMinutes).abs();
    if (durationDiff <= 5) {
      return 'Perfect for now';
    }

    // Check if workout type matches
    final title = rec.title.toLowerCase();
    for (var type in context.idealWorkoutTypes) {
      if (title.contains(type.toLowerCase())) {
        return 'Ideal for ${_getTimeLabel()}';
      }
    }

    // Check energy level match
    if (context.energyLevel == EnergyLevel.low && rec.timePerWorkout <= 20) {
      return 'Light & Easy';
    }

    if (context.energyLevel == EnergyLevel.high && rec.timePerWorkout >= 45) {
      return 'High Energy';
    }

    return null;
  }

  /// Get time label for current time
  String _getTimeLabel() {
    final timeOfDay = getCurrentTimeOfDay();
    switch (timeOfDay) {
      case TimeOfDay.earlyMorning:
        return 'early morning';
      case TimeOfDay.morning:
        return 'morning';
      case TimeOfDay.midday:
        return 'midday';
      case TimeOfDay.afternoon:
        return 'afternoon';
      case TimeOfDay.evening:
        return 'evening';
      case TimeOfDay.night:
        return 'night';
      case TimeOfDay.lateNight:
        return 'late night';
    }
  }

  /// Get motivational message based on time and day
  String getMotivationalMessage() {
    final context = getCurrentWorkoutContext();
    final dayOfWeek = DateTime.now().weekday;
    final hour = DateTime.now().hour;

    if (dayOfWeek == DateTime.monday && hour < 12) {
      return 'Start your week with strength!';
    } else if (dayOfWeek == DateTime.friday && hour >= 17) {
      return 'Finish strong before the weekend!';
    } else if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
      return 'Weekend gains matter too!';
    } else if (context.energyLevel == EnergyLevel.high) {
      return 'Your energy is peak - time to crush it!';
    } else if (context.energyLevel == EnergyLevel.low) {
      return 'Listen to your body - gentle movement is still progress';
    } else {
      return 'Consistency beats perfection - you got this!';
    }
  }
}
