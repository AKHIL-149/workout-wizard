import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart';
import 'dart:io';
import '../models/calendar_sync.dart';
import '../services/calendar_sync_service.dart';
import 'calendar_sync_history_screen.dart';

/// Screen for managing calendar sync settings
class CalendarSyncScreen extends StatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen> {
  final CalendarSyncService _calendarService = CalendarSyncService();

  CalendarSyncConfig? _config;
  Map<String, dynamic>? _stats;
  List<Calendar> _calendars = [];
  bool _isLoading = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _calendarService.isAvailable();
    setState(() {
      _isAvailable = available;
    });
  }

  void _loadData() {
    setState(() {
      _config = _calendarService.getSyncConfig();
      _stats = _calendarService.getSyncStats();
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await _calendarService.requestPermissions();

      if (!mounted) return;

      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calendar permissions granted'),
            backgroundColor: Colors.green,
          ),
        );

        // Load calendars
        await _loadCalendars();
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calendar permissions denied'),
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

  Future<void> _loadCalendars() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final calendars = await _calendarService.getCalendars();
      setState(() {
        _calendars = calendars;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading calendars: $e'),
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
    await _calendarService.updateSyncConfig(updated);
    _loadData();
  }

  Future<void> _selectCalendar() async {
    if (_calendars.isEmpty) {
      await _loadCalendars();
    }

    if (_calendars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No calendars available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selected = await showDialog<Calendar>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Calendar'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _calendars.length,
            itemBuilder: (context, index) {
              final calendar = _calendars[index];
              return ListTile(
                title: Text(calendar.name ?? 'Unnamed Calendar'),
                subtitle: Text(calendar.accountName ?? ''),
                trailing: _config?.selectedCalendarId == calendar.id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, calendar),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null && _config != null) {
      final updated = _config!.copyWith(
        selectedCalendarId: selected.id,
        selectedCalendarName: selected.name,
      );
      await _calendarService.updateSyncConfig(updated);
      _loadData();
    }
  }

  Future<void> _updateSyncOption(String option, dynamic value) async {
    if (_config == null) return;

    CalendarSyncConfig updated;
    switch (option) {
      case 'autoSync':
        updated = _config!.copyWith(autoSync: value as bool);
        break;
      case 'syncScheduled':
        updated = _config!.copyWith(syncScheduledWorkouts: value as bool);
        break;
      case 'syncCompleted':
        updated = _config!.copyWith(syncCompletedWorkouts: value as bool);
        break;
      case 'includeNotes':
        updated = _config!.copyWith(includeNotes: value as bool);
        break;
      case 'reminderMinutes':
        updated = _config!.copyWith(reminderMinutesBefore: value as int);
        break;
      default:
        return;
    }

    await _calendarService.updateSyncConfig(updated);
    _loadData();
  }

  void _viewSyncHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CalendarSyncHistoryScreen(),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Calendar Integration'),
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
                  'Calendar integration is only available on iOS and Android devices.',
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

    final platformName = Platform.isIOS ? 'Apple Calendar' : 'Google Calendar';
    final isEnabled = _config?.isEnabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Sync'),
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
                          Icons.calendar_today,
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
                                'Sync workouts to your device calendar',
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
                    title: const Text('Enable Calendar Sync'),
                    subtitle: Text(
                      isEnabled
                          ? 'Automatically sync with calendar'
                          : 'Tap to enable calendar integration',
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

                // Calendar selection
                if (isEnabled) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Selected Calendar'),
                      subtitle: Text(
                        _config?.selectedCalendarName ?? 'None selected',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _selectCalendar,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sync options
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
                          title: const Text('Auto Sync'),
                          subtitle: const Text('Sync after scheduling workouts'),
                          value: _config?.autoSync ?? true,
                          onChanged: (value) => _updateSyncOption('autoSync', value),
                          secondary: const Icon(Icons.sync),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Sync Scheduled Workouts'),
                          subtitle: const Text('Add upcoming workouts to calendar'),
                          value: _config?.syncScheduledWorkouts ?? true,
                          onChanged: (value) => _updateSyncOption('syncScheduled', value),
                          secondary: const Icon(Icons.event_available),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Update Completed Workouts'),
                          subtitle: const Text('Mark completed workouts in calendar'),
                          value: _config?.syncCompletedWorkouts ?? false,
                          onChanged: (value) => _updateSyncOption('syncCompleted', value),
                          secondary: const Icon(Icons.check_circle),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Include Notes'),
                          subtitle: const Text('Add workout details to events'),
                          value: _config?.includeNotes ?? true,
                          onChanged: (value) => _updateSyncOption('includeNotes', value),
                          secondary: const Icon(Icons.notes),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reminder settings
                  Text(
                    'Reminders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.alarm),
                          title: const Text('Reminder Time'),
                          subtitle: Text(
                            '${_config?.reminderMinutesBefore ?? 30} minutes before',
                          ),
                        ),
                        Slider(
                          value: (_config?.reminderMinutesBefore ?? 30).toDouble(),
                          min: 0,
                          max: 120,
                          divisions: 24,
                          label: '${_config?.reminderMinutesBefore ?? 30} min',
                          onChanged: (value) => _updateSyncOption(
                            'reminderMinutes',
                            value.toInt(),
                          ),
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
                            'Total Events',
                            '${_stats?['totalEvents'] ?? 0}',
                            Icons.event,
                          ),
                          const Divider(height: 24),
                          _buildStatRow(
                            'Completed Events',
                            '${_stats?['completedEvents'] ?? 0}',
                            Icons.check_circle,
                          ),
                        ],
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
