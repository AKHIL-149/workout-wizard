import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/linear_periodization_service.dart';

/// Screen for creating linear periodization programs
class CreateLinearProgramScreen extends StatefulWidget {
  final String templateType;

  const CreateLinearProgramScreen({
    super.key,
    required this.templateType,
  });

  @override
  State<CreateLinearProgramScreen> createState() =>
      _CreateLinearProgramScreenState();
}

class _CreateLinearProgramScreenState extends State<CreateLinearProgramScreen> {
  final LinearPeriodizationService _periodizationService =
      LinearPeriodizationService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Main lifts and their 1RM
  final Map<String, TextEditingController> _maxControllers = {
    'Squat': TextEditingController(),
    'Bench Press': TextEditingController(),
    'Deadlift': TextEditingController(),
    'Overhead Press': TextEditingController(),
  };

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _getDefaultName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _maxControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getDefaultName() {
    switch (widget.templateType) {
      case 'beginner':
        return 'Beginner Linear Progression';
      case 'intermediate':
        return 'Intermediate Linear Program';
      case 'strength':
        return 'Strength Peaking Program';
      default:
        return 'Linear Periodization Program';
    }
  }

  String _getDescription() {
    switch (widget.templateType) {
      case 'beginner':
        return '12-week progressive linear program for beginners';
      case 'intermediate':
        return '8-week linear program for intermediate lifters';
      case 'strength':
        return '6-week strength peaking program for competition prep';
      default:
        return 'Linear periodization program';
    }
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    // Collect baseline maxes
    final baselineMaxes = <String, double>{};
    for (var entry in _maxControllers.entries) {
      final value = double.tryParse(entry.value.text);
      if (value != null && value > 0) {
        baselineMaxes[entry.key] = value;
      }
    }

    if (baselineMaxes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one baseline max'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _periodizationService.createProgramFromTemplate(
        templateType: widget.templateType,
        name: _nameController.text.trim(),
        baselineMaxes: baselineMaxes,
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
        title: const Text('Create Program'),
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
            // Template info
            Card(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Template',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDefaultName(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDescription(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Program name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Program Name',
                hintText: 'e.g., My Linear Program',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a program name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Baseline maxes section
            Text(
              'Baseline 1-Rep Maxes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your current estimated or tested 1-rep max for each lift. The program will calculate working weights based on these values.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Maxes inputs
            ..._maxControllers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    hintText: 'e.g., 225',
                    suffixText: 'lbs',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Helper info card
            Card(
              color: Colors.blue.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Estimating Your 1RM',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If you don\'t know your 1RM, use this formula:\n\n'
                      '1RM ≈ Weight × (1 + Reps ÷ 30)\n\n'
                      'Example: If you can lift 200 lbs for 5 reps:\n'
                      '1RM ≈ 200 × (1 + 5 ÷ 30) = 233 lbs',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
