import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_challenge.dart';
import '../services/challenge_service.dart';

/// Screen for viewing challenge details and leaderboard
class ChallengeDetailScreen extends StatefulWidget {
  final WorkoutChallenge challenge;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final ChallengeService _challengeService = ChallengeService();

  List<ChallengeProgress> _leaderboard = [];
  ChallengeProgress? _userProgress;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() {
    setState(() {
      _leaderboard = _challengeService.getChallengeProgress(widget.challenge.id);
      _userProgress = _challengeService.getUserProgress(widget.challenge.id);
    });
  }

  Future<void> _joinChallenge() async {
    try {
      await _challengeService.joinChallenge(widget.challenge.id);
      _loadProgress();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Joined challenge!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Challenge?'),
        content: const Text(
          'Are you sure you want to leave this challenge? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _challengeService.leaveChallenge(widget.challenge.id);
      _loadProgress();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Left challenge'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Challenge?'),
        content: const Text(
          'Are you sure you want to delete this challenge? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _challengeService.deleteChallenge(widget.challenge.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge deleted'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isParticipating = _userProgress != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Details'),
        actions: [
          if (isParticipating)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'leave') {
                  _leaveChallenge();
                } else if (value == 'delete') {
                  _deleteChallenge();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, size: 20),
                      SizedBox(width: 8),
                      Text('Leave Challenge'),
                    ],
                  ),
                ),
                if (widget.challenge.creatorId == _userProgress?.userId)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Challenge'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: ListView(
        children: [
          _buildChallengeHeader(),
          const SizedBox(height: 8),
          _buildProgressSection(),
          const SizedBox(height: 16),
          _buildLeaderboardSection(),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: !isParticipating && !widget.challenge.isCompleted
          ? _buildJoinButton()
          : null,
    );
  }

  Widget _buildChallengeHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          if (widget.challenge.icon != null)
            Text(
              widget.challenge.icon!,
              style: const TextStyle(fontSize: 64),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            widget.challenge.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'by ${widget.challenge.creatorName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.challenge.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildStatusChip(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoItem(
                Icons.people,
                '${widget.challenge.participantIds.length}',
                'Participants',
              ),
              const SizedBox(width: 24),
              _buildInfoItem(
                Icons.calendar_today,
                '${widget.challenge.durationDays}',
                'Days',
              ),
              if (widget.challenge.isActive)
                const SizedBox(width: 24),
              if (widget.challenge.isActive)
                _buildInfoItem(
                  Icons.timer,
                  '${widget.challenge.daysRemaining}',
                  'Days Left',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${DateFormat('MMM d, y').format(widget.challenge.startDate)} - ${DateFormat('MMM d, y').format(widget.challenge.endDate)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    if (widget.challenge.isActive) {
      color = Colors.green;
      label = 'Active';
    } else if (widget.challenge.isUpcoming) {
      color = Colors.blue;
      label = 'Upcoming';
    } else {
      color = Colors.grey;
      label = 'Completed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    if (_userProgress == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: _userProgress!.isCompleted
            ? Colors.amber.withValues(alpha: 0.1)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _userProgress!.isCompleted
                        ? Icons.emoji_events
                        : Icons.trending_up,
                    color: _userProgress!.isCompleted
                        ? Colors.amber
                        : Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _userProgress!.isCompleted
                        ? 'Goal Completed! 🎉'
                        : 'Your Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _userProgress!.isCompleted ? Colors.amber : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressDetails(_userProgress!.progressData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDetails(Map<String, dynamic> data) {
    switch (widget.challenge.challengeType) {
      case 'workout_count':
        final completed = data['workoutsCompleted'] as int? ?? 0;
        final target =
            widget.challenge.goalCriteria['targetWorkouts'] as int? ?? 0;
        return Column(
          children: [
            LinearProgressIndicator(
              value: target > 0 ? completed / target : 0,
              backgroundColor: Colors.grey.shade200,
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              '$completed / $target workouts completed',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 'total_volume':
        final completed = (data['totalVolume'] as num?)?.toDouble() ?? 0.0;
        final target =
            (widget.challenge.goalCriteria['targetVolume'] as num?)?.toDouble() ??
                0.0;
        return Column(
          children: [
            LinearProgressIndicator(
              value: target > 0 ? completed / target : 0,
              backgroundColor: Colors.grey.shade200,
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              '${completed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} lbs lifted',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 'streak':
        final current = data['currentStreak'] as int? ?? 0;
        final longest = data['longestStreak'] as int? ?? 0;
        final target = widget.challenge.goalCriteria['targetStreak'] as int? ?? 0;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakItem('Current', current),
                _buildStreakItem('Longest', longest),
                _buildStreakItem('Target', target),
              ],
            ),
          ],
        );
      default:
        return const Text('Progress tracking not available');
    }
  }

  Widget _buildStreakItem(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'days',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLeaderboardSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.leaderboard, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Leaderboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_leaderboard.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No participants yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._leaderboard.asMap().entries.map((entry) {
                  final index = entry.key;
                  final progress = entry.value;
                  return _buildLeaderboardItem(progress, index + 1);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(ChallengeProgress progress, int rank) {
    final isCurrentUser = progress.userId == _userProgress?.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          _buildRankBadge(rank),
          const SizedBox(width: 12),
          Text(
            progress.avatarEmoji ?? '👤',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCurrentUser ? Theme.of(context).primaryColor : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getProgressSummary(progress.progressData),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (progress.isCompleted)
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData? icon;

    if (rank == 1) {
      color = Colors.amber;
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      color = Colors.grey;
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      color = Colors.brown;
      icon = Icons.emoji_events;
    } else {
      color = Colors.grey.shade400;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: color, size: 20)
            : Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
      ),
    );
  }

  String _getProgressSummary(Map<String, dynamic> data) {
    switch (widget.challenge.challengeType) {
      case 'workout_count':
        final count = data['workoutsCompleted'] as int? ?? 0;
        return '$count ${count == 1 ? 'workout' : 'workouts'}';
      case 'total_volume':
        final volume = (data['totalVolume'] as num?)?.toDouble() ?? 0.0;
        return '${volume.toStringAsFixed(0)} lbs';
      case 'streak':
        final streak = data['longestStreak'] as int? ?? 0;
        return '$streak day ${streak == 1 ? 'streak' : 'streak'}';
      default:
        return 'In progress';
    }
  }

  Widget _buildJoinButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _joinChallenge,
          icon: const Icon(Icons.add),
          label: const Text('Join Challenge'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
