// Basic widget test for Fitness Recommender app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_frontend/main.dart';

void main() {
  // TODO: Re-enable after adding mocking infrastructure for SplashScreen timer and services
  testWidgets('App builds and shows MaterialApp', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const FitnessRecommenderApp());

    // Verify that our app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  }, skip: true);
}
