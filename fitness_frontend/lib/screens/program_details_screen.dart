import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../services/analytics_service.dart';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkFavoriteStatus();
    _trackView();
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

  Future<void> _startProgram() async {
    await _analyticsService.trackEvent(
      AnalyticsEvent.programClicked,
      metadata: {
        'program_id': widget.recommendation.programId,
        'action': 'started',
      },
    );
    await _gamificationService.recordActivity('program_started');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Started: ${widget.recommendation.title}'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildProgramStructureTab(),
                      _buildResultsTab(),
                      _buildReviewsTab(),
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
                    _getColorForLevel(widget.recommendation.primaryLevel).withOpacity(0.6),
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
                color: Colors.white.withOpacity(0.1),
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
                      color: Colors.green.withOpacity(0.3),
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
              const SizedBox(width: 12),
              // Rating
              if (widget.recommendation.rating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.recommendation.rating!.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.amber.shade900,
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
          if (widget.recommendation.description != null)
            Text(
              widget.recommendation.description!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          if (widget.recommendation.userCount != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${widget.recommendation.userCount} users following',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
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
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          Tab(text: 'Reviews'),
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
          _buildInfoRow('Fitness Level', widget.recommendation.primaryLevel, Icons.trending_up),
          _buildInfoRow('Primary Goal', widget.recommendation.primaryGoal, Icons.flag),
          _buildInfoRow('Equipment', widget.recommendation.equipment, Icons.fitness_center),
          if (widget.recommendation.trainingStyle != null)
            _buildInfoRow('Training Style', widget.recommendation.trainingStyle!, Icons.sports_gymnastics),
          _buildInfoRow('Program ID', widget.recommendation.programId, Icons.tag),

          const SizedBox(height: 24),
          _buildSectionTitle('What You\'ll Get', Icons.star_border),
          const SizedBox(height: 12),

          if (widget.recommendation.highlights != null && widget.recommendation.highlights!.isNotEmpty)
            ...widget.recommendation.highlights!.map((highlight) => Padding(
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
                      highlight,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ))
          else ...[
            _buildBenefitItem('Structured workout plan'),
            _buildBenefitItem('Progressive overload principles'),
            _buildBenefitItem('Detailed exercise instructions'),
            _buildBenefitItem('Track your progress'),
          ],

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Expected Results', Icons.trending_up),
          const SizedBox(height: 12),

          _buildResultCard(
            'Strength Gains',
            '15-25%',
            'Average increase in major lifts',
            Icons.fitness_center,
            Colors.red,
          ),
          _buildResultCard(
            'Muscle Growth',
            '2-5 lbs',
            'Lean muscle mass gained',
            Icons.accessibility_new,
            Colors.blue,
          ),
          _buildResultCard(
            'Body Fat',
            '-2-5%',
            'Reduction in body fat percentage',
            Icons.trending_down,
            Colors.green,
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Progress Timeline', Icons.show_chart),
          const SizedBox(height: 12),

          _buildTimelineItem(
            'Week 1-2',
            'Adaptation Phase',
            'Learning movements, some initial strength gains',
            Colors.blue,
          ),
          _buildTimelineItem(
            'Week 3-6',
            'Noticeable Changes',
            'Visible muscle definition, improved endurance',
            Colors.orange,
          ),
          _buildTimelineItem(
            'Week 7+',
            'Transformation',
            'Significant strength gains, body recomposition',
            Colors.green,
          ),

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

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('User Reviews', Icons.rate_review),
          const SizedBox(height: 12),

          // Rating Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade100, Colors.amber.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      widget.recommendation.rating?.toStringAsFixed(1) ?? '4.8',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          color: Colors.amber.shade700,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.recommendation.userCount ?? "1.2k"} reviews',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(5, 0.75),
                      _buildRatingBar(4, 0.15),
                      _buildRatingBar(3, 0.06),
                      _buildRatingBar(2, 0.03),
                      _buildRatingBar(1, 0.01),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sample Reviews
          _buildReviewCard(
            'Sarah M.',
            5,
            '3 months ago',
            'Amazing program! I\'ve gained so much strength and confidence. The progression is well-structured and challenging.',
          ),
          _buildReviewCard(
            'Mike T.',
            4,
            '1 month ago',
            'Great program overall. Saw significant gains in the first 8 weeks. Could use more recovery guidance.',
          ),
          _buildReviewCard(
            'Jennifer K.',
            5,
            '2 weeks ago',
            'Best program I\'ve ever followed. Clear instructions, perfect for my level, and I love the variety!',
          ),
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  '${widget.recommendation.timePerWorkout} min • ${_getExerciseCount()} exercises',
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
    );
  }

  Widget _buildPhaseCard(String title, String weeks, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.1),
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
                color: color.withOpacity(0.3),
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

  Widget _buildRatingBar(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star, size: 14, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              color: Colors.amber.shade700,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, int stars, String time, String review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(stars, (index) {
                          return Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade700,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review,
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

  int _getExerciseCount() {
    return widget.recommendation.timePerWorkout ~/ 5; // Rough estimate
  }
}
