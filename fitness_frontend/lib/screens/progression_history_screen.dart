import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/progression_metrics.dart';
import '../services/progression_tracking_service.dart';
import '../services/workout_session_service.dart';
import '../widgets/progression_chart.dart';

/// Screen displaying progression history and charts for an exercise
class ProgressionHistoryScreen extends StatefulWidget {
  final String exerciseName;

  const ProgressionHistoryScreen({
    super.key,
    required this.exerciseName,
  });

  @override
  State<ProgressionHistoryScreen> createState() =>
      _ProgressionHistoryScreenState();
}

class _ProgressionHistoryScreenState extends State<ProgressionHistoryScreen> {
  final ProgressionTrackingService _progressionService =
      ProgressionTrackingService();
  final WorkoutSessionService _sessionService = WorkoutSessionService();

  ProgressionMetrics? _metrics;
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedPeriod = 30; // Days

  @override
  void initState() {
    super.initState();
    _loadProgressionData();
  }

  Future<void> _loadProgressionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: _selectedPeriod));

      final metrics = _progressionService.getProgressionMetrics(
        widget.exerciseName,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading progression data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        actions: [
          PopupMenuButton<int>(
            onSelected: (period) {
              setState(() => _selectedPeriod = period);
              _loadProgressionData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
              const PopupMenuItem(value: 365, child: Text('Last year')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadProgressionData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _metrics == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timeline,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No data for this exercise',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start logging workouts to track your progress',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProgressionData,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          _buildSummaryCard(),
                          _buildPersonalRecordsCard(),
                          ProgressionChart(
                            volumeHistory: _metrics!.volumeHistory,
                            chartType: ChartType.volume,
                            title: 'Volume Progression',
                          ),
                          ProgressionChart(
                            weightHistory: _metrics!.weightHistory,
                            chartType: ChartType.weight,
                            title: 'Weight Progression',
                          ),
                          if (_metrics!.recommendation != null)
                            _buildRecommendationCard(),
                          _buildSessionHistoryCard(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryMetric(
                  'Sessions',
                  _metrics!.totalSessions.toString(),
                  Icons.fitness_center,
                ),
                _buildSummaryMetric(
                  'Frequency',
                  '${_metrics!.sessionsPerWeek.toStringAsFixed(1)}/week',
                  Icons.calendar_today,
                ),
                _buildSummaryMetric(
                  'Trend',
                  _getTrendText(),
                  _getTrendIcon(),
                  color: _getTrendColor(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insights,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _metrics!.summary,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color ?? Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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

  Widget _buildPersonalRecordsCard() {
    final hasRecords = _metrics!.volumePR != null ||
        _metrics!.weightPR != null ||
        _metrics!.repsPR != null;

    if (!hasRecords) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Personal Records',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_metrics!.weightPR != null)
              _buildPRRow(
                'Max Weight',
                '${_metrics!.weightPR!.value.toStringAsFixed(1)} kg',
                _metrics!.weightPR!.achievedDate,
                _metrics!.weightPR!.notes,
              ),
            if (_metrics!.volumePR != null)
              _buildPRRow(
                'Max Volume',
                '${_metrics!.volumePR!.value.toStringAsFixed(0)} kg',
                _metrics!.volumePR!.achievedDate,
                _metrics!.volumePR!.notes,
              ),
            if (_metrics!.repsPR != null)
              _buildPRRow(
                'Max Reps',
                _metrics!.repsPR!.value.toInt().toString(),
                _metrics!.repsPR!.achievedDate,
                _metrics!.repsPR!.notes,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRRow(
    String label,
    String value,
    DateTime date,
    String? notes,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (notes != null)
                Text(
                  notes,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          Text(
            DateFormat('MMM d, y').format(date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final rec = _metrics!.recommendation!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Next Workout Recommendation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              rec.rationale,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRecMetric(
                    'Weight',
                    '${rec.recommendedWeight.toStringAsFixed(1)} kg',
                  ),
                  _buildRecMetric(
                    'Sets',
                    rec.recommendedSets.toString(),
                  ),
                  _buildRecMetric(
                    'Reps',
                    rec.recommendedReps.toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
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

  Widget _buildSessionHistoryCard() {
    final sessions =
        _sessionService.getWorkoutSessionsWithExercise(widget.exerciseName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            ...sessions.take(5).map((session) {
              final exercise = session.exercises
                  .firstWhere((ex) => ex.exerciseName == widget.exerciseName);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.fitness_center,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  DateFormat('MMM d, y').format(session.startTime),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${exercise.sets.length} sets • ${exercise.totalVolume.toStringAsFixed(0)} kg volume',
                ),
                trailing: Text(
                  '${exercise.maxWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getTrendText() {
    switch (_metrics!.trend) {
      case ProgressionTrend.increasing:
        return 'Improving';
      case ProgressionTrend.stable:
        return 'Stable';
      case ProgressionTrend.decreasing:
        return 'Declining';
      case ProgressionTrend.inconsistent:
        return 'Variable';
    }
  }

  IconData _getTrendIcon() {
    switch (_metrics!.trend) {
      case ProgressionTrend.increasing:
        return Icons.trending_up;
      case ProgressionTrend.stable:
        return Icons.trending_flat;
      case ProgressionTrend.decreasing:
        return Icons.trending_down;
      case ProgressionTrend.inconsistent:
        return Icons.show_chart;
    }
  }

  Color _getTrendColor() {
    switch (_metrics!.trend) {
      case ProgressionTrend.increasing:
        return Colors.green;
      case ProgressionTrend.stable:
        return Colors.blue;
      case ProgressionTrend.decreasing:
        return Colors.red;
      case ProgressionTrend.inconsistent:
        return Colors.orange;
    }
  }
}
