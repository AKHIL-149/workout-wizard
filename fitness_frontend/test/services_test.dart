import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_frontend/services/storage_service.dart';
import 'package:fitness_frontend/services/session_service.dart';
import 'package:fitness_frontend/models/user_profile.dart';
import 'package:fitness_frontend/models/recommendation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit tests for core services in the Fitness Recommender app.
///
/// Tests individual service methods in isolation to ensure correct behavior.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Tests', () {
    late StorageService storageService;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.initialize();
    });

    test('initialize() completes successfully', () async {
      expect(() async => await storageService.initialize(), returnsNormally);
    });

    test('saveUserProfile() and getLastUserProfile() work correctly', () async {
      final profile = UserProfile(
        fitnessLevel: 'Intermediate',
        goals: ['Weight Loss', 'Strength'],
        equipment: 'Full Gym',
      );

      await storageService.saveUserProfile(profile);
      final retrieved = await storageService.getLastUserProfile();

      expect(retrieved, isNotNull);
      expect(retrieved!.fitnessLevel, equals('Intermediate'));
      expect(retrieved.goals, containsAll(['Weight Loss', 'Strength']));
      expect(retrieved.equipment, equals('Full Gym'));
    });

    test('addToFavorites() and getFavorites() work correctly', () async {
      await storageService.addToFavorites('PROG001');
      await storageService.addToFavorites('PROG002');

      final favorites = await storageService.getFavorites();
      expect(favorites, hasLength(2));
      expect(favorites, containsAll(['PROG001', 'PROG002']));
    });

    test('addToFavorites() prevents duplicates', () async {
      await storageService.addToFavorites('PROG001');
      await storageService.addToFavorites('PROG001');

      final favorites = await storageService.getFavorites();
      expect(favorites, hasLength(1));
    });

    test('removeFromFavorites() works correctly', () async {
      await storageService.addToFavorites('PROG001');
      await storageService.addToFavorites('PROG002');
      await storageService.removeFromFavorites('PROG001');

      final favorites = await storageService.getFavorites();
      expect(favorites, hasLength(1));
      expect(favorites, contains('PROG002'));
      expect(favorites, isNot(contains('PROG001')));
    });

    test('isFavorite() returns correct status', () async {
      await storageService.addToFavorites('PROG001');

      expect(await storageService.isFavorite('PROG001'), isTrue);
      expect(await storageService.isFavorite('PROG002'), isFalse);
    });

    test('addToSearchHistory() maintains order', () async {
      await storageService.addToSearchHistory('query1');
      await storageService.addToSearchHistory('query2');
      await storageService.addToSearchHistory('query3');

      final history = await storageService.getSearchHistory();
      expect(history[0], equals('query3')); // Most recent first
      expect(history[1], equals('query2'));
      expect(history[2], equals('query1'));
    });

    test('addToSearchHistory() limits to 10 items', () async {
      for (int i = 0; i < 15; i++) {
        await storageService.addToSearchHistory('query$i');
      }

      final history = await storageService.getSearchHistory();
      expect(history, hasLength(10));
    });

    test('addToSearchHistory() removes duplicates', () async {
      await storageService.addToSearchHistory('query1');
      await storageService.addToSearchHistory('query2');
      await storageService.addToSearchHistory('query1'); // Duplicate

      final history = await storageService.getSearchHistory();
      expect(history, hasLength(2));
      expect(history[0], equals('query1')); // Should move to front
    });

    test('clearSearchHistory() removes all history', () async {
      await storageService.addToSearchHistory('query1');
      await storageService.addToSearchHistory('query2');
      await storageService.clearSearchHistory();

      final history = await storageService.getSearchHistory();
      expect(history, isEmpty);
    });

    test('trackViewedProgram() records views', () async {
      await storageService.trackViewedProgram('PROG001');
      await storageService.trackViewedProgram('PROG002');

      final viewed = await storageService.getViewedPrograms();
      expect(viewed, hasLength(2));
      expect(viewed, containsAll(['PROG001', 'PROG002']));
    });

    test('trackViewedProgram() prevents duplicates', () async {
      await storageService.trackViewedProgram('PROG001');
      await storageService.trackViewedProgram('PROG001');

      final viewed = await storageService.getViewedPrograms();
      expect(viewed, hasLength(1));
    });

    test('markProgramCompleted() records completions', () async {
      await storageService.markProgramCompleted('PROG001');

      final completed = await storageService.getCompletedPrograms();
      expect(completed, contains('PROG001'));
    });

    test('clearAllData() removes all stored data', () async {
      await storageService.addToFavorites('PROG001');
      await storageService.addToSearchHistory('query1');
      await storageService.trackViewedProgram('PROG002');

      await storageService.clearAllData();

      expect(await storageService.getFavorites(), isEmpty);
      expect(await storageService.getSearchHistory(), isEmpty);
      expect(await storageService.getViewedPrograms(), isEmpty);
    });
  });

  group('SessionService Tests', () {
    late SessionService sessionService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sessionService = SessionService();
      await sessionService.initialize();
    });

    test('initialize() generates device ID', () async {
      expect(sessionService.deviceId, isNotEmpty);
      expect(sessionService.deviceId, isNot(equals('unknown')));
    });

    test('isNewUser returns true for first launch', () async {
      // First initialization
      expect(sessionService.isNewUser, isTrue);
    });

    test('totalLaunches increments on each initialization', () async {
      final firstCount = sessionService.totalLaunches;

      // Reinitialize to simulate app restart
      await sessionService.initialize();
      expect(sessionService.totalLaunches, greaterThan(firstCount));
    });

    test('currentStreak starts at 0', () {
      expect(sessionService.currentStreak, equals(0));
    });

    test('deviceId persists across sessions', () async {
      final firstDeviceId = sessionService.deviceId;

      // Simulate new session
      final newSessionService = SessionService();
      await newSessionService.initialize();

      expect(newSessionService.deviceId, equals(firstDeviceId));
    });

    test('lastSeenVersion is recorded', () {
      expect(sessionService.lastSeenVersion, isNotEmpty);
    });
  });

  group('UserProfile Tests', () {
    test('UserProfile.toJson() produces valid JSON', () {
      final profile = UserProfile(
        fitnessLevel: 'Beginner',
        goals: ['General Fitness'],
        equipment: 'At Home',
        preferredDuration: '30-45 min',
        preferredFrequency: 3,
        preferredStyle: 'Full Body',
      );

      final json = profile.toJson();

      expect(json['fitness_level'], equals('Beginner'));
      expect(json['goals'], equals(['General Fitness']));
      expect(json['equipment'], equals('At Home'));
      expect(json['preferred_duration'], equals('30-45 min'));
      expect(json['preferred_frequency'], equals(3));
      expect(json['preferred_style'], equals('Full Body'));
    });

    test('UserProfile handles optional fields', () {
      final profile = UserProfile(
        fitnessLevel: 'Beginner',
        goals: ['General Fitness'],
        equipment: 'At Home',
      );

      final json = profile.toJson();

      expect(json['preferred_duration'], isNull);
      expect(json['preferred_frequency'], isNull);
      expect(json['preferred_style'], isNull);
    });
  });

  group('Recommendation Tests', () {
    test('Recommendation.fromJson() parses correctly', () {
      final json = {
        'program_id': 'FP000001',
        'title': 'Test Program',
        'primary_level': 'Intermediate',
        'primary_goal': 'Strength',
        'equipment': 'Full Gym',
        'program_length': 12,
        'time_per_workout': 60,
        'workout_frequency': 4,
        'match_percentage': 95,
      };

      final recommendation = Recommendation.fromJson('FP000001', json);

      expect(recommendation.programId, equals('FP000001'));
      expect(recommendation.title, equals('Test Program'));
      expect(recommendation.primaryLevel, equals('Intermediate'));
      expect(recommendation.matchPercentage, equals(95));
    });

    test('Recommendation.toJson() produces valid JSON', () {
      final recommendation = Recommendation(
        programId: 'FP000001',
        title: 'Test Program',
        primaryLevel: 'Intermediate',
        primaryGoal: 'Strength',
        equipment: 'Full Gym',
        programLength: 12,
        timePerWorkout: 60,
        workoutFrequency: 4,
        matchPercentage: 95,
      );

      final json = recommendation.toJson();

      expect(json['program_id'], equals('FP000001'));
      expect(json['title'], equals('Test Program'));
      expect(json['match_percentage'], equals(95));
    });
  });
}
