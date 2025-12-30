import 'package:flutter/material.dart';
import '../services/rest_timer_service.dart';

/// Screen for configuring rest timer preferences
class RestTimerSettingsScreen extends StatefulWidget {
  const RestTimerSettingsScreen({super.key});

  @override
  State<RestTimerSettingsScreen> createState() =>
      _RestTimerSettingsScreenState();
}

class _RestTimerSettingsScreenState extends State<RestTimerSettingsScreen> {
  final RestTimerService _timerService = RestTimerService();

  int _defaultRestTime = 90;
  bool _autoStartTimer = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;

  // Preset rest durations (in seconds)
  static const List<int> presetDurations = [30, 60, 90, 120, 180, 240, 300];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final restTime = await _timerService.getDefaultRestTime();
      final autoStart = await _timerService.isAutoStartEnabled();
      final sound = await _timerService.isSoundEnabled();
      final vibration = await _timerService.isVibrationEnabled();

      setState(() {
        _defaultRestTime = restTime;
        _autoStartTimer = autoStart;
        _soundEnabled = sound;
        _vibrationEnabled = vibration;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds % 60 == 0) {
      return '${seconds ~/ 60} min';
    } else {
      return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rest Timer Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildDefaultDurationCard(),
                const SizedBox(height: 16),
                _buildPreferencesCard(),
                const SizedBox(height: 16),
                _buildAlertsCard(),
                const SizedBox(height: 24),
                _buildTestTimerButton(),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.timer,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'Rest Timer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optimize your rest periods between sets',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultDurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Default Rest Duration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Duration slider
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _defaultRestTime.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 27, // 10-second increments
                    label: _formatDuration(_defaultRestTime),
                    onChanged: (value) async {
                      setState(() => _defaultRestTime = value.toInt());
                      await _timerService.setDefaultRestTime(value.toInt());
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    _formatDuration(_defaultRestTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick preset buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetDurations.map((duration) {
                final isSelected = _defaultRestTime == duration;
                return ChoiceChip(
                  label: Text(_formatDuration(duration)),
                  selected: isSelected,
                  onSelected: (selected) async {
                    if (selected) {
                      setState(() => _defaultRestTime = duration);
                      await _timerService.setDefaultRestTime(duration);
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Auto-start Timer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Start timer automatically after completing a set'),
            value: _autoStartTimer,
            onChanged: (value) async {
              setState(() => _autoStartTimer = value);
              await _timerService.setAutoStart(value);
            },
            secondary: Icon(
              Icons.play_circle,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Play sound when timer completes'),
            value: _soundEnabled,
            onChanged: (value) async {
              setState(() => _soundEnabled = value);
              await _timerService.setSoundEnabled(value);
            },
            secondary: const Icon(Icons.volume_up),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate when timer completes'),
            value: _vibrationEnabled,
            onChanged: (value) async {
              setState(() => _vibrationEnabled = value);
              await _timerService.setVibrationEnabled(value);
            },
            secondary: const Icon(Icons.vibration),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTimerButton() {
    return ElevatedButton.icon(
      onPressed: _testTimer,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Test Timer (10 seconds)'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Future<void> _testTimer() async {
    await _timerService.startTimer(10);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test timer started for 10 seconds'),
        duration: Duration(seconds: 2),
      ),
    );

    // Show timer dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TestTimerDialog(timerService: _timerService),
    );
  }
}

class _TestTimerDialog extends StatefulWidget {
  final RestTimerService timerService;

  const _TestTimerDialog({required this.timerService});

  @override
  State<_TestTimerDialog> createState() => _TestTimerDialogState();
}

class _TestTimerDialogState extends State<_TestTimerDialog> {
  @override
  void initState() {
    super.initState();
    widget.timerService.addListener(_onTimerUpdate);
  }

  @override
  void dispose() {
    widget.timerService.removeListener(_onTimerUpdate);
    super.dispose();
  }

  void _onTimerUpdate() {
    if (mounted) {
      setState(() {});

      // Auto-close when complete
      if (widget.timerService.isCompleted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.timerService.resetTimer();
            Navigator.pop(context);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Test Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.timerService.isCompleted ? Icons.check_circle : Icons.timer,
            size: 64,
            color: widget.timerService.isCompleted
                ? Colors.green
                : Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            widget.timerService.isCompleted
                ? 'Complete!'
                : widget.timerService.remainingTimeFormatted,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: widget.timerService.isCompleted
                  ? Colors.green
                  : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (!widget.timerService.isCompleted)
            LinearProgressIndicator(
              value: widget.timerService.progress,
              backgroundColor: Colors.grey.shade200,
            ),
        ],
      ),
      actions: [
        if (!widget.timerService.isCompleted) ...[
          TextButton(
            onPressed: () {
              widget.timerService.addTime(5);
            },
            child: const Text('+5s'),
          ),
          TextButton(
            onPressed: () {
              widget.timerService.resetTimer();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              widget.timerService.resetTimer();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ],
    );
  }
}
