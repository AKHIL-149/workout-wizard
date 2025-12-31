import 'package:flutter/material.dart';
import '../models/exercise_database_item.dart';
import '../services/exercise_database_service.dart';
import 'exercise_detail_screen.dart';

/// Screen for browsing the exercise database
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final ExerciseDatabaseService _databaseService = ExerciseDatabaseService();

  List<ExerciseDatabaseItem> _exercises = [];
  List<ExerciseDatabaseItem> _filteredExercises = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedEquipment;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    setState(() {
      _exercises = _databaseService.getAllExercises();
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = _exercises;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = _databaseService.searchExercises(_searchQuery);
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    // Apply equipment filter
    if (_selectedEquipment != null) {
      filtered =
          filtered.where((e) => e.equipment == _selectedEquipment).toList();
    }

    // Apply difficulty filter
    if (_selectedDifficulty != null) {
      filtered =
          filtered.where((e) => e.difficulty == _selectedDifficulty).toList();
    }

    setState(() => _filteredExercises = filtered);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedEquipment = null;
      _selectedDifficulty = null;
      _applyFilters();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedCategory: _selectedCategory,
        selectedEquipment: _selectedEquipment,
        selectedDifficulty: _selectedDifficulty,
        onApply: (category, equipment, difficulty) {
          setState(() {
            _selectedCategory = category;
            _selectedEquipment = equipment;
            _selectedDifficulty = difficulty;
            _applyFilters();
          });
        },
      ),
    );
  }

  void _navigateToExerciseDetail(ExerciseDatabaseItem exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedCategory != null ||
        _selectedEquipment != null ||
        _selectedDifficulty != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: hasActiveFilters ? Theme.of(context).colorScheme.secondary : null,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          if (hasActiveFilters || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (hasActiveFilters) _buildActiveFiltersChips(),
          _buildResultsCount(),
          Expanded(
            child: _filteredExercises.isEmpty
                ? _buildEmptyState()
                : _buildExerciseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search exercises, muscles, equipment...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _onSearchChanged(''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedCategory != null)
            _buildFilterChip('Category: $_selectedCategory', () {
              setState(() {
                _selectedCategory = null;
                _applyFilters();
              });
            }),
          if (_selectedEquipment != null)
            _buildFilterChip('Equipment: $_selectedEquipment', () {
              setState(() {
                _selectedEquipment = null;
                _applyFilters();
              });
            }),
          if (_selectedDifficulty != null)
            _buildFilterChip('Difficulty: $_selectedDifficulty', () {
              setState(() {
                _selectedDifficulty = null;
                _applyFilters();
              });
            }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontSize: 12,
      ),
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${_filteredExercises.length} exercise${_filteredExercises.length != 1 ? 's' : ''} found',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No exercises found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = _filteredExercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(ExerciseDatabaseItem exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToExerciseDetail(exercise),
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
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildDifficultyBadge(exercise.difficulty),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exercise.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.category, exercise.category),
                  _buildInfoChip(Icons.fitness_center, exercise.equipment),
                  _buildInfoChip(
                    Icons.accessibility_new,
                    exercise.primaryMuscles.join(', '),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
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
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedEquipment;
  final String? selectedDifficulty;
  final Function(String?, String?, String?) onApply;

  const _FilterDialog({
    required this.selectedCategory,
    required this.selectedEquipment,
    required this.selectedDifficulty,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  final ExerciseDatabaseService _databaseService = ExerciseDatabaseService();

  late String? _category;
  late String? _equipment;
  late String? _difficulty;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _equipment = widget.selectedEquipment;
    _difficulty = widget.selectedDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Exercises'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _category,
              decoration: const InputDecoration(
                hintText: 'All Categories',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ..._databaseService.getAllCategories().map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'Equipment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _equipment,
              decoration: const InputDecoration(
                hintText: 'All Equipment',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ..._databaseService.getAllEquipment().map((eq) {
                  return DropdownMenuItem(value: eq, child: Text(eq));
                }),
              ],
              onChanged: (value) => setState(() => _equipment = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'Difficulty',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _difficulty,
              decoration: const InputDecoration(
                hintText: 'All Levels',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ..._databaseService.getDifficultyLevels().map((diff) {
                  return DropdownMenuItem(value: diff, child: Text(diff));
                }),
              ],
              onChanged: (value) => setState(() => _difficulty = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _category = null;
              _equipment = null;
              _difficulty = null;
            });
          },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_category, _equipment, _difficulty);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
