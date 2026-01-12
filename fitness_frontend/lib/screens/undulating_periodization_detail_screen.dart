import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/undulating_periodization.dart';
import '../services/undulating_periodization_service.dart';

/// Screen for viewing undulating periodization program details
class UndulatingPeriodizationDetailScreen extends StatefulWidget {
  final UndulatingPeriodizationProgram program;

  const UndulatingPeriodizationDetailScreen({
    super.key,
    required this.program,
  });

  @override
  State<UndulatingPeriodizationDetailScreen> createState() =>
      _UndulatingPeriodizationDetailScreenState();
}

class _UndulatingPeriodizationDetailScreenState
    extends State<UndulatingPeriodizationDetailScreen> {
  final UndulatingPeriodizationService _periodizationService =
      UndulatingPeriodizationService();

  late UndulatingPeriodizationProgram _program;
  Map<String, dynamic>? _workoutParams;
  List<UndulatingProgressionEntry> _progressionEntries = [];
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
      _workoutParams =
          _periodizationService.getCurrentWorkoutParameters(_program.id);
      _progressionEntries = _periodizationService.getProgressionEntries(
        programId: _program.id,
      );
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

  Future<void> _progressToNextWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Progress to Next Workout'),
        content: const Text(
          'Mark current workout as complete and move to the next one?',
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
      final hasNext =
          await _periodizationService.progressToNextWorkout(_program.id);
      _loadData();

      if (!mounted) return;

      if (hasNext) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progressed to next workout!'),
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

  Color _getDayTypeColor(String dayType) {
    switch (dayType) {
      case 'heavy':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'light':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getDayTypeIcon(String dayType) {
    switch (dayType) {
      case 'heavy':
        return Icons.fitness_center;
      case 'moderate':
        return Icons.trending_up;
      case 'light':
        return Icons.spa;
      default:
        return Icons.circle;
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
                // Program info card
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
                                'Cycles',
                                '${_program.cycles.length}',
                                Icons.loop,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Type',
                                _program.undulationType.toUpperCase(),
                                Icons.waves,
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

                // Current workout parameters (if active)
                if (_workoutParams != null && _program.isActive) ...[
                  Card(
                    color: _getDayTypeColor(_workoutParams!['dayType'] ?? '')
                        .withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getDayTypeIcon(
                                    _workoutParams!['dayType'] ?? ''),
                                color: _getDayTypeColor(
                                    _workoutParams!['dayType'] ?? ''),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Workout',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _workoutParams!['dayName'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Day ${_workoutParams!['dayInCycle']}/${_workoutParams!['totalDaysInCycle']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildParamChip(
                                'Intensity',
                                '${(_workoutParams!['intensity'] * 100).toInt()}%',
                                Icons.trending_up,
                              ),
                              _buildParamChip(
                                'Reps',
                                '${_workoutParams!['repsMin']}-${_workoutParams!['repsMax']}',
                                Icons.repeat,
                              ),
                              _buildParamChip(
                                'Sets',
                                '${_workoutParams!['sets']}',
                                Icons.view_list,
                              ),
                              _buildParamChip(
                                'Rest',
                                '${_workoutParams!['restSeconds']}s',
                                Icons.timer,
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
                    onPressed: _progressToNextWorkout,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Complete Current Workout'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                const SizedBox(height: 24),

                // Cycles list
                Text(
                  'Training Cycles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_program.cycles.length, (index) {
                  final cycle = _program.cycles[index];
                  final isActive = cycle.id == _program.currentCycleId;
                  return _buildCycleCard(cycle, index + 1, isActive);
                }),
                const SizedBox(height: 24),

                // Progression history
                if (_progressionEntries.isNotEmpty) ...[
                  Text(
                    'Workout History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _progressionEntries.length > 10
                          ? 10
                          : _progressionEntries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = _progressionEntries[index];
                        return _buildProgressionEntry(entry);
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleCard(UndulatingCycle cycle, int cycleNumber, bool isActive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isActive ? Colors.purple.withValues(alpha: 0.05) : null,
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
                      Row(
                        children: [
                          Text(
                            'Cycle $cycleNumber',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cycle.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cycle.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '×${cycle.repeatCount}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Workout days in this cycle
            ...cycle.workoutDays.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final color = _getDayTypeColor(day.dayType);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < cycle.workoutDays.length - 1 ? 8 : 0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(_getDayTypeIcon(day.dayType), size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          day.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${(day.intensityPercent * 100).toInt()}% × ${day.repsMin}-${day.repsMax}',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionEntry(UndulatingProgressionEntry entry) {
    final cycle = _program.cycles.where((c) => c.id == entry.cycleId).firstOrNull;
    final day = cycle?.workoutDays
        .where((d) => d.id == entry.workoutDayId)
        .firstOrNull;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            _getDayTypeColor(day?.dayType ?? '').withValues(alpha: 0.1),
        child: Icon(
          _getDayTypeIcon(day?.dayType ?? ''),
          color: _getDayTypeColor(day?.dayType ?? ''),
          size: 20,
        ),
      ),
      title: Text(
        day?.name ?? 'Workout',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        'Week ${entry.weekNumber}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        DateFormat('MMM d').format(entry.timestamp),
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
