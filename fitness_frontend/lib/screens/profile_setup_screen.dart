import 'package:flutter/material.dart';
import '../models/social_models.dart';
import '../services/workout_buddies_service.dart';

/// Screen for setting up user's social profile
class ProfileSetupScreen extends StatefulWidget {
  final SocialProfile? existingProfile;

  const ProfileSetupScreen({
    super.key,
    this.existingProfile,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final WorkoutBuddiesService _buddiesService = WorkoutBuddiesService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bioController;

  String _selectedEmoji = '💪';

  final List<String> _avatarEmojis = [
    '💪',
    '🏋️',
    '🤸',
    '🚴',
    '🏃',
    '⚡',
    '🔥',
    '🎯',
    '🏆',
    '⭐',
    '👑',
    '🥇',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingProfile?.displayName ?? '');
    _bioController =
        TextEditingController(text: widget.existingProfile?.bio ?? '');
    _selectedEmoji = widget.existingProfile?.avatarEmoji ?? '💪';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.existingProfile != null) {
        // Update existing profile
        final updated = widget.existingProfile!.copyWith(
          displayName: _nameController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          avatarEmoji: _selectedEmoji,
        );

        await _buddiesService.saveSocialProfile(updated);
      } else {
        // Create new profile
        await _buddiesService.createInitialProfile(
          _nameController.text.trim(),
          avatarEmoji: _selectedEmoji,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingProfile != null
              ? 'Profile updated!'
              : 'Profile created!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProfile != null
            ? 'Edit Profile'
            : 'Create Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAvatarSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Choose Your Avatar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _selectedEmoji,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _avatarEmojis.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Basic Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
                hintText: 'How should buddies see you?',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a display name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Tell your buddies about your fitness journey...',
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveProfile,
      icon: const Icon(Icons.save),
      label: Text(
          widget.existingProfile != null ? 'Save Changes' : 'Create Profile'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
