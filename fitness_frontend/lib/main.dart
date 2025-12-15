import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/hybrid_recommender_service.dart';
import 'services/session_service.dart';
import 'services/analytics_service.dart';
import 'services/gamification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await SessionService().initialize();
  await AnalyticsService().initialize();
  await GamificationService().initialize();

  // Initialize hybrid recommender (loads on-device program database)
  await HybridRecommenderService().initialize();

  // Track app launch
  await AnalyticsService().trackEvent(AnalyticsEvent.appOpened);
  await GamificationService().recordActivity('app_opened');

  runApp(const FitnessRecommenderApp());
}

class FitnessRecommenderApp extends StatelessWidget {
  const FitnessRecommenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Program Recommender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Color scheme - Modern fitness theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Blue
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFFF97316), // Orange
          tertiary: const Color(0xFF10B981), // Green
          brightness: Brightness.light,
        ),
        
        // Typography using Google Fonts
        textTheme: GoogleFonts.interTextTheme(),
        
        // App Bar theme
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        // Card theme
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
