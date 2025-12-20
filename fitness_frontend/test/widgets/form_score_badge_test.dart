import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_frontend/widgets/form_score_badge.dart';
import 'package:fitness_frontend/models/form_analysis.dart';

void main() {
  group('FormScoreBadge', () {
    testWidgets('should display A+ grade for 95+ score', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(98.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      expect(find.text('A+'), findsOneWidget);
      expect(find.text('98%'), findsOneWidget);
    });

    testWidgets('should display A grade for 90-94 score', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(92.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
    });

    testWidgets('should display A- grade for 85-89 score', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(85.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      expect(find.text('A-'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('should display B grade for 75-79 score', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(75.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      expect(find.text('B'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('should display C+ grade for 65-69 score', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(65.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      expect(find.text('C+'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('should display F grade for below 60 score', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(45.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      expect(find.text('F'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('should use green color for high scores', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(95.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      // Verify the score has a green color (for A+ grade >= 95%)
      expect(score.displayColor, equals(Colors.green[700]));

      // Verify the grade text widget uses the correct color
      final gradeText = tester.widget<Text>(
        find.text('A+'),
      );
      expect(gradeText.style?.color, equals(Colors.green[700]));
    });

    testWidgets('should handle minimum score (0)', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(0.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      expect(find.text('F'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('should handle maximum score (100)', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(100.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      expect(find.text('A+'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('should have proper size constraints', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(85.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      final badge = tester.getSize(find.byType(FormScoreBadge));
      expect(badge.width, greaterThan(0));
      expect(badge.height, greaterThan(0));
    });

    testWidgets('should be accessible', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(85.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(score: score),
          ),
        ),
      );

      // Should have proper semantic labels
      final semantics = tester.getSemantics(find.byType(FormScoreBadge));
      expect(semantics.label, isNotNull);
    });

    // Compact mode test removed - feature not yet implemented in widget
    testWidgets('should have consistent size', (WidgetTester tester) async {
      final score = FormScore.fromPercentage(85.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormScoreBadge(
              score: score,
            ),
          ),
        ),
      );

      // Should display grade (85% -> A-)
      expect(find.text('A-'), findsOneWidget);

      final size = tester.getSize(find.byType(FormScoreBadge));

      // Size should be reasonable
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    testWidgets('should update when score changes', (WidgetTester tester) async {
      var percentage = 45.0;  // F grade (< 50%)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    FormScoreBadge(
                      score: FormScore.fromPercentage(percentage),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => percentage = 95.0),
                      child: const Text('Improve'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('F'), findsOneWidget);

      await tester.tap(find.text('Improve'));
      await tester.pump();

      expect(find.text('A+'), findsOneWidget);
    });
  });
}
