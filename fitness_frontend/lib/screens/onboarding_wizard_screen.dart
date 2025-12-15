import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/session_service.dart';
import '../services/analytics_service.dart';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';
import 'main_navigation_screen.dart';

/// Multi-step onboarding wizard for new users
class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  // User selections
  String? _fitnessLevel;
  final List<String> _selectedGoals = [];
  String? _equipment;
  String? _experienceDescription;
  String? _timeCommitment;

  final SessionService _sessionService = SessionService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final GamificationService _gamificationService = GamificationService();
  final StorageService _storageService = StorageService();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Track onboarding completion
    await _analyticsService.trackEvent(
      AnalyticsEvent.onboardingCompleted,
      metadata: {
        'fitness_level': _fitnessLevel,
        'goals': _selectedGoals,
        'equipment': _equipment,
      },
    );

    // Award achievement
    await _gamificationService.recordActivity('onboarding_completed');

    if (!mounted) return;

    // Navigate to main app with navigation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${_currentPage + 1} of $_totalPages',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentPage > 0)
                          TextButton.icon(
                            onPressed: _previousPage,
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Back'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _WelcomePage(onNext: _nextPage),
                    _FitnessLevelPage(
                      selectedLevel: _fitnessLevel,
                      onLevelSelected: (level) {
                        setState(() {
                          _fitnessLevel = level;
                        });
                      },
                      onNext: _nextPage,
                    ),
                    _GoalsPage(
                      selectedGoals: _selectedGoals,
                      onGoalsChanged: (goals) {
                        setState(() {
                          _selectedGoals.clear();
                          _selectedGoals.addAll(goals);
                        });
                      },
                      onNext: _nextPage,
                    ),
                    _EquipmentPage(
                      selectedEquipment: _equipment,
                      onEquipmentSelected: (equipment) {
                        setState(() {
                          _equipment = equipment;
                        });
                      },
                      onNext: _nextPage,
                    ),
                    _TimeCommitmentPage(
                      selectedCommitment: _timeCommitment,
                      onCommitmentSelected: (commitment) {
                        setState(() {
                          _timeCommitment = commitment;
                        });
                      },
                      onComplete: _completeOnboarding,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Welcome page
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final sessionService = SessionService();
    final greeting = sessionService.timeBasedGreeting;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            '$greeting!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Workout Wizard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Let\'s create your personalized fitness journey in just a few simple steps',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildFeatureItem(
            context,
            Icons.speed,
            'Quick Setup',
            'Less than 2 minutes',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            context,
            Icons.psychology,
            'AI-Powered',
            'Personalized recommendations',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            context,
            Icons.emoji_events,
            'Track Progress',
            'Achievements & streaks',
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Get Started'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Fitness level selection page
class _FitnessLevelPage extends StatelessWidget {
  final String? selectedLevel;
  final Function(String) onLevelSelected;
  final VoidCallback onNext;

  const _FitnessLevelPage({
    required this.selectedLevel,
    required this.onLevelSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your fitness level?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us recommend programs that match your experience',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildLevelCard(
                  context,
                  'Beginner',
                  'New to fitness or returning after a break',
                  Icons.emoji_people,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildLevelCard(
                  context,
                  'Intermediate',
                  'Regular exercise with some experience',
                  Icons.directions_run,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildLevelCard(
                  context,
                  'Advanced',
                  'Experienced athlete or trainer',
                  Icons.sports_martial_arts,
                  Colors.orange,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: selectedLevel != null ? onNext : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    String level,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedLevel == level;

    return InkWell(
      onTap: () => onLevelSelected(level),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}

/// Goals selection page
class _GoalsPage extends StatelessWidget {
  final List<String> selectedGoals;
  final Function(List<String>) onGoalsChanged;
  final VoidCallback onNext;

  const _GoalsPage({
    required this.selectedGoals,
    required this.onGoalsChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are your fitness goals?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: Constants.goalOptions.length,
              itemBuilder: (context, index) {
                final goal = Constants.goalOptions[index];
                final isSelected = selectedGoals.contains(goal.name);

                return InkWell(
                  onTap: () {
                    final newGoals = List<String>.from(selectedGoals);
                    if (isSelected) {
                      newGoals.remove(goal.name);
                    } else {
                      newGoals.add(goal.name);
                    }
                    onGoalsChanged(newGoals);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? goal.color : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? goal.color : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: goal.color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          goal.icon,
                          color: isSelected ? Colors.white : goal.color,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          goal.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: selectedGoals.isNotEmpty ? onNext : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

/// Equipment availability page
class _EquipmentPage extends StatelessWidget {
  final String? selectedEquipment;
  final Function(String) onEquipmentSelected;
  final VoidCallback onNext;

  const _EquipmentPage({
    required this.selectedEquipment,
    required this.onEquipmentSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What equipment do you have access to?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll recommend programs that match your setup',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildEquipmentCard(
                  context,
                  'Bodyweight Only',
                  'No equipment needed - perfect for home',
                  Icons.accessibility_new,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildEquipmentCard(
                  context,
                  'Minimal Equipment',
                  'Dumbbells, resistance bands, etc.',
                  Icons.fitness_center,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildEquipmentCard(
                  context,
                  'Full Gym',
                  'Access to a complete gym facility',
                  Icons.warehouse,
                  Colors.orange,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: selectedEquipment != null ? onNext : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    String equipment,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedEquipment == equipment;

    return InkWell(
      onTap: () => onEquipmentSelected(equipment),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}

/// Time commitment page
class _TimeCommitmentPage extends StatelessWidget {
  final String? selectedCommitment;
  final Function(String) onCommitmentSelected;
  final VoidCallback onComplete;

  const _TimeCommitmentPage({
    required this.selectedCommitment,
    required this.onCommitmentSelected,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much time can you commit?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Per workout session',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildTimeCard(
                  context,
                  '< 30 minutes',
                  'Quick and efficient',
                  Icons.flash_on,
                  Colors.red,
                ),
                const SizedBox(height: 16),
                _buildTimeCard(
                  context,
                  '30-45 minutes',
                  'Balanced workout',
                  Icons.schedule,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildTimeCard(
                  context,
                  '45-60 minutes',
                  'Comprehensive training',
                  Icons.fitness_center,
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildTimeCard(
                  context,
                  '60+ minutes',
                  'Extended sessions',
                  Icons.access_time,
                  Colors.purple,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: selectedCommitment != null ? onComplete : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Complete Setup'),
                SizedBox(width: 8),
                Icon(Icons.check, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(
    BuildContext context,
    String time,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedCommitment == time;

    return InkWell(
      onTap: () => onCommitmentSelected(time),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
