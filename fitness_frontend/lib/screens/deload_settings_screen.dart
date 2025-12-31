import 'package:flutter/material.dart';
import '../models/deload_settings.dart';
import '../services/deload_service.dart';

/// Screen for configuring deload and recovery settings
class DeloadSettingsScreen extends StatefulWidget {
  const DeloadSettingsScreen({super.key});

  @override
  State<DeloadSettingsScreen> createState() => _DeloadSettingsScreenState();
}

class _DeloadSettingsScreenState extends State<DeloadSettingsScreen> {
  final DeloadService _deloadService = DeloadService();

  late DeloadSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _deloadService.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = DeloadSettings();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _deloadService.saveSettings(_settings);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deload Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildAutoDeloadToggle(),
          const SizedBox(height: 16),
          _buildFrequencySelector(),
          const SizedBox(height: 16),
          _buildIntensitySelector(),
          const SizedBox(height: 16),
          _buildRecoveryTrackingToggle(),
          const SizedBox(height: 16),
          _buildRemindersToggle(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'About Deload Weeks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Deload weeks are planned recovery periods with reduced training volume and intensity. They help prevent overtraining, reduce injury risk, and promote long-term progress.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoDeloadToggle() {
    return Card(
      child: SwitchListTile(
        value: _settings.autoDeloadEnabled,
        onChanged: (value) {
          setState(() {
            _settings = _settings.copyWith(autoDeloadEnabled: value);
          });
        },
        title: const Text(
          'Auto Deload',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Automatically schedule deload weeks based on your settings',
        ),
        secondary: Icon(
          Icons.auto_mode,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Deload Frequency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule a deload week every ${_settings.deloadFrequencyWeeks} weeks',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _settings.deloadFrequencyWeeks.toDouble(),
                    min: 3,
                    max: 12,
                    divisions: 9,
                    label: '${_settings.deloadFrequencyWeeks} weeks',
                    onChanged: _settings.autoDeloadEnabled
                        ? (value) {
                            setState(() {
                              _settings = _settings.copyWith(
                                deloadFrequencyWeeks: value.round(),
                              );
                            });
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_settings.deloadFrequencyWeeks}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFrequencyRecommendation(_settings.deloadFrequencyWeeks),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFrequencyRecommendation(int weeks) {
    if (weeks <= 4) return 'Frequent deloads - good for beginners or high intensity training';
    if (weeks <= 6) return 'Standard deload schedule - works well for most people';
    if (weeks <= 8) return 'Moderate frequency - suitable for experienced lifters';
    return 'Infrequent deloads - only for advanced lifters with good recovery';
  }

  Widget _buildIntensitySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center,
                    size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Default Deload Intensity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIntensityOption(
              DeloadIntensity.light,
              'Light',
              '40-50% volume reduction',
              'Best for when you\'re feeling very fatigued',
              Icons.water_drop,
            ),
            const SizedBox(height: 12),
            _buildIntensityOption(
              DeloadIntensity.moderate,
              'Moderate',
              '30-40% volume reduction',
              'Standard deload - works for most situations',
              Icons.opacity,
            ),
            const SizedBox(height: 12),
            _buildIntensityOption(
              DeloadIntensity.minimal,
              'Minimal',
              '20-30% volume reduction',
              'Light deload - good for active recovery',
              Icons.wb_sunny_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityOption(
    DeloadIntensity intensity,
    String title,
    String reduction,
    String description,
    IconData icon,
  ) {
    final isSelected = _settings.defaultIntensity == intensity;

    return InkWell(
      onTap: _settings.autoDeloadEnabled
          ? () {
              setState(() {
                _settings = _settings.copyWith(defaultIntensity: intensity);
              });
            }
          : null,
      borderRadius: BorderRadius.circular(12),
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
            width: isSelected ? 2 : 1,
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
                      fontSize: 14,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black,
                    ),
                  ),
                  Text(
                    reduction,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
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

  Widget _buildRecoveryTrackingToggle() {
    return Card(
      child: SwitchListTile(
        value: _settings.trackRecoveryMetrics,
        onChanged: (value) {
          setState(() {
            _settings = _settings.copyWith(trackRecoveryMetrics: value);
          });
        },
        title: const Text(
          'Track Recovery Metrics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Monitor sleep, energy, and soreness to optimize deload timing',
        ),
        secondary: Icon(
          Icons.monitor_heart,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildRemindersToggle() {
    return Card(
      child: SwitchListTile(
        value: _settings.showDeloadReminders,
        onChanged: (value) {
          setState(() {
            _settings = _settings.copyWith(showDeloadReminders: value);
          });
        },
        title: const Text(
          'Deload Reminders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Get notified when it\'s time to deload',
        ),
        secondary: Icon(
          Icons.notifications,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveSettings,
      icon: const Icon(Icons.save),
      label: const Text('Save Settings'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
