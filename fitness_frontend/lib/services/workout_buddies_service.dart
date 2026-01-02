import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/social_models.dart';

/// Service for managing workout buddies and progress sharing
class WorkoutBuddiesService {
  static final WorkoutBuddiesService _instance =
      WorkoutBuddiesService._internal();
  factory WorkoutBuddiesService() => _instance;
  WorkoutBuddiesService._internal();

  static const String _profileBoxName = 'social_profile';
  static const String _buddiesBoxName = 'workout_buddies';
  static const String _updatesBoxName = 'progress_updates';

  final Uuid _uuid = const Uuid();

  /// Initialize Hive boxes
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_profileBoxName)) {
        await Hive.openBox<SocialProfile>(_profileBoxName);
      }
      if (!Hive.isBoxOpen(_buddiesBoxName)) {
        await Hive.openBox<WorkoutBuddy>(_buddiesBoxName);
      }
      if (!Hive.isBoxOpen(_updatesBoxName)) {
        await Hive.openBox<ProgressUpdate>(_updatesBoxName);
      }

      debugPrint('WorkoutBuddiesService: Initialized');
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error initializing: $e');
      rethrow;
    }
  }

  /// Get user's social profile
  SocialProfile? getSocialProfile() {
    try {
      final box = Hive.box<SocialProfile>(_profileBoxName);
      return box.get('profile');
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error getting profile: $e');
      return null;
    }
  }

  /// Create or update social profile
  Future<void> saveSocialProfile(SocialProfile profile) async {
    try {
      final box = Hive.box<SocialProfile>(_profileBoxName);
      await box.put('profile', profile);
      debugPrint('WorkoutBuddiesService: Profile saved');
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error saving profile: $e');
      rethrow;
    }
  }

  /// Create initial profile
  Future<SocialProfile> createInitialProfile(String displayName,
      {String? avatarEmoji, String? bio}) async {
    try {
      final profile = SocialProfile(
        id: _uuid.v4(),
        displayName: displayName,
        avatarEmoji: avatarEmoji ?? '💪',
        createdAt: DateTime.now(),
        bio: bio,
        stats: {
          'totalWorkouts': 0,
          'totalExercises': 0,
          'totalSets': 0,
          'totalReps': 0,
          'totalVolume': 0.0,
        },
      );

      await saveSocialProfile(profile);
      return profile;
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error creating profile: $e');
      rethrow;
    }
  }

  /// Update profile stats
  Future<void> updateProfileStats(Map<String, dynamic> newStats) async {
    try {
      final profile = getSocialProfile();
      if (profile == null) return;

      final updatedProfile = profile.copyWith(
        stats: {...profile.stats, ...newStats},
      );

      await saveSocialProfile(updatedProfile);
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error updating stats: $e');
    }
  }

  /// Get all workout buddies
  List<WorkoutBuddy> getAllBuddies() {
    try {
      final box = Hive.box<WorkoutBuddy>(_buddiesBoxName);
      return box.values.toList()
        ..sort((a, b) => b.connectedAt.compareTo(a.connectedAt));
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error getting buddies: $e');
      return [];
    }
  }

  /// Add a workout buddy
  Future<void> addBuddy(WorkoutBuddy buddy) async {
    try {
      final box = Hive.box<WorkoutBuddy>(_buddiesBoxName);
      await box.put(buddy.id, buddy);
      debugPrint('WorkoutBuddiesService: Buddy added: ${buddy.displayName}');
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error adding buddy: $e');
      rethrow;
    }
  }

  /// Remove a workout buddy
  Future<void> removeBuddy(String buddyId) async {
    try {
      final box = Hive.box<WorkoutBuddy>(_buddiesBoxName);
      await box.delete(buddyId);
      debugPrint('WorkoutBuddiesService: Buddy removed');
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error removing buddy: $e');
      rethrow;
    }
  }

  /// Update buddy's last activity
  Future<void> updateBuddyActivity(
      String buddyId, String activity, Map<String, dynamic> data) async {
    try {
      final box = Hive.box<WorkoutBuddy>(_buddiesBoxName);
      final buddy = box.get(buddyId);

      if (buddy != null) {
        final updatedBuddy = buddy.copyWith(
          lastActivity: activity,
          lastActivitySync: DateTime.now(),
          sharedData: {...buddy.sharedData, ...data},
        );

        await box.put(buddyId, updatedBuddy);
      }
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error updating buddy activity: $e');
    }
  }

  /// Add progress update to feed
  Future<void> addProgressUpdate(ProgressUpdate update) async {
    try {
      final box = Hive.box<ProgressUpdate>(_updatesBoxName);
      await box.put(update.id, update);
      debugPrint('WorkoutBuddiesService: Progress update added');

      // Keep only last 100 updates
      if (box.length > 100) {
        final updates = box.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Remove old updates
        for (var i = 100; i < updates.length; i++) {
          await box.delete(updates[i].id);
        }
      }
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error adding update: $e');
      rethrow;
    }
  }

  /// Get progress updates (feed)
  List<ProgressUpdate> getProgressUpdates({int limit = 50}) {
    try {
      final box = Hive.box<ProgressUpdate>(_updatesBoxName);
      final updates = box.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return updates.take(limit).toList();
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error getting updates: $e');
      return [];
    }
  }

  /// Get progress updates for a specific buddy
  List<ProgressUpdate> getBuddyUpdates(String buddyId, {int limit = 20}) {
    try {
      final box = Hive.box<ProgressUpdate>(_updatesBoxName);
      final updates = box.values.where((u) => u.userId == buddyId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return updates.take(limit).toList();
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error getting buddy updates: $e');
      return [];
    }
  }

  /// Create workout completion update
  Future<void> createWorkoutUpdate(
      String workoutName, Map<String, dynamic> workoutData) async {
    try {
      final profile = getSocialProfile();
      if (profile == null) return;

      final update = ProgressUpdate(
        id: _uuid.v4(),
        userId: profile.id,
        userName: profile.displayName,
        timestamp: DateTime.now(),
        updateType: 'workout_completed',
        message: 'Completed $workoutName',
        data: workoutData,
        avatarEmoji: profile.avatarEmoji,
      );

      await addProgressUpdate(update);
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error creating workout update: $e');
    }
  }

  /// Create PR (Personal Record) update
  Future<void> createPRUpdate(
      String exercise, String prType, dynamic value) async {
    try {
      final profile = getSocialProfile();
      if (profile == null) return;

      final update = ProgressUpdate(
        id: _uuid.v4(),
        userId: profile.id,
        userName: profile.displayName,
        timestamp: DateTime.now(),
        updateType: 'personal_record',
        message: 'New $prType PR on $exercise: $value',
        data: {
          'exercise': exercise,
          'prType': prType,
          'value': value,
        },
        avatarEmoji: profile.avatarEmoji,
      );

      await addProgressUpdate(update);
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error creating PR update: $e');
    }
  }

  /// Create achievement update
  Future<void> createAchievementUpdate(
      String achievement, String description) async {
    try {
      final profile = getSocialProfile();
      if (profile == null) return;

      final update = ProgressUpdate(
        id: _uuid.v4(),
        userId: profile.id,
        userName: profile.displayName,
        timestamp: DateTime.now(),
        updateType: 'achievement',
        message: achievement,
        data: {'description': description},
        avatarEmoji: profile.avatarEmoji,
      );

      await addProgressUpdate(update);
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error creating achievement update: $e');
    }
  }

  /// Export buddy connection data for sharing
  String exportBuddyConnection() {
    try {
      final profile = getSocialProfile();
      if (profile == null) {
        throw Exception('No profile found');
      }

      final connectionData = {
        'version': '1.0',
        'type': 'buddy_connection',
        'profile': profile.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(connectionData);
      final bytes = utf8.encode(jsonString);
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error exporting connection: $e');
      rethrow;
    }
  }

  /// Import buddy connection from shared data
  Future<WorkoutBuddy> importBuddyConnection(String data) async {
    try {
      // Decode from base64
      String jsonString;
      try {
        final bytes = base64Decode(data);
        jsonString = utf8.decode(bytes);
      } catch (e) {
        // If base64 decode fails, assume it's already JSON
        jsonString = data;
      }

      final Map<String, dynamic> json = jsonDecode(jsonString);

      // Validate structure
      if (json['type'] != 'buddy_connection') {
        throw Exception('Invalid data format: not a buddy connection');
      }

      if (json['profile'] == null) {
        throw Exception('Missing profile data');
      }

      // Parse profile
      final profileData = json['profile'] as Map<String, dynamic>;
      final profile = SocialProfile.fromJson(profileData);

      // Create buddy from profile
      final buddy = WorkoutBuddy(
        id: profile.id,
        displayName: profile.displayName,
        avatarEmoji: profile.avatarEmoji,
        connectedAt: DateTime.now(),
        sharedData: profile.stats,
      );

      // Add buddy
      await addBuddy(buddy);

      debugPrint(
          'WorkoutBuddiesService: Imported buddy ${buddy.displayName}');
      return buddy;
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error importing connection: $e');
      rethrow;
    }
  }

  /// Check if buddy exists
  bool isBuddyConnected(String buddyId) {
    try {
      final box = Hive.box<WorkoutBuddy>(_buddiesBoxName);
      return box.containsKey(buddyId);
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error checking buddy: $e');
      return false;
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      await Hive.box<SocialProfile>(_profileBoxName).clear();
      await Hive.box<WorkoutBuddy>(_buddiesBoxName).clear();
      await Hive.box<ProgressUpdate>(_updatesBoxName).clear();
      debugPrint('WorkoutBuddiesService: All data cleared');
    } catch (e) {
      debugPrint('WorkoutBuddiesService: Error clearing data: $e');
      rethrow;
    }
  }
}
