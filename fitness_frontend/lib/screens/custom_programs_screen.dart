import 'package:flutter/material.dart';
import '../models/workout_program.dart';
import '../services/custom_program_service.dart';
import '../services/program_library_service.dart';
import 'program_detail_screen.dart';
import 'program_editor_screen.dart';
import 'program_share_screen.dart';

/// Screen for managing user's custom workout programs
class CustomProgramsScreen extends StatefulWidget {
  const CustomProgramsScreen({super.key});

  @override
  State<CustomProgramsScreen> createState() => _CustomProgramsScreenState();
}

class _CustomProgramsScreenState extends State<CustomProgramsScreen> {
  final CustomProgramService _customService = CustomProgramService();
  final ProgramLibraryService _libraryService = ProgramLibraryService();

  List<WorkoutProgram> _customPrograms = [];

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  void _loadPrograms() {
    setState(() {
      _customPrograms = _customService.getAllCustomPrograms();
    });
  }

  Future<void> _createNewProgram() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramEditorScreen(
          program: _customService.createBlankProgram(),
          isNew: true,
        ),
      ),
    );

    if (result == true) {
      _loadPrograms();
    }
  }

  Future<void> _cloneProgram() async {
    final allPrograms = [
      ..._libraryService.getAllPrograms(),
      ..._customPrograms,
    ];

    if (allPrograms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No programs available to clone')),
      );
      return;
    }

    final selected = await showDialog<WorkoutProgram>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Program to Clone'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allPrograms.length,
            itemBuilder: (context, index) {
              final program = allPrograms[index];
              return ListTile(
                title: Text(program.name),
                subtitle: Text(program.author),
                onTap: () => Navigator.pop(context, program),
              );
            },
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

    if (selected == null || !mounted) return;

    try {
      final cloned = await _customService.cloneProgram(selected);
      _loadPrograms();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cloned ${selected.name}'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to editor
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProgramEditorScreen(
            program: cloned,
            isNew: false,
          ),
        ),
      );

      if (result == true) {
        _loadPrograms();
      }
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

  Future<void> _editProgram(WorkoutProgram program) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramEditorScreen(
          program: program,
          isNew: false,
        ),
      ),
    );

    if (result == true) {
      _loadPrograms();
    }
  }

  Future<void> _deleteProgram(WorkoutProgram program) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program?'),
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

    if (confirm != true || !mounted) return;

    try {
      await _customService.deleteProgram(program.id);
      _loadPrograms();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${program.name}'),
          backgroundColor: Colors.orange,
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

  void _viewProgram(WorkoutProgram program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(program: program),
      ),
    );
  }

  void _shareProgram(WorkoutProgram program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramShareScreen(program: program),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Programs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _cloneProgram,
            tooltip: 'Clone Program',
          ),
        ],
      ),
      body: _customPrograms.isEmpty
          ? _buildEmptyState()
          : _buildProgramList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewProgram,
        icon: const Icon(Icons.add),
        label: const Text('New Program'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No Custom Programs',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create a new program or clone an existing one',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _createNewProgram,
                icon: const Icon(Icons.add),
                label: const Text('Create New'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _cloneProgram,
                icon: const Icon(Icons.copy),
                label: const Text('Clone Existing'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customPrograms.length,
      itemBuilder: (context, index) {
        final program = _customPrograms[index];
        return _buildProgramCard(program);
      },
    );
  }

  Widget _buildProgramCard(WorkoutProgram program) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () => _viewProgram(program),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          program.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildDifficultyBadge(program.difficulty),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    program.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                          Icons.calendar_today, '${program.durationWeeks} weeks'),
                      _buildInfoChip(
                          Icons.fitness_center, '${program.daysPerWeek} days/week'),
                      ...program.goals.map((goal) => _buildGoalBadge(goal)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _shareProgram(program),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
                TextButton.icon(
                  onPressed: () => _editProgram(program),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteProgram(program),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        color = Colors.green;
        break;
      case 'intermediate':
        color = Colors.orange;
        break;
      case 'advanced':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
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

  Widget _buildGoalBadge(String goal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag,
            size: 12,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            goal,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
