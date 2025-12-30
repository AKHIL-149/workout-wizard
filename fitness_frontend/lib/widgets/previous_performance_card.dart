import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise_performance.dart';

/// Widget to display previous workout performance for an exercise
class PreviousPerformanceCard extends StatelessWidget {
  final ExercisePerformance performance;
  final DateTime workoutDate;
  final VoidCallback? onTap;

  const PreviousPerformanceCard({
    super.key,
    required this.performance,
    required this.workoutDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final workingSets = performance.sets.where((s) => !s.isWarmup).toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last Workout',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('MMM d').format(workoutDate),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Performance summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    context,
                    'Sets',
                    workingSets.length.toString(),
                    Icons.fitness_center,
                  ),
                  _buildMetric(
                    context,
                    'Max Weight',
                    '${performance.maxWeight.toStringAsFixed(1)} kg',
                    Icons.trending_up,
                  ),
                  _buildMetric(
                    context,
                    'Volume',
                    '${performance.totalVolume.toStringAsFixed(0)} kg',
                    Icons.bar_chart,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Set breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Breakdown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...workingSets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final set = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Set ${index + 1}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${set.weight} kg × ${set.reps} reps',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (set.targetAchieved)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Form score if available
              if (performance.averageFormScore != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: _getFormScoreColor(performance.averageFormScore!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Form Score: ${performance.averageFormScore!.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getFormScoreColor(performance.averageFormScore!),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              // Tap to view details
              if (onTap != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View Full History'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getFormScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
