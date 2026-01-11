import 'package:flutter/material.dart';
import '../models/block_periodization.dart';
import '../services/block_periodization_service.dart';
import 'package:uuid/uuid.dart';

/// Screen for creating custom block periodization programs
class CreateBlockProgramScreen extends StatefulWidget {
  const CreateBlockProgramScreen({super.key});

  @override
  State<CreateBlockProgramScreen> createState() =>
      _CreateBlockProgramScreenState();
}

class _CreateBlockProgramScreenState extends State<CreateBlockProgramScreen> {
  final BlockPeriodizationService _periodizationService =
      BlockPeriodizationService();
  final Uuid _uuid = const Uuid();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<TrainingBlock> _blocks = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addBlock() async {
    final block = await showDialog<TrainingBlock>(
      context: context,
      builder: (context) => _BlockEditorDialog(blockNumber: _blocks.length + 1),
    );

    if (block != null) {
      setState(() {
        _blocks.add(block);
      });
    }
  }

  Future<void> _editBlock(int index) async {
    final block = await showDialog<TrainingBlock>(
      context: context,
      builder: (context) => _BlockEditorDialog(
        blockNumber: index + 1,
        existingBlock: _blocks[index],
      ),
    );

    if (block != null) {
      setState(() {
        _blocks[index] = block;
      });
    }
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
    });
  }

  void _moveBlockUp(int index) {
    if (index > 0) {
      setState(() {
        final block = _blocks.removeAt(index);
        _blocks.insert(index - 1, block);
      });
    }
  }

  void _moveBlockDown(int index) {
    if (index < _blocks.length - 1) {
      setState(() {
        final block = _blocks.removeAt(index);
        _blocks.insert(index + 1, block);
      });
    }
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    if (_blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one training block'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _periodizationService.createCustomProgram(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        blocks: _blocks,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
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
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Program'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _saveProgram,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Program name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Program Name',
                hintText: 'e.g., My Custom Periodization',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a program name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Program description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your program goals and structure',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Blocks section
            Row(
              children: [
                Text(
                  'Training Blocks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addBlock,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Block'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_blocks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.view_module_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No blocks added yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_blocks.length, (index) {
                return _buildBlockCard(index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockCard(int index) {
    final block = _blocks[index];
    final color = _getBlockColor(block.blockType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Block ${index + 1}',
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
                    block.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  onPressed: index > 0 ? () => _moveBlockUp(index) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 20),
                  onPressed: index < _blocks.length - 1
                      ? () => _moveBlockDown(index)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editBlock(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _removeBlock(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildInfoChip('${block.blockTypeDisplay}', color),
                _buildInfoChip('${block.durationWeeks}w', Colors.grey),
                _buildInfoChip('${block.repsMin}-${block.repsMax} reps', Colors.grey),
                _buildInfoChip(
                  '${(block.intensityMin * 100).toInt()}-${(block.intensityMax * 100).toInt()}%',
                  Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
}

/// Dialog for creating/editing a training block
class _BlockEditorDialog extends StatefulWidget {
  final int blockNumber;
  final TrainingBlock? existingBlock;

  const _BlockEditorDialog({
    required this.blockNumber,
    this.existingBlock,
  });

  @override
  State<_BlockEditorDialog> createState() => _BlockEditorDialogState();
}

class _BlockEditorDialogState extends State<_BlockEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  late final TextEditingController _nameController;
  late String _blockType;
  late int _durationWeeks;
  late int _sessionsPerWeek;
  late double _intensityMin;
  late double _intensityMax;
  late int _repsMin;
  late int _repsMax;
  late int _setsPerExercise;
  late int _restSeconds;
  late bool _includeDeload;

  @override
  void initState() {
    super.initState();
    final block = widget.existingBlock;

    _nameController = TextEditingController(
      text: block?.name ?? 'Block ${widget.blockNumber}',
    );
    _blockType = block?.blockType ?? 'hypertrophy';
    _durationWeeks = block?.durationWeeks ?? 4;
    _sessionsPerWeek = block?.sessionsPerWeek ?? 4;
    _intensityMin = block?.intensityMin ?? 0.60;
    _intensityMax = block?.intensityMax ?? 0.75;
    _repsMin = block?.repsMin ?? 8;
    _repsMax = block?.repsMax ?? 12;
    _setsPerExercise = block?.setsPerExercise ?? 4;
    _restSeconds = block?.restSeconds ?? 90;
    _includeDeload = block?.includeDeload ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyPreset(String blockType) {
    setState(() {
      _blockType = blockType;

      switch (blockType) {
        case 'hypertrophy':
          _intensityMin = 0.60;
          _intensityMax = 0.75;
          _repsMin = 8;
          _repsMax = 12;
          _setsPerExercise = 4;
          _restSeconds = 90;
          break;
        case 'strength':
          _intensityMin = 0.75;
          _intensityMax = 0.85;
          _repsMin = 4;
          _repsMax = 6;
          _setsPerExercise = 5;
          _restSeconds = 180;
          break;
        case 'power':
          _intensityMin = 0.85;
          _intensityMax = 0.95;
          _repsMin = 1;
          _repsMax = 3;
          _setsPerExercise = 5;
          _restSeconds = 240;
          break;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final block = TrainingBlock(
      id: widget.existingBlock?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      blockType: _blockType,
      durationWeeks: _durationWeeks,
      sessionsPerWeek: _sessionsPerWeek,
      intensityMin: _intensityMin,
      intensityMax: _intensityMax,
      repsMin: _repsMin,
      repsMax: _repsMax,
      setsPerExercise: _setsPerExercise,
      restSeconds: _restSeconds,
      includeDeload: _includeDeload,
    );

    Navigator.pop(context, block);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingBlock != null ? 'Edit Block' : 'Add Block'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Block name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Block Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Block type presets
              const Text('Block Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Hypertrophy'),
                    selected: _blockType == 'hypertrophy',
                    onSelected: (_) => _applyPreset('hypertrophy'),
                  ),
                  ChoiceChip(
                    label: const Text('Strength'),
                    selected: _blockType == 'strength',
                    onSelected: (_) => _applyPreset('strength'),
                  ),
                  ChoiceChip(
                    label: const Text('Power'),
                    selected: _blockType == 'power',
                    onSelected: (_) => _applyPreset('power'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Duration
              Text('Duration: $_durationWeeks weeks'),
              Slider(
                value: _durationWeeks.toDouble(),
                min: 2,
                max: 8,
                divisions: 6,
                label: '$_durationWeeks weeks',
                onChanged: (value) => setState(() => _durationWeeks = value.toInt()),
              ),
              const SizedBox(height: 8),

              // Sessions per week
              Text('Sessions: $_sessionsPerWeek per week'),
              Slider(
                value: _sessionsPerWeek.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                label: '$_sessionsPerWeek',
                onChanged: (value) => setState(() => _sessionsPerWeek = value.toInt()),
              ),
              const SizedBox(height: 8),

              // Intensity range
              Text(
                'Intensity: ${(_intensityMin * 100).toInt()}-${(_intensityMax * 100).toInt()}% 1RM',
              ),
              RangeSlider(
                values: RangeValues(_intensityMin, _intensityMax),
                min: 0.5,
                max: 1.0,
                divisions: 10,
                labels: RangeLabels(
                  '${(_intensityMin * 100).toInt()}%',
                  '${(_intensityMax * 100).toInt()}%',
                ),
                onChanged: (values) => setState(() {
                  _intensityMin = values.start;
                  _intensityMax = values.end;
                }),
              ),
              const SizedBox(height: 8),

              // Reps range
              Text('Reps: $_repsMin-$_repsMax'),
              RangeSlider(
                values: RangeValues(_repsMin.toDouble(), _repsMax.toDouble()),
                min: 1,
                max: 20,
                divisions: 19,
                labels: RangeLabels('$_repsMin', '$_repsMax'),
                onChanged: (values) => setState(() {
                  _repsMin = values.start.toInt();
                  _repsMax = values.end.toInt();
                }),
              ),
              const SizedBox(height: 8),

              // Sets
              Text('Sets: $_setsPerExercise per exercise'),
              Slider(
                value: _setsPerExercise.toDouble(),
                min: 2,
                max: 8,
                divisions: 6,
                label: '$_setsPerExercise',
                onChanged: (value) => setState(() => _setsPerExercise = value.toInt()),
              ),
              const SizedBox(height: 8),

              // Rest
              Text('Rest: $_restSeconds seconds'),
              Slider(
                value: _restSeconds.toDouble(),
                min: 30,
                max: 300,
                divisions: 27,
                label: '$_restSeconds s',
                onChanged: (value) => setState(() => _restSeconds = value.toInt()),
              ),
              const SizedBox(height: 8),

              // Include deload
              SwitchListTile(
                title: const Text('Include Deload Week'),
                value: _includeDeload,
                onChanged: (value) => setState(() => _includeDeload = value),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
