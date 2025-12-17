import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/hybrid_recommender_service.dart';
import 'services/session_service.dart';
import 'services/analytics_service.dart';
import 'services/gamification_service.dart';
import 'services/storage_service.dart';
import 'providers/recommendation_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for form correction data
  await Hive.initFlutter();

  // Open Hive boxes for form correction
  await Hive.openBox<Map>('form_correction_sessions');
  await Hive.openBox<Map>('form_correction_stats');
  await Hive.openBox<Map>('form_correction_settings');

  // Initialize core services
  await StorageService().initialize();
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..initialize()),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
