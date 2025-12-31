import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deload_settings.dart';
import '../services/deload_service.dart';

/// Screen for tracking daily recovery metrics
class RecoveryMetricsScreen extends StatefulWidget {
  const RecoveryMetricsScreen({super.key});

  @override
  State<RecoveryMetricsScreen> createState() => _RecoveryMetricsScreenState();
}

class _RecoveryMetricsScreenState extends State<RecoveryMetricsScreen> {
  final DeloadService _deloadService = DeloadService();

  DateTime _selectedDate = DateTime.now();
  int _sleepQuality = 3;
  int _energyLevel = 3;
  int _muscleSoreness = 3;
  int _stressLevel = 3;

  bool _hasExistingMetrics = false;

  @override
  void initState() {
    super.initState();
    _loadMetricsForDate();
  }

  void _loadMetricsForDate() {
    final metrics = _deloadService.getMetricsForDate(_selectedDate);

    setState(() {
      if (metrics != null) {
        _sleepQuality = metrics.sleepQuality;
        _energyLevel = metrics.energyLevel;
        _muscleSoreness = metrics.muscleSoreness;
        _stressLevel = metrics.stressLevel;
        _hasExistingMetrics = true;
      } else {
        _sleepQuality = 3;
        _energyLevel = 3;
        _muscleSoreness = 3;
        _stressLevel = 3;
        _hasExistingMetrics = false;
      }
    });
  }

  Future<void> _saveMetrics() async {
    final metrics = RecoveryMetrics(
      id: _selectedDate.toIso8601String().split('T')[0],
      date: _selectedDate,
      sleepQuality: _sleepQuality,
      energyLevel: _energyLevel,
      muscleSoreness: _muscleSoreness,
      stressLevel: _stressLevel,
    );

    try {
      await _deloadService.saveRecoveryMetrics(metrics);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recovery metrics saved'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _hasExistingMetrics = true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving metrics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadMetricsForDate();
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 3.5) return Colors.green;
    if (score >= 2.5) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 4.0) return 'Excellent';
    if (score >= 3.5) return 'Good';
    if (score >= 2.5) return 'Fair';
    if (score >= 2.0) return 'Poor';
    return 'Very Poor';
  }

  @override
  Widget build(BuildContext context) {
    final currentMetrics = RecoveryMetrics(
      id: 'temp',
      date: _selectedDate,
      sleepQuality: _sleepQuality,
      energyLevel: _energyLevel,
      muscleSoreness: _muscleSoreness,
      stressLevel: _stressLevel,
    );

    final recoveryScore = currentMetrics.recoveryScore;
    final scoreColor = _getScoreColor(recoveryScore);
    final scoreLabel = _getScoreLabel(recoveryScore);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(),
            tooltip: 'View History',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildRecoveryScoreCard(recoveryScore, scoreColor, scoreLabel),
          const SizedBox(height: 24),
          _buildMetricSlider(
            'Sleep Quality',
            Icons.bedtime,
            _sleepQuality,
            (value) => setState(() => _sleepQuality = value),
            'How well did you sleep?',
          ),
          const SizedBox(height: 16),
          _buildMetricSlider(
            'Energy Level',
            Icons.bolt,
            _energyLevel,
            (value) => setState(() => _energyLevel = value),
            'How energetic do you feel?',
          ),
          const SizedBox(height: 16),
          _buildMetricSlider(
            'Muscle Soreness',
            Icons.fitness_center,
            _muscleSoreness,
            (value) => setState(() => _muscleSoreness = value),
            'How sore are your muscles?',
            isReversed: true,
          ),
          const SizedBox(height: 16),
          _buildMetricSlider(
            'Stress Level',
            Icons.psychology,
            _stressLevel,
            (value) => setState(() => _stressLevel = value),
            'How stressed do you feel?',
            isReversed: true,
          ),
          const SizedBox(height: 24),
          _buildWeeklyAverage(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Card(
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'Today' : DateFormat('EEEE, MMMM d').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_hasExistingMetrics)
                      Text(
                        'Metrics recorded',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryScoreCard(double score, Color color, String label) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Recovery Score',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (score < 2.5) ...[
              const SizedBox(height: 12),
              const Text(
                '⚠️ Consider taking a rest day or deload',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSlider(
    String title,
    IconData icon,
    int value,
    Function(int) onChanged,
    String subtitle, {
    bool isReversed = false,
  }) {
    final labels = isReversed
        ? ['Very Low', 'Low', 'Moderate', 'High', 'Very High']
        : ['Very Poor', 'Poor', 'Fair', 'Good', 'Excellent'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: labels[value - 1],
                    onChanged: (val) => onChanged(val.round()),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              labels[value - 1],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAverage() {
    final avgScore = _deloadService.getAverageRecoveryScore(days: 7);
    final recentMetrics = _deloadService.getRecentMetrics(days: 7);

    if (recentMetrics.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Log metrics for 7 days to see weekly average',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '7-Day Average',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  avgScore.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(avgScore),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getScoreLabel(avgScore),
                  style: TextStyle(
                    fontSize: 16,
                    color: _getScoreColor(avgScore),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Based on ${recentMetrics.length} day${recentMetrics.length != 1 ? 's' : ''} of data',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveMetrics,
      icon: Icon(_hasExistingMetrics ? Icons.update : Icons.save),
      label: Text(_hasExistingMetrics ? 'Update Metrics' : 'Save Metrics'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  void _showHistory() {
    final metrics = _deloadService.getRecentMetrics(days: 30);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Recovery History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: metrics.isEmpty
                    ? const Center(child: Text('No metrics recorded yet'))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: metrics.length,
                        itemBuilder: (context, index) {
                          final metric = metrics[index];
                          final isToday = DateFormat('yyyy-MM-dd')
                                  .format(metric.date) ==
                              DateFormat('yyyy-MM-dd').format(DateTime.now());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getScoreColor(metric.recoveryScore)
                                        .withValues(alpha: 0.2),
                                child: Text(
                                  metric.recoveryScore.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(metric.recoveryScore),
                                  ),
                                ),
                              ),
                              title: Text(
                                isToday
                                    ? 'Today'
                                    : DateFormat('EEEE, MMM d')
                                        .format(metric.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _getScoreLabel(metric.recoveryScore),
                                style: TextStyle(
                                  color: _getScoreColor(metric.recoveryScore),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() => _selectedDate = metric.date);
                                _loadMetricsForDate();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
