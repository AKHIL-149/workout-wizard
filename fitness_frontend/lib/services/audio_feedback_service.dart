import 'package:flutter_tts/flutter_tts.dart';
import '../models/form_analysis.dart';

/// Priority levels for audio messages
enum AudioPriority {
  critical, // Immediate safety concerns
  warning, // Form violations
  info, // General guidance
  celebration, // Rep completion, achievements
}

/// Audio message model
class AudioMessage {
  final String text;
  final AudioPriority priority;
  final DateTime timestamp;

  AudioMessage({
    required this.text,
    required this.priority,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service for providing audio feedback during workouts
class AudioFeedbackService {
  final FlutterTts _tts = FlutterTts();

  // Settings
  bool _isEnabled = true;
  double _volume = 0.8; // 0.0 to 1.0
  double _speechRate = 0.5; // 0.0 to 1.0 (slower to faster)
  double _pitch = 1.0; // 0.5 to 2.0
  String _language = 'en-US';

  // Debouncing
  DateTime? _lastSpokenTime;
  String? _lastSpokenMessage;
  static const Duration _minTimeBetweenMessages = Duration(seconds: 3);
  static const Duration _criticalMessageInterval = Duration(seconds: 1);

  // Message queue
  final List<AudioMessage> _messageQueue = [];
  bool _isSpeaking = false;

  /// Initialize TTS service
  Future<void> initialize() async {
    await _tts.setLanguage(_language);
    await _tts.setVolume(_volume);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);

    // Set up callbacks
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _processQueue();
    });
  }

  /// Speak text with priority-based queuing
  Future<void> speak(String text, {AudioPriority priority = AudioPriority.info}) async {
    if (!_isEnabled || text.isEmpty) return;

    // Check if message is duplicate
    if (_lastSpokenMessage == text) {
      final now = DateTime.now();
      final timeSinceLastMessage = _lastSpokenTime != null
          ? now.difference(_lastSpokenTime!)
          : Duration.zero;

      // Skip duplicates within debounce period
      final debounceTime = priority == AudioPriority.critical
          ? _criticalMessageInterval
          : _minTimeBetweenMessages;

      if (timeSinceLastMessage < debounceTime) {
        return;
      }
    }

    final message = AudioMessage(text: text, priority: priority);

    // Critical messages interrupt current speech
    if (priority == AudioPriority.critical) {
      if (_isSpeaking) {
        await _tts.stop();
      }
      _messageQueue.clear();
      _messageQueue.add(message);
      await _processQueue();
    } else {
      // Add to queue and process if not speaking
      _messageQueue.add(message);
      if (!_isSpeaking) {
        await _processQueue();
      }
    }
  }

  /// Process message queue
  Future<void> _processQueue() async {
    if (_messageQueue.isEmpty || _isSpeaking || !_isEnabled) return;

    // Sort by priority (critical first)
    _messageQueue.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    final message = _messageQueue.removeAt(0);

    // Check debounce
    final now = DateTime.now();
    if (_lastSpokenTime != null) {
      final timeSinceLastMessage = now.difference(_lastSpokenTime!);
      final requiredInterval = message.priority == AudioPriority.critical
          ? _criticalMessageInterval
          : _minTimeBetweenMessages;

      if (timeSinceLastMessage < requiredInterval) {
        // Wait and retry
        await Future.delayed(requiredInterval - timeSinceLastMessage);
      }
    }

    _lastSpokenMessage = message.text;
    _lastSpokenTime = DateTime.now();

    await _tts.speak(message.text);
  }

  /// Speak form feedback
  Future<void> speakFormFeedback(FormFeedback feedback) async {
    if (feedback.audioMessage == null || feedback.audioMessage!.isEmpty) return;

    // Determine priority based on violations
    AudioPriority priority = AudioPriority.info;
    if (feedback.hasCriticalIssues) {
      priority = AudioPriority.critical;
    } else if (feedback.violations.any((v) => v.severity == Severity.warning)) {
      priority = AudioPriority.warning;
    }

    await speak(feedback.audioMessage!, priority: priority);
  }

  /// Speak rep completion
  Future<void> speakRepCompletion(int repNumber, {bool isGoodRep = true}) async {
    if (isGoodRep) {
      await speak(
        'Rep $repNumber complete. Good form!',
        priority: AudioPriority.celebration,
      );
    } else {
      await speak(
        'Rep $repNumber complete. Watch your form.',
        priority: AudioPriority.info,
      );
    }
  }

  /// Speak encouragement
  Future<void> speakEncouragement(String message) async {
    await speak(message, priority: AudioPriority.celebration);
  }

  /// Speak countdown (for timed exercises)
  Future<void> speakCountdown(int seconds) async {
    if (seconds <= 3) {
      await speak(seconds.toString(), priority: AudioPriority.info);
    }
  }

  /// Speak custom message
  Future<void> speakCustom(String message, {AudioPriority priority = AudioPriority.info}) async {
    await speak(message, priority: priority);
  }

  /// Stop speaking
  Future<void> stop() async {
    await _tts.stop();
    _messageQueue.clear();
    _isSpeaking = false;
  }

  /// Pause speaking
  Future<void> pause() async {
    await _tts.pause();
  }

  /// Clear message queue
  void clearQueue() {
    _messageQueue.clear();
  }

  /// Enable/disable audio feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
  }

  /// Set speech rate (0.0 to 1.0, slower to faster)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_speechRate);
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    _language = language;
    await _tts.setLanguage(_language);
  }

  /// Get available languages
  Future<List<dynamic>> getAvailableLanguages() async {
    return await _tts.getLanguages;
  }

  /// Get available voices
  Future<List<dynamic>> getAvailableVoices() async {
    return await _tts.getVoices;
  }

  /// Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
  }

  /// Dispose TTS service
  void dispose() {
    _tts.stop();
    _messageQueue.clear();
  }

  // Getters
  bool get isEnabled => _isEnabled;
  double get volume => _volume;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get language => _language;
  bool get isSpeaking => _isSpeaking;
  int get queueLength => _messageQueue.length;
}

/// Audio feedback settings model
class AudioFeedbackSettings {
  final bool enabled;
  final double volume;
  final double speechRate;
  final double pitch;
  final String language;
  final bool speakRepCompletions;
  final bool speakViolations;
  final bool speakEncouragement;

  AudioFeedbackSettings({
    this.enabled = true,
    this.volume = 0.8,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.language = 'en-US',
    this.speakRepCompletions = true,
    this.speakViolations = true,
    this.speakEncouragement = true,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'volume': volume,
    'speechRate': speechRate,
    'pitch': pitch,
    'language': language,
    'speakRepCompletions': speakRepCompletions,
    'speakViolations': speakViolations,
    'speakEncouragement': speakEncouragement,
  };

  factory AudioFeedbackSettings.fromJson(Map<String, dynamic> json) {
    return AudioFeedbackSettings(
      enabled: json['enabled'] as bool? ?? true,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      language: json['language'] as String? ?? 'en-US',
      speakRepCompletions: json['speakRepCompletions'] as bool? ?? true,
      speakViolations: json['speakViolations'] as bool? ?? true,
      speakEncouragement: json['speakEncouragement'] as bool? ?? true,
    );
  }

  AudioFeedbackSettings copyWith({
    bool? enabled,
    double? volume,
    double? speechRate,
    double? pitch,
    String? language,
    bool? speakRepCompletions,
    bool? speakViolations,
    bool? speakEncouragement,
  }) {
    return AudioFeedbackSettings(
      enabled: enabled ?? this.enabled,
      volume: volume ?? this.volume,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      language: language ?? this.language,
      speakRepCompletions: speakRepCompletions ?? this.speakRepCompletions,
      speakViolations: speakViolations ?? this.speakViolations,
      speakEncouragement: speakEncouragement ?? this.speakEncouragement,
    );
  }
}
