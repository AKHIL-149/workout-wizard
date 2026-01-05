import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/health_data.dart';
import '../services/health_integration_service.dart';
import 'health_sync_screen.dart';

/// Screen for managing health app integration settings
class HealthIntegrationScreen extends StatefulWidget {
  const HealthIntegrationScreen({super.key});

  @override
  State<HealthIntegrationScreen> createState() => _HealthIntegrationScreenState();
}

class _HealthIntegrationScreenState extends State<HealthIntegrationScreen> {
  final HealthIntegrationService _healthService = HealthIntegrationService();

  HealthSyncConfig? _config;
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _healthService.isAvailable();
    setState(() {
      _isAvailable = available;
    });
  }

  void _loadData() {
    setState(() {
      _config = _healthService.getSyncConfig();
      _stats = _healthService.getSyncStats();
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await _healthService.requestPermissions();

      if (!mounted) return;

      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health permissions granted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health permissions denied'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSync(bool value) async {
    if (_config == null) return;

    if (value && !(_config!.isEnabled)) {
      // Request permissions first
      await _requestPermissions();
      return;
    }

    final updated = _config!.copyWith(isEnabled: value);
    await _healthService.updateSyncConfig(updated);
    _loadData();
  }

  Future<void> _updateSyncOption(String option, bool value) async {
    if (_config == null) return;

    HealthSyncConfig updated;
    switch (option) {
      case 'workouts':
        updated = _config!.copyWith(syncWorkouts: value);
        break;
      case 'calories':
        updated = _config!.copyWith(syncCalories: value);
        break;
      case 'heartRate':
        updated = _config!.copyWith(syncHeartRate: value);
        break;
      case 'steps':
        updated = _config!.copyWith(syncSteps: value);
        break;
      case 'autoSync':
        updated = _config!.copyWith(autoSync: value);
        break;
      default:
        return;
    }

    await _healthService.updateSyncConfig(updated);
    _loadData();
  }

  Future<void> _performSync() async {
    if (_config == null || !_config!.isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable health sync first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _healthService.performFullSync();

      if (!mounted) return;

      if (results['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced: ${results['heartRate']} heart rate, ${results['steps']} steps',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${results['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewSyncHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HealthSyncScreen(),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health Integration'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.smartphone,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'Not Available',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Health integration is only available on iOS and Android devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final platformName = Platform.isIOS ? 'Apple Health' : 'Google Fit';
    final isEnabled = _config?.isEnabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Integration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _viewSyncHistory,
            tooltip: 'View sync history',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Platform info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Platform.isIOS ? Icons.apple : Icons.android,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                platformName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sync workout data with $platformName',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Enable sync toggle
                Card(
                  child: SwitchListTile(
                    title: const Text('Enable Health Sync'),
                    subtitle: Text(
                      isEnabled
                          ? 'Automatically sync with $platformName'
                          : 'Tap to enable health integration',
                    ),
                    value: isEnabled,
                    onChanged: _toggleSync,
                    secondary: Icon(
                      isEnabled ? Icons.cloud_done : Icons.cloud_off,
                      color: isEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sync options
                if (isEnabled) ...[
                  Text(
                    'Sync Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Sync Workouts'),
                          subtitle: const Text('Export completed workouts'),
                          value: _config?.syncWorkouts ?? true,
                          onChanged: (value) => _updateSyncOption('workouts', value),
                          secondary: const Icon(Icons.fitness_center),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Sync Calories'),
                          subtitle: const Text('Export calories burned'),
                          value: _config?.syncCalories ?? true,
                          onChanged: (value) => _updateSyncOption('calories', value),
                          secondary: const Icon(Icons.local_fire_department),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Import Heart Rate'),
                          subtitle: const Text('Import heart rate data'),
                          value: _config?.syncHeartRate ?? true,
                          onChanged: (value) => _updateSyncOption('heartRate', value),
                          secondary: const Icon(Icons.favorite),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Import Steps'),
                          subtitle: const Text('Import daily step count'),
                          value: _config?.syncSteps ?? true,
                          onChanged: (value) => _updateSyncOption('steps', value),
                          secondary: const Icon(Icons.directions_walk),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Auto Sync'),
                          subtitle: const Text('Sync after each workout'),
                          value: _config?.autoSync ?? true,
                          onChanged: (value) => _updateSyncOption('autoSync', value),
                          secondary: const Icon(Icons.sync),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics
                  Text(
                    'Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatRow(
                            'Last Sync',
                            _config?.lastSyncTime != null
                                ? DateFormat('MMM d, y h:mm a').format(_config!.lastSyncTime)
                                : 'Never',
                            Icons.schedule,
                          ),
                          const Divider(height: 24),
                          _buildStatRow(
                            'Total Records',
                            '${_stats?['totalRecords'] ?? 0}',
                            Icons.data_usage,
                          ),
                          const Divider(height: 24),
                          _buildStatRow(
                            'Heart Rate Records',
                            '${_stats?['heartRateRecords'] ?? 0}',
                            Icons.favorite,
                          ),
                          const Divider(height: 24),
                          _buildStatRow(
                            'Steps Records',
                            '${_stats?['stepsRecords'] ?? 0}',
                            Icons.directions_walk,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sync button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _performSync,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
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
}
