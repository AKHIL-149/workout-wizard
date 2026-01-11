import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/block_periodization.dart';
import '../services/block_periodization_service.dart';

/// Screen for viewing block periodization program details
class BlockPeriodizationDetailScreen extends StatefulWidget {
  final BlockPeriodizationProgram program;

  const BlockPeriodizationDetailScreen({
    super.key,
    required this.program,
  });

  @override
  State<BlockPeriodizationDetailScreen> createState() =>
      _BlockPeriodizationDetailScreenState();
}

class _BlockPeriodizationDetailScreenState
    extends State<BlockPeriodizationDetailScreen> {
  final BlockPeriodizationService _periodizationService =
      BlockPeriodizationService();

  late BlockPeriodizationProgram _program;
  List<BlockProgressionEntry> _progressionEntries = [];
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

  Future<void> _progressToNextBlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Progress to Next Block'),
        content: const Text(
          'Are you ready to complete the current block and move to the next one?',
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
      final hasNext = await _periodizationService.progressToNextBlock(_program.id);
      _loadData();

      if (!mounted) return;

      if (hasNext) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progressed to next block!'),
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

  Color _getBlockColor(String blockType) {
    switch (blockType) {
      case 'hypertrophy':
        return Colors.blue;
      case 'strength':
        return Colors.orange;
      case 'power':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getBlockIcon(String blockType) {
    switch (blockType) {
      case 'hypertrophy':
        return Icons.fitness_center;
      case 'strength':
        return Icons.flash_on;
      case 'power':
        return Icons.rocket_launch;
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
                                'Blocks',
                                '${_program.blocks.length}',
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
                    onPressed: _progressToNextBlock,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Complete Current Block'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                const SizedBox(height: 24),

                // Blocks list
                Text(
                  'Training Blocks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_program.blocks.length, (index) {
                  final block = _program.blocks[index];
                  final isActive = block.id == _program.currentBlockId;
                  return _buildBlockCard(block, index + 1, isActive);
                }),
                const SizedBox(height: 24),

                // Progression timeline
                if (_progressionEntries.isNotEmpty) ...[
                  Text(
                    'Progression Timeline',
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

  Widget _buildBlockCard(TrainingBlock block, int blockNumber, bool isActive) {
    final color = _getBlockColor(block.blockType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isActive ? color.withValues(alpha: 0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getBlockIcon(block.blockType),
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Block $blockNumber',
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
                                color: color,
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
                        block.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        block.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildBlockDetail(
                  '${block.durationWeeks} weeks',
                  Icons.calendar_today,
                  color,
                ),
                _buildBlockDetail(
                  '${block.repsMin}-${block.repsMax} reps',
                  Icons.repeat,
                  color,
                ),
                _buildBlockDetail(
                  '${(block.intensityMin * 100).toInt()}-${(block.intensityMax * 100).toInt()}% 1RM',
                  Icons.trending_up,
                  color,
                ),
                _buildBlockDetail(
                  '${block.setsPerExercise} sets',
                  Icons.view_list,
                  color,
                ),
                _buildBlockDetail(
                  '${block.restSeconds}s rest',
                  Icons.timer,
                  color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockDetail(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
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

  Widget _buildProgressionEntry(BlockProgressionEntry entry) {
    IconData icon;
    Color color;

    switch (entry.eventType) {
      case 'started':
        icon = Icons.play_circle;
        color = Colors.green;
        break;
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.blue;
        break;
      case 'progressed':
        icon = Icons.trending_up;
        color = Colors.orange;
        break;
      case 'adjusted':
        icon = Icons.tune;
        color = Colors.purple;
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        entry.eventType.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Week ${entry.weekNumber}',
            style: const TextStyle(fontSize: 13),
          ),
          if (entry.notes != null) ...[
            const SizedBox(height: 2),
            Text(
              entry.notes!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
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
