import 'package:flutter/material.dart';
import '../models/workout_day.dart';
import '../models/exercise.dart';
import '../models/recommendation.dart';

/// Screen displaying detailed exercise list for a specific workout day
class WorkoutDayDetailsScreen extends StatefulWidget {
  final WorkoutDay workoutDay;
  final Recommendation program;

  const WorkoutDayDetailsScreen({
    super.key,
    required this.workoutDay,
    required this.program,
  });

  @override
  State<WorkoutDayDetailsScreen> createState() =>
      _WorkoutDayDetailsScreenState();
}

class _WorkoutDayDetailsScreenState extends State<WorkoutDayDetailsScreen> {
  final Set<String> _expandedExerciseIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('D${widget.workoutDay.dayNumber} - ${widget.workoutDay.dayName}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            _buildSummaryCard(),

            const SizedBox(height: 24),

            // Phase Indicator
            _buildPhaseIndicator(),

            const SizedBox(height: 24),

            // Compound Movements Section
            if (widget.workoutDay.compoundExercises.isNotEmpty) ...[
              _buildSectionHeader('💪 Compound Movements',
                  widget.workoutDay.compoundCount),
              const SizedBox(height: 12),
              ...widget.workoutDay.compoundExercises
                  .asMap()
                  .entries
                  .map((entry) => _buildExerciseCard(entry.value, entry.key + 1)),
              const SizedBox(height: 24),
            ],

            // Isolation Movements Section
            if (widget.workoutDay.isolationExercises.isNotEmpty) ...[
              _buildSectionHeader('🎯 Isolation Movements',
                  widget.workoutDay.isolationCount),
              const SizedBox(height: 12),
              ...widget.workoutDay.isolationExercises.asMap().entries.map(
                  (entry) => _buildExerciseCard(
                      entry.value,
                      entry.key + 1 + widget.workoutDay.compoundCount)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'D${widget.workoutDay.dayNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workoutDay.dayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Week ${widget.workoutDay.weekNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(Icons.access_time, '${widget.workoutDay.duration} min',
                    'Duration'),
                _buildStat(Icons.fitness_center,
                    '${widget.workoutDay.totalExercises}', 'Exercises'),
                _buildStat(
                    Icons.bolt, '${widget.workoutDay.compoundCount}', 'Compound'),
                _buildStat(Icons.track_changes,
                    '${widget.workoutDay.isolationCount}', 'Isolation'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseIndicator() {
    Color phaseColor;
    IconData phaseIcon;

    switch (widget.workoutDay.phase) {
      case 'Foundation':
        phaseColor = Colors.blue;
        phaseIcon = Icons.foundation;
        break;
      case 'Growth':
        phaseColor = Colors.green;
        phaseIcon = Icons.trending_up;
        break;
      case 'Peak':
        phaseColor = Colors.orange;
        phaseIcon = Icons.emoji_events;
        break;
      default:
        phaseColor = Colors.grey;
        phaseIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: phaseColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: phaseColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(phaseIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.workoutDay.phase} Phase',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: phaseColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.workoutDay.phaseDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    final isExpanded = _expandedExerciseIds.contains(exercise.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedExerciseIds.remove(exercise.id);
            } else {
              _expandedExerciseIds.add(exercise.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Number
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Exercise Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildChip(
                              Icons.my_location,
                              exercise.primaryMuscle,
                              Colors.blue,
                            ),
                            _buildChip(
                              exercise.movementType == 'Compound'
                                  ? Icons.bolt
                                  : Icons.track_changes,
                              exercise.movementType,
                              exercise.movementType == 'Compound'
                                  ? Colors.orange
                                  : Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Volume Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sets × Reps',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exercise.setsRepsFormatted,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Rest',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exercise.restFormatted,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded Details
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _buildExpandedDetails(exercise),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(Exercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Equipment
        Row(
          children: [
            Icon(Icons.fitness_center,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Equipment: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              exercise.equipment,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Difficulty
        Row(
          children: [
            Icon(Icons.signal_cellular_alt,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Difficulty: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              exercise.difficulty,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),

        // Description (if available)
        if (exercise.description != null) ...[
          const SizedBox(height: 12),
          Text(
            'Description:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exercise.description!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],

        // Technique (if available)
        if (exercise.technique != null) ...[
          const SizedBox(height: 12),
          Text(
            'Form Tips:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exercise.technique!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
