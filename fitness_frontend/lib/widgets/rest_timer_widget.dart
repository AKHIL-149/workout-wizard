import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rest_timer_service.dart';

/// Compact rest timer widget shown during workouts
class RestTimerWidget extends StatelessWidget {
  final VoidCallback? onTimerComplete;

  const RestTimerWidget({
    super.key,
    this.onTimerComplete,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: RestTimerService(),
      child: Consumer<RestTimerService>(
        builder: (context, timerService, child) {
          if (!timerService.isRunning && !timerService.isCompleted) {
            return const SizedBox.shrink();
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: timerService.isCompleted
                  ? Colors.green.shade50
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: timerService.isCompleted
                    ? Colors.green
                    : Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timer display
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon
                      Icon(
                        timerService.isCompleted
                            ? Icons.check_circle
                            : Icons.timer,
                        color: timerService.isCompleted
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 16),

                      // Time display
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timerService.isCompleted
                                  ? 'Rest Complete!'
                                  : 'Resting...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timerService.isCompleted
                                  ? 'Ready for next set'
                                  : timerService.remainingTimeFormatted,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: timerService.isCompleted
                                    ? Colors.green
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      if (!timerService.isCompleted) ...[
                        // Add time button
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => timerService.addTime(15),
                          tooltip: '+15s',
                          color: Theme.of(context).primaryColor,
                        ),

                        // Pause/Resume button
                        IconButton(
                          icon: Icon(
                            timerService.isRunning ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () {
                            if (timerService.isRunning) {
                              timerService.pauseTimer();
                            } else {
                              timerService.resumeTimer();
                            }
                          },
                          color: Theme.of(context).primaryColor,
                        ),

                        // Skip button
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: () {
                            timerService.skipRest();
                            onTimerComplete?.call();
                          },
                          tooltip: 'Skip',
                          color: Colors.orange,
                        ),
                      ] else ...[
                        // Dismiss button when completed
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            timerService.resetTimer();
                            onTimerComplete?.call();
                          },
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),

                // Progress bar
                if (!timerService.isCompleted)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    child: LinearProgressIndicator(
                      value: timerService.progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen rest timer overlay
class RestTimerOverlay extends StatelessWidget {
  final int remainingSeconds;
  final VoidCallback onSkip;
  final VoidCallback onAddTime;

  const RestTimerOverlay({
    super.key,
    required this.remainingSeconds,
    required this.onSkip,
    required this.onAddTime,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer icon
            Icon(
              Icons.timer,
              size: 80,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 32),

            // Rest label
            Text(
              'Rest Time',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Time display
            Text(
              timeString,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add 15 seconds
                ElevatedButton.icon(
                  onPressed: onAddTime,
                  icon: const Icon(Icons.add),
                  label: const Text('+15s'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Skip rest
                ElevatedButton.icon(
                  onPressed: onSkip,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip Rest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
