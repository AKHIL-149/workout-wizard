import 'package:flutter/material.dart';
import '../services/audio_feedback_service.dart';
import '../services/form_correction_storage_service.dart';

/// Settings screen for form correction preferences
class FormCorrectionSettingsScreen extends StatefulWidget {
  const FormCorrectionSettingsScreen({super.key});

  @override
  State<FormCorrectionSettingsScreen> createState() =>
      _FormCorrectionSettingsScreenState();
}

class _FormCorrectionSettingsScreenState
    extends State<FormCorrectionSettingsScreen> {
  final FormCorrectionStorageService _storageService =
      FormCorrectionStorageService();
  final AudioFeedbackService _audioService = AudioFeedbackService();

  late AudioFeedbackSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final audioSettings = _storageService.getSetting<Map>(
      'audio_settings',
      defaultValue: {},
    );

    if (audioSettings != null && audioSettings.isNotEmpty) {
      _settings = AudioFeedbackSettings.fromJson(
        Map<String, dynamic>.from(audioSettings),
      );
    } else {
      _settings = AudioFeedbackSettings();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _storageService.saveSetting('audio_settings', _settings.toJson());
  }

  Future<void> _updateSettings(AudioFeedbackSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    await _saveSettings();

    // Apply settings immediately
    _audioService.setEnabled(_settings.enabled);
    await _audioService.setVolume(_settings.volume);
    await _audioService.setSpeechRate(_settings.speechRate);
    await _audioService.setPitch(_settings.pitch);
  }

  Future<void> _testAudio() async {
    await _audioService.initialize();
    await _audioService.setVolume(_settings.volume);
    await _audioService.setSpeechRate(_settings.speechRate);
    await _audioService.setPitch(_settings.pitch);
    await _audioService.speak(
      'This is how audio feedback will sound during your workout.',
      priority: AudioPriority.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Form Correction Settings'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Correction Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: _settings.enabled ? _testAudio : null,
            tooltip: 'Test Audio',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Audio Feedback Section
          _buildSectionHeader('Audio Feedback'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Audio Feedback'),
                  subtitle: const Text(
                    'Receive voice guidance during workouts',
                  ),
                  value: _settings.enabled,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(enabled: value));
                  },
                ),
                if (_settings.enabled) ...[
                  const Divider(),
                  ListTile(
                    title: const Text('Volume'),
                    subtitle: Slider(
                      value: _settings.volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: '${(_settings.volume * 100).round()}%',
                      onChanged: (value) {
                        _updateSettings(_settings.copyWith(volume: value));
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Speech Rate'),
                    subtitle: Slider(
                      value: _settings.speechRate,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: _getSpeechRateLabel(_settings.speechRate),
                      onChanged: (value) {
                        _updateSettings(_settings.copyWith(speechRate: value));
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Pitch'),
                    subtitle: Slider(
                      value: _settings.pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: _settings.pitch.toStringAsFixed(1),
                      onChanged: (value) {
                        _updateSettings(_settings.copyWith(pitch: value));
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Feedback Types Section
          if (_settings.enabled) ...[
            _buildSectionHeader('Feedback Types'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Rep Completions'),
                    subtitle: const Text(
                      'Announce when each rep is completed',
                    ),
                    value: _settings.speakRepCompletions,
                    onChanged: (value) {
                      _updateSettings(
                        _settings.copyWith(speakRepCompletions: value),
                      );
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Form Violations'),
                    subtitle: const Text(
                      'Announce when form issues are detected',
                    ),
                    value: _settings.speakViolations,
                    onChanged: (value) {
                      _updateSettings(
                        _settings.copyWith(speakViolations: value),
                      );
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Encouragement'),
                    subtitle: const Text(
                      'Receive motivational messages',
                    ),
                    value: _settings.speakEncouragement,
                    onChanged: (value) {
                      _updateSettings(
                        _settings.copyWith(speakEncouragement: value),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Camera & Detection Section
          _buildSectionHeader('Camera & Detection'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Default Camera'),
                  subtitle: Text(_getDefaultCameraText()),
                  trailing: DropdownButton<String>(
                    value: _storageService.getSetting<String>(
                      FormCorrectionSettings.defaultCamera,
                      defaultValue: 'front',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'front',
                        child: Text('Front'),
                      ),
                      DropdownMenuItem(
                        value: 'back',
                        child: Text('Back'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _storageService.saveSetting(
                          FormCorrectionSettings.defaultCamera,
                          value,
                        );
                        setState(() {});
                      }
                    },
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.palette),
                  title: const Text('Show Skeleton Overlay'),
                  subtitle: const Text('Display pose detection overlay'),
                  value: _storageService.getSetting<bool>(
                    FormCorrectionSettings.showSkeleton,
                    defaultValue: true,
                  )!,
                  onChanged: (value) {
                    _storageService.saveSetting(
                      FormCorrectionSettings.showSkeleton,
                      value,
                    );
                    setState(() {});
                  },
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.label),
                  title: const Text('Show Joint Labels'),
                  subtitle: const Text('Display joint point labels'),
                  value: _storageService.getSetting<bool>(
                    FormCorrectionSettings.showLabels,
                    defaultValue: false,
                  )!,
                  onChanged: (value) {
                    _storageService.saveSetting(
                      FormCorrectionSettings.showLabels,
                      value,
                    );
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionHeader('Data Management'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Storage Used'),
                  subtitle: Text(_getStorageText()),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_sweep),
                  title: const Text('Data Retention'),
                  subtitle: Text(
                    'Keep session data for ${_storageService.getSetting<int>(FormCorrectionSettings.dataRetentionDays, defaultValue: 90)} days',
                  ),
                  trailing: DropdownButton<int>(
                    value: _storageService.getSetting<int>(
                      FormCorrectionSettings.dataRetentionDays,
                      defaultValue: 90,
                    ),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                      DropdownMenuItem(value: 60, child: Text('60 days')),
                      DropdownMenuItem(value: 90, child: Text('90 days')),
                      DropdownMenuItem(value: 180, child: Text('180 days')),
                      DropdownMenuItem(value: 365, child: Text('1 year')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _storageService.saveSetting(
                          FormCorrectionSettings.dataRetentionDays,
                          value,
                        );
                        setState(() {});
                      }
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text('Clean Up Old Data'),
                  subtitle: const Text('Remove sessions older than retention period'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _cleanUpOldData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reset Settings Button
          Center(
            child: OutlinedButton.icon(
              onPressed: _resetSettings,
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getSpeechRateLabel(double rate) {
    if (rate < 0.3) return 'Very Slow';
    if (rate < 0.5) return 'Slow';
    if (rate < 0.7) return 'Normal';
    if (rate < 0.9) return 'Fast';
    return 'Very Fast';
  }

  String _getDefaultCameraText() {
    final camera = _storageService.getSetting<String>(
      FormCorrectionSettings.defaultCamera,
      defaultValue: 'front',
    );
    return camera == 'front' ? 'Front Camera' : 'Back Camera';
  }

  String _getStorageText() {
    final stats = _storageService.getDatabaseStats();
    final sizeKB = stats['databaseSizeKB'] ?? 0;
    if (sizeKB < 1024) {
      return '$sizeKB KB';
    } else {
      return '${(sizeKB / 1024).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _cleanUpOldData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Up Old Data'),
        content: const Text(
          'This will permanently delete session data older than your retention period. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Clean Up'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final retentionDays = _storageService.getSetting<int>(
        FormCorrectionSettings.dataRetentionDays,
        defaultValue: 90,
      )!;

      await _storageService.deleteOldSessions(daysToKeep: retentionDays);
      await _storageService.compactDatabase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Old data cleaned up successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh storage stats
      }
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateSettings(AudioFeedbackSettings());
      await _storageService.saveSetting(
        FormCorrectionSettings.defaultCamera,
        'front',
      );
      await _storageService.saveSetting(
        FormCorrectionSettings.showSkeleton,
        true,
      );
      await _storageService.saveSetting(
        FormCorrectionSettings.showLabels,
        false,
      );
      await _storageService.saveSetting(
        FormCorrectionSettings.dataRetentionDays,
        90,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    }
  }
}
