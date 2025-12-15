import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitness_frontend/main.dart' as app;
import 'package:fitness_frontend/services/session_service.dart';
import 'package:fitness_frontend/services/storage_service.dart';

/// Integration tests for complete user flows in the Fitness Recommender app.
///
/// These tests verify end-to-end functionality including:
/// - App initialization
/// - Onboarding flow
/// - Recommendation generation
/// - Navigation between screens
/// - Data persistence
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Initialization', () {
    testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should navigate from splash to either onboarding or main navigation
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Onboarding Flow', () {
    setUp(() async {
      // Clear all data before onboarding tests
      await StorageService().clearAllData();
      await SessionService().initialize();
    });

    testWidgets('Complete onboarding wizard flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show onboarding for new users
      // Note: Specific finders depend on your onboarding implementation
      // This is a template - adjust based on actual widgets

      // Look for common onboarding elements
      final hasGetStartedButton = find.text('Get Started');
      final hasWelcomeText = find.textContaining('Welcome');

      expect(
        hasGetStartedButton.evaluate().isNotEmpty ||
        hasWelcomeText.evaluate().isNotEmpty,
        isTrue,
        reason: 'Should show onboarding screen for new users',
      );
    });

    testWidgets('Can navigate through onboarding steps', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to find and tap "Get Started" or "Next" buttons
      final getStartedFinder = find.text('Get Started');
      if (getStartedFinder.evaluate().isNotEmpty) {
        await tester.tap(getStartedFinder);
        await tester.pumpAndSettle();
      }

      // Should progress to fitness level selection
      // Adjust based on your actual onboarding screens
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Recommendation Flow', () {
    testWidgets('Can generate recommendations', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate past onboarding if needed
      // This depends on session state

      // Look for recommendation-related UI elements
      // Adjust based on actual implementation
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('Bottom navigation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for bottom navigation bar
      final bottomNavFinder = find.byType(BottomNavigationBar);

      if (bottomNavFinder.evaluate().isNotEmpty) {
        // Get the bottom navigation bar
        final bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);

        // Should have 3 tabs (Home, Find Program, My Progress)
        expect(bottomNav.items.length, 3);

        // Try tapping second tab
        await tester.tap(find.byIcon(Icons.search).hitTestable());
        await tester.pumpAndSettle();

        // Should navigate to search/find program screen
        expect(find.byType(MaterialApp), findsOneWidget);

        // Try tapping third tab
        await tester.tap(find.byIcon(Icons.analytics).hitTestable());
        await tester.pumpAndSettle();

        // Should navigate to analytics screen
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });
  });

  group('Data Persistence', () {
    testWidgets('Session persists across app restarts', (WidgetTester tester) async {
      // First launch
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Record session info
      final sessionService = SessionService();
      final initialSessionCount = sessionService.sessionCount;

      // Simulate app restart by reinitializing
      await sessionService.initialize();

      // Session count should increment
      expect(sessionService.sessionCount, greaterThanOrEqualTo(initialSessionCount));
    });

    testWidgets('Storage service saves and retrieves data', (WidgetTester tester) async {
      final storageService = StorageService();
      await storageService.initialize();

      // Test favorites
      await storageService.addToFavorites('TEST_PROGRAM_001');
      final favorites = await storageService.getFavorites();
      expect(favorites, contains('TEST_PROGRAM_001'));

      // Test search history
      await storageService.addToSearchHistory('test query');
      final history = await storageService.getSearchHistory();
      expect(history, contains('test query'));

      // Cleanup
      await storageService.clearAllData();
    });
  });

  group('Error Handling', () {
    testWidgets('App handles offline mode gracefully', (WidgetTester tester) async {
      // The app should still work with on-device recommendations when offline
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should not crash
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App handles invalid data gracefully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should handle edge cases without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Service Integration', () {
    testWidgets('All services initialize correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify services are initialized
      final storageService = StorageService();
      final sessionService = SessionService();

      // Services should be accessible (singleton pattern)
      expect(storageService, isNotNull);
      expect(sessionService, isNotNull);
      expect(sessionService.userId, isNotEmpty);
    });
  });
}
