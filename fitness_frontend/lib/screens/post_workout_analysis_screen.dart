import 'package:flutter/material.dart';
import '../models/form_analysis.dart';
import '../providers/form_correction_provider.dart';
import '../services/export_share_service.dart';
import '../widgets/form_score_chart.dart';
import '../widgets/violation_frequency_chart.dart';
import '../widgets/form_score_badge.dart';

/// Screen showing post-workout form analysis and statistics
class PostWorkoutAnalysisScreen extends StatelessWidget {
  final String exerciseName;
  final List<RepAnalysis> repHistory;
  final Map<String, int> violationFrequency;
  final double averageFormScore;
  final Duration workoutDuration;

  const PostWorkoutAnalysisScreen({
    super.key,
    required this.exerciseName,
    required this.repHistory,
    required this.violationFrequency,
    required this.averageFormScore,
    required this.workoutDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Analysis'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareAnalysis(context),
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Summary cards
            _buildSummaryCards(),
            const SizedBox(height: 24),

            // Average score widget
            AverageFormScoreWidget(averageScore: averageFormScore),
            const SizedBox(height: 24),

            // Form score chart
            _buildSectionTitle('Form Score Progress'),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: FormScoreChart(repHistory: repHistory),
            ),
            const SizedBox(height: 24),

            // Violation frequency
            if (violationFrequency.isNotEmpty) ...[
              _buildSectionTitle('Common Form Issues'),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: ViolationFrequencyChart(
                  violationFrequency: violationFrequency,
                ),
              ),
              const SizedBox(height: 16),
              ViolationListWidget(violationFrequency: violationFrequency),
              const SizedBox(height: 24),
            ],

            // Rep-by-rep breakdown
            _buildSectionTitle('Rep-by-Rep Breakdown'),
            const SizedBox(height: 16),
            _buildRepBreakdown(),
            const SizedBox(height: 24),

            // Suggestions
            _buildSuggestions(),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exerciseName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Completed ${_formatDuration(workoutDuration)} ago',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.fitness_center,
            title: 'Total Reps',
            value: repHistory.length.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.timer,
            title: 'Duration',
            value: _formatDuration(workoutDuration),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.warning,
            title: 'Issues',
            value: violationFrequency.values.fold(0, (a, b) => a + b).toString(),
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRepBreakdown() {
    return Column(
      children: repHistory.asMap().entries.map((entry) {
        final index = entry.key;
        final rep = entry.value;
        final score = FormScore.fromPercentage(rep.formScore);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: score.displayColor,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  'Rep ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                CompactFormScoreBadge(score: score),
              ],
            ),
            subtitle: rep.violations.isNotEmpty
                ? Text(
                    '${rep.violations.length} ${rep.violations.length == 1 ? 'issue' : 'issues'}: ${rep.violations.map((v) => _formatViolationType(v.type)).join(', ')}',
                    style: const TextStyle(fontSize: 12),
                  )
                : const Text(
                    'Perfect form!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            trailing: Icon(
              rep.isGoodRep ? Icons.check_circle : Icons.warning_amber,
              color: rep.isGoodRep ? Colors.green : Colors.orange,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = _generateSuggestions();

    if (suggestions.isEmpty) {
      return Card(
        color: Colors.green.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.green, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Excellent Work!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your form was great throughout the workout. Keep it up!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.lightbulb, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Suggestions for Improvement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<String> _generateSuggestions() {
    final suggestions = <String>[];

    // Based on average score
    if (averageFormScore < 70) {
      suggestions.add(
        'Consider reducing weight and focusing on form quality over quantity',
      );
    }

    // Based on common violations
    final sortedViolations = violationFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedViolations.isNotEmpty) {
      final topViolation = sortedViolations.first;
      final suggestion = _getSuggestionForViolation(topViolation.key);
      if (suggestion != null) {
        suggestions.add(suggestion);
      }
    }

    // Based on rep consistency
    if (repHistory.length >= 3) {
      final scores = repHistory.map((r) => r.formScore).toList();
      final variance = _calculateVariance(scores);
      if (variance > 300) {
        suggestions.add(
          'Form quality varies significantly between reps. Focus on consistent movement patterns',
        );
      }
    }

    return suggestions;
  }

  String? _getSuggestionForViolation(String violationType) {
    const suggestionMap = {
      'KNEE_CAVE': 'Work on hip abductor and glute strength to prevent knee valgus',
      'BACK_ROUNDING': 'Focus on core bracing and hip hinge mechanics',
      'SHALLOW_SQUAT': 'Work on ankle and hip mobility to achieve better depth',
      'KNEE_TOO_FORWARD': 'Practice sitting back into the movement, engage hips earlier',
    };

    return suggestionMap[violationType];
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate back to form correction for another set
              Navigator.pop(context);
            },
            icon: const Icon(Icons.replay),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatViolationType(String violationType) {
    return violationType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  void _shareAnalysis(BuildContext context) async {
    final exportService = ExportShareService();

    // Create session object
    final session = FormCorrectionSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseName: exerciseName,
      startTime: DateTime.now().subtract(workoutDuration),
      duration: workoutDuration,
      totalReps: repHistory.length,
      averageFormScore: averageFormScore,
      repHistory: repHistory,
      violationFrequency: violationFrequency,
    );

    // Show export options dialog
    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose export format:'),
            const SizedBox(height: 16),
            ...ExportFormat.values.map((format) {
              return ListTile(
                leading: Icon(format.icon),
                title: Text(format.displayName),
                onTap: () => Navigator.pop(context, format),
              );
            }).toList(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share as Text'),
              onTap: () => Navigator.pop(context, null),
            ),
          ],
        ),
      ),
    );

    if (format != null) {
      // Share with file
      await exportService.shareSessionFile(session, format: format);
    } else if (format == null && context.mounted) {
      // Share as text
      await exportService.shareSessionText(session);
    }
  }
}
