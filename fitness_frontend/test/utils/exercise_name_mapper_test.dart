import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_frontend/utils/exercise_name_mapper.dart';
import 'package:fitness_frontend/models/exercise_form_rules.dart';

void main() {
  group('ExerciseNameMapper', () {
    late List<ExerciseFormRules> testExercises;

    setUp(() {
      // Create test exercise data
      testExercises = [
        ExerciseFormRules(
          id: 'squat_barbell',
          name: 'Barbell Squat',
          aliases: ['squat', 'back squat', 'barbell squats'],
          type: ExerciseType.squat,
          category: 'squat',
          description: 'Test squat exercise',
          angleRules: [],
          alignmentRules: [],
          repDetection: RepDetectionRule(
            keyJoint: 'LEFT_HIP',
            axis: MovementAxis.y,
            threshold: 0.15,
            direction: MovementDirection.downThenUp,
            holdTimeMs: 200,
          ),
        ),
        ExerciseFormRules(
          id: 'deadlift_barbell',
          name: 'Barbell Deadlift',
          aliases: ['deadlift', 'conventional deadlift'],
          type: ExerciseType.deadlift,
          category: 'hinge',
          description: 'Test deadlift exercise',
          angleRules: [],
          alignmentRules: [],
          repDetection: RepDetectionRule(
            keyJoint: 'LEFT_HIP',
            axis: MovementAxis.y,
            threshold: 0.18,
            direction: MovementDirection.upThenDown,
            holdTimeMs: 300,
          ),
        ),
        ExerciseFormRules(
          id: 'bench_press',
          name: 'Bench Press',
          aliases: ['bench', 'flat bench press'],
          type: ExerciseType.benchPress,
          category: 'horizontal_push',
          description: 'Test bench press exercise',
          angleRules: [],
          alignmentRules: [],
          repDetection: RepDetectionRule(
            keyJoint: 'LEFT_WRIST',
            axis: MovementAxis.y,
            threshold: 0.12,
            direction: MovementDirection.downThenUp,
            holdTimeMs: 250,
          ),
        ),
      ];
    });

    group('findBestMatch', () {
      test('should find exact match by name', () {
        final result = ExerciseNameMapper.findBestMatch(
          'Barbell Squat',
          testExercises,
        );

        expect(result.hasMatch, isTrue);
        expect(result.match!.id, equals('squat_barbell'));
        expect(result.confidence, equals(100.0));
        expect(result.isExactMatch, isTrue);
      });

      test('should find exact match by alias', () {
        final result = ExerciseNameMapper.findBestMatch(
          'deadlift',
          testExercises,
        );

        expect(result.hasMatch, isTrue);
        expect(result.match!.id, equals('deadlift_barbell'));
        expect(result.confidence, equals(100.0));
        expect(result.isExactMatch, isTrue);
      });

      test('should match case-insensitively', () {
        final result = ExerciseNameMapper.findBestMatch(
          'BARBELL SQUAT',
          testExercises,
        );

        expect(result.hasMatch, isTrue);
        expect(result.match!.id, equals('squat_barbell'));
        expect(result.confidence, equals(100.0));
      });

      test('should find fuzzy match with typo', () {
        final result = ExerciseNameMapper.findBestMatch(
          'Barbell Sqat', // Missing 'u'
          testExercises,
        );

        expect(result.hasMatch, isTrue);
        expect(result.match!.id, equals('squat_barbell'));
        expect(result.confidence, greaterThan(80.0));
        expect(result.isExactMatch, isFalse);
      });

      test('should find fuzzy match with extra characters', () {
        final result = ExerciseNameMapper.findBestMatch(
          'Barbell Squats', // Extra 's'
          testExercises,
        );

        expect(result.hasMatch, isTrue);
        expect(result.match!.id, equals('squat_barbell'));
        expect(result.confidence, greaterThan(90.0));
      });

      test('should find substring match', () {
        final result = ExerciseNameMapper.findBestMatch(
          'bench',
          testExercises,
        );

        expect(result.hasMatch, isTrue);
        expect(result.match!.id, equals('bench_press'));
        expect(result.confidence, greaterThan(60.0));
      });

      test('should return no match for completely different name', () {
        final result = ExerciseNameMapper.findBestMatch(
          'Pull Up',
          testExercises,
          minSimilarity: 60.0,
        );

        expect(result.hasMatch, isFalse);
        expect(result.match, isNull);
      });

      test('should return no match for empty string', () {
        final result = ExerciseNameMapper.findBestMatch(
          '',
          testExercises,
        );

        expect(result.hasMatch, isFalse);
        expect(result.confidence, equals(0.0));
      });

      test('should respect minimum similarity threshold', () {
        final result = ExerciseNameMapper.findBestMatch(
          'Squt', // Very different
          testExercises,
          minSimilarity: 95.0, // High threshold
        );

        expect(result.hasMatch, isFalse);
      });
    });

    group('findAllMatches', () {
      test('should find multiple matches sorted by confidence', () {
        final results = ExerciseNameMapper.findAllMatches(
          'squat',
          testExercises,
          minSimilarity: 50.0,
          maxResults: 5,
        );

        expect(results.isNotEmpty, isTrue);
        expect(results.first.match!.id, equals('squat_barbell'));
        expect(results.first.confidence, equals(100.0));
      });

      test('should limit results to maxResults', () {
        final results = ExerciseNameMapper.findAllMatches(
          'barbell',
          testExercises,
          minSimilarity: 30.0,
          maxResults: 2,
        );

        expect(results.length, lessThanOrEqualTo(2));
      });

      test('should sort results by confidence descending', () {
        final results = ExerciseNameMapper.findAllMatches(
          'press',
          testExercises,
          minSimilarity: 30.0,
          maxResults: 5,
        );

        for (int i = 0; i < results.length - 1; i++) {
          expect(
            results[i].confidence,
            greaterThanOrEqualTo(results[i + 1].confidence),
          );
        }
      });

      test('should return empty list for no matches', () {
        final results = ExerciseNameMapper.findAllMatches(
          'xyz123',
          testExercises,
          minSimilarity: 60.0,
        );

        expect(results.isEmpty, isTrue);
      });
    });

    group('suggestCorrections', () {
      test('should suggest corrections for misspelled name', () {
        final suggestions = ExerciseNameMapper.suggestCorrections(
          'deddlift', // Misspelled deadlift
          testExercises,
          maxSuggestions: 3,
        );

        expect(suggestions.isNotEmpty, isTrue);
        expect(suggestions.first, equals('Barbell Deadlift'));
      });

      test('should limit suggestions to maxSuggestions', () {
        final suggestions = ExerciseNameMapper.suggestCorrections(
          'barbell',
          testExercises,
          maxSuggestions: 2,
        );

        expect(suggestions.length, lessThanOrEqualTo(2));
      });

      test('should return empty list for no similar names', () {
        final suggestions = ExerciseNameMapper.suggestCorrections(
          'xyz123',
          testExercises,
        );

        expect(suggestions.isEmpty, isTrue);
      });
    });

    group('filterByCategory', () {
      test('should filter exercises by category', () {
        final squatExercises = ExerciseNameMapper.filterByCategory(
          testExercises,
          'squat',
        );

        expect(squatExercises.length, equals(1));
        expect(squatExercises.first.category, equals('squat'));
      });

      test('should be case-insensitive', () {
        final hingeExercises = ExerciseNameMapper.filterByCategory(
          testExercises,
          'HINGE',
        );

        expect(hingeExercises.length, equals(1));
        expect(hingeExercises.first.category, equals('hinge'));
      });

      test('should return empty list for non-existent category', () {
        final result = ExerciseNameMapper.filterByCategory(
          testExercises,
          'non_existent',
        );

        expect(result.isEmpty, isTrue);
      });
    });

    group('getAllCategories', () {
      test('should return all unique categories', () {
        final categories = ExerciseNameMapper.getAllCategories(testExercises);

        expect(categories.length, equals(3));
        expect(categories, contains('squat'));
        expect(categories, contains('hinge'));
        expect(categories, contains('horizontal_push'));
      });

      test('should return sorted categories', () {
        final categories = ExerciseNameMapper.getAllCategories(testExercises);

        final sortedCategories = List.from(categories)..sort();
        expect(categories, equals(sortedCategories));
      });
    });

    group('searchByKeyword', () {
      test('should find exercises by keyword in name', () {
        final results = ExerciseNameMapper.searchByKeyword(
          testExercises,
          'barbell',
        );

        expect(results.length, equals(2)); // Squat and Deadlift
        expect(results.every((e) => e.name.toLowerCase().contains('barbell')), isTrue);
      });

      test('should find exercises by keyword in alias', () {
        final results = ExerciseNameMapper.searchByKeyword(
          testExercises,
          'bench',
        );

        expect(results.isNotEmpty, isTrue);
        expect(results.first.id, equals('bench_press'));
      });

      test('should find exercises by keyword in description', () {
        final results = ExerciseNameMapper.searchByKeyword(
          testExercises,
          'test',
        );

        expect(results.length, equals(3)); // All have "Test" in description
      });

      test('should be case-insensitive', () {
        final results = ExerciseNameMapper.searchByKeyword(
          testExercises,
          'SQUAT',
        );

        expect(results.isNotEmpty, isTrue);
      });

      test('should return empty list for non-matching keyword', () {
        final results = ExerciseNameMapper.searchByKeyword(
          testExercises,
          'xyz123',
        );

        expect(results.isEmpty, isTrue);
      });
    });

    group('extractEquipmentType', () {
      test('should extract barbell equipment', () {
        final equipment = ExerciseNameMapper.extractEquipmentType('Barbell Squat');
        expect(equipment, equals('barbell'));
      });

      test('should extract dumbbell equipment', () {
        final equipment = ExerciseNameMapper.extractEquipmentType('Dumbbell Press');
        expect(equipment, equals('dumbbell'));
      });

      test('should handle DB abbreviation', () {
        final equipment = ExerciseNameMapper.extractEquipmentType('DB Curl');
        expect(equipment, equals('dumbbell'));
      });

      test('should default to bodyweight', () {
        final equipment = ExerciseNameMapper.extractEquipmentType('Push Up');
        expect(equipment, equals('bodyweight'));
      });

      test('should be case-insensitive', () {
        final equipment = ExerciseNameMapper.extractEquipmentType('KETTLEBELL SWING');
        expect(equipment, equals('kettlebell'));
      });
    });

    group('getCategoryDisplayName', () {
      test('should return friendly name for squat category', () {
        final displayName = ExerciseNameMapper.getCategoryDisplayName('squat');
        expect(displayName, equals('Squat Variations'));
      });

      test('should return friendly name for hinge category', () {
        final displayName = ExerciseNameMapper.getCategoryDisplayName('hinge');
        expect(displayName, equals('Hip Hinge Movements'));
      });

      test('should return original name for unknown category', () {
        final displayName = ExerciseNameMapper.getCategoryDisplayName('unknown');
        expect(displayName, equals('unknown'));
      });

      test('should be case-insensitive', () {
        final displayName = ExerciseNameMapper.getCategoryDisplayName('SQUAT');
        expect(displayName, equals('Squat Variations'));
      });
    });

    group('ExerciseMatchResult', () {
      test('should indicate when there is a match', () {
        final result = ExerciseMatchResult(
          match: testExercises.first,
          confidence: 95.0,
          isExactMatch: false,
        );

        expect(result.hasMatch, isTrue);
      });

      test('should indicate when there is no match', () {
        final result = ExerciseMatchResult(
          match: null,
          confidence: 45.0,
          isExactMatch: false,
        );

        expect(result.hasMatch, isFalse);
      });

      test('should provide correct confidence level for excellent match', () {
        final result = ExerciseMatchResult(
          match: testExercises.first,
          confidence: 98.0,
          isExactMatch: false,
        );

        expect(result.confidenceLevel, equals('Excellent'));
      });

      test('should provide correct confidence level for high match', () {
        final result = ExerciseMatchResult(
          match: testExercises.first,
          confidence: 85.0,
          isExactMatch: false,
        );

        expect(result.confidenceLevel, equals('High'));
      });

      test('should provide correct confidence level for medium match', () {
        final result = ExerciseMatchResult(
          match: testExercises.first,
          confidence: 70.0,
          isExactMatch: false,
        );

        expect(result.confidenceLevel, equals('Medium'));
      });

      test('should provide correct confidence level for low match', () {
        final result = ExerciseMatchResult(
          match: testExercises.first,
          confidence: 55.0,
          isExactMatch: false,
        );

        expect(result.confidenceLevel, equals('Low'));
      });

      test('should format toString correctly for match', () {
        final result = ExerciseMatchResult(
          match: testExercises.first,
          confidence: 100.0,
          isExactMatch: true,
        );

        final str = result.toString();
        expect(str, contains('Barbell Squat'));
        expect(str, contains('Exact'));
        expect(str, contains('100.0'));
      });

      test('should format toString correctly for no match', () {
        final result = ExerciseMatchResult(
          match: null,
          confidence: 30.0,
          isExactMatch: false,
        );

        final str = result.toString();
        expect(str, contains('No match found'));
        expect(str, contains('30.0'));
      });
    });
  });
}
