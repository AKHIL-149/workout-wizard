import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'recommendation_form_screen.dart';
import 'analytics_dashboard_screen.dart';
import '../services/gamification_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RecommendationFormScreen(),
    const AnalyticsDashboardScreen(),
  ];

  final List<String> _titles = [
    'Home',
    'Find Program',
    'My Progress',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: _titles[0],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: _titles[1],
          ),
          BottomNavigationBarItem(
            icon: _buildAnalyticsIcon(),
            activeIcon: _buildAnalyticsIcon(active: true),
            label: _titles[2],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsIcon({bool active = false}) {
    final gamificationService = GamificationService();
    final currentStreak = gamificationService.currentStreak;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          active ? Icons.analytics : Icons.analytics_outlined,
        ),
        if (currentStreak > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                currentStreak > 99 ? '99+' : currentStreak.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
