// User profile model matching the FastAPI backend schema

import 'package:flutter/material.dart';

class UserProfile {
  final String fitnessLevel;
  final List<String> goals;
  final String equipment;
  final String? preferredDuration;
  final int? preferredFrequency;
  final String? preferredStyle;

  UserProfile({
    required this.fitnessLevel,
    required this.goals,
    required this.equipment,
    this.preferredDuration,
    this.preferredFrequency,
    this.preferredStyle,
  });

  Map<String, dynamic> toJson() {
    return {
      'fitness_level': fitnessLevel,
      'goals': goals,
      'equipment': equipment,
      'preferred_duration': preferredDuration,
      'preferred_frequency': preferredFrequency,
      'preferred_style': preferredStyle,
    };
  }
}

// Enhanced goal option with visual properties
class GoalOption {
  final String name;
  final IconData icon;
  final Color color;

  const GoalOption({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class Constants {
  // Must match backend validation in src/config.py
  static const List<String> fitnessLevels = [
    'Beginner',
    'Novice',
    'Intermediate',
    'Advanced',
  ];

  static const List<String> goals = [
    'General Fitness',
    'Weight Loss',
    'Strength',
    'Hypertrophy',
    'Bodybuilding',
    'Powerlifting',
    'Athletics',
    'Endurance',
    'Muscle & Sculpting',
    'Bodyweight Fitness',
    'Athletic Performance',
  ];

  // Enhanced goals with icons and colors
  static const List<GoalOption> goalOptions = [
    GoalOption(
      name: 'General Fitness',
      icon: Icons.directions_run,
      color: Color(0xFFFF6B6B),
    ),
    GoalOption(
      name: 'Weight Loss',
      icon: Icons.monitor_weight,
      color: Color(0xFF4ECDC4),
    ),
    GoalOption(
      name: 'Strength',
      icon: Icons.fitness_center,
      color: Color(0xFF45B7D1),
    ),
    GoalOption(
      name: 'Hypertrophy',
      icon: Icons.local_fire_department,
      color: Color(0xFF96CEB4),
    ),
    GoalOption(
      name: 'Bodybuilding',
      icon: Icons.emoji_events,
      color: Color(0xFFFECA57),
    ),
    GoalOption(
      name: 'Powerlifting',
      icon: Icons.flash_on,
      color: Color(0xFFFF9FF3),
    ),
    GoalOption(
      name: 'Athletics',
      icon: Icons.sports,
      color: Color(0xFF54A0FF),
    ),
    GoalOption(
      name: 'Endurance',
      icon: Icons.directions_bike,
      color: Color(0xFF5F27CD),
    ),
    GoalOption(
      name: 'Muscle & Sculpting',
      icon: Icons.track_changes,
      color: Color(0xFF00D2D3),
    ),
    GoalOption(
      name: 'Bodyweight Fitness',
      icon: Icons.self_improvement,
      color: Color(0xFFFF9F43),
    ),
    GoalOption(
      name: 'Athletic Performance',
      icon: Icons.military_tech,
      color: Color(0xFF10AC84),
    ),
  ];

  static const List<String> equipment = [
    'At Home',
    'Dumbbell Only',
    'Full Gym',
    'Garage Gym',
  ];

  static const List<String> durations = [
    '30-45 min',
    '45-60 min',
    '60-75 min',
    '75-90 min',
    '90+ min',
  ];

  static const List<String> trainingStyles = [
    'Full Body',
    'Upper/Lower',
    'Push/Pull/Legs',
    'Body Part Split',
    'No preference',
  ];
}

