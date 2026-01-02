import 'package:flutter/material.dart';
import '../models/social_models.dart';
import '../services/workout_buddies_service.dart';
import 'profile_setup_screen.dart';
import 'buddy_connect_screen.dart';
import 'progress_feed_screen.dart';
import 'buddy_detail_screen.dart';

/// Screen for managing workout buddies
class WorkoutBuddiesScreen extends StatefulWidget {
  const WorkoutBuddiesScreen({super.key});

  @override
  State<WorkoutBuddiesScreen> createState() => _WorkoutBuddiesScreenState();
}

class _WorkoutBuddiesScreenState extends State<WorkoutBuddiesScreen> {
  final WorkoutBuddiesService _buddiesService = WorkoutBuddiesService();

  SocialProfile? _profile;
  List<WorkoutBuddy> _buddies = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _profile = _buddiesService.getSocialProfile();
      _buddies = _buddiesService.getAllBuddies();
    });
  }

  Future<void> _setupProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(existingProfile: _profile),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _connectBuddy() async {
    if (_profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set up your profile first'),
          backgroundColor: Colors.orange,
        ),
      );
      _setupProfile();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BuddyConnectScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _viewProgressFeed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProgressFeedScreen(),
      ),
    );
  }

  void _viewBuddyDetail(WorkoutBuddy buddy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuddyDetailScreen(buddy: buddy),
      ),
    );
  }

  Future<void> _removeBuddy(WorkoutBuddy buddy) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Buddy?'),
        content: Text(
          'Are you sure you want to remove ${buddy.displayName} from your workout buddies?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _buddiesService.removeBuddy(buddy.id);
      _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${buddy.displayName}'),
          backgroundColor: Colors.orange,
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Buddies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.feed),
            onPressed: _viewProgressFeed,
            tooltip: 'Progress Feed',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _setupProfile,
            tooltip: 'My Profile',
          ),
        ],
      ),
      body: _profile == null
          ? _buildNoProfileState()
          : _buddies.isEmpty
              ? _buildEmptyState()
              : _buildBuddiesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _connectBuddy,
        icon: const Icon(Icons.person_add),
        label: const Text('Connect Buddy'),
      ),
    );
  }

  Widget _buildNoProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Set Up Your Profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your profile to start connecting with workout buddies',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _setupProfile,
              icon: const Icon(Icons.person_add),
              label: const Text('Create Profile'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 32),
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Workout Buddies Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect with friends to share progress and stay motivated',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _connectBuddy,
              icon: const Icon(Icons.person_add),
              label: const Text('Connect Your First Buddy'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_profile == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _profile!.avatarEmoji ?? '💪',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile!.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_profile!.bio != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _profile!.bio!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _setupProfile,
              tooltip: 'Edit Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuddiesList() {
    return Column(
      children: [
        _buildProfileCard(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _buddies.length,
            itemBuilder: (context, index) {
              final buddy = _buddies[index];
              return _buildBuddyCard(buddy);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBuddyCard(WorkoutBuddy buddy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _viewBuddyDetail(buddy),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    buddy.avatarEmoji ?? '👤',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buddy.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (buddy.lastActivity != null)
                      Text(
                        buddy.lastActivity!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Connected ${_formatDate(buddy.connectedAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeBuddy(buddy);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove Buddy'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
}
