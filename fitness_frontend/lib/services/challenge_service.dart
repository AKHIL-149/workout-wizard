import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_challenge.dart';
import '../models/social_models.dart';
import 'workout_buddies_service.dart';

/// Service for managing workout challenges
class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();
  factory ChallengeService() => _instance;
  ChallengeService._internal();

  static const String _challengesBoxName = 'workout_challenges';
  static const String _progressBoxName = 'challenge_progress';

  final Uuid _uuid = const Uuid();
  final WorkoutBuddiesService _buddiesService = WorkoutBuddiesService();

  /// Initialize Hive boxes
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_challengesBoxName)) {
        await Hive.openBox<WorkoutChallenge>(_challengesBoxName);
      }
      if (!Hive.isBoxOpen(_progressBoxName)) {
        await Hive.openBox<ChallengeProgress>(_progressBoxName);
      }

      debugPrint('ChallengeService: Initialized');
    } catch (e) {
      debugPrint('ChallengeService: Error initializing: $e');
      rethrow;
    }
  }

  /// Get all challenges
  List<WorkoutChallenge> getAllChallenges() {
    try {
      final box = Hive.box<WorkoutChallenge>(_challengesBoxName);
      return box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('ChallengeService: Error getting challenges: $e');
      return [];
    }
  }

  /// Get active challenges
  List<WorkoutChallenge> getActiveChallenges() {
    try {
      return getAllChallenges().where((c) => c.isActive).toList();
    } catch (e) {
      debugPrint('ChallengeService: Error getting active challenges: $e');
      return [];
    }
  }

  /// Get upcoming challenges
  List<WorkoutChallenge> getUpcomingChallenges() {
    try {
      return getAllChallenges().where((c) => c.isUpcoming).toList();
    } catch (e) {
      debugPrint('ChallengeService: Error getting upcoming challenges: $e');
      return [];
    }
  }

  /// Get completed challenges
  List<WorkoutChallenge> getCompletedChallenges() {
    try {
      return getAllChallenges().where((c) => c.isCompleted).toList();
    } catch (e) {
      debugPrint('ChallengeService: Error getting completed challenges: $e');
      return [];
    }
  }

  /// Get challenges user is participating in
  List<WorkoutChallenge> getUserChallenges() {
    try {
      final profile = _buddiesService.getSocialProfile();
      if (profile == null) return [];

      return getAllChallenges()
          .where((c) => c.participantIds.contains(profile.id))
          .toList();
    } catch (e) {
      debugPrint('ChallengeService: Error getting user challenges: $e');
      return [];
    }
  }

  /// Get challenge by ID
  WorkoutChallenge? getChallenge(String challengeId) {
    try {
      final box = Hive.box<WorkoutChallenge>(_challengesBoxName);
      return box.get(challengeId);
    } catch (e) {
      debugPrint('ChallengeService: Error getting challenge: $e');
      return null;
    }
  }

  /// Create a new challenge
  Future<WorkoutChallenge> createChallenge({
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String challengeType,
    required Map<String, dynamic> goalCriteria,
    bool isPublic = false,
    String? icon,
  }) async {
    try {
      final profile = _buddiesService.getSocialProfile();
      if (profile == null) {
        throw Exception('No profile found. Create a profile first.');
      }

      final challenge = WorkoutChallenge(
        id: _uuid.v4(),
        name: name,
        description: description,
        creatorId: profile.id,
        creatorName: profile.displayName,
        startDate: startDate,
        endDate: endDate,
        challengeType: challengeType,
        goalCriteria: goalCriteria,
        isPublic: isPublic,
        participantIds: [profile.id], // Creator auto-joins
        createdAt: DateTime.now(),
        icon: icon,
      );

      final box = Hive.box<WorkoutChallenge>(_challengesBoxName);
      await box.put(challenge.id, challenge);

      // Create progress entry for creator
      await joinChallenge(challenge.id);

      debugPrint('ChallengeService: Created challenge ${challenge.name}');
      return challenge;
    } catch (e) {
      debugPrint('ChallengeService: Error creating challenge: $e');
      rethrow;
    }
  }

  /// Join a challenge
  Future<void> joinChallenge(String challengeId) async {
    try {
      final profile = _buddiesService.getSocialProfile();
      if (profile == null) {
        throw Exception('No profile found. Create a profile first.');
      }

      final challenge = getChallenge(challengeId);
      if (challenge == null) {
        throw Exception('Challenge not found');
      }

      // Check if already joined
      if (challenge.participantIds.contains(profile.id)) {
        debugPrint('ChallengeService: Already joined challenge');
        return;
      }

      // Add user to participants
      final updatedChallenge = challenge.copyWith(
        participantIds: [...challenge.participantIds, profile.id],
      );

      final box = Hive.box<WorkoutChallenge>(_challengesBoxName);
      await box.put(challengeId, updatedChallenge);

      // Create progress entry
      final progress = ChallengeProgress(
        id: _uuid.v4(),
        challengeId: challengeId,
        userId: profile.id,
        userName: profile.displayName,
        joinedAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        avatarEmoji: profile.avatarEmoji,
        progressData: _initializeProgressData(challenge.challengeType),
      );

      final progressBox = Hive.box<ChallengeProgress>(_progressBoxName);
      await progressBox.put(progress.id, progress);

      debugPrint('ChallengeService: Joined challenge ${challenge.name}');
    } catch (e) {
      debugPrint('ChallengeService: Error joining challenge: $e');
      rethrow;
    }
  }

  /// Leave a challenge
  Future<void> leaveChallenge(String challengeId) async {
    try {
      final profile = _buddiesService.getSocialProfile();
      if (profile == null) return;

      final challenge = getChallenge(challengeId);
      if (challenge == null) return;

      // Can't leave if creator
      if (challenge.creatorId == profile.id) {
        throw Exception('Challenge creator cannot leave the challenge');
      }

      // Remove user from participants
      final updatedChallenge = challenge.copyWith(
        participantIds: challenge.participantIds
            .where((id) => id != profile.id)
            .toList(),
      );

      final box = Hive.box<WorkoutChallenge>(_challengesBoxName);
      await box.put(challengeId, updatedChallenge);

      // Remove progress entry
      final progress = getUserProgress(challengeId);
      if (progress != null) {
        final progressBox = Hive.box<ChallengeProgress>(_progressBoxName);
        await progressBox.delete(progress.id);
      }

      debugPrint('ChallengeService: Left challenge ${challenge.name}');
    } catch (e) {
      debugPrint('ChallengeService: Error leaving challenge: $e');
      rethrow;
    }
  }

  /// Delete a challenge (creator only)
  Future<void> deleteChallenge(String challengeId) async {
    try {
      final profile = _buddiesService.getSocialProfile();
      if (profile == null) return;

      final challenge = getChallenge(challengeId);
      if (challenge == null) return;

      // Only creator can delete
      if (challenge.creatorId != profile.id) {
        throw Exception('Only challenge creator can delete the challenge');
      }

      // Delete all progress entries
      final allProgress = getChallengeProgress(challengeId);
      final progressBox = Hive.box<ChallengeProgress>(_progressBoxName);
      for (var progress in allProgress) {
        await progressBox.delete(progress.id);
      }

      // Delete challenge
      final box = Hive.box<WorkoutChallenge>(_challengesBoxName);
      await box.delete(challengeId);

      debugPrint('ChallengeService: Deleted challenge');
    } catch (e) {
      debugPrint('ChallengeService: Error deleting challenge: $e');
      rethrow;
    }
  }

  /// Update user's progress in a challenge
  Future<void> updateProgress({
    required String challengeId,
    required Map<String, dynamic> progressUpdate,
  }) async {
    try {
      final progress = getUserProgress(challengeId);
      if (progress == null) {
        throw Exception('Not participating in this challenge');
      }

      final newProgressData = {...progress.progressData, ...progressUpdate};

      // Check if goal is met
      final challenge = getChallenge(challengeId);
      if (challenge == null) return;

      final isGoalMet = _checkGoalCompletion(
        challenge.challengeType,
        challenge.goalCriteria,
        newProgressData,
      );

      final updatedProgress = progress.copyWith(
        progressData: newProgressData,
        lastUpdated: DateTime.now(),
        isCompleted: isGoalMet,
      );

      final box = Hive.box<ChallengeProgress>(_progressBoxName);
      await box.put(progress.id, updatedProgress);

      debugPrint('ChallengeService: Updated progress for challenge');
    } catch (e) {
      debugPrint('ChallengeService: Error updating progress: $e');
      rethrow;
    }
  }

  /// Get all progress for a challenge (leaderboard)
  List<ChallengeProgress> getChallengeProgress(String challengeId) {
    try {
      final box = Hive.box<ChallengeProgress>(_progressBoxName);
      return box.values
          .where((p) => p.challengeId == challengeId)
          .toList()
        ..sort((a, b) => _compareProgress(a, b));
    } catch (e) {
      debugPrint('ChallengeService: Error getting challenge progress: $e');
      return [];
    }
  }

  /// Get user's progress in a challenge
  ChallengeProgress? getUserProgress(String challengeId) {
    try {
      final profile = _buddiesService.getSocialProfile();
      if (profile == null) return null;

      final box = Hive.box<ChallengeProgress>(_progressBoxName);
      return box.values.firstWhere(
        (p) => p.challengeId == challengeId && p.userId == profile.id,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Initialize progress data based on challenge type
  Map<String, dynamic> _initializeProgressData(String challengeType) {
    switch (challengeType) {
      case 'workout_count':
        return {'workoutsCompleted': 0};
      case 'total_volume':
        return {'totalVolume': 0.0};
      case 'streak':
        return {'currentStreak': 0, 'longestStreak': 0, 'lastWorkoutDate': null};
      case 'custom':
        return {};
      default:
        return {};
    }
  }

  /// Check if goal is completed
  bool _checkGoalCompletion(
    String challengeType,
    Map<String, dynamic> goalCriteria,
    Map<String, dynamic> progressData,
  ) {
    switch (challengeType) {
      case 'workout_count':
        final target = goalCriteria['targetWorkouts'] as int? ?? 0;
        final completed = progressData['workoutsCompleted'] as int? ?? 0;
        return completed >= target;
      case 'total_volume':
        final target = (goalCriteria['targetVolume'] as num?)?.toDouble() ?? 0.0;
        final completed = (progressData['totalVolume'] as num?)?.toDouble() ?? 0.0;
        return completed >= target;
      case 'streak':
        final target = goalCriteria['targetStreak'] as int? ?? 0;
        final longest = progressData['longestStreak'] as int? ?? 0;
        return longest >= target;
      default:
        return false;
    }
  }

  /// Compare progress for sorting (higher is better)
  int _compareProgress(ChallengeProgress a, ChallengeProgress b) {
    // Completed first
    if (a.isCompleted && !b.isCompleted) return -1;
    if (!a.isCompleted && b.isCompleted) return 1;

    // Then by progress value
    final aValue = _getProgressValue(a.progressData);
    final bValue = _getProgressValue(b.progressData);

    return bValue.compareTo(aValue);
  }

  /// Get numeric progress value for comparison
  double _getProgressValue(Map<String, dynamic> progressData) {
    if (progressData.containsKey('workoutsCompleted')) {
      return (progressData['workoutsCompleted'] as int? ?? 0).toDouble();
    } else if (progressData.containsKey('totalVolume')) {
      return (progressData['totalVolume'] as num?)?.toDouble() ?? 0.0;
    } else if (progressData.containsKey('longestStreak')) {
      return (progressData['longestStreak'] as int? ?? 0).toDouble();
    }
    return 0.0;
  }

  /// Get challenge statistics
  Map<String, dynamic> getChallengeStats() {
    try {
      final all = getAllChallenges();
      final active = getActiveChallenges();
      final completed = getCompletedChallenges();
      final userChallenges = getUserChallenges();

      return {
        'total': all.length,
        'active': active.length,
        'completed': completed.length,
        'participating': userChallenges.length,
      };
    } catch (e) {
      debugPrint('ChallengeService: Error getting stats: $e');
      return {
        'total': 0,
        'active': 0,
        'completed': 0,
        'participating': 0,
      };
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      await Hive.box<WorkoutChallenge>(_challengesBoxName).clear();
      await Hive.box<ChallengeProgress>(_progressBoxName).clear();
      debugPrint('ChallengeService: All data cleared');
    } catch (e) {
      debugPrint('ChallengeService: Error clearing data: $e');
      rethrow;
    }
  }
}
