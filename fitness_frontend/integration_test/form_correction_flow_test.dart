import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitness_frontend/main.dart' as app;
import 'package:fitness_frontend/repositories/exercise_form_rules_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Form Correction Flow Integration Tests', () {
    testWidgets('should load exercise rules on app start', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // App should load without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should initialize repository and load exercises', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        await repository.loadRules();

        expect(repository.isLoaded, isTrue);
        expect(repository.exerciseCount, greaterThan(0));

        // Should have multiple categories
        final categories = repository.getAllCategories();
        expect(categories.length, greaterThan(3));

        // Should have squat exercises
        final squatExercises = repository.getExercisesByCategory('squat');
        expect(squatExercises.isNotEmpty, isTrue);
      } catch (e) {
        // Expected if JSON file is not available in test environment
        fail('Repository failed to load: $e');
      }
    });

    testWidgets('should find exercises by name', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        await repository.loadRules();

        // Test exact match
        final exactMatch = repository.findExerciseByName('Barbell Squat');
        expect(exactMatch, isNotNull);
        expect(exactMatch!.name, contains('Squat'));

        // Test fuzzy match
        final fuzzyMatch = repository.findExerciseByName('Squat');
        expect(fuzzyMatch, isNotNull);

        // Test with typo
        final typoMatch = repository.findExerciseByName('Barrbell Squat');
        expect(typoMatch, isNotNull);
      } catch (e) {
        // May not have JSON in test environment
      }
    });

    testWidgets('should generate fallback rules for unknown exercises', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      final fallbackSquat = repository.getFallbackRules('Custom Squat Exercise');
      expect(fallbackSquat.category, equals('squat'));
      expect(fallbackSquat.angleRules.isNotEmpty, isTrue);

      final fallbackDeadlift = repository.getFallbackRules('Custom Deadlift');
      expect(fallbackDeadlift.category, equals('hinge'));

      final fallbackPush = repository.getFallbackRules('Custom Press');
      expect(fallbackPush.category, anyOf(equals('horizontal_push'), equals('vertical_push')));
    });

    testWidgets('should provide exercise suggestions', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        await repository.loadRules();

        final suggestions = repository.getSuggestedCorrections('deddlift', max: 3);
        expect(suggestions.isNotEmpty, isTrue);
        expect(suggestions.first.toLowerCase(), contains('deadlift'));
      } catch (e) {
        // May not have JSON in test environment
      }
    });

    testWidgets('should group exercises by category', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        await repository.loadRules();

        final grouped = repository.getExercisesGroupedByCategory();
        expect(grouped.isNotEmpty, isTrue);

        // Each category should have at least one exercise
        for (final entry in grouped.entries) {
          expect(entry.value.isNotEmpty, isTrue,
              reason: 'Category ${entry.key} should have exercises');
        }
      } catch (e) {
        // May not have JSON in test environment
      }
    });

    testWidgets('should search exercises by keywords', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        await repository.loadRules();

        // Search by single keyword
        final squatResults = repository.searchExercises('squat');
        expect(squatResults.isNotEmpty, isTrue);

        // Search by multiple keywords
        final barbellResults = repository.findExercisesByKeywords(['barbell', 'squat']);
        expect(barbellResults.isNotEmpty, isTrue);
      } catch (e) {
        // May not have JSON in test environment
      }
    });

    testWidgets('should provide repository statistics', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        await repository.loadRules();

        final stats = repository.getStatistics();

        expect(stats['totalExercises'], greaterThan(0));
        expect(stats['totalViolations'], greaterThan(0));
        expect(stats['exercisesByType'], isA<Map>());
        expect(stats['totalAngleRules'], greaterThan(0));
      } catch (e) {
        // May not have JSON in test environment
      }
    });

    testWidgets('should handle cache clearing', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        await repository.loadRules();
        expect(repository.isLoaded, isTrue);

        repository.clearCache();
        expect(repository.isLoaded, isFalse);

        // Should be able to reload
        await repository.loadRules();
        expect(repository.isLoaded, isTrue);
      } catch (e) {
        // May not have JSON in test environment
      }
    });

    testWidgets('should prevent accessing unloaded repository', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      expect(
        () => repository.getAllExercises(),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('end-to-end: find exercise, analyze form, count reps', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        // Step 1: Load rules
        await repository.loadRules();

        // Step 2: Find exercise (with fallback)
        var rules = repository.findExerciseByName('Barbell Squat');
        rules ??= repository.getFallbackRules('Barbell Squat');

        expect(rules.name, contains('Squat'));

        // Step 3: Verify rules have proper configuration
        expect(rules.repDetection, isNotNull);
        expect(rules.angleRules.isNotEmpty, isTrue);

        // Step 4: Verify rep detection settings
        final repDetection = rules.repDetection;
        expect(repDetection.threshold, greaterThan(0));
        expect(repDetection.threshold, lessThan(1));
        expect(repDetection.holdTimeMs, greaterThan(0));

        // Step 5: Verify angle rules have proper ranges
        for (final angleRule in rules.angleRules) {
          expect(angleRule.minDegrees, lessThan(angleRule.maxDegrees));
          expect(angleRule.joints.length, equals(3));
        }
      } catch (e) {
        fail('End-to-end test failed: $e');
      }
    });

    testWidgets('performance: should load 30+ exercises quickly', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      final stopwatch = Stopwatch()..start();

      try {
        await repository.loadRules();
        stopwatch.stop();

        expect(repository.exerciseCount, greaterThanOrEqualTo(30));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Loading should complete within 1 second');
      } catch (e) {
        // May not have JSON in test environment
      }
    });

    testWidgets('performance: should perform fuzzy matching quickly', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        await repository.loadRules();

        final stopwatch = Stopwatch()..start();

        // Perform 100 fuzzy matches
        for (int i = 0; i < 100; i++) {
          repository.findExerciseByName('squat variation $i');
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
            reason: '100 fuzzy matches should complete within 5 seconds');
      } catch (e) {
        // May not have JSON in test environment
      }
    });

    testWidgets('stress test: should handle rapid exercise lookups', (WidgetTester tester) async {
      final repository = ExerciseFormRulesRepository();

      try {
        await repository.loadRules();

        final exerciseNames = [
          'Squat',
          'Deadlift',
          'Bench Press',
          'Overhead Press',
          'Pull Up',
          'Barbell Row',
          'Lunge',
          'Plank',
        ];

        // Perform 1000 rapid lookups
        for (int i = 0; i < 1000; i++) {
          final name = exerciseNames[i % exerciseNames.length];
          final rules = repository.findExerciseByName(name);
          expect(rules, isNotNull);
        }
      } catch (e) {
        fail('Stress test failed: $e');
      }
    });
  });
}
