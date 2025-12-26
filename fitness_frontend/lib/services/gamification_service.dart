import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Achievement definition
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredCount;
  bool unlocked;
  DateTime? unlockedDate;
  int currentProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredCount,
    this.unlocked = false,
    this.unlockedDate,
    this.currentProgress = 0,
  });

  double get progress => (currentProgress / requiredCount).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'unlocked': unlocked,
    'unlocked_date': unlockedDate?.toIso8601String(),
    'current_progress': currentProgress,
  };

  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) =>
      Achievement(
        id: template.id,
        title: template.title,
        description: template.description,
        icon: template.icon,
        color: template.color,
        requiredCount: template.requiredCount,
        unlocked: json['unlocked'] as bool? ?? false,
        unlockedDate: json['unlocked_date'] != null
            ? DateTime.parse(json['unlocked_date'] as String)
            : null,
        currentProgress: json['current_progress'] as int? ?? 0,
      );
}

/// Gamification service for achievements, streaks, and progress
class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  static const String _achievementsKey = 'achievements';
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _lastActivityDateKey = 'last_activity_date';
  static const String _totalPointsKey = 'total_points';

  late List<Achievement> _achievements;
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActivityDate;
  int _totalPoints = 0;

  /// Initialize gamification
  Future<void> initialize() async {
    _initializeAchievements();
    await _loadProgress();
  }

  /// Initialize achievement definitions
  void _initializeAchievements() {
    _achievements = [
      Achievement(
        id: 'first_recommendation',
        title: 'Getting Started',
        description: 'Get your first program recommendation',
        icon: Icons.rocket_launch,
        color: Colors.blue,
        requiredCount: 1,
      ),
      Achievement(
        id: 'week_warrior',
        title: 'Week Warrior',
        description: 'Use the app for 7 consecutive days',
        icon: Icons.calendar_today,
        color: Colors.orange,
        requiredCount: 7,
      ),
      Achievement(
        id: 'program_explorer',
        title: 'Program Explorer',
        description: 'View 10 different programs',
        icon: Icons.explore,
        color: Colors.green,
        requiredCount: 10,
      ),
      Achievement(
        id: 'favorite_collector',
        title: 'Favorite Collector',
        description: 'Add 5 programs to favorites',
        icon: Icons.favorite,
        color: Colors.red,
        requiredCount: 5,
      ),
      Achievement(
        id: 'search_master',
        title: 'Search Master',
        description: 'Perform 20 searches',
        icon: Icons.search,
        color: Colors.purple,
        requiredCount: 20,
      ),
      Achievement(
        id: 'consistency_king',
        title: 'Consistency King',
        description: 'Maintain a 30-day streak',
        icon: Icons.emoji_events,
        color: Colors.amber,
        requiredCount: 30,
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Use the app before 7 AM 5 times',
        icon: Icons.wb_sunny,
        color: Colors.yellow,
        requiredCount: 5,
      ),
      Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Use the app after 10 PM 5 times',
        icon: Icons.nightlight,
        color: Colors.indigo,
        requiredCount: 5,
      ),
      Achievement(
        id: 'program_starter',
        title: 'Program Starter',
        description: 'Start your first program',
        icon: Icons.play_arrow,
        color: Colors.teal,
        requiredCount: 1,
      ),
      Achievement(
        id: 'dedicated_user',
        title: 'Dedicated User',
        description: 'Use the app 50 times',
        icon: Icons.star,
        color: Colors.pink,
        requiredCount: 50,
      ),
    ];
  }

  /// Load progress from storage
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // Load achievements
    final achievementsJson = prefs.getString(_achievementsKey);
    if (achievementsJson != null) {
      try {
        final achievementsList = json.decode(achievementsJson) as List;
        for (var i = 0; i < achievementsList.length && i < _achievements.length; i++) {
          _achievements[i] = Achievement.fromJson(
            achievementsList[i] as Map<String, dynamic>,
            _achievements[i],
          );
        }
      } catch (e) {
        // Ignore errors
      }
    }

    // Load streaks
    _currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    _longestStreak = prefs.getInt(_longestStreakKey) ?? 0;
    _totalPoints = prefs.getInt(_totalPointsKey) ?? 0;

    final lastActivityStr = prefs.getString(_lastActivityDateKey);
    if (lastActivityStr != null) {
      _lastActivityDate = DateTime.parse(lastActivityStr);
    }

    // Update streak
    _updateStreak();
  }

  /// Save progress to storage
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // Save achievements
    final achievementsJson = json.encode(
      _achievements.map((a) => a.toJson()).toList(),
    );
    await prefs.setString(_achievementsKey, achievementsJson);

    // Save streaks
    await prefs.setInt(_currentStreakKey, _currentStreak);
    await prefs.setInt(_longestStreakKey, _longestStreak);
    await prefs.setInt(_totalPointsKey, _totalPoints);

    if (_lastActivityDate != null) {
      await prefs.setString(_lastActivityDateKey, _lastActivityDate!.toIso8601String());
    }
  }

  /// Update streak based on activity
  void _updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastActivityDate == null) {
      _currentStreak = 1;
      _lastActivityDate = today;
    } else {
      final lastDay = DateTime(
        _lastActivityDate!.year,
        _lastActivityDate!.month,
        _lastActivityDate!.day,
      );

      final daysDifference = today.difference(lastDay).inDays;

      if (daysDifference == 0) {
        // Same day, no change
      } else if (daysDifference == 1) {
        // Consecutive day
        _currentStreak++;
        _lastActivityDate = today;

        // Update longest streak
        if (_currentStreak > _longestStreak) {
          _longestStreak = _currentStreak;
        }
      } else {
        // Streak broken
        _currentStreak = 1;
        _lastActivityDate = today;
      }
    }

    _saveProgress();
  }

  /// Record activity and update achievements
  Future<List<Achievement>> recordActivity(String activityType, {int count = 1}) async {
    _updateStreak();

    final newlyUnlocked = <Achievement>[];

    // Update relevant achievements
    for (final achievement in _achievements) {
      if (achievement.unlocked) continue;

      bool shouldUpdate = false;

      switch (achievement.id) {
        case 'first_recommendation':
          if (activityType == 'recommendation_viewed') shouldUpdate = true;
          break;
        case 'week_warrior':
          achievement.currentProgress = _currentStreak;
          break;
        case 'program_explorer':
          if (activityType == 'program_viewed') shouldUpdate = true;
          break;
        case 'favorite_collector':
          if (activityType == 'program_favorited') shouldUpdate = true;
          break;
        case 'search_master':
          if (activityType == 'search_performed') shouldUpdate = true;
          break;
        case 'consistency_king':
          achievement.currentProgress = _currentStreak;
          break;
        case 'early_bird':
          if (activityType == 'early_morning_activity') shouldUpdate = true;
          break;
        case 'night_owl':
          if (activityType == 'night_activity') shouldUpdate = true;
          break;
        case 'program_starter':
          if (activityType == 'program_started') shouldUpdate = true;
          break;
        case 'dedicated_user':
          if (activityType == 'app_opened') shouldUpdate = true;
          break;
      }

      if (shouldUpdate) {
        achievement.currentProgress += count;
      }

      // Check if newly unlocked
      if (!achievement.unlocked && achievement.currentProgress >= achievement.requiredCount) {
        achievement.unlocked = true;
        achievement.unlockedDate = DateTime.now();
        newlyUnlocked.add(achievement);
        _totalPoints += 100; // Award points
      }
    }

    await _saveProgress();
    return newlyUnlocked;
  }

  /// Get progress towards next achievement
  Achievement? getNextAchievement() {
    final locked = _achievements.where((a) => !a.unlocked).toList();
    if (locked.isEmpty) return null;

    // Sort by progress (closest to completion first)
    locked.sort((a, b) => b.progress.compareTo(a.progress));
    return locked.first;
  }

  /// Get achievement stats
  Map<String, dynamic> getStats() {
    final unlocked = _achievements.where((a) => a.unlocked).length;
    return {
      'total_achievements': _achievements.length,
      'unlocked_achievements': unlocked,
      'current_streak': _currentStreak,
      'longest_streak': _longestStreak,
      'total_points': _totalPoints,
      'completion_percentage': (unlocked / _achievements.length * 100).round(),
    };
  }

  // Getters
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.unlocked).toList();
  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.unlocked).toList();
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get totalPoints => _totalPoints;

  /// Export gamification data for backup
  Future<Map<String, dynamic>> exportGamificationData() async {
    return {
      'achievements': _achievements.map((a) => a.toJson()).toList(),
      'current_streak': _currentStreak,
      'longest_streak': _longestStreak,
      'total_points': _totalPoints,
      'last_activity_date': _lastActivityDate?.toIso8601String(),
    };
  }

  /// Import gamification data from backup
  Future<void> importGamificationData(
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    if (data['achievements'] != null) {
      if (merge) {
        // Merge achievements intelligently
        // Keep unlocked state if unlocked in either, merge progress
        final backupAchievementsList = data['achievements'] as List;

        for (var i = 0; i < backupAchievementsList.length && i < _achievements.length; i++) {
          final backupData = backupAchievementsList[i] as Map<String, dynamic>;
          final existing = _achievements[i];

          // Merge: keep unlocked if unlocked in either
          final wasUnlocked = existing.unlocked || (backupData['unlocked'] as bool? ?? false);

          // Merge: keep higher progress
          final backupProgress = backupData['current_progress'] as int? ?? 0;
          final mergedProgress = existing.currentProgress > backupProgress
              ? existing.currentProgress
              : backupProgress;

          // Merge: keep earlier unlock date if both unlocked
          DateTime? mergedUnlockDate = existing.unlockedDate;
          if (backupData['unlocked_date'] != null) {
            final backupUnlockDate = DateTime.parse(backupData['unlocked_date'] as String);
            if (mergedUnlockDate == null || backupUnlockDate.isBefore(mergedUnlockDate)) {
              mergedUnlockDate = backupUnlockDate;
            }
          }

          _achievements[i] = Achievement(
            id: existing.id,
            title: existing.title,
            description: existing.description,
            icon: existing.icon,
            color: existing.color,
            requiredCount: existing.requiredCount,
            unlocked: wasUnlocked,
            unlockedDate: mergedUnlockDate,
            currentProgress: mergedProgress,
          );
        }
      } else {
        // Replace: load achievements from backup
        final backupAchievementsList = data['achievements'] as List;
        for (var i = 0; i < backupAchievementsList.length && i < _achievements.length; i++) {
          _achievements[i] = Achievement.fromJson(
            backupAchievementsList[i] as Map<String, dynamic>,
            _achievements[i],
          );
        }
      }
    }

    if (data['current_streak'] != null && data['longest_streak'] != null) {
      if (merge) {
        // Keep higher streak values
        _currentStreak = _currentStreak > (data['current_streak'] as int)
            ? _currentStreak
            : data['current_streak'] as int;
        _longestStreak = _longestStreak > (data['longest_streak'] as int)
            ? _longestStreak
            : data['longest_streak'] as int;
      } else {
        _currentStreak = data['current_streak'] as int;
        _longestStreak = data['longest_streak'] as int;
      }
    }

    if (data['total_points'] != null) {
      if (merge) {
        // Add points together when merging
        _totalPoints += data['total_points'] as int;
      } else {
        _totalPoints = data['total_points'] as int;
      }
    }

    if (data['last_activity_date'] != null) {
      final backupLastActivity = DateTime.parse(data['last_activity_date'] as String);
      if (merge) {
        // Keep most recent activity date
        if (_lastActivityDate == null || backupLastActivity.isAfter(_lastActivityDate!)) {
          _lastActivityDate = backupLastActivity;
        }
      } else {
        _lastActivityDate = backupLastActivity;
      }
    }

    // Save all updated data
    await _saveProgress();
  }
}
