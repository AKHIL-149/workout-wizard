import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/linear_periodization.dart';
import '../services/linear_periodization_service.dart';

/// Screen for viewing linear periodization program details
class LinearPeriodizationDetailScreen extends StatefulWidget {
  final LinearPeriodizationProgram program;

  const LinearPeriodizationDetailScreen({
    super.key,
    required this.program,
  });

  @override
  State<LinearPeriodizationDetailScreen> createState() =>
      _LinearPeriodizationDetailScreenState();
}

class _LinearPeriodizationDetailScreenState
    extends State<LinearPeriodizationDetailScreen> {
  final LinearPeriodizationService _periodizationService =
      LinearPeriodizationService();

  late LinearPeriodizationProgram _program;
  List<LinearProgressionEntry> _progressionEntries = [];
  Map<String, dynamic>? _weekParams;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _program = widget.program;
    _loadData();
  }

  void _loadData() {
    setState(() {
      final updated = _periodizationService.getProgram(_program.id);
      if (updated != null) {
        _program = updated;
      }
      _progressionEntries = _periodizationService.getProgressionEntries(
        programId: _program.id,
      );
      if (_program.isActive) {
        _weekParams = _periodizationService.getCurrentWeekParameters(_program.id);
      }
    });
  }

  Future<void> _startProgram() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Program'),
        content: const Text(
          'This will deactivate any currently active programs. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _periodizationService.startProgram(_program.id);
      _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program started!'),
          backgroundColor: Colors.green,
        ),
      );
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

  Future<void> _progressToNextWeek() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Progress to Next Week'),
        content: const Text(
          'Complete current week and progress to the next?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Progress'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hasNext = await _periodizationService.progressToNextWeek(_program.id);
      _loadData();

      if (!mounted) return;

      if (hasNext) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progressed to next week!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program completed! 🎉'),
            backgroundColor: Colors.green,
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

  Color _getPhaseColor(String phaseType) {
    switch (phaseType) {
      case 'hypertrophy':
        return Colors.blue;
      case 'strength':
        return Colors.orange;
      case 'power':
        return Colors.red;
      case 'peaking':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_program.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Program info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Program Info',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _program.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_program.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'Phases',
                                '${_program.phases.length}',
                                Icons.view_module,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Total Weeks',
                                '${_program.totalWeeks}',
                                Icons.calendar_today,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Progress',
                                '${(_program.overallProgress * 100).toInt()}%',
                                Icons.pie_chart,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Current week parameters
                if (_weekParams != null && _program.isActive) ...[
                  Card(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week ${_weekParams!['week']} Parameters',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildParamChip(
                                  'Intensity',
                                  '${(_weekParams!['intensity'] * 100).toInt()}%',
                                  Icons.trending_up,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildParamChip(
                                  'Volume',
                                  '${_weekParams!['volume']} sets',
                                  Icons.view_list,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildParamChip(
                                  'Reps',
                                  '${_weekParams!['repsPerSet']}',
                                  Icons.repeat,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                if (!_program.isActive && !_program.isCompleted)
                  ElevatedButton.icon(
                    onPressed: _startProgram,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Program'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  )
                else if (_program.isActive)
                  ElevatedButton.icon(
                    onPressed: _progressToNextWeek,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Complete Week'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                const SizedBox(height: 24),

                // Phases
                Text(
                  'Training Phases',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_program.phases.length, (index) {
                  final phase = _program.phases[index];
                  return _buildPhaseCard(phase, index + 1);
                }),
                const SizedBox(height: 24),

                // Progression history
                if (_progressionEntries.isNotEmpty) ...[
                  Text(
                    'Weekly Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _progressionEntries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return _buildProgressionEntry(_progressionEntries[index]);
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildParamChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(LinearPhase phase, int phaseNumber) {
    final color = _getPhaseColor(phase.phaseType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Phase $phaseNumber',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phase.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              phase.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildPhaseDetail(
                  '${phase.durationWeeks}w',
                  Icons.calendar_today,
                ),
                _buildPhaseDetail(
                  '${(phase.startingIntensity * 100).toInt()}-${(phase.endingIntensity * 100).toInt()}%',
                  Icons.trending_up,
                ),
                _buildPhaseDetail(
                  '${phase.startingVolume}-${phase.endingVolume} sets',
                  Icons.view_list,
                ),
                _buildPhaseDetail(
                  '${phase.repsPerSet} reps',
                  Icons.repeat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseDetail(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressionEntry(LinearProgressionEntry entry) {
    final isOnTrack = entry.isOnTrack;
    final color = isOnTrack ? Colors.green : Colors.orange;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Text(
          'W${entry.weekNumber}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
      title: Text(
        'Intensity: ${(entry.plannedIntensity * 100).toInt()}% planned',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: entry.actualVolume > 0
          ? Text(
              'Adherence: ${(entry.adherenceScore * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12),
            )
          : Text(
              'Not completed yet',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
      trailing: entry.deloadWeek
          ? const Chip(
              label: Text(
                'DELOAD',
                style: TextStyle(fontSize: 10),
              ),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }
}
