import 'package:flutter/material.dart';
import '../utils/exceptions.dart';

/// Widget to display errors in a user-friendly way
class ErrorDisplay extends StatelessWidget {
  final AppException error;
  final VoidCallback? onRetry;
  final bool showDetails;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForError(),
              size: 64,
              color: _getColorForError(context),
            ),
            const SizedBox(height: 16),
            Text(
              error.userMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (showDetails && error.details != null) ...[
              const SizedBox(height: 8),
              Text(
                error.details!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForError() {
    if (error is NetworkException) {
      return Icons.wifi_off;
    } else if (error is TimeoutException) {
      return Icons.access_time;
    } else if (error is ServerException) {
      return Icons.cloud_off;
    } else if (error is NoRecommendationsException) {
      return Icons.search_off;
    } else if (error is ValidationException) {
      return Icons.error_outline;
    } else {
      return Icons.error;
    }
  }

  Color _getColorForError(BuildContext context) {
    if (error is NoRecommendationsException) {
      return Colors.orange;
    } else if (error is ValidationException) {
      return Colors.amber;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }
}

/// Inline error message widget (for forms and small spaces)
class InlineErrorMessage extends StatelessWidget {
  final String message;

  const InlineErrorMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Snackbar helper for showing errors
class ErrorSnackbar {
  static void show(BuildContext context, AppException error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error is NetworkException
                  ? Icons.wifi_off
                  : error is TimeoutException
                      ? Icons.access_time
                      : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(error.userMessage),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Dialog helper for showing errors
class ErrorDialog {
  static Future<void> show(
    BuildContext context,
    AppException error, {
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userMessage),
            if (error.details != null) ...[
              const SizedBox(height: 8),
              Text(
                error.details!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
