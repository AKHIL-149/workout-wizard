import 'package:flutter/material.dart';
import '../models/workout_program.dart';
import '../services/program_library_service.dart';
import 'program_detail_screen.dart';

/// Screen for browsing pre-built workout programs
class ProgramLibraryScreen extends StatefulWidget {
  const ProgramLibraryScreen({super.key});

  @override
  State<ProgramLibraryScreen> createState() => _ProgramLibraryScreenState();
}

class _ProgramLibraryScreenState extends State<ProgramLibraryScreen> {
  final ProgramLibraryService _libraryService = ProgramLibraryService();

  List<WorkoutProgram> _programs = [];
  List<WorkoutProgram> _filteredPrograms = [];
  String? _selectedDifficulty;
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  void _loadPrograms() {
    setState(() {
      _programs = _libraryService.getAllPrograms();
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = _programs;

    if (_selectedDifficulty != null) {
      filtered = filtered
          .where((p) => p.difficulty == _selectedDifficulty)
          .toList();
    }

    if (_selectedGoal != null) {
      filtered = filtered.where((p) => p.goals.contains(_selectedGoal)).toList();
    }

    setState(() => _filteredPrograms = filtered);
  }

  void _clearFilters() {
    setState(() {
      _selectedDifficulty = null;
      _selectedGoal = null;
      _applyFilters();
    });
  }

  void _navigateToProgramDetail(WorkoutProgram program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(program: program),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedDifficulty != null || _selectedGoal != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Programs'),
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _filteredPrograms.isEmpty
                ? _buildEmptyState()
                : _buildProgramList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Programs',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDifficultyChip('Beginner'),
                const SizedBox(width: 8),
                _buildDifficultyChip('Intermediate'),
                const SizedBox(width: 8),
                _buildDifficultyChip('Advanced'),
                const SizedBox(width: 16),
                _buildGoalChip('Strength'),
                const SizedBox(width: 8),
                _buildGoalChip('Hypertrophy'),
                const SizedBox(width: 8),
                _buildGoalChip('Powerlifting'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    final isSelected = _selectedDifficulty == difficulty;
    return ChoiceChip(
      label: Text(difficulty),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDifficulty = selected ? difficulty : null;
          _applyFilters();
        });
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildGoalChip(String goal) {
    final isSelected = _selectedGoal == goal;
    return ChoiceChip(
      label: Text(goal),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedGoal = selected ? goal : null;
          _applyFilters();
        });
      },
      selectedColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No programs found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPrograms.length,
      itemBuilder: (context, index) {
        final program = _filteredPrograms[index];
        return _buildProgramCard(program);
      },
    );
  }

  Widget _buildProgramCard(WorkoutProgram program) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToProgramDetail(program),
        borderRadius: BorderRadius.circular(12),
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.calendar_today,
                      '${program.durationWeeks} weeks'),
                  _buildInfoChip(
                      Icons.fitness_center, '${program.daysPerWeek} days/week'),
                  ...program.goals.map((goal) => _buildGoalBadge(goal)),
                ],
              ),
              if (program.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: program.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
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
