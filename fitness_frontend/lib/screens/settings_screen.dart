import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_service.dart';
import '../services/storage_service.dart';
import '../services/session_service.dart';
import '../services/analytics_service.dart';
import '../services/gamification_service.dart';
import '../services/form_correction_storage_service.dart';
import '../services/workout_session_service.dart';
import '../widgets/backup_dialogs.dart';
import '../models/backup_model.dart';
import 'form_correction_settings_screen.dart';
import 'video_library_screen.dart';
import 'workout_calendar_screen.dart';
import 'notification_settings_screen.dart';
import 'rest_timer_settings_screen.dart';
import 'statistics_dashboard_screen.dart';

/// Settings screen for backup, restore, and app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final BackupService _backupService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(
      storageService: StorageService(),
      sessionService: SessionService(),
      analyticsService: AnalyticsService(),
      gamificationService: GamificationService(),
      formCorrectionService: FormCorrectionStorageService(),
      workoutSessionService: WorkoutSessionService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  context,
                  title: 'Account & Data',
                  icon: Icons.account_circle,
                  children: [
                    _buildListTile(
                      context,
                      title: 'Backup My Data',
                      subtitle: 'Save your progress to a file',
                      icon: Icons.backup,
                      onTap: _handleBackup,
                    ),
                    _buildListTile(
                      context,
                      title: 'Restore from Backup',
                      subtitle: 'Import previously saved data',
                      icon: Icons.restore,
                      onTap: _handleRestore,
                    ),
                    _buildListTile(
                      context,
                      title: 'Clear All Data',
                      subtitle: 'Delete everything (cannot be undone)',
                      icon: Icons.delete_forever,
                      iconColor: Colors.red,
                      onTap: _handleClearData,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Form Correction',
                  icon: Icons.fitness_center,
                  children: [
                    _buildListTile(
                      context,
                      title: 'Form Correction Settings',
                      subtitle: 'Audio feedback, skeleton display, etc.',
                      icon: Icons.settings,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FormCorrectionSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      title: 'Video Library',
                      subtitle: 'View recorded workout videos',
                      icon: Icons.video_library,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VideoLibraryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      title: 'Statistics Dashboard',
                      subtitle: 'View your progress and achievements',
                      icon: Icons.bar_chart,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StatisticsDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      title: 'Workout Calendar',
                      subtitle: 'View workout history',
                      icon: Icons.calendar_month,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkoutCalendarScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      title: 'Notification Settings',
                      subtitle: 'Configure workout reminders',
                      icon: Icons.notifications,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildListTile(
                      context,
                      title: 'Rest Timer Settings',
                      subtitle: 'Configure rest periods between sets',
                      icon: Icons.timer,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RestTimerSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'About',
                  icon: Icons.info,
                  children: [
                    _buildListTile(
                      context,
                      title: 'App Version',
                      subtitle: '0.4.30',
                      icon: Icons.info_outline,
                      onTap: null,
                    ),
                    _buildListTile(
                      context,
                      title: 'Privacy Policy',
                      subtitle: 'How we handle your data',
                      icon: Icons.privacy_tip,
                      onTap: _showPrivacyInfo,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  Future<void> _handleBackup() async {
    setState(() => _isProcessing = true);

    try {
      // Ask for optional password
      final password = await PasswordDialog.show(
        context,
        isEncrypt: true,
        hint: 'Optionally encrypt your backup with a password. You\'ll need this password to restore.',
      );

      if (password == null) {
        setState(() => _isProcessing = false);
        return; // User cancelled
      }

      // Export data
      final result = await _backupService.exportAllData(
        password: password.isEmpty ? null : password,
      );

      if (!mounted) return;

      if (result.success && result.filePath != null) {
        // Share the backup file
        final shared = await _backupService.shareBackupFile(result.filePath!);

        if (!shared && mounted) {
          await BackupErrorDialog.show(
            context,
            title: 'Share Failed',
            message: 'Backup created but could not open share dialog.',
            details: 'File saved to: ${result.filePath}',
          );
        } else if (mounted) {
          await BackupSuccessDialog.show(
            context,
            title: 'Backup Created',
            message: 'Your data has been backed up successfully!\n\n'
                'Keep this file safe. You\'ll need it to restore your progress.',
            summary: result.summary,
          );

          // Clean old backups
          await _backupService.cleanOldBackups();
        }
      } else if (mounted) {
        await BackupErrorDialog.show(
          context,
          title: 'Backup Failed',
          message: result.errorMessage ?? 'An unknown error occurred',
        );
      }
    } catch (e) {
      if (mounted) {
        await BackupErrorDialog.show(
          context,
          title: 'Backup Failed',
          message: 'An error occurred while creating backup',
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    try {
      // Pick backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wwb'],
        dialogTitle: 'Select Backup File',
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      setState(() => _isProcessing = true);

      final filePath = result.files.single.path!;

      // Try to preview backup (might be encrypted)
      BackupSummary? summary;
      bool needsPassword = false;

      try {
        summary = await _backupService.previewBackup(filePath);
      } catch (e) {
        // Might be encrypted, we'll ask for password
        needsPassword = true;
      }

      String? password;

      // If preview failed or file seems encrypted, ask for password
      if (needsPassword || summary == null) {
        if (!mounted) return;

        password = await PasswordDialog.show(
          context,
          isEncrypt: false,
          hint: 'This backup is encrypted. Enter the password you used when creating it.',
        );

        if (password == null) {
          setState(() => _isProcessing = false);
          return; // User cancelled
        }

        // Try preview again with password
        try {
          summary = await _backupService.previewBackup(filePath, password: password);
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          await BackupErrorDialog.show(
            context,
            title: 'Invalid Password',
            message: 'Could not decrypt backup with provided password',
          );
          return;
        }
      }

      if (!mounted || summary == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // Show summary and confirm
      final proceed = await BackupSummaryDialog.show(context, summary: summary);

      if (proceed != true) {
        setState(() => _isProcessing = false);
        return;
      }

      // Import data
      final importResult = await _backupService.importAllData(
        filePath,
        password: password,
      );

      if (!mounted) return;

      if (importResult.success) {
        await BackupSuccessDialog.show(
          context,
          title: 'Restore Complete',
          message: 'Your data has been restored successfully!',
          summary: importResult.summary,
        );

        // Optionally restart app or reload data
        // For now just pop back
      } else {
        // Check if strategy needed
        if (importResult.errorMessage == 'STRATEGY_REQUIRED') {
          if (!mounted) return;

          // Ask user for merge strategy
          final strategy = await MergeStrategyDialog.show(context);

          if (strategy == null || strategy == MergeStrategy.cancel) {
            setState(() => _isProcessing = false);
            return;
          }

          // Try import again with strategy
          final retryResult = await _backupService.importAllData(
            filePath,
            password: password,
            strategy: strategy,
          );

          if (!mounted) return;

          if (retryResult.success) {
            await BackupSuccessDialog.show(
              context,
              title: 'Restore Complete',
              message: 'Your data has been restored successfully!',
              summary: retryResult.summary,
            );
          } else {
            await BackupErrorDialog.show(
              context,
              title: 'Restore Failed',
              message: retryResult.errorMessage ?? 'An unknown error occurred',
            );
          }
        } else {
          await BackupErrorDialog.show(
            context,
            title: 'Restore Failed',
            message: importResult.errorMessage ?? 'An unknown error occurred',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await BackupErrorDialog.show(
          context,
          title: 'Restore Failed',
          message: 'An error occurred while restoring backup',
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleClearData() async {
    final confirmed = await ClearDataConfirmDialog.show(context);

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      // Clear all data from all services
      await StorageService().clearAllData();
      await FormCorrectionStorageService().deleteAllSessions();
      await FormCorrectionStorageService().clearSettings();
      // Session service and others will be reset on next app launch

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Data Cleared'),
            ],
          ),
          content: const Text(
            'All data has been cleared. The app will restart.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Pop back to home or restart app
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        await BackupErrorDialog.show(
          context,
          title: 'Clear Failed',
          message: 'An error occurred while clearing data',
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Workout Wizard Privacy Information:\n\n'
            '• All data is stored locally on your device\n'
            '• No data is sent to external servers without your permission\n'
            '• Device fingerprint is used for session tracking only\n'
            '• Backups are encrypted with your password (if provided)\n'
            '• You can export and delete all your data at any time\n\n'
            'This app respects your privacy and gives you full control over your data.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
