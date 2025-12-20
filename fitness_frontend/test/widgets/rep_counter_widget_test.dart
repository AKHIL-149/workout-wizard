import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_frontend/widgets/rep_counter_widget.dart';

void main() {
  group('RepCounterWidget', () {
    testWidgets('should display zero reps initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RepCounterWidget(
              repCount: 0,
              targetReps: 10,
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('of 10'), findsOneWidget);
    });

    testWidgets('should display current rep count', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RepCounterWidget(
              repCount: 5,
              targetReps: 10,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('of 10'), findsOneWidget);
    });

    testWidgets('should display completed state when target reached', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RepCounterWidget(
              repCount: 10,
              targetReps: 10,
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
      expect(find.text('of 10'), findsOneWidget);
    });

    testWidgets('should handle reps exceeding target', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RepCounterWidget(
              repCount: 12,
              targetReps: 10,
            ),
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('of 10'), findsOneWidget);
    });

    testWidgets('should display without target when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RepCounterWidget(
              repCount: 7,
            ),
          ),
        ),
      );

      expect(find.text('7'), findsOneWidget);
      // Widget should be displayed
      expect(find.byType(RepCounterWidget), findsOneWidget);
    });

    testWidgets('should have proper semantics for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RepCounterWidget(
              repCount: 5,
              targetReps: 10,
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(RepCounterWidget));
      expect(semantics.label, contains('5'));
    });

    testWidgets('should update when rep count changes', (WidgetTester tester) async {
      int repCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    RepCounterWidget(
                      repCount: repCount,
                      targetReps: 10,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => repCount++),
                      child: const Text('Increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });
}
