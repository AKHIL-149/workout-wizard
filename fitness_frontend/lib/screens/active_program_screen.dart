import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_program.dart';
import '../services/program_library_service.dart';
import '../services/program_enrollment_service.dart';
import '../services/deload_service.dart';
import '../models/deload_settings.dart';

/// Screen showing active program progress
class ActiveProgramScreen extends StatefulWidget {
  const ActiveProgramScreen({super.key});

  @override
  State<ActiveProgramScreen> createState() => _ActiveProgramScreenState();
}

class _ActiveProgramScreenState extends State<ActiveProgramScreen> {
  final ProgramEnrollmentService _enrollmentService =
      ProgramEnrollmentService();
  final ProgramLibraryService _libraryService = ProgramLibraryService();
  final DeloadService _deloadService = DeloadService();

  ProgramEnrollment? _enrollment;
  WorkoutProgram? _program;
  DeloadSettings? _deloadSettings;
  DeloadRecommendation? _deloadRecommendation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveProgram();
  }

  Future<void> _loadActiveProgram() async {
    setState(() => _isLoading = true);

    try {
      final enrollment = _enrollmentService.getActiveEnrollment();

      if (enrollment != null) {
        final program = _libraryService.getProgramById(enrollment.programId);
        final deloadSettings = await _deloadService.getSettings();
        final deloadRec = _deloadService.getDeloadRecommendation(
          enrollment,
          deloadSettings,
        );

        setState(() {
          _enrollment = enrollment;
          _program = program;
          _deloadSettings = deloadSettings;
          _deloadRecommendation = deloadRec;
          _isLoading = false;
        });
      } else {
        setState(() {
          _enrollment = null;
          _program = null;
          _deloadSettings = null;
          _deloadRecommendation = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading program: $e')),
      );
    }
  }

  Future<void> _completeWorkout(int week, int day) async {
    if (_enrollment == null || _program == null) return;

    try {
      await _enrollmentService.completeWorkout(_enrollment!.id, week, day);
      await _enrollmentService.advanceToNextWorkout(
        _enrollment!.id,
        _program!.durationWeeks,
        _program!.daysPerWeek,
      );

      _loadActiveProgram();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout completed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _quitProgram() async {
    if (_enrollment == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Program?'),
        content: const Text(
          'Are you sure you want to quit this program? Your progress will be saved but the program will no longer be active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quit Program'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _enrollmentService.quitProgram(_enrollment!.id);
      _loadActiveProgram();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program ended'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Program'),
        actions: [
          if (_enrollment != null && _program != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _quitProgram,
              tooltip: 'Quit Program',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollment == null || _program == null
              ? _buildNoProgramState()
              : _buildProgramProgress(),
    );
  }

  Widget _buildNoProgramState() {
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
            'No Active Program',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Browse training programs to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search),
            label: const Text('Browse Programs'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramProgress() {
    final currentWeek = _program!.weeks[_enrollment!.currentWeek - 1];
    final completion = _enrollmentService.getCompletionPercentage(
      _enrollment!,
      _program!.durationWeeks,
    );

    return RefreshIndicator(
      onRefresh: _loadActiveProgram,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProgressCard(completion),
          const SizedBox(height: 16),
          if (_deloadRecommendation != null) ...[
            _buildDeloadRecommendationCard(_deloadRecommendation!),
            const SizedBox(height: 16),
          ],
          _buildCurrentWeekCard(currentWeek),
          const SizedBox(height: 16),
          _buildWeekList(),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double completion) {
    final daysSinceStart = DateTime.now().difference(_enrollment!.startDate).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _program!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Week ${_enrollment!.currentWeek}/${_program!.durationWeeks}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
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
                        'Started',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, y').format(_enrollment!.startDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Days Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '$daysSinceStart days',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${completion.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: completion / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
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

  Widget _buildCurrentWeekCard(ProgramWeek week) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (week.weekName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  week.weekName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...week.days.asMap().entries.map((entry) {
              final dayIndex = entry.key + 1;
              final day = entry.value;
              final isCurrentDay = dayIndex == _enrollment!.currentDay;
              final isCompleted = _enrollment!.isWorkoutCompleted(
                _enrollment!.currentWeek,
                dayIndex,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: day.isRestDay || isCompleted
                      ? null
                      : () => _completeWorkout(_enrollment!.currentWeek, dayIndex),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentDay
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrentDay
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green
                                : day.isRestDay
                                    ? Colors.grey.shade300
                                    : Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, color: Colors.white)
                                : day.isRestDay
                                    ? const Icon(Icons.bed, size: 20)
                                    : Icon(
                                        Icons.fitness_center,
                                        size: 20,
                                        color: Theme.of(context).primaryColor,
                                      ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    day.dayName,
                                    style: TextStyle(
                                      fontWeight: isCurrentDay
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  if (isCurrentDay) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'TODAY',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (!day.isRestDay)
                                Text(
                                  '${day.exercises.length} exercises',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!day.isRestDay && !isCompleted)
                          Icon(
                            Icons.play_circle_outline,
                            color: isCurrentDay
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade400,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDeloadRecommendationCard(DeloadRecommendation recommendation) {
    Color intensityColor;
    IconData intensityIcon;

    switch (recommendation.recommendedIntensity) {
      case DeloadIntensity.light:
        intensityColor = Colors.blue;
        intensityIcon = Icons.water_drop;
        break;
      case DeloadIntensity.moderate:
        intensityColor = Colors.orange;
        intensityIcon = Icons.opacity;
        break;
      case DeloadIntensity.minimal:
        intensityColor = Colors.green;
        intensityIcon = Icons.wb_sunny_outlined;
        break;
    }

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Deload Recommended',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Reason',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recommendation.reason,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: intensityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: intensityColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(intensityIcon,
                                size: 16, color: intensityColor),
                            const SizedBox(width: 6),
                            Text(
                              'Recommended Intensity',
                              style: TextStyle(
                                fontSize: 12,
                                color: intensityColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recommendation.recommendedIntensity.name
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: intensityColor,
                          ),
                        ),
                        Text(
                          '${(recommendation.recommendedIntensity.volumeReduction * 100).toStringAsFixed(0)}% volume reduction',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (recommendation.recoveryScore > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Recovery',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.recoveryScore.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: recommendation.recoveryScore >= 3
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        Text(
                          '/5.0',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '💡 Tip: Reduce volume and intensity this week to promote recovery and prevent overtraining.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Weeks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._program!.weeks.asMap().entries.map((entry) {
              final weekIndex = entry.key + 1;
              final week = entry.value;
              final isCurrentWeek = weekIndex == _enrollment!.currentWeek;
              final isPastWeek = weekIndex < _enrollment!.currentWeek;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentWeek
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isPastWeek
                              ? Colors.green.withValues(alpha: 0.2)
                              : isCurrentWeek
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.2)
                                  : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$weekIndex',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPastWeek
                                  ? Colors.green
                                  : isCurrentWeek
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Week $weekIndex',
                              style: TextStyle(
                                fontWeight: isCurrentWeek
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                            if (week.weekName != null)
                              Text(
                                week.weekName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isPastWeek)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
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
}
