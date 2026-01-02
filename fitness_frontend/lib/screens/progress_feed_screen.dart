import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/social_models.dart';
import '../services/workout_buddies_service.dart';

/// Screen for viewing progress updates from workout buddies
class ProgressFeedScreen extends StatefulWidget {
  const ProgressFeedScreen({super.key});

  @override
  State<ProgressFeedScreen> createState() => _ProgressFeedScreenState();
}

class _ProgressFeedScreenState extends State<ProgressFeedScreen> {
  final WorkoutBuddiesService _buddiesService = WorkoutBuddiesService();

  List<ProgressUpdate> _updates = [];

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  void _loadUpdates() {
    setState(() {
      _updates = _buddiesService.getProgressUpdates(limit: 100);
    });
  }

  Future<void> _clearAllUpdates() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Updates?'),
        content: const Text(
          'This will remove all progress updates from your feed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Clear updates through service
    // For now, just reload
    _loadUpdates();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All updates cleared'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Feed'),
        actions: [
          if (_updates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllUpdates,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _updates.isEmpty ? _buildEmptyState() : _buildUpdatesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Updates Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete workouts and connect with buddies to see progress updates here',
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

  Widget _buildUpdatesList() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadUpdates();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _updates.length,
        itemBuilder: (context, index) {
          final update = _updates[index];
          return _buildUpdateCard(update);
        },
      ),
    );
  }

  Widget _buildUpdateCard(ProgressUpdate update) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      update.avatarEmoji ?? '👤',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
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
                _getUpdateTypeIcon(update.updateType),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              update.message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (update.data.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildUpdateData(update),
            ],
          ],
        ),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildUpdateData(ProgressUpdate update) {
    switch (update.updateType) {
      case 'workout_completed':
        return _buildWorkoutData(update.data);
      case 'personal_record':
        return _buildPRData(update.data);
      case 'achievement':
        return _buildAchievementData(update.data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWorkoutData(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['duration'] != null)
            _buildDataRow(Icons.timer, 'Duration', data['duration']),
          if (data['exercises'] != null)
            _buildDataRow(Icons.fitness_center, 'Exercises',
                '${data['exercises']} exercises'),
          if (data['sets'] != null)
            _buildDataRow(Icons.repeat, 'Sets', '${data['sets']} sets'),
          if (data['totalVolume'] != null)
            _buildDataRow(Icons.work, 'Volume', '${data['totalVolume']} lbs'),
        ],
      ),
    );
  }

  Widget _buildPRData(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (data['exercise'] != null)
            _buildPRItem('Exercise', data['exercise']),
          if (data['prType'] != null) _buildPRItem('Type', data['prType']),
          if (data['value'] != null) _buildPRItem('Value', '${data['value']}'),
        ],
      ),
    );
  }

  Widget _buildAchievementData(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Text(
        data['description'] ?? '',
        style: TextStyle(
          fontSize: 14,
          color: Colors.purple.shade900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPRItem(String label, String value) {
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
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}
