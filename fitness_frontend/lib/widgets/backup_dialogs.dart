import 'package:flutter/material.dart';
import '../models/backup_model.dart';

/// Dialog for entering password for backup encryption
class PasswordDialog extends StatefulWidget {
  final bool isEncrypt;
  final String? hint;

  const PasswordDialog({
    super.key,
    required this.isEncrypt,
    this.hint,
  });

  static Future<String?> show(
    BuildContext context, {
    required bool isEncrypt,
    String? hint,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(
        isEncrypt: isEncrypt,
        hint: hint,
      ),
    );
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEncrypt ? 'Encrypt Backup' : 'Enter Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.hint!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: widget.isEncrypt ? 'Optional - leave empty for no encryption' : 'Enter backup password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.isEncrypt && _passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.isEncrypt)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Skip Encryption'),
          ),
        ElevatedButton(
          onPressed: _canSubmit()
              ? () => Navigator.pop(context, _passwordController.text)
              : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  bool _canSubmit() {
    if (widget.isEncrypt) {
      // For encryption, allow empty password (no encryption)
      if (_passwordController.text.isEmpty) return true;
      // If password provided, must match confirmation
      return _passwordController.text == _confirmController.text &&
          _passwordController.text.length >= 6;
    } else {
      // For decryption, password required if dialog shown
      return _passwordController.text.isNotEmpty;
    }
  }
}

/// Dialog showing backup preview/summary
class BackupSummaryDialog extends StatelessWidget {
  final BackupSummary summary;
  final VoidCallback? onProceed;
  final VoidCallback? onCancel;

  const BackupSummaryDialog({
    super.key,
    required this.summary,
    this.onProceed,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required BackupSummary summary,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => BackupSummaryDialog(
        summary: summary,
        onProceed: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup Summary'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, 'Export Date', summary.exportDate.toLocal().toString()),
            _buildInfoRow(context, 'Sessions', summary.sessionCount.toString()),
            if (summary.hasProfile) _buildInfoRow(context, 'Profile', 'Yes'),
            if (summary.favoritesCount > 0)
              _buildInfoRow(context, 'Favorites', summary.favoritesCount.toString()),
            if (summary.searchHistoryCount > 0)
              _buildInfoRow(context, 'Search History', '${summary.searchHistoryCount} items'),
            if (summary.currentStreak > 0)
              _buildInfoRow(context, 'Current Streak', '${summary.currentStreak} days'),
            if (summary.achievementsCount > 0)
              _buildInfoRow(context, 'Achievements', summary.achievementsCount.toString()),
            if (summary.formSessionsCount > 0)
              _buildInfoRow(context, 'Form Sessions', summary.formSessionsCount.toString()),
            const Divider(height: 24),
            _buildInfoRow(context, 'Total Size', summary.humanReadableSize),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onProceed,
          child: const Text('Import'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Dialog for selecting merge strategy
class MergeStrategyDialog extends StatelessWidget {
  const MergeStrategyDialog({super.key});

  static Future<MergeStrategy?> show(BuildContext context) async {
    return showDialog<MergeStrategy>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MergeStrategyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Existing Data Detected'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have existing data. How would you like to proceed?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildStrategyOption(
            context,
            MergeStrategy.mergeIntelligently,
            Icons.merge,
          ),
          const SizedBox(height: 12),
          _buildStrategyOption(
            context,
            MergeStrategy.replaceAll,
            Icons.delete_sweep,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, MergeStrategy.cancel),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildStrategyOption(
    BuildContext context,
    MergeStrategy strategy,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, strategy),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strategy.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strategy.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Success dialog with summary
class BackupSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final BackupSummary? summary;

  const BackupSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.summary,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    BackupSummary? summary,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => BackupSuccessDialog(
        title: title,
        message: message,
        summary: summary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (summary != null && summary!.hasSignificantData) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Restored:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (summary!.favoritesCount > 0)
              _buildInfoChip(context, '${summary!.favoritesCount} favorites'),
            if (summary!.achievementsCount > 0)
              _buildInfoChip(context, '${summary!.achievementsCount} achievements'),
            if (summary!.currentStreak > 0)
              _buildInfoChip(context, '${summary!.currentStreak}-day streak'),
            if (summary!.formSessionsCount > 0)
              _buildInfoChip(context, '${summary!.formSessionsCount} form sessions'),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Chip(
        label: Text(text),
        backgroundColor: Colors.green.shade50,
        labelStyle: TextStyle(color: Colors.green.shade700),
      ),
    );
  }
}

/// Error dialog
class BackupErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? details;

  const BackupErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.details,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => BackupErrorDialog(
        title: title,
        message: message,
        details: details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (details != null) ...[
            const SizedBox(height: 12),
            Text(
              details!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Confirmation dialog for clearing data
class ClearDataConfirmDialog extends StatelessWidget {
  const ClearDataConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => const ClearDataConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('Clear All Data'),
        ],
      ),
      content: const Text(
        'This will permanently delete all your data including:\n\n'
        '• User profile\n'
        '• Favorites\n'
        '• Search history\n'
        '• Achievements and streaks\n'
        '• Form correction sessions\n\n'
        'This action cannot be undone. Consider backing up first!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Clear All Data'),
        ),
      ],
    );
  }
}
