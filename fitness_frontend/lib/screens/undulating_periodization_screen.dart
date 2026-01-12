import 'package:flutter/material.dart';
import '../models/undulating_periodization.dart';
import '../services/undulating_periodization_service.dart';
import 'undulating_periodization_detail_screen.dart';
import 'create_undulating_program_screen.dart';

/// Screen for managing undulating periodization programs
class UndulatingPeriodizationScreen extends StatefulWidget {
  const UndulatingPeriodizationScreen({super.key});

  @override
  State<UndulatingPeriodizationScreen> createState() =>
      _UndulatingPeriodizationScreenState();
}

class _UndulatingPeriodizationScreenState
    extends State<UndulatingPeriodizationScreen> {
  final UndulatingPeriodizationService _periodizationService =
      UndulatingPeriodizationService();

  List<UndulatingPeriodizationProgram> _programs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  void _loadPrograms() {
    setState(() {
      _programs = _periodizationService.getAllPrograms();
    });
  }

  Future<void> _showTemplateSelector() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTemplateOption(
                'beginner',
                'Beginner DUP',
                '3-day cycle: Heavy, Light, Moderate',
                '12 weeks',
                Icons.fitness_center,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildTemplateOption(
                'advanced',
                'Advanced DUP',
                '4-day cycle: Max Strength, Hypertrophy, Power, Recovery',
                '8 weeks',
                Icons.flash_on,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildTemplateOption(
                'weekly',
                'Weekly Undulating',
                'Volume, Intensity, and Deload weeks',
                '10 weeks',
                Icons.trending_up,
                Colors.purple,
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

    if (selected != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateUndulatingProgramScreen(templateType: selected),
        ),
      ).then((_) => _loadPrograms());
    }
  }

  Widget _buildTemplateOption(
    String value,
    String title,
    String description,
    String duration,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
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
                      color: color,
                      fontWeight: FontWeight.w600,
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

  Future<void> _deleteProgram(UndulatingPeriodizationProgram program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text('Delete "${program.name}"? This cannot be undone.'),
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
      await _periodizationService.deleteProgram(program.id);
      _loadPrograms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Undulating Periodization'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _programs.isEmpty
              ? _buildEmptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Info card
                    Card(
                      color: Colors.purple.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.purple.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'About Undulating Periodization',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Varies intensity and volume daily or weekly for optimal adaptation and recovery. Prevents plateaus through constant variation.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Programs list
                    ..._programs.map((program) => _buildProgramCard(program)),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTemplateSelector,
        icon: const Icon(Icons.add),
        label: const Text('New Program'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.waves,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Undulating Programs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first program with daily or weekly variation to maximize strength gains',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showTemplateSelector,
              icon: const Icon(Icons.add),
              label: const Text('Create Program'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard(UndulatingPeriodizationProgram program) {
    final stats = _periodizationService.getProgramStatistics(program.id);
    final currentDay = program.currentWorkoutDay;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UndulatingPeriodizationDetailScreen(program: program),
            ),
          ).then((_) => _loadPrograms());
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
                            fontSize: 18,
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
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteProgram(program),
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current workout day (if active)
              if (program.isActive && currentDay != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getDayTypeColor(currentDay.dayType)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getDayTypeIcon(currentDay.dayType),
                        color: _getDayTypeColor(currentDay.dayType),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Workout',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              currentDay.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(currentDay.intensityPercent * 100).toInt()}% × ${currentDay.repsMin}-${currentDay.repsMax}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getDayTypeColor(currentDay.dayType),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      'Week ${stats['currentWeek'] ?? 0}/${stats['totalWeeks'] ?? 0}',
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      '${((stats['progress'] ?? 0.0) * 100).toInt()}% done',
                      Icons.pie_chart,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      '${program.undulationType} DUP',
                      Icons.waves,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
}
