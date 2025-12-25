import 'package:flutter/foundation.dart';
import '../models/pose_data.dart';
import '../models/form_analysis.dart';
import '../services/form_analysis_service.dart';
import '../services/form_correction_storage_service.dart';
import '../services/analytics_service.dart';
import '../services/audio_feedback_service.dart';

/// Provider for managing form correction session state
class FormCorrectionProvider with ChangeNotifier {
  final FormAnalysisService _formAnalysisService;
  final FormCorrectionStorageService _storageService;
  final AnalyticsService _analyticsService;
  final AudioFeedbackService _audioService;
  final String _exerciseName;
  final String? _programId;

  // Session state
  PoseSnapshot? _currentPose;
  FormFeedback? _currentFeedback;
  bool _isDetecting = false;
  bool _showPositioningGuide = true;
  DateTime? _sessionStartTime;
  String? _sessionId;

  // Statistics
  int _totalSessions = 0;
  double _bestScore = 0.0;
  Map<String, int> _lifetimeViolations = {};

  FormCorrectionProvider({
    required FormAnalysisService formAnalysisService,
    required FormCorrectionStorageService storageService,
    required AnalyticsService analyticsService,
    required AudioFeedbackService audioService,
    required String exerciseName,
    String? programId,
  })  : _formAnalysisService = formAnalysisService,
        _storageService = storageService,
        _analyticsService = analyticsService,
        _audioService = audioService,
        _exerciseName = exerciseName,
        _programId = programId {
    _initialize();
  }

  // Getters
  PoseSnapshot? get currentPose => _currentPose;
  FormFeedback? get currentFeedback => _currentFeedback;
  bool get isDetecting => _isDetecting;
  bool get showPositioningGuide => _showPositioningGuide;
  int get repCount => _formAnalysisService.repCount;
  ExercisePhase get currentPhase => _formAnalysisService.currentPhase;
  List<RepAnalysis> get repHistory => _formAnalysisService.getRepHistory();
  Map<String, int> get violationFrequency =>
      _formAnalysisService.getViolationFrequency();
  double get averageFormScore => _formAnalysisService.getAverageFormScore();
  DateTime? get sessionStartTime => _sessionStartTime;
  int get totalSessions => _totalSessions;
  double get bestScore => _bestScore;
  Map<String, int> get lifetimeViolations => _lifetimeViolations;
  FormAnalysisService get formAnalysisService => _formAnalysisService;
  AudioFeedbackService get audioService => _audioService;

  Future<void> _initialize() async {
    // Load statistics
    final stats = await _storageService.getExerciseStatistics(_exerciseName);
    _totalSessions = stats['totalSessions'] ?? 0;
    _bestScore = stats['bestScore'] ?? 0.0;
    _lifetimeViolations = Map<String, int>.from(stats['violations'] ?? {});

    // Initialize audio service
    await _audioService.initialize();

    // Load audio settings
    final audioSettings = _storageService.getSetting<Map>(
      'audio_settings',
      defaultValue: {},
    );
    if (audioSettings != null && audioSettings.isNotEmpty) {
      final settings = AudioFeedbackSettings.fromJson(
        Map<String, dynamic>.from(audioSettings),
      );
      _audioService.setEnabled(settings.enabled);
      await _audioService.setVolume(settings.volume);
      await _audioService.setSpeechRate(settings.speechRate);
      await _audioService.setPitch(settings.pitch);
    }

    notifyListeners();
  }

  /// Start detection session
  void startSession() {
    _isDetecting = true;
    _sessionStartTime = DateTime.now();
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    // Track analytics
    _analyticsService.logEvent(
      AnalyticsEvent.formCorrectionStarted,
      parameters: {
        'exercise_name': _exerciseName,
        'program_id': _programId ?? 'none',
      },
    );

    notifyListeners();
  }

  /// Stop detection session
  void stopSession() {
    _isDetecting = false;
    _audioService.stop();
    notifyListeners();
  }

  /// Update current pose and analyze
  Future<void> updatePose(PoseSnapshot pose) async {
    _currentPose = pose;

    // Analyze form
    final feedback = await _formAnalysisService.analyzePose(pose);
    _currentFeedback = feedback;

    // Hide positioning guide once pose is detected with good confidence
    if (_showPositioningGuide && pose.overallConfidence > 0.7) {
      _showPositioningGuide = false;
      await _audioService.speak(
        'Position confirmed. Begin your exercise.',
        priority: AudioPriority.info,
      );
    }

    // Speak audio feedback for violations
    if (_isDetecting && !_showPositioningGuide) {
      await _audioService.speakFormFeedback(feedback);
    }

    // Track violations
    if (feedback.hasCriticalIssues) {
      _analyticsService.logEvent(
        AnalyticsEvent.formViolationDetected,
        parameters: {
          'exercise_name': _exerciseName,
          'violation_type': feedback.mostSevereViolation?.type ?? 'unknown',
          'severity': feedback.mostSevereViolation?.severity.toString() ?? 'unknown',
        },
      );
    }

    notifyListeners();
  }

  /// Handle rep completion
  void onRepCompleted(RepEvent event) {
    // Speak rep completion
    final isGoodRep = (_currentFeedback?.score.percentage ?? 0.0) >= 80;
    _audioService.speakRepCompletion(repCount, isGoodRep: isGoodRep);

    // Track analytics
    _analyticsService.logEvent(
      AnalyticsEvent.formScoreRecorded,
      parameters: {
        'exercise_name': _exerciseName,
        'rep_number': repCount,
        'form_score': _currentFeedback?.score.percentage ?? 0,
      },
    );

    notifyListeners();
  }

  /// Finish session and save data
  Future<void> finishSession() async {
    if (_sessionId == null || repCount == 0) {
      return;
    }

    stopSession();

    final duration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!)
        : const Duration(seconds: 0);

    // Create session data
    final session = FormCorrectionSession(
      sessionId: _sessionId!,
      exerciseName: _exerciseName,
      programId: _programId,
      startTime: _sessionStartTime!,
      duration: duration,
      totalReps: repCount,
      averageFormScore: averageFormScore,
      repHistory: repHistory,
      violationFrequency: violationFrequency,
    );

    // Save session
    await _storageService.saveSession(session);

    // Update statistics
    _totalSessions++;
    if (averageFormScore > _bestScore) {
      _bestScore = averageFormScore;

      // Track improvement
      _analyticsService.logEvent(
        AnalyticsEvent.exerciseFormImproved,
        parameters: {
          'exercise_name': _exerciseName,
          'previous_best': _bestScore,
          'new_best': averageFormScore,
        },
      );
    }

    // Merge lifetime violations
    violationFrequency.forEach((key, value) {
      _lifetimeViolations[key] = (_lifetimeViolations[key] ?? 0) + value;
    });

    await _storageService.saveExerciseStatistics(
      _exerciseName,
      {
        'totalSessions': _totalSessions,
        'bestScore': _bestScore,
        'violations': _lifetimeViolations,
      },
    );

    // Track analytics
    _analyticsService.logEvent(
      AnalyticsEvent.formCorrectionCompleted,
      parameters: {
        'exercise_name': _exerciseName,
        'total_reps': repCount,
        'average_score': averageFormScore,
        'duration_seconds': duration.inSeconds,
      },
    );

    notifyListeners();
  }

  /// Reset session (for retry)
  void resetSession() {
    _formAnalysisService.resetSession();
    _currentPose = null;
    _currentFeedback = null;
    _showPositioningGuide = true;
    _sessionStartTime = null;
    _sessionId = null;
    notifyListeners();
  }

  /// Get session history for this exercise
  Future<List<FormCorrectionSession>> getSessionHistory() async {
    return _storageService.getSessionsByExercise(_exerciseName);
  }

  /// Get progress over time (last N sessions)
  Future<List<double>> getProgressData({int lastN = 10}) async {
    final sessions = await getSessionHistory();
    final recentSessions = sessions.take(lastN).toList();
    return recentSessions.map((s) => s.averageFormScore).toList();
  }

  @override
  void dispose() {
    _formAnalysisService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}

/// Model for form correction session
class FormCorrectionSession {
  final String sessionId;
  final String exerciseName;
  final String? programId;
  final DateTime startTime;
  final Duration duration;
  final int totalReps;
  final double averageFormScore;
  final List<RepAnalysis> repHistory;
  final Map<String, int> violationFrequency;

  FormCorrectionSession({
    required this.sessionId,
    required this.exerciseName,
    this.programId,
    required this.startTime,
    required this.duration,
    required this.totalReps,
    required this.averageFormScore,
    required this.repHistory,
    required this.violationFrequency,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'exerciseName': exerciseName,
        'programId': programId,
        'startTime': startTime.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'totalReps': totalReps,
        'averageFormScore': averageFormScore,
        'repHistory': repHistory.map((r) => r.toJson()).toList(),
        'violationFrequency': violationFrequency,
      };

  factory FormCorrectionSession.fromJson(Map<String, dynamic> json) {
    return FormCorrectionSession(
      sessionId: json['sessionId'] as String,
      exerciseName: json['exerciseName'] as String,
      programId: json['programId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int),
      totalReps: json['totalReps'] as int,
      averageFormScore: (json['averageFormScore'] as num).toDouble(),
      repHistory: (json['repHistory'] as List)
          .map((r) => RepAnalysis.fromJson(r as Map<String, dynamic>))
          .toList(),
      violationFrequency: Map<String, int>.from(json['violationFrequency'] as Map),
    );
  }
}
