import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise_set.dart';

/// Widget for inputting a single set's data (weight, reps)
class SetInputCard extends StatefulWidget {
  final int setNumber;
  final int targetReps;
  final ExerciseSet? previousSet; // Previous set for reference
  final double? suggestedWeight; // Suggested weight based on progression
  final Function(double weight, int reps, String? notes) onSetCompleted;
  final VoidCallback? onDelete;
  final bool isWarmup;

  const SetInputCard({
    super.key,
    required this.setNumber,
    required this.targetReps,
    this.previousSet,
    this.suggestedWeight,
    required this.onSetCompleted,
    this.onDelete,
    this.isWarmup = false,
  });

  @override
  State<SetInputCard> createState() => _SetInputCardState();
}

class _SetInputCardState extends State<SetInputCard> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill weight from previous set or suggestion
    if (widget.previousSet != null) {
      _weightController.text = widget.previousSet!.weight.toString();
    } else if (widget.suggestedWeight != null) {
      _weightController.text = widget.suggestedWeight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _completeSet() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    if (reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid reps')),
      );
      return;
    }

    setState(() => _isCompleted = true);

    widget.onSetCompleted(
      weight,
      reps,
      _notesController.text.isEmpty ? null : _notesController.text,
    );
  }

  void _editSet() {
    setState(() => _isCompleted = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: _isCompleted ? 1 : 2,
      color: _isCompleted
          ? Colors.green.shade50
          : widget.isWarmup
              ? Colors.orange.shade50
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      widget.isWarmup ? 'Warmup Set' : 'Set ${widget.setNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Target: ${widget.targetReps} reps',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isCompleted)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: _editSet,
                    tooltip: 'Edit',
                  )
                else if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete',
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (!_isCompleted) ...[
              // Input fields
              Row(
                children: [
                  // Weight input
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        hintText: widget.suggestedWeight?.toStringAsFixed(1),
                        suffixText: 'kg',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reps input
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Previous set reference
              if (widget.previousSet != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last time: ${widget.previousSet!.weight}kg × ${widget.previousSet!.reps} reps',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Complete button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completeSet,
                  icon: const Icon(Icons.check),
                  label: const Text('Complete Set'),
                ),
              ),
            ] else ...[
              // Completed view
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fitness_center, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_weightController.text} kg × ${_repsController.text} reps',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Volume: ${(double.parse(_weightController.text) * int.parse(_repsController.text)).toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (int.parse(_repsController.text) >= widget.targetReps)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Target achieved!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
