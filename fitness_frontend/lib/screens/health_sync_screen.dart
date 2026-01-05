import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_data.dart';
import '../services/health_integration_service.dart';

/// Screen for viewing health data and sync history
class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen>
    with SingleTickerProviderStateMixin {
  final HealthIntegrationService _healthService = HealthIntegrationService();

  late TabController _tabController;
  List<HealthDataRecord> _heartRateRecords = [];
  List<HealthDataRecord> _stepsRecords = [];
  List<HealthSyncHistory> _syncHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _heartRateRecords = _healthService.getHealthRecords(type: 'heart_rate');
      _stepsRecords = _healthService.getHealthRecords(type: 'steps');
      _syncHistory = _healthService.getSyncHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Data'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Heart Rate', icon: Icon(Icons.favorite, size: 18)),
            Tab(text: 'Steps', icon: Icon(Icons.directions_walk, size: 18)),
            Tab(text: 'Sync History', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHeartRateTab(),
          _buildStepsTab(),
          _buildSyncHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildHeartRateTab() {
    if (_heartRateRecords.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title: 'No Heart Rate Data',
        subtitle: 'Import heart rate data from your health app',
      );
    }

    // Get last 7 days of data for chart
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentRecords = _heartRateRecords
        .where((r) => r.timestamp.isAfter(sevenDaysAgo))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistics card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Heart Rate Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHeartRateStats(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chart card
          if (recentRecords.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last 7 Days',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildHeartRateChart(recentRecords),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Records list
          Text(
            'Recent Records (${_heartRateRecords.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._heartRateRecords.take(50).map((record) => _buildDataCard(record)),
        ],
      ),
    );
  }

  Widget _buildStepsTab() {
    if (_stepsRecords.isEmpty) {
      return _buildEmptyState(
        icon: Icons.directions_walk_outlined,
        title: 'No Steps Data',
        subtitle: 'Import steps data from your health app',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistics card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Steps Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStepsStats(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Records list
          Text(
            'Recent Records (${_stepsRecords.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._stepsRecords.take(50).map((record) => _buildDataCard(record)),
        ],
      ),
    );
  }

  Widget _buildSyncHistoryTab() {
    if (_syncHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Sync History',
        subtitle: 'Sync history will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _syncHistory.length,
        itemBuilder: (context, index) {
          final history = _syncHistory[index];
          return _buildSyncHistoryCard(history);
        },
      ),
    );
  }

  Widget _buildHeartRateStats() {
    if (_heartRateRecords.isEmpty) return const SizedBox.shrink();

    final values = _heartRateRecords.map((r) => r.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn('Average', '${avg.toStringAsFixed(0)} bpm', Colors.blue),
        _buildStatColumn('Min', '${min.toStringAsFixed(0)} bpm', Colors.green),
        _buildStatColumn('Max', '${max.toStringAsFixed(0)} bpm', Colors.red),
      ],
    );
  }

  Widget _buildStepsStats() {
    if (_stepsRecords.isEmpty) return const SizedBox.shrink();

    final values = _stepsRecords.map((r) => r.value).toList();
    final total = values.reduce((a, b) => a + b);
    final avg = total / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn('Total', total.toStringAsFixed(0), Colors.blue),
        _buildStatColumn('Avg/Day', avg.toStringAsFixed(0), Colors.green),
        _buildStatColumn('Max', max.toStringAsFixed(0), Colors.orange),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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

  Widget _buildHeartRateChart(List<HealthDataRecord> records) {
    final spots = records.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(HealthDataRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          record.type == 'heart_rate' ? Icons.favorite : Icons.directions_walk,
          color: record.type == 'heart_rate' ? Colors.red : Colors.green,
        ),
        title: Text(
          '${record.value.toStringAsFixed(record.type == 'heart_rate' ? 0 : 0)} ${record.unit ?? ''}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM d, y h:mm a').format(record.timestamp),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            record.source == 'apple_health' ? 'Apple Health' : 'Google Fit',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncHistoryCard(HealthSyncHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  history.success ? Icons.check_circle : Icons.error,
                  color: history.success ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    history.syncType.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(history.syncTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.data_usage, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${history.recordsProcessed} records processed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            if (history.recordsByType.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: history.recordsByType.entries.map((entry) {
                  return Chip(
                    label: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (!history.success && history.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        history.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
