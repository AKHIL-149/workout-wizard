import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_sync.dart';
import '../services/calendar_sync_service.dart';

/// Screen for viewing calendar sync history
class CalendarSyncHistoryScreen extends StatefulWidget {
  const CalendarSyncHistoryScreen({super.key});

  @override
  State<CalendarSyncHistoryScreen> createState() => _CalendarSyncHistoryScreenState();
}

class _CalendarSyncHistoryScreenState extends State<CalendarSyncHistoryScreen> {
  final CalendarSyncService _calendarService = CalendarSyncService();

  List<CalendarSyncHistory> _history = [];
  List<SyncedCalendarEvent> _syncedEvents = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _history = _calendarService.getSyncHistory();
      _syncedEvents = _calendarService.getAllSyncedEvents();
      _stats = _calendarService.getSyncStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Sync History'),
      ),
      body: DefaultTabBarController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Sync History', icon: Icon(Icons.history, size: 18)),
                Tab(text: 'Synced Events', icon: Icon(Icons.event, size: 18)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildHistoryTab(),
                  _buildEventsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistics card
          if (_stats != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sync Statistics',
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
                          'Total',
                          '${_stats!['totalSyncs']}',
                          Icons.sync,
                          Colors.blue,
                        ),
                        _buildStatColumn(
                          'Success',
                          '${_stats!['successfulSyncs']}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatColumn(
                          'Failed',
                          '${_stats!['failedSyncs']}',
                          Icons.error,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // History list
          Text(
            'Recent Syncs',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._history.map((entry) => _buildHistoryCard(entry)),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_syncedEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy,
        title: 'No Synced Events',
        subtitle: 'Synced workout events will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _syncedEvents.length,
        itemBuilder: (context, index) {
          final event = _syncedEvents[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
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

  Widget _buildHistoryCard(CalendarSyncHistory history) {
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
                Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${history.eventsProcessed} events processed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            if (history.eventsByType.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: history.eventsByType.entries.map((entry) {
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

  Widget _buildEventCard(SyncedCalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          event.isCompleted ? Icons.check_circle : Icons.event,
          color: event.isCompleted ? Colors.green : Colors.blue,
          size: 32,
        ),
        title: Text(
          event.workoutName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y h:mm a').format(event.startTime),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Synced: ${DateFormat('MMM d, y').format(event.syncedAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: event.isCompleted
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              )
            : null,
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
