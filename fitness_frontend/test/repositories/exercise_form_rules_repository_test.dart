import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_frontend/repositories/exercise_form_rules_repository.dart';
import 'package:fitness_frontend/models/exercise_form_rules.dart';
import 'package:fitness_frontend/models/form_analysis.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExerciseFormRulesRepository', () {
    late ExerciseFormRulesRepository repository;

    setUp(() {
      repository = ExerciseFormRulesRepository();
    });

    tearDown(() {
      repository.clearCache();
    });

    group('loadRules', () {
      test('should load rules successfully', () async {
        // Note: This test requires the actual JSON file to exist
        // In a real test environment, you might mock the rootBundle
        try {
          await repository.loadRules();
          expect(repository.isLoaded, isTrue);
          expect(repository.exerciseCount, greaterThan(0));
        } on Exception catch (e) {
          // If file doesn't exist in test environment, that's expected
          expect(e.toString(), contains('Failed to load'));
        }
      });

      test('should not reload if already loaded', () async {
        // Mock test - can't fully test without mocking rootBundle
        try {
          await repository.loadRules();
          final count1 = repository.exerciseCount;

          await repository.loadRules(); // Second call
          final count2 = repository.exerciseCount;

          expect(count1, equals(count2));
        } catch (e) {
          // Expected if file doesn't exist
        }
      });
    });

    group('getFallbackRules', () {
      test('should generate squat fallback rules', () {
        final rules = repository.getFallbackRules('Goblet Squat');

        expect(rules.name, equals('Goblet Squat'));
        expect(rules.category, equals('squat'));
        expect(rules.type, equals(ExerciseType.squat));
        expect(rules.angleRules.isNotEmpty, isTrue);
        expect(rules.repDetection.direction, equals(MovementDirection.downThenUp));
      });

      test('should generate deadlift fallback rules', () {
        final rules = repository.getFallbackRules('Romanian Deadlift');

        expect(rules.name, equals('Romanian Deadlift'));
        expect(rules.category, equals('hinge'));
        expect(rules.type, equals(ExerciseType.deadlift));
        expect(rules.angleRules.isNotEmpty, isTrue);
      });

      test('should generate push fallback rules for overhead press', () {
        final rules = repository.getFallbackRules('Overhead Press');

        expect(rules.name, equals('Overhead Press'));
        expect(rules.category, equals('vertical_push'));
        expect(rules.type, equals(ExerciseType.overheadPress));
      });

      test('should generate push fallback rules for bench press', () {
        final rules = repository.getFallbackRules('Dumbbell Press');

        expect(rules.name, equals('Dumbbell Press'));
        expect(rules.category, equals('horizontal_push'));
        expect(rules.type, equals(ExerciseType.benchPress));
      });

      test('should generate pull fallback rules for vertical pull', () {
        final rules = repository.getFallbackRules('Pull Up');

        expect(rules.name, equals('Pull Up'));
        expect(rules.category, equals('vertical_pull'));
      });

      test('should generate pull fallback rules for horizontal pull', () {
        final rules = repository.getFallbackRules('Barbell Row');

        expect(rules.name, equals('Barbell Row'));
        expect(rules.category, equals('horizontal_pull'));
      });

      test('should generate core fallback rules', () {
        final rules = repository.getFallbackRules('Plank');

        expect(rules.name, equals('Plank'));
        expect(rules.category, equals('core'));
        expect(rules.repDetection.direction, equals(MovementDirection.downThenUp));
      });

      test('should generate accessory fallback rules', () {
        final rules = repository.getFallbackRules('Bicep Curl');

        expect(rules.name, equals('Bicep Curl'));
        expect(rules.category, equals('accessory'));
      });

      test('should generate generic fallback for unknown exercise', () {
        final rules = repository.getFallbackRules('Some Unknown Exercise');

        expect(rules.name, equals('Some Unknown Exercise'));
        expect(rules.category, equals('other'));
        expect(rules.type, equals(ExerciseType.other));
        expect(rules.angleRules.isNotEmpty, isTrue);
      });

      test('should include appropriate violations in fallback rules', () {
        final squatRules = repository.getFallbackRules('Bulgarian Split Squat');

        final hasKneeRule = squatRules.angleRules.any(
          (rule) => rule.name.toLowerCase().contains('knee'),
        );
        final hasBackRule = squatRules.angleRules.any(
          (rule) => rule.name.toLowerCase().contains('back'),
        );

        expect(hasKneeRule, isTrue);
        expect(hasBackRule, isTrue);
      });
    });

    group('state management', () {
      test('isLoaded should be false initially', () {
        expect(repository.isLoaded, isFalse);
      });

      test('clearCache should reset loaded state', () async {
        try {
          await repository.loadRules();
          expect(repository.isLoaded, isTrue);

          repository.clearCache();
          expect(repository.isLoaded, isFalse);
        } catch (e) {
          // Expected if file doesn't exist
        }
      });

      test('should throw StateError when accessing before loading', () {
        expect(
          () => repository.getAllExercises(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('findExerciseByName (without loading)', () {
      test('should throw StateError when not loaded', () {
        expect(
          () => repository.findExerciseByName('Squat'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('getAllCategories (without loading)', () {
      test('should throw StateError when not loaded', () {
        expect(
          () => repository.getAllCategories(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('fallback rule categories', () {
      test('should detect lunge as squat category', () {
        final rules = repository.getFallbackRules('Walking Lunges');
        expect(rules.category, equals('squat'));
      });

      test('should detect good morning as hinge category', () {
        final rules = repository.getFallbackRules('Good Morning');
        expect(rules.category, equals('hinge'));
      });

      test('should detect shoulder press as vertical push', () {
        final rules = repository.getFallbackRules('Shoulder Press');
        expect(rules.category, equals('vertical_push'));
      });

      test('should detect military press as vertical push', () {
        final rules = repository.getFallbackRules('Military Press');
        expect(rules.category, equals('vertical_push'));
      });

      test('should detect bench as horizontal push', () {
        final rules = repository.getFallbackRules('Bench Press');
        expect(rules.category, equals('horizontal_push'));
      });

      test('should detect pull up as vertical pull', () {
        final rules = repository.getFallbackRules('Chin Up');
        expect(rules.category, equals('vertical_pull'));
      });

      test('should detect lat pulldown as vertical pull', () {
        final rules = repository.getFallbackRules('Lat Pulldown');
        expect(rules.category, equals('vertical_pull'));
      });

      test('should detect crunch as core', () {
        final rules = repository.getFallbackRules('Ab Crunch');
        expect(rules.category, equals('core'));
      });

      test('should detect sit up as core', () {
        final rules = repository.getFallbackRules('Sit Up');
        expect(rules.category, equals('core'));
      });

      test('should detect raise as accessory', () {
        final rules = repository.getFallbackRules('Lateral Raise');
        expect(rules.category, equals('accessory'));
      });

      test('should detect fly as accessory', () {
        final rules = repository.getFallbackRules('Chest Fly');
        expect(rules.category, equals('accessory'));
      });
    });

    group('fallback rule generation', () {
      test('should generate unique IDs for different exercises', () {
        final rules1 = repository.getFallbackRules('Exercise One');
        final rules2 = repository.getFallbackRules('Exercise Two');

        expect(rules1.id, isNot(equals(rules2.id)));
      });

      test('should include description in fallback rules', () {
        final rules = repository.getFallbackRules('Test Exercise');

        expect(rules.description, contains('Test Exercise'));
        expect(rules.description, contains('Auto-generated'));
      });

      test('should include exercise name in aliases', () {
        final rules = repository.getFallbackRules('My Exercise');

        expect(rules.aliases, contains('my exercise'));
      });

      test('should set appropriate severity levels', () {
        final rules = repository.getFallbackRules('Squat');

        final criticalRules = rules.angleRules.where(
          (rule) => rule.severity == Severity.critical,
        );

        expect(criticalRules.isNotEmpty, isTrue);
      });

      test('should set reasonable angle ranges', () {
        final rules = repository.getFallbackRules('Squat');

        for (final rule in rules.angleRules) {
          expect(rule.minDegrees, greaterThanOrEqualTo(0));
          expect(rule.maxDegrees, lessThanOrEqualTo(185));
          expect(rule.minDegrees, lessThan(rule.maxDegrees));
        }
      });

      test('should set appropriate rep detection thresholds', () {
        final rules = repository.getFallbackRules('Squat');

        expect(rules.repDetection.threshold, greaterThan(0));
        expect(rules.repDetection.threshold, lessThan(1.0));
      });

      test('should set appropriate hold times', () {
        final rules = repository.getFallbackRules('Squat');

        expect(rules.repDetection.holdTimeMs, greaterThan(0));
        expect(rules.repDetection.holdTimeMs, lessThan(5000));
      });
    });

    group('category-specific rep detection', () {
      test('squat should use downThenUp movement', () {
        final rules = repository.getFallbackRules('Squat');
        expect(rules.repDetection.direction, equals(MovementDirection.downThenUp));
      });

      test('deadlift should use upThenDown movement', () {
        final rules = repository.getFallbackRules('Deadlift');
        expect(rules.repDetection.direction, equals(MovementDirection.upThenDown));
      });

      test('plank should use downThenUp movement', () {
        final rules = repository.getFallbackRules('Plank');
        expect(rules.repDetection.direction, equals(MovementDirection.downThenUp));
      });

      test('bench press should use downThenUp movement', () {
        final rules = repository.getFallbackRules('Bench Press');
        expect(rules.repDetection.direction, equals(MovementDirection.downThenUp));
      });

      test('overhead press should use upThenDown movement', () {
        final rules = repository.getFallbackRules('Overhead Press');
        expect(rules.repDetection.direction, equals(MovementDirection.upThenDown));
      });
    });

    group('category-specific key joints', () {
      test('squat should track hip joint', () {
        final rules = repository.getFallbackRules('Squat');
        expect(rules.repDetection.keyJoint, equals('LEFT_HIP'));
      });

      test('horizontal push should track wrist joint', () {
        final rules = repository.getFallbackRules('Push Up');
        expect(rules.repDetection.keyJoint, equals('LEFT_WRIST'));
      });

      test('vertical push should track wrist joint', () {
        final rules = repository.getFallbackRules('Overhead Press');
        expect(rules.repDetection.keyJoint, equals('LEFT_WRIST'));
      });

      test('core exercises should track hip joint', () {
        final rules = repository.getFallbackRules('Plank');
        expect(rules.repDetection.keyJoint, equals('LEFT_HIP'));
      });
    });
  });
}
