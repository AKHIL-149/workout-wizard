import 'package:flutter/material.dart';
import '../models/workout_program.dart';
import '../models/workout_template.dart';
import '../services/custom_program_service.dart';

/// Screen for creating and editing custom workout programs
class ProgramEditorScreen extends StatefulWidget {
  final WorkoutProgram program;
  final bool isNew;

  const ProgramEditorScreen({
    super.key,
    required this.program,
    this.isNew = false,
  });

  @override
  State<ProgramEditorScreen> createState() => _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends State<ProgramEditorScreen> {
  final CustomProgramService _customService = CustomProgramService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  late String _difficulty;
  late int _durationWeeks;
  late int _daysPerWeek;
  late List<String> _goals;
  late List<String> _tags;
  late List<ProgramWeek> _weeks;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program.name);
    _descriptionController =
        TextEditingController(text: widget.program.description);
    _notesController = TextEditingController(text: widget.program.notes ?? '');

    _difficulty = widget.program.difficulty;
    _durationWeeks = widget.program.durationWeeks;
    _daysPerWeek = widget.program.daysPerWeek;
    _goals = List.from(widget.program.goals);
    _tags = List.from(widget.program.tags);
    _weeks = List.from(widget.program.weeks);

    _nameController.addListener(() => setState(() => _hasChanges = true));
    _descriptionController
        .addListener(() => setState(() => _hasChanges = true));
    _notesController.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content:
            const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final updatedProgram = widget.program.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        difficulty: _difficulty,
        durationWeeks: _durationWeeks,
        daysPerWeek: _daysPerWeek,
        goals: _goals,
        tags: _tags,
        weeks: _weeks,
      );

      if (widget.isNew) {
        await _customService.createProgram(updatedProgram);
      } else {
        await _customService.updateProgram(updatedProgram);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isNew ? 'Program created!' : 'Program updated!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving program: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateWeeksStructure() {
    // Update weeks to match new duration
    if (_weeks.length < _durationWeeks) {
      // Add weeks
      while (_weeks.length < _durationWeeks) {
        _weeks.add(ProgramWeek(
          weekNumber: _weeks.length + 1,
          days: _generateDaysForWeek(),
        ));
      }
    } else if (_weeks.length > _durationWeeks) {
      // Remove weeks
      _weeks = _weeks.sublist(0, _durationWeeks);
    }

    // Update days per week for all weeks
    for (var i = 0; i < _weeks.length; i++) {
      final week = _weeks[i];
      if (week.days.length != _daysPerWeek) {
        _weeks[i] = ProgramWeek(
          weekNumber: week.weekNumber,
          weekName: week.weekName,
          notes: week.notes,
          days: _generateDaysForWeek(existingDays: week.days),
        );
      }
    }
  }

  List<ProgramDay> _generateDaysForWeek({List<ProgramDay>? existingDays}) {
    final days = <ProgramDay>[];

    for (var i = 0; i < _daysPerWeek; i++) {
      if (existingDays != null && i < existingDays.length) {
        days.add(existingDays[i]);
      } else {
        days.add(ProgramDay(
          dayNumber: i + 1,
          dayName: 'Day ${i + 1}',
          exercises: [],
          isRestDay: false,
        ));
      }
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isNew ? 'Create Program' : 'Edit Program'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProgram,
              tooltip: 'Save',
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildStructureSection(),
              const SizedBox(height: 24),
              _buildGoalsSection(),
              const SizedBox(height: 24),
              _buildWeeksSection(),
              const SizedBox(height: 24),
              _buildSaveButton(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Basic Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Program Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a program name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.signal_cellular_alt),
              ),
              items: ['Beginner', 'Intermediate', 'Advanced'].map((level) {
                return DropdownMenuItem(value: level, child: Text(level));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _difficulty = value;
                    _hasChanges = true;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Program Structure',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration: $_durationWeeks weeks',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: _durationWeeks.toDouble(),
                        min: 1,
                        max: 24,
                        divisions: 23,
                        label: '$_durationWeeks weeks',
                        onChanged: (value) {
                          setState(() {
                            _durationWeeks = value.round();
                            _updateWeeksStructure();
                            _hasChanges = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Training Days: $_daysPerWeek days/week',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: _daysPerWeek.toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        label: '$_daysPerWeek days',
                        onChanged: (value) {
                          setState(() {
                            _daysPerWeek = value.round();
                            _updateWeeksStructure();
                            _hasChanges = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection() {
    final availableGoals = [
      'Strength',
      'Hypertrophy',
      'Powerlifting',
      'Fat Loss',
      'Endurance',
      'Athletic Performance',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Goals & Tags',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Training Goals:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableGoals.map((goal) {
                final isSelected = _goals.contains(goal);
                return FilterChip(
                  label: Text(goal),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _goals.add(goal);
                      } else {
                        _goals.remove(goal);
                      }
                      _hasChanges = true;
                    });
                  },
                  selectedColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.view_week, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Week Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Configure individual weeks and days in the detailed editor',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to detailed week/day editor
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Detailed week editor coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Edit Weeks & Days'),
            ),
            const SizedBox(height: 16),
            ...List.generate(_weeks.length, (index) {
              final week = _weeks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              week.weekName ?? 'Week ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${week.days.length} days',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
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

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveProgram,
      icon: const Icon(Icons.save),
      label: Text(widget.isNew ? 'Create Program' : 'Save Changes'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
