import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../services/active_program_service.dart';
import '../services/analytics_service.dart';
import '../widgets/formatted_exercise_guidance.dart';
import 'form_correction_screen.dart';

/// Screen for tracking workouts and viewing exercise guidance
class WorkoutTrackingScreen extends StatefulWidget {
  final Recommendation program;

  const WorkoutTrackingScreen({
    super.key,
    required this.program,
  });

  @override
  State<WorkoutTrackingScreen> createState() => _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends State<WorkoutTrackingScreen> {
  final ActiveProgramService _activeProgramService = ActiveProgramService();
  final AnalyticsService _analyticsService = AnalyticsService();

  int _currentWeek = 1;
  int _currentDay = 1;
  List<String> _completedWorkouts = [];
  DateTime? _startDate;
  int _daysSinceStart = 0;

  @override
  void initState() {
    super.initState();
    _loadProgramData();
  }

  Future<void> _loadProgramData() async {
    final startDate = await _activeProgramService.getProgramStartDate();
    final currentWeek = await _activeProgramService.getCurrentWeek();
    final currentDay = await _activeProgramService.getCurrentDay();
    final completed = await _activeProgramService.getCompletedWorkouts();
    final days = await _activeProgramService.getDaysSinceStart();

    setState(() {
      _startDate = startDate;
      _currentWeek = currentWeek;
      _currentDay = currentDay;
      _completedWorkouts = completed;
      _daysSinceStart = days;
    });
  }

  Future<void> _completeWorkout() async {
    final workoutId = 'week_${_currentWeek}_day_$_currentDay';

    await _activeProgramService.completeWorkout(workoutId);
    await _analyticsService.trackEvent(
      AnalyticsEvent.workoutCompleted,
      metadata: {
        'program_id': widget.program.programId,
        'week': _currentWeek,
        'day': _currentDay,
      },
    );

    // Move to next workout
    if (_currentDay < widget.program.workoutFrequency) {
      await _activeProgramService.setCurrentDay(_currentDay + 1);
    } else if (_currentWeek < widget.program.programLength) {
      await _activeProgramService.setCurrentWeek(_currentWeek + 1);
      await _activeProgramService.setCurrentDay(1);
    }

    await _loadProgramData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Workout completed! Great job! 💪'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completedWorkouts.length /
        (widget.program.programLength * widget.program.workoutFrequency);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.title),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showProgramInfo();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Card
            _buildProgressCard(progress),

            const SizedBox(height: 24),

            // Current Workout Info
            _buildCurrentWorkoutCard(),

            const SizedBox(height: 24),

            // Exercise Guidance Section
            _buildExerciseGuidanceSection(),

            const SizedBox(height: 24),

            // Complete Workout Button
            _buildCompleteWorkoutButton(),

            const SizedBox(height: 16),

            // Week Navigator
            _buildWeekNavigator(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(double progress) {
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
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Program Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.calendar_today,
                    'Week $_currentWeek/${widget.program.programLength}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.fitness_center,
                    'Day $_currentDay/${widget.program.workoutFrequency}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.check_circle,
                    '${_completedWorkouts.length} done',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWorkoutCard() {
    final workoutId = 'week_${_currentWeek}_day_$_currentDay';
    final isCompleted = _completedWorkouts.contains(workoutId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.fitness_center,
                    color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week $_currentWeek - Day $_currentDay',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted ? 'Completed ✓' : '${widget.program.timePerWorkout} min workout',
                        style: TextStyle(
                          fontSize: 14,
                          color: isCompleted ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.access_time, '${widget.program.timePerWorkout} min'),
                _buildInfoChip(Icons.signal_cellular_alt, widget.program.primaryLevel),
                _buildInfoChip(Icons.flag, widget.program.primaryGoal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseGuidanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Exercise Guidance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Form Check button
            ElevatedButton.icon(
              onPressed: _startFormCorrection,
              icon: const Icon(Icons.videocam, size: 18),
              label: const Text('Form Check'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormattedExerciseGuidance(markdownText: widget.program.exerciseGuidance),
      ],
    );
  }

  Widget _buildCompleteWorkoutButton() {
    final workoutId = 'week_${_currentWeek}_day_$_currentDay';
    final isCompleted = _completedWorkouts.contains(workoutId);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isCompleted ? null : _completeWorkout,
        icon: Icon(isCompleted ? Icons.check_circle : Icons.check),
        label: Text(
          isCompleted ? 'Workout Completed' : 'Mark as Complete',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildWeekNavigator() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Week Navigator',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _currentWeek > 1
                      ? () async {
                          await _activeProgramService.setCurrentWeek(_currentWeek - 1);
                          await _loadProgramData();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Week $_currentWeek of ${widget.program.programLength}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _currentWeek < widget.program.programLength
                      ? () async {
                          await _activeProgramService.setCurrentWeek(_currentWeek + 1);
                          await _loadProgramData();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _currentDay > 1
                      ? () async {
                          await _activeProgramService.setCurrentDay(_currentDay - 1);
                          await _loadProgramData();
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 20,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Day $_currentDay of ${widget.program.workoutFrequency}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _currentDay < widget.program.workoutFrequency
                      ? () async {
                          await _activeProgramService.setCurrentDay(_currentDay + 1);
                          await _loadProgramData();
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProgramInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Program Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Title', widget.program.title),
              _buildInfoRow('Duration', '${widget.program.programLength} weeks'),
              _buildInfoRow('Frequency', '${widget.program.workoutFrequency}x per week'),
              _buildInfoRow('Time/Workout', '${widget.program.timePerWorkout} min'),
              _buildInfoRow('Level', widget.program.level.join(', ')),
              _buildInfoRow('Goals', widget.program.goal.join(', ')),
              _buildInfoRow('Equipment', widget.program.equipment),
              _buildInfoRow('Total Exercises', '${widget.program.totalExercises}'),
              if (_startDate != null)
                _buildInfoRow('Started', _formatDate(_startDate!)),
              _buildInfoRow('Days Active', '$_daysSinceStart days'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _startFormCorrection() {
    // Extract exercise name from program (use program name or first exercise)
    String exerciseName = widget.program.title;

    // Navigate to form correction screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormCorrectionScreen(
          exerciseName: exerciseName,
          programId: widget.program.programId,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
