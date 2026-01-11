import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/block_periodization.dart';
import '../services/block_periodization_service.dart';
import 'block_periodization_detail_screen.dart';
import 'create_block_program_screen.dart';

/// Screen for managing block periodization programs
class BlockPeriodizationScreen extends StatefulWidget {
  const BlockPeriodizationScreen({super.key});

  @override
  State<BlockPeriodizationScreen> createState() =>
      _BlockPeriodizationScreenState();
}

class _BlockPeriodizationScreenState extends State<BlockPeriodizationScreen> {
  final BlockPeriodizationService _periodizationService =
      BlockPeriodizationService();

  List<BlockPeriodizationProgram> _programs = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _programs = _periodizationService.getAllPrograms();
      _stats = _periodizationService.getStats();
    });
  }

  Future<void> _createProgramFromTemplate(String templateType) async {
    final name = await _promptForName(templateType);
    if (name == null || name.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final program = await _periodizationService.createProgramFromTemplate(
        templateType: templateType,
        name: name,
      );

      _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to program detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlockPeriodizationDetailScreen(program: program),
        ),
      ).then((_) => _loadData());
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

  Future<String?> _promptForName(String templateType) async {
    String? name;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Program Name'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter program name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => name = value,
          onSubmitted: (value) {
            name = value;
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    return name;
  }

  Future<void> _showTemplateSelector() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildTemplateOption(
                'classic',
                'Classic Periodization',
                'Hypertrophy → Strength → Power',
                '11 weeks total',
                Icons.trending_up,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildTemplateOption(
                'powerbuilding',
                'Powerbuilding',
                'Alternating hypertrophy and strength blocks',
                '13 weeks total',
                Icons.fitness_center,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildTemplateOption(
                'strength',
                'Strength Focused',
                'Extended strength blocks leading to peak',
                '13 weeks total',
                Icons.flash_on,
                Colors.red,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      await _createProgramFromTemplate(selected);
    }
  }

  Widget _buildTemplateOption(
    String id,
    String title,
    String description,
    String duration,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProgram(BlockPeriodizationProgram program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text(
          'Are you sure you want to delete "${program.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _periodizationService.deleteProgram(program.id);
        _loadData();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program deleted'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Periodization'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statistics card
                if (_stats != null && _stats!['activePrograms'] > 0) ...[
                  Card(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Active Program',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_stats!['currentBlock'] ?? 'N/A'} Block',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Week ${_stats!['currentWeek']} of ${_stats!['totalWeeks']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Create program section
                Text(
                  'Create Program',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showTemplateSelector,
                        icon: const Icon(Icons.article),
                        label: const Text('From Template'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateBlockProgramScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Custom'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Programs list
                Text(
                  'Your Programs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (_programs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No programs yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first block periodization program',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._programs.map((program) => _buildProgramCard(program)),
              ],
            ),
    );
  }

  Widget _buildProgramCard(BlockPeriodizationProgram program) {
    final currentBlock = program.currentBlock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlockPeriodizationDetailScreen(program: program),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
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
                        Text(
                          program.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          program.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (program.isActive)
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
                    )
                  else if (program.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteProgram(program),
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${program.blocks.length} Blocks',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${program.totalWeeks} Weeks Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (currentBlock != null)
                    Text(
                      'Current: ${currentBlock.blockTypeDisplay}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
              if (program.isActive) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: program.overallProgress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(program.overallProgress * 100).toInt()}% Complete',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              if (!program.isActive && !program.isCompleted) ...[
                const SizedBox(height: 12),
                Text(
                  'Created ${DateFormat('MMM d, y').format(program.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
