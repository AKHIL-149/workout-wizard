import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_challenge.dart';
import '../services/challenge_service.dart';
import 'challenge_detail_screen.dart';
import 'create_challenge_screen.dart';

/// Screen for viewing and managing workout challenges
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  final ChallengeService _challengeService = ChallengeService();

  late TabController _tabController;

  List<WorkoutChallenge> _activeChallenges = [];
  List<WorkoutChallenge> _upcomingChallenges = [];
  List<WorkoutChallenge> _completedChallenges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadChallenges() {
    setState(() {
      _activeChallenges = _challengeService.getActiveChallenges();
      _upcomingChallenges = _challengeService.getUpcomingChallenges();
      _completedChallenges = _challengeService.getCompletedChallenges();
    });
  }

  Future<void> _createChallenge() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateChallengeScreen(),
      ),
    );

    if (result == true) {
      _loadChallenges();
    }
  }

  Future<void> _viewChallengeDetail(WorkoutChallenge challenge) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(challenge: challenge),
      ),
    );

    if (result == true) {
      _loadChallenges();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Active (${_activeChallenges.length})'),
            Tab(text: 'Upcoming (${_upcomingChallenges.length})'),
            Tab(text: 'Completed (${_completedChallenges.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChallengeList(_activeChallenges, 'active'),
          _buildChallengeList(_upcomingChallenges, 'upcoming'),
          _buildChallengeList(_completedChallenges, 'completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createChallenge,
        icon: const Icon(Icons.add),
        label: const Text('New Challenge'),
      ),
    );
  }

  Widget _buildChallengeList(List<WorkoutChallenge> challenges, String type) {
    if (challenges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'No ${type.capitalize()} Challenges',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                type == 'active'
                    ? 'Create or join a challenge to get started!'
                    : type == 'upcoming'
                        ? 'No upcoming challenges yet'
                        : 'Complete some challenges to see them here',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadChallenges();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return _buildChallengeCard(challenge);
        },
      ),
    );
  }

  Widget _buildChallengeCard(WorkoutChallenge challenge) {
    final progress = _challengeService.getUserProgress(challenge.id);
    final isParticipating = progress != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _viewChallengeDetail(challenge),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (challenge.icon != null)
                    Text(
                      challenge.icon!,
                      style: const TextStyle(fontSize: 32),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${challenge.creatorName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isParticipating)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Joined',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                challenge.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.people,
                    '${challenge.participantIds.length} ${challenge.participantIds.length == 1 ? 'participant' : 'participants'}',
                  ),
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${DateFormat('MMM d').format(challenge.startDate)} - ${DateFormat('MMM d').format(challenge.endDate)}',
                  ),
                  if (challenge.isActive)
                    _buildInfoChip(
                      Icons.timer,
                      '${challenge.daysRemaining} days left',
                    ),
                  _buildInfoChip(
                    Icons.flag,
                    _getChallengeTypeLabel(challenge.challengeType),
                  ),
                ],
              ),
              if (isParticipating && progress!.isCompleted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Goal Completed! 🎉',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getChallengeTypeLabel(String type) {
    switch (type) {
      case 'workout_count':
        return 'Workout Count';
      case 'total_volume':
        return 'Total Volume';
      case 'streak':
        return 'Streak';
      case 'custom':
        return 'Custom';
      default:
        return type;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
