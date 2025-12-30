import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/exercise_performance.dart';
import '../models/workout_session.dart';
import '../services/workout_session_service.dart';
import '../services/rest_timer_service.dart';
import '../widgets/set_input_card.dart';
import '../widgets/previous_performance_card.dart';
import '../widgets/rest_timer_widget.dart';

/// Screen for logging workout performance (sets, reps, weight)
class ExerciseLoggingScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final String? programId;
  final int? weekNumber;
  final int? dayNumber;
  final String? workoutName;

  const ExerciseLoggingScreen({
    super.key,
    required this.exercises,
    this.programId,
    this.weekNumber,
    this.dayNumber,
    this.workoutName,
  });

  @override
  State<ExerciseLoggingScreen> createState() => _ExerciseLoggingScreenState();
}

class _ExerciseLoggingScreenState extends State<ExerciseLoggingScreen> {
  final WorkoutSessionService _sessionService = WorkoutSessionService();
  final RestTimerService _timerService = RestTimerService();

  late DateTime _startTime;
  int _currentExerciseIndex = 0;

  // Map of exercise name to list of sets
  final Map<String, List<ExerciseSet>> _exerciseSets = {};

  // Map of exercise name to previous performance
  final Map<String, ExercisePerformance?> _previousPerformances = {};

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadPreviousPerformances();
  }

  Future<void> _loadPreviousPerformances() async {
    setState(() => _isLoading = true);

    for (final exercise in widget.exercises) {
      final lastSession =
          _sessionService.getMostRecentWorkoutWithExercise(exercise.name);

      if (lastSession != null) {
        final performance = lastSession.exercises
            .firstWhere((ex) => ex.exerciseName == exercise.name);
        _previousPerformances[exercise.name] = performance;
      }

      _exerciseSets[exercise.name] = [];
    }

    setState(() => _isLoading = false);
  }

  void _completeSet(String exerciseName, double weight, int reps, String? notes) async {
    final exercise = widget.exercises
        .firstWhere((ex) => ex.name == exerciseName);

    final set = ExerciseSet(
      id: const Uuid().v4(),
      weight: weight,
      reps: reps,
      targetReps: exercise.minReps,
      restSeconds: exercise.restSeconds,
      notes: notes,
    );

    setState(() {
      _exerciseSets[exerciseName]!.add(set);
    });

    // Start rest timer if auto-start is enabled
    final autoStart = await _timerService.isAutoStartEnabled();
    if (autoStart) {
      final restDuration = set.restSeconds > 0
          ? set.restSeconds
          : await _timerService.getDefaultRestTime();
      await _timerService.startTimer(restDuration);
    }
  }

  void _removeSet(String exerciseName, int index) {
    setState(() {
      _exerciseSets[exerciseName]!.removeAt(index);
    });
  }

  void _nextExercise() {
    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() => _currentExerciseIndex++);
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() => _currentExerciseIndex--);
    }
  }

  Future<void> _finishWorkout() async {
    // Check if at least one exercise has sets
    final hasAnySets = _exerciseSets.values.any((sets) => sets.isNotEmpty);

    if (!hasAnySets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log at least one set before finishing'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Build exercise performances
      final exercisePerformances = <ExercisePerformance>[];

      for (final entry in _exerciseSets.entries) {
        if (entry.value.isEmpty) continue;

        final exercise = widget.exercises
            .firstWhere((ex) => ex.name == entry.key);

        final performance = ExercisePerformance(
          id: const Uuid().v4(),
          exerciseName: exercise.name,
          exerciseId: exercise.id,
          sets: entry.value,
          startTime: _startTime,
          endTime: DateTime.now(),
        );

        exercisePerformances.add(performance);
      }

      // Create workout session
      final session = WorkoutSession(
        id: const Uuid().v4(),
        programId: widget.programId,
        workoutName: widget.workoutName,
        weekNumber: widget.weekNumber,
        dayNumber: widget.dayNumber,
        exercises: exercisePerformances,
        startTime: _startTime,
        endTime: DateTime.now(),
        completed: true,
      );

      // Save to storage
      await _sessionService.saveWorkoutSession(session);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Workout saved! ${session.totalVolume.toStringAsFixed(0)} kg total volume',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Pop back with success
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Log Workout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentExercise = widget.exercises[_currentExerciseIndex];
    final currentSets = _exerciseSets[currentExercise.name] ?? [];
    final previousPerformance = _previousPerformances[currentExercise.name];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutName ?? 'Log Workout'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _finishWorkout,
              tooltip: 'Finish Workout',
            ),
        ],
      ),
      body: Column(
        children: [
          // Exercise progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentExercise.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exercise ${_currentExerciseIndex + 1} of ${widget.exercises.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${currentSets.length} sets',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Rest timer widget
          RestTimerWidget(
            onTimerComplete: () {
              // Optional: Add haptic feedback or sound
            },
          ),

          // Previous performance card
          if (previousPerformance != null)
            PreviousPerformanceCard(
              performance: previousPerformance,
              workoutDate: _sessionService
                      .getMostRecentWorkoutWithExercise(currentExercise.name)
                      ?.startTime ??
                  DateTime.now(),
            ),

          // Sets list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                ...currentSets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final set = entry.value;

                  // For display only - show completed sets
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        '${set.weight} kg × ${set.reps} reps',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Volume: ${set.volume.toStringAsFixed(1)} kg',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeSet(currentExercise.name, index),
                      ),
                    ),
                  );
                }),

                // Add set card
                SetInputCard(
                  setNumber: currentSets.length + 1,
                  targetReps: currentExercise.minReps,
                  previousSet: currentSets.isNotEmpty
                      ? currentSets.last
                      : previousPerformance?.sets.last,
                  onSetCompleted: (weight, reps, notes) {
                    _completeSet(currentExercise.name, weight, reps, notes);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentExerciseIndex > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousExercise,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
              ),
            if (_currentExerciseIndex > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _currentExerciseIndex < widget.exercises.length - 1
                    ? _nextExercise
                    : _finishWorkout,
                icon: Icon(_currentExerciseIndex < widget.exercises.length - 1
                    ? Icons.arrow_forward
                    : Icons.check),
                label: Text(_currentExerciseIndex < widget.exercises.length - 1
                    ? 'Next Exercise'
                    : 'Finish Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
