import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/third_party_integration.dart';
import '../services/third_party_integration_service.dart';

/// Screen for viewing and managing a specific integration
class IntegrationDetailScreen extends StatefulWidget {
  final ThirdPartyIntegration integration;

  const IntegrationDetailScreen({
    super.key,
    required this.integration,
  });

  @override
  State<IntegrationDetailScreen> createState() =>
      _IntegrationDetailScreenState();
}

class _IntegrationDetailScreenState extends State<IntegrationDetailScreen>
    with SingleTickerProviderStateMixin {
  final ThirdPartyIntegrationService _integrationService =
      ThirdPartyIntegrationService();

  late TabController _tabController;
  late ThirdPartyIntegration _integration;
  List<IntegrationSyncActivity> _activities = [];
  List<IntegrationSyncHistory> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _integration = widget.integration;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _integration =
          _integrationService.getIntegration(_integration.provider) ??
              _integration;
      _activities = _integrationService.getSyncedActivities(
        provider: _integration.provider,
      );
      _history = _integrationService.getSyncHistory(
        provider: _integration.provider,
      );
    });
  }

  Future<void> _syncNow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await _integrationService.syncActivities(_integration.provider);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${result['activitiesProcessed']} activities',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Sync failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _loadData();
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

  Future<void> _toggleAutoSync(bool value) async {
    try {
      final updated = _integration.copyWith(autoSync: value);
      await _integrationService.updateIntegration(updated);
      _loadData();
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

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final settings = Map<String, dynamic>.from(_integration.settings);
      settings[key] = value;
      final updated = _integration.copyWith(settings: settings);
      await _integrationService.updateIntegration(updated);
      _loadData();
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

  String _getProviderName() {
    switch (_integration.provider) {
      case 'strava':
        return 'Strava';
      case 'myfitnesspal':
        return 'MyFitnessPal';
      case 'garmin':
        return 'Garmin';
      case 'fitbit':
        return 'Fitbit';
      default:
        return _integration.provider;
    }
  }

  Color _getProviderColor() {
    switch (_integration.provider) {
      case 'strava':
        return Colors.orange;
      case 'myfitnesspal':
        return Colors.blue;
      case 'garmin':
        return Colors.teal;
      case 'fitbit':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getProviderName()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Details'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildSettingsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection status card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _integration.isConnected
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _integration.isConnected ? 'Connected' : 'Not Connected',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Provider',
                  _getProviderName(),
                  Icons.business,
                ),
                if (_integration.userName != null) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Account',
                    _integration.userName!,
                    Icons.person,
                  ),
                ],
                const Divider(height: 24),
                _buildInfoRow(
                  'Connected',
                  DateFormat('MMM d, y h:mm a').format(_integration.connectedAt),
                  Icons.calendar_today,
                ),
                if (_integration.lastSyncTime != null) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Last Sync',
                    DateFormat('MMM d, y h:mm a')
                        .format(_integration.lastSyncTime!),
                    Icons.sync,
                  ),
                ],
                if (_integration.isConnected && !_integration.isTokenValid) ...[
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Token expired. Please reconnect.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Sync button
        if (_integration.isConnected)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _syncNow,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_isLoading ? 'Syncing...' : 'Sync Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getProviderColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
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
                  'Synced Activities',
                  '${_activities.length}',
                  Icons.fitness_center,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Total Syncs',
                  '${_history.length}',
                  Icons.history,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  'Successful Syncs',
                  '${_history.where((h) => h.success).length}',
                  Icons.check_circle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Auto sync
        Card(
          child: SwitchListTile(
            title: const Text('Auto Sync'),
            subtitle: const Text('Automatically sync new activities'),
            value: _integration.autoSync,
            onChanged: _toggleAutoSync,
            secondary: const Icon(Icons.sync),
          ),
        ),
        const SizedBox(height: 16),

        // Provider-specific settings
        Text(
          'Sync Options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildProviderSettings(),
      ],
    );
  }

  Widget _buildProviderSettings() {
    switch (_integration.provider) {
      case 'strava':
        return _buildStravaSettings();
      case 'myfitnesspal':
        return _buildMyFitnessPalSettings();
      case 'garmin':
        return _buildGarminSettings();
      case 'fitbit':
        return _buildFitbitSettings();
      default:
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No settings available'),
          ),
        );
    }
  }

  Widget _buildStravaSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Sync Activities'),
            subtitle: const Text('Import runs, rides, and workouts'),
            value: _integration.settings['syncActivities'] ?? true,
            onChanged: (value) => _updateSetting('syncActivities', value),
            secondary: const Icon(Icons.directions_run),
          ),
        ],
      ),
    );
  }

  Widget _buildMyFitnessPalSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Sync Nutrition'),
            subtitle: const Text('Import nutrition data'),
            value: _integration.settings['syncNutrition'] ?? true,
            onChanged: (value) => _updateSetting('syncNutrition', value),
            secondary: const Icon(Icons.restaurant),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sync Calories'),
            subtitle: const Text('Import calorie tracking'),
            value: _integration.settings['syncCalories'] ?? true,
            onChanged: (value) => _updateSetting('syncCalories', value),
            secondary: const Icon(Icons.local_fire_department),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sync Macros'),
            subtitle: const Text('Import macronutrient data'),
            value: _integration.settings['syncMacros'] ?? true,
            onChanged: (value) => _updateSetting('syncMacros', value),
            secondary: const Icon(Icons.pie_chart),
          ),
        ],
      ),
    );
  }

  Widget _buildGarminSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Sync Activities'),
            subtitle: const Text('Import workout activities'),
            value: _integration.settings['syncActivities'] ?? true,
            onChanged: (value) => _updateSetting('syncActivities', value),
            secondary: const Icon(Icons.fitness_center),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sync Heart Rate'),
            subtitle: const Text('Import heart rate data'),
            value: _integration.settings['syncHeartRate'] ?? true,
            onChanged: (value) => _updateSetting('syncHeartRate', value),
            secondary: const Icon(Icons.favorite),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sync Steps'),
            subtitle: const Text('Import daily step count'),
            value: _integration.settings['syncSteps'] ?? true,
            onChanged: (value) => _updateSetting('syncSteps', value),
            secondary: const Icon(Icons.directions_walk),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sync Sleep'),
            subtitle: const Text('Import sleep data'),
            value: _integration.settings['syncSleep'] ?? true,
            onChanged: (value) => _updateSetting('syncSleep', value),
            secondary: const Icon(Icons.bedtime),
          ),
        ],
      ),
    );
  }

  Widget _buildFitbitSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Sync Activities'),
            subtitle: const Text('Import workout activities'),
            value: _integration.settings['syncActivities'] ?? true,
            onChanged: (value) => _updateSetting('syncActivities', value),
            secondary: const Icon(Icons.fitness_center),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sync Heart Rate'),
            subtitle: const Text('Import heart rate data'),
            value: _integration.settings['syncHeartRate'] ?? true,
            onChanged: (value) => _updateSetting('syncHeartRate', value),
            secondary: const Icon(Icons.favorite),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sync Steps'),
            subtitle: const Text('Import daily step count'),
            value: _integration.settings['syncSteps'] ?? true,
            onChanged: (value) => _updateSetting('syncSteps', value),
            secondary: const Icon(Icons.directions_walk),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sync Sleep'),
            subtitle: const Text('Import sleep data'),
            value: _integration.settings['syncSleep'] ?? true,
            onChanged: (value) => _updateSetting('syncSleep', value),
            secondary: const Icon(Icons.bedtime),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sync Weight'),
            subtitle: const Text('Import weight measurements'),
            value: _integration.settings['syncWeight'] ?? true,
            onChanged: (value) => _updateSetting('syncWeight', value),
            secondary: const Icon(Icons.monitor_weight),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No sync history',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: entry.success
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              child: Icon(
                entry.success ? Icons.check : Icons.error,
                color: entry.success ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              '${entry.syncType.toUpperCase()} - ${entry.activitiesProcessed} activities',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(DateFormat('MMM d, y h:mm a').format(entry.syncTime)),
                if (entry.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
            trailing: entry.success
                ? const Icon(Icons.cloud_done, color: Colors.green)
                : const Icon(Icons.cloud_off, color: Colors.red),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
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

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _getProviderColor(), size: 20),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getProviderColor(),
          ),
        ),
      ],
    );
  }
}
