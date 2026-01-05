import 'package:flutter/material.dart';
import '../services/challenge_service.dart';

/// Screen for creating a new workout challenge
class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _challengeType = 'workout_count';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  int _targetWorkouts = 10;
  double _targetVolume = 10000;
  int _targetStreak = 7;
  String? _selectedIcon;

  final List<String> _availableIcons = [
    '🏆',
    '💪',
    '🔥',
    '⚡',
    '🎯',
    '🚀',
    '⭐',
    '👑',
    '🥇',
    '💯',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> goalCriteria;

      switch (_challengeType) {
        case 'workout_count':
          goalCriteria = {'targetWorkouts': _targetWorkouts};
          break;
        case 'total_volume':
          goalCriteria = {'targetVolume': _targetVolume};
          break;
        case 'streak':
          goalCriteria = {'targetStreak': _targetStreak};
          break;
        default:
          goalCriteria = {};
      }

      await _challengeService.createChallenge(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        challengeType: _challengeType,
        goalCriteria: goalCriteria,
        icon: _selectedIcon,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge created!'),
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

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Challenge'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildIconSection(),
            const SizedBox(height: 24),
            _buildChallengeTypeSection(),
            const SizedBox(height: 24),
            _buildGoalSection(),
            const SizedBox(height: 24),
            _buildDatesSection(),
            const SizedBox(height: 24),
            _buildCreateButton(),
            const SizedBox(height: 80),
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
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Challenge Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Challenge Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                hintText: 'e.g., 30-Day Workout Streak',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a challenge name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Describe the challenge...',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_emotions, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Challenge Icon',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
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

  Widget _buildChallengeTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Challenge Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChallengeTypeOption(
              'workout_count',
              'Workout Count',
              'Complete a specific number of workouts',
              Icons.fitness_center,
            ),
            const SizedBox(height: 12),
            _buildChallengeTypeOption(
              'total_volume',
              'Total Volume',
              'Lift a target amount of total weight',
              Icons.work,
            ),
            const SizedBox(height: 12),
            _buildChallengeTypeOption(
              'streak',
              'Workout Streak',
              'Maintain consecutive days of working out',
              Icons.local_fire_department,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeTypeOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _challengeType == value;

    return GestureDetector(
      onTap: () => setState(() => _challengeType = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Goal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_challengeType == 'workout_count') ...[
              Text(
                'Target Workouts: $_targetWorkouts',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _targetWorkouts.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                label: '$_targetWorkouts workouts',
                onChanged: (value) {
                  setState(() => _targetWorkouts = value.round());
                },
              ),
            ] else if (_challengeType == 'total_volume') ...[
              Text(
                'Target Volume: ${_targetVolume.toStringAsFixed(0)} lbs',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _targetVolume,
                min: 1000,
                max: 100000,
                divisions: 99,
                label: '${_targetVolume.toStringAsFixed(0)} lbs',
                onChanged: (value) {
                  setState(() => _targetVolume = value);
                },
              ),
            ] else if (_challengeType == 'streak') ...[
              Text(
                'Target Streak: $_targetStreak days',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _targetStreak.toDouble(),
                min: 3,
                max: 100,
                divisions: 97,
                label: '$_targetStreak days',
                onChanged: (value) {
                  setState(() => _targetStreak = value.round());
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Duration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.event),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Date',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.event),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Date',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${_endDate.month}/${_endDate.day}/${_endDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Duration: ${_endDate.difference(_startDate).inDays} days',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton.icon(
      onPressed: _createChallenge,
      icon: const Icon(Icons.add),
      label: const Text('Create Challenge'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}
