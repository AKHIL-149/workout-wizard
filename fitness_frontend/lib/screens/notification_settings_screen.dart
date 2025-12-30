import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Screen for configuring notification preferences
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = false;
  int _reminderHour = 18;
  bool _restDayReminders = true;
  bool _weeklyGoalReminders = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final enabled = await _notificationService.areNotificationsEnabled();
      final hour = await _notificationService.getReminderTime();
      final restDay = await _notificationService.areRestDayRemindersEnabled();
      final weeklyGoal =
          await _notificationService.areWeeklyGoalRemindersEnabled();

      setState(() {
        _notificationsEnabled = enabled;
        _reminderHour = hour;
        _restDayReminders = restDay;
        _weeklyGoalReminders = weeklyGoal;
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

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Request permissions first
      final granted = await _notificationService.requestPermissions();

      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission denied. Please enable in system settings.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _notificationsEnabled = value);
    await _notificationService.setNotificationsEnabled(value);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notifications enabled'
              : 'Notifications disabled',
        ),
        backgroundColor: value ? Colors.green : Colors.grey,
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null && picked.hour != _reminderHour) {
      setState(() => _reminderHour = picked.hour);
      await _notificationService.setReminderTime(picked.hour);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder time set to ${picked.format(context)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildMainToggle(),
                if (_notificationsEnabled) ...[
                  const SizedBox(height: 24),
                  _buildReminderTimeCard(),
                  const SizedBox(height: 16),
                  _buildAdditionalSettings(),
                ],
                const SizedBox(height: 24),
                _buildTestNotificationButton(),
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
              Icons.notifications_active,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'Workout Reminders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay consistent with daily reminders',
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

  Widget _buildMainToggle() {
    return Card(
      child: SwitchListTile(
        title: const Text(
          'Enable Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Receive daily workout reminders'),
        value: _notificationsEnabled,
        onChanged: _toggleNotifications,
        secondary: Icon(
          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: _notificationsEnabled
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildReminderTimeCard() {
    final timeOfDay = TimeOfDay(hour: _reminderHour, minute: 0);

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.access_time,
          color: Theme.of(context).primaryColor,
        ),
        title: const Text(
          'Reminder Time',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('When to receive daily reminders'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeOfDay.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: _selectReminderTime,
      ),
    );
  }

  Widget _buildAdditionalSettings() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Additional Reminders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Rest Day Reminders'),
            subtitle: const Text('Remind about active recovery'),
            value: _restDayReminders,
            onChanged: (value) async {
              setState(() => _restDayReminders = value);
              await _notificationService.setRestDayReminders(value);
            },
            secondary: const Icon(Icons.hotel),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Weekly Goal Reminders'),
            subtitle: const Text('Track weekly workout goals'),
            value: _weeklyGoalReminders,
            onChanged: (value) async {
              setState(() => _weeklyGoalReminders = value);
              await _notificationService.setWeeklyGoalReminders(value);
            },
            secondary: const Icon(Icons.flag),
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return ElevatedButton.icon(
      onPressed: _notificationsEnabled ? _sendTestNotification : null,
      icon: const Icon(Icons.send),
      label: const Text('Send Test Notification'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      await _notificationService.showNotification(
        id: 999,
        title: 'Test Notification',
        body: 'Your notifications are working! 💪',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
