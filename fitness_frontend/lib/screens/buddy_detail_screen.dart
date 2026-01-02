import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/social_models.dart';
import '../services/workout_buddies_service.dart';

/// Screen for viewing a specific workout buddy's details
class BuddyDetailScreen extends StatefulWidget {
  final WorkoutBuddy buddy;

  const BuddyDetailScreen({
    super.key,
    required this.buddy,
  });

  @override
  State<BuddyDetailScreen> createState() => _BuddyDetailScreenState();
}

class _BuddyDetailScreenState extends State<BuddyDetailScreen> {
  final WorkoutBuddiesService _buddiesService = WorkoutBuddiesService();

  List<ProgressUpdate> _buddyUpdates = [];

  @override
  void initState() {
    super.initState();
    _loadBuddyUpdates();
  }

  void _loadBuddyUpdates() {
    setState(() {
      _buddyUpdates = _buddiesService.getBuddyUpdates(widget.buddy.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buddy.displayName),
      ),
      body: ListView(
        children: [
          _buildBuddyHeader(),
          const SizedBox(height: 8),
          _buildStatsSection(),
          const SizedBox(height: 16),
          _buildActivitySection(),
        ],
      ),
    );
  }

  Widget _buildBuddyHeader() {
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.buddy.avatarEmoji ?? '👤',
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.buddy.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connected ${_formatDate(widget.buddy.connectedAt)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (widget.buddy.lastActivitySync != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Last synced ${_formatDate(widget.buddy.lastActivitySync!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (widget.buddy.sharedData.isEmpty) return const SizedBox.shrink();

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
                  Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Shared Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (widget.buddy.sharedData['totalWorkouts'] != null)
                    _buildStatChip(
                      Icons.fitness_center,
                      'Workouts',
                      '${widget.buddy.sharedData['totalWorkouts']}',
                      Colors.blue,
                    ),
                  if (widget.buddy.sharedData['totalExercises'] != null)
                    _buildStatChip(
                      Icons.list,
                      'Exercises',
                      '${widget.buddy.sharedData['totalExercises']}',
                      Colors.green,
                    ),
                  if (widget.buddy.sharedData['totalSets'] != null)
                    _buildStatChip(
                      Icons.repeat,
                      'Sets',
                      '${widget.buddy.sharedData['totalSets']}',
                      Colors.orange,
                    ),
                  if (widget.buddy.sharedData['totalVolume'] != null)
                    _buildStatChip(
                      Icons.work,
                      'Volume',
                      '${widget.buddy.sharedData['totalVolume']} lbs',
                      Colors.purple,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
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
                  Icon(Icons.history, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_buddyUpdates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activity',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._buddyUpdates.map((update) => _buildActivityItem(update)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(ProgressUpdate update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getUpdateTypeIcon(update.updateType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.message,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(update.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (update.data.isNotEmpty &&
              update.updateType == 'workout_completed') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (update.data['exercises'] != null)
                  _buildDataBadge(
                      '${update.data['exercises']} exercises', Colors.blue),
                if (update.data['sets'] != null)
                  _buildDataBadge('${update.data['sets']} sets', Colors.green),
                if (update.data['duration'] != null)
                  _buildDataBadge(update.data['duration'], Colors.orange),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _getUpdateTypeIcon(String updateType) {
    IconData icon;
    Color color;

    switch (updateType) {
      case 'workout_completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'personal_record':
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 'achievement':
        icon = Icons.stars;
        color = Colors.purple;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildDataBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
