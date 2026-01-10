import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/third_party_integration.dart';
import '../services/third_party_integration_service.dart';
import 'integration_detail_screen.dart';

/// Screen for managing third-party app integrations
class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  final ThirdPartyIntegrationService _integrationService =
      ThirdPartyIntegrationService();

  List<ThirdPartyIntegration> _integrations = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  // Available providers
  final List<Map<String, dynamic>> _availableProviders = [
    {
      'id': 'strava',
      'name': 'Strava',
      'description': 'Sync running and cycling activities',
      'icon': Icons.directions_run,
      'color': Colors.orange,
    },
    {
      'id': 'myfitnesspal',
      'name': 'MyFitnessPal',
      'description': 'Track nutrition and calories',
      'icon': Icons.restaurant,
      'color': Colors.blue,
    },
    {
      'id': 'garmin',
      'name': 'Garmin',
      'description': 'Sync activities from Garmin devices',
      'icon': Icons.watch,
      'color': Colors.teal,
    },
    {
      'id': 'fitbit',
      'name': 'Fitbit',
      'description': 'Connect Fitbit tracker data',
      'icon': Icons.favorite,
      'color': Colors.pink,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _integrations = _integrationService.getAllIntegrations();
      _stats = _integrationService.getStats();
    });
  }

  ThirdPartyIntegration? _getIntegration(String providerId) {
    try {
      return _integrations.firstWhere((i) => i.provider == providerId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _connectProvider(String providerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;

      switch (providerId) {
        case 'strava':
          success = await _integrationService.connectStrava();
          break;
        case 'myfitnesspal':
          success = await _integrationService.connectMyFitnessPal();
          break;
        case 'garmin':
          success = await _integrationService.connectGarmin();
          break;
        case 'fitbit':
          success = await _integrationService.connectFitbit();
          break;
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${_getProviderName(providerId)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showImplementationNote(providerId);
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

  void _showImplementationNote(String providerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 12),
            Text('${_getProviderName(providerId)} Integration'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This integration requires additional setup:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• OAuth 2.0 authentication'),
            const Text('• API keys and secrets'),
            const Text('• Backend server for token management'),
            const Text('• Developer account registration'),
            const SizedBox(height: 16),
            Text(
              'The integration framework is in place and ready for implementation when API credentials are available.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectProvider(String providerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Integration'),
        content: Text(
          'Are you sure you want to disconnect ${_getProviderName(providerId)}? This will remove all synced data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _integrationService.disconnect(providerId);
        _loadData();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disconnected from ${_getProviderName(providerId)}'),
            backgroundColor: Colors.green,
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
  }

  void _viewIntegrationDetails(String providerId) {
    final integration = _getIntegration(providerId);
    if (integration != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IntegrationDetailScreen(integration: integration),
        ),
      ).then((_) => _loadData());
    }
  }

  String _getProviderName(String providerId) {
    final provider = _availableProviders.firstWhere(
      (p) => p['id'] == providerId,
      orElse: () => {'name': providerId},
    );
    return provider['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Integrations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statistics card
                if (_stats != null && _stats!['totalIntegrations'] > 0) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Integration Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn(
                                'Connected',
                                '${_stats!['connectedIntegrations']}',
                                Icons.link,
                                Colors.green,
                              ),
                              _buildStatColumn(
                                'Activities',
                                '${_stats!['totalActivities']}',
                                Icons.fitness_center,
                                Colors.blue,
                              ),
                              _buildStatColumn(
                                'Syncs',
                                '${_stats!['totalSyncs']}',
                                Icons.sync,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Available integrations
                Text(
                  'Available Integrations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ..._availableProviders.map((provider) {
                  final integration = _getIntegration(provider['id'] as String);
                  return _buildIntegrationCard(provider, integration);
                }),
              ],
            ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildIntegrationCard(
    Map<String, dynamic> provider,
    ThirdPartyIntegration? integration,
  ) {
    final isConnected = integration?.isConnected ?? false;
    final providerId = provider['id'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isConnected ? () => _viewIntegrationDetails(providerId) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (provider['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  provider['icon'] as IconData,
                  color: provider['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isConnected && integration?.lastSyncTime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last synced: ${DateFormat('MMM d, h:mm a').format(integration!.lastSyncTime!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isConnected)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'disconnect') {
                      _disconnectProvider(providerId);
                    } else if (value == 'details') {
                      _viewIntegrationDetails(providerId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info, size: 20),
                          SizedBox(width: 12),
                          Text('Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          Icon(Icons.link_off, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Disconnect', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () => _connectProvider(providerId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider['color'] as Color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Connect'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
