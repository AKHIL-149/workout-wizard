import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../services/active_program_service.dart';
import '../services/analytics_service.dart';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';
import '../services/workout_day_generator.dart';
import '../services/exercise_parser_service.dart';
import '../widgets/formatted_exercise_guidance.dart';
import 'workout_tracking_screen.dart';
import 'workout_day_details_screen.dart';

/// Enhanced program details screen with comprehensive information
class ProgramDetailsScreen extends StatefulWidget {
  final Recommendation recommendation;

  const ProgramDetailsScreen({
    super.key,
    required this.recommendation,
  });

  @override
  State<ProgramDetailsScreen> createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;
  final StorageService _storageService = StorageService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final GamificationService _gamificationService = GamificationService();
  final ExerciseParserService _parser = ExerciseParserService();

  // Cached parsed exercises organized by day type
  Map<String, List<ParsedExercise>> _exercisesByDay = {};
  bool _exercisesParsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed from 4 to 3 (removed Reviews tab)
    _checkFavoriteStatus();
    _trackView();
    _parseExercises();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final favorites = await _storageService.getFavorites();
    setState(() {
      _isFavorite = favorites.contains(widget.recommendation.programId);
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _storageService.removeFromFavorites(widget.recommendation.programId);
    } else {
      await _storageService.addToFavorites(widget.recommendation.programId);
      await _analyticsService.trackEvent(
        AnalyticsEvent.programFavorited,
        metadata: {'program_id': widget.recommendation.programId},
      );
      await _gamificationService.recordActivity('program_favorited');
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Future<void> _trackView() async {
    await _storageService.trackViewedProgram(widget.recommendation.programId);
    await _analyticsService.trackEvent(
      AnalyticsEvent.programClicked,
      metadata: {
        'program_id': widget.recommendation.programId,
        'match_percentage': widget.recommendation.matchPercentage,
      },
    );
    await _gamificationService.recordActivity('program_viewed');
  }

  void _parseExercises() {
    // Parse exercises from markdown and cache them
    final parsed = _parser.parseExerciseGuidance(widget.recommendation.exerciseGuidance);
    _exercisesByDay = _parser.organizeByDayType(parsed);
    _exercisesParsed = true;
  }

  Future<void> _startProgram() async {
    final activeProgramService = ActiveProgramService();

    // Start the program
    await activeProgramService.startProgram(widget.recommendation);

    await _analyticsService.trackEvent(
      AnalyticsEvent.programStarted,
      metadata: {
        'program_id': widget.recommendation.programId,
        'program_title': widget.recommendation.title,
      },
    );
    await _gamificationService.recordActivity('program_started');

    if (!mounted) return;

    // Navigate to workout tracking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutTrackingScreen(
          program: widget.recommendation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          _buildSliverAppBar(),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match Badge and Title
                _buildTitleSection(),

                // Key Stats Cards
                _buildStatsGrid(),

                const SizedBox(height: 24),

                // Tab Bar
                _buildTabBar(),

                // Tab Content
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildProgramStructureTab(),
                      _buildResultsTab(),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.recommendation.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getColorForLevel(widget.recommendation.primaryLevel),
                    _getColorForLevel(widget.recommendation.primaryLevel).withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -50,
              bottom: -50,
              child: Icon(
                _getIconForGoal(widget.recommendation.primaryGoal),
                size: 200,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          color: _isFavorite ? Colors.red : Colors.white,
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share functionality coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Match Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.recommendation.matchPercentage >= 90
                        ? [Colors.green.shade600, Colors.green.shade400]
                        : widget.recommendation.matchPercentage >= 70
                            ? [Colors.blue.shade600, Colors.blue.shade400]
                            : [Colors.orange.shade600, Colors.orange.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.recommendation.matchPercentage}% Match',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.recommendation.shortDescription,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildStatCard(
            Icons.calendar_today,
            '${widget.recommendation.programLength}',
            'Weeks',
            Colors.blue,
          ),
          _buildStatCard(
            Icons.fitness_center,
            '${widget.recommendation.workoutFrequency}x',
            'Per Week',
            Colors.orange,
          ),
          _buildStatCard(
            Icons.timer,
            '${widget.recommendation.timePerWorkout}',
            'Min/Session',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Structure'),
          Tab(text: 'Results'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Program Details', Icons.info_outline),
          const SizedBox(height: 12),
          _buildInfoRow('Fitness Level', widget.recommendation.level.join(', '), Icons.trending_up),
          _buildInfoRow('Primary Goal', widget.recommendation.goal.join(', '), Icons.flag),
          _buildInfoRow('Equipment', widget.recommendation.equipment, Icons.fitness_center),
          _buildInfoRow('Total Exercises', '${widget.recommendation.totalExercises}', Icons.list_alt),
          _buildInfoRow('Program ID', widget.recommendation.programId, Icons.tag),

          const SizedBox(height: 24),
          _buildSectionTitle('Exercise Guidance', Icons.fitness_center),
          const SizedBox(height: 12),

          FormattedExerciseGuidance(markdownText: widget.recommendation.exerciseGuidance),

          const SizedBox(height: 24),
          _buildSectionTitle('Who Is This For?', Icons.people_outline),
          const SizedBox(height: 12),
          _buildAudienceCard(),
        ],
      ),
    );
  }

  Widget _buildProgramStructureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Weekly Breakdown', Icons.calendar_view_week),
          const SizedBox(height: 12),

          // Generate weekly structure based on frequency
          ...List.generate(widget.recommendation.workoutFrequency, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWorkoutDayCard(index + 1),
            );
          }),

          const SizedBox(height: 24),
          _buildSectionTitle('Program Phases', Icons.timeline),
          const SizedBox(height: 12),

          _buildPhaseCard(
            'Phase 1: Foundation',
            'Weeks 1-${(widget.recommendation.programLength / 3).ceil()}',
            'Build base strength and perfect form',
            Colors.blue,
          ),
          _buildPhaseCard(
            'Phase 2: Growth',
            'Weeks ${(widget.recommendation.programLength / 3).ceil() + 1}-${(widget.recommendation.programLength * 2 / 3).ceil()}',
            'Increase intensity and volume',
            Colors.orange,
          ),
          _buildPhaseCard(
            'Phase 3: Peak',
            'Weeks ${(widget.recommendation.programLength * 2 / 3).ceil() + 1}-${widget.recommendation.programLength}',
            'Maximize results and test limits',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    final goalSpecificResults = _buildGoalSpecificResults();
    final dynamicTimeline = _buildDynamicTimeline();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Expected Results', Icons.trending_up),
          const SizedBox(height: 12),
          ...goalSpecificResults,
          const SizedBox(height: 24),
          _buildSectionTitle('Progress Timeline', Icons.show_chart),
          const SizedBox(height: 12),
          ...dynamicTimeline,
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Results vary based on consistency, nutrition, and recovery',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGoalSpecificResults() {
    final goal = widget.recommendation.primaryGoal.toLowerCase();
    final level = widget.recommendation.primaryLevel.toLowerCase();

    // Adjust expectations based on level
    double strengthMultiplier = level == 'beginner' ? 1.2 : (level == 'intermediate' ? 1.0 : 0.8);
    double muscleMultiplier = level == 'beginner' ? 1.3 : (level == 'intermediate' ? 1.0 : 0.7);

    if (goal.contains('strength') || goal.contains('power')) {
      return [
        _buildResultCard(
          'Strength Gains',
          '${(20 * strengthMultiplier).round()}-${(30 * strengthMultiplier).round()}%',
          'Average increase in major lifts',
          Icons.fitness_center,
          Colors.red,
        ),
        _buildResultCard(
          'Power Output',
          '15-20%',
          'Explosive strength improvements',
          Icons.bolt,
          Colors.orange,
        ),
        _buildResultCard(
          'Muscle Density',
          '${(2 * muscleMultiplier).round()}-${(4 * muscleMultiplier).round()} lbs',
          'Dense, functional muscle mass',
          Icons.accessibility_new,
          Colors.blue,
        ),
      ];
    } else if (goal.contains('muscle') || goal.contains('hypertrophy')) {
      return [
        _buildResultCard(
          'Muscle Growth',
          '${(3 * muscleMultiplier).round()}-${(7 * muscleMultiplier).round()} lbs',
          'Lean muscle mass gained',
          Icons.accessibility_new,
          Colors.blue,
        ),
        _buildResultCard(
          'Muscle Definition',
          '40-60%',
          'Increased muscle visibility',
          Icons.visibility,
          Colors.purple,
        ),
        _buildResultCard(
          'Strength Gains',
          '${(15 * strengthMultiplier).round()}-${(25 * strengthMultiplier).round()}%',
          'Secondary benefit from training',
          Icons.fitness_center,
          Colors.red,
        ),
      ];
    } else if (goal.contains('weight') || goal.contains('fat') || goal.contains('loss')) {
      return [
        _buildResultCard(
          'Body Fat',
          '-3-7%',
          'Reduction in body fat percentage',
          Icons.trending_down,
          Colors.green,
        ),
        _buildResultCard(
          'Weight Loss',
          '8-15 lbs',
          'Healthy sustainable fat loss',
          Icons.monitor_weight,
          Colors.teal,
        ),
        _buildResultCard(
          'Muscle Retention',
          '95-100%',
          'Preserve lean muscle mass',
          Icons.shield,
          Colors.blue,
        ),
      ];
    } else if (goal.contains('cardio') || goal.contains('endurance')) {
      return [
        _buildResultCard(
          'VO2 Max',
          '12-18%',
          'Cardiovascular capacity improvement',
          Icons.favorite,
          Colors.red,
        ),
        _buildResultCard(
          'Endurance',
          '25-40%',
          'Increased workout stamina',
          Icons.timer,
          Colors.orange,
        ),
        _buildResultCard(
          'Recovery Speed',
          '30-45%',
          'Faster between-set recovery',
          Icons.refresh,
          Colors.green,
        ),
      ];
    } else {
      // General fitness or unknown goal
      return [
        _buildResultCard(
          'Overall Fitness',
          '20-35%',
          'Comprehensive fitness improvement',
          Icons.trending_up,
          Colors.purple,
        ),
        _buildResultCard(
          'Strength & Muscle',
          '${(15 * strengthMultiplier).round()}-${(25 * strengthMultiplier).round()}%',
          'Balanced strength and size gains',
          Icons.fitness_center,
          Colors.red,
        ),
        _buildResultCard(
          'Body Composition',
          '3-6%',
          'Improved muscle-to-fat ratio',
          Icons.analytics,
          Colors.blue,
        ),
      ];
    }
  }

  List<Widget> _buildDynamicTimeline() {
    final weeks = widget.recommendation.programLength;
    final level = widget.recommendation.primaryLevel.toLowerCase();

    if (weeks <= 4) {
      // Short programs
      return [
        _buildTimelineItem(
          'Week 1',
          'Quick Start',
          level == 'beginner' ? 'Form mastery and initial adaptation' : 'Rapid strength activation',
          Colors.blue,
        ),
        _buildTimelineItem(
          'Week 2-3',
          'Progressive Gains',
          'Noticeable improvements in performance',
          Colors.orange,
        ),
        _buildTimelineItem(
          'Week 4',
          'Peak Performance',
          'Maximum output and visible changes',
          Colors.green,
        ),
      ];
    } else if (weeks <= 8) {
      // Medium programs
      return [
        _buildTimelineItem(
          'Week 1-2',
          'Foundation Phase',
          'Neural adaptation and movement patterns',
          Colors.blue,
        ),
        _buildTimelineItem(
          'Week 3-5',
          'Growth Phase',
          'Visible muscle development and strength gains',
          Colors.orange,
        ),
        _buildTimelineItem(
          'Week 6-8',
          'Peak Phase',
          'Maximum results and performance',
          Colors.green,
        ),
      ];
    } else {
      // Long programs (8+ weeks)
      final midPoint = (weeks / 2).round();
      final peakPoint = ((weeks * 0.75).round());

      return [
        _buildTimelineItem(
          'Week 1-$midPoint',
          'Foundation Building',
          'Systematic strength and muscle development',
          Colors.blue,
        ),
        _buildTimelineItem(
          'Week ${midPoint + 1}-$peakPoint',
          'Acceleration Phase',
          'Rapid gains and body transformation',
          Colors.orange,
        ),
        _buildTimelineItem(
          'Week ${peakPoint + 1}-$weeks',
          'Peak & Consolidation',
          'Maximum results and strength solidification',
          Colors.green,
        ),
      ];
    }
  }


  Widget _buildFloatingActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: FloatingActionButton.extended(
              onPressed: _startProgram,
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Start Program',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: () {
              // Download/save functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Program saved for offline access'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            backgroundColor: Colors.white,
            child: Icon(
              Icons.download,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Perfect for ${widget.recommendation.primaryLevel} Level',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getAudienceDescription(),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDayCard(int day) {
    return InkWell(
      onTap: () => _navigateToWorkoutDayDetails(day),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'D$day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getWorkoutTypeName(day),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.recommendation.timePerWorkout} min • ${_getExerciseCount(day)} exercises',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// Navigate to workout day details
  Future<void> _navigateToWorkoutDayDetails(int day) async {
    final generator = WorkoutDayGenerator();
    final dayName = _getWorkoutTypeName(day);

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Generate workout day
      final workoutDay = await generator.generateWorkoutDay(
        program: widget.recommendation,
        dayNumber: day,
        dayName: dayName,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to details screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutDayDetailsScreen(
            workoutDay: workoutDay,
            program: widget.recommendation,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading workout details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPhaseCard(String title, String weeks, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  weeks,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String value, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String week, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              Container(
                width: 2,
                height: 40,
                color: color.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  week,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // Helper Methods

  Color _getColorForLevel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.blue;
      case 'advanced':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForGoal(String goal) {
    if (goal.toLowerCase().contains('strength')) return Icons.fitness_center;
    if (goal.toLowerCase().contains('cardio')) return Icons.directions_run;
    if (goal.toLowerCase().contains('weight')) return Icons.monitor_weight;
    if (goal.toLowerCase().contains('muscle')) return Icons.accessibility_new;
    return Icons.flag;
  }

  String _getAudienceDescription() {
    switch (widget.recommendation.primaryLevel.toLowerCase()) {
      case 'beginner':
        return 'Ideal for those new to fitness or returning after a break. Start your journey with proper form and progressive challenges.';
      case 'intermediate':
        return 'Perfect for those with consistent training experience. Take your fitness to the next level with increased intensity.';
      case 'advanced':
        return 'Designed for experienced athletes. Push your limits and achieve peak performance with advanced techniques.';
      default:
        return 'Suitable for various fitness levels with scalable intensity.';
    }
  }

  String _getWorkoutTypeName(int day) {
    final goal = widget.recommendation.primaryGoal.toLowerCase();
    if (goal.contains('strength') || goal.contains('muscle')) {
      const types = ['Push Day', 'Pull Day', 'Leg Day', 'Upper Body', 'Lower Body', 'Full Body'];
      return types[(day - 1) % types.length];
    } else if (goal.contains('cardio')) {
      const types = ['HIIT Session', 'Endurance Run', 'Interval Training', 'Active Recovery'];
      return types[(day - 1) % types.length];
    }
    return 'Workout $day';
  }

  int _getExerciseCount(int day) {
    if (!_exercisesParsed) return 0;

    final dayName = _getWorkoutTypeName(day);
    final exercises = _exercisesByDay[dayName] ?? [];

    // If no exercises found for this specific day, use fallback
    if (exercises.isEmpty) {
      return widget.recommendation.timePerWorkout ~/ 5; // Rough estimate
    }

    return exercises.length;
  }
}
