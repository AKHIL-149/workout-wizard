import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service for managing rest timer between sets
class RestTimerService extends ChangeNotifier {
  static final RestTimerService _instance = RestTimerService._internal();
  factory RestTimerService() => _instance;
  RestTimerService._internal();

  // Timer state
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _isCompleted = false;

  // Audio player for completion sound
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Settings keys
  static const String _keyDefaultRestTime = 'default_rest_time';
  static const String _keyAutoStartTimer = 'auto_start_timer';
  static const String _keySoundEnabled = 'timer_sound_enabled';
  static const String _keyVibrationEnabled = 'timer_vibration_enabled';

  // Getters
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;
  double get progress => _totalSeconds > 0 ? (_totalSeconds - _remainingSeconds) / _totalSeconds : 0.0;

  String get remainingTimeFormatted {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get default rest time in seconds
  Future<int> getDefaultRestTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDefaultRestTime) ?? 90; // Default: 90 seconds
  }

  /// Set default rest time
  Future<void> setDefaultRestTime(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultRestTime, seconds);
  }

  /// Check if auto-start is enabled
  Future<bool> isAutoStartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoStartTimer) ?? true;
  }

  /// Set auto-start preference
  Future<void> setAutoStart(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoStartTimer, enabled);
  }

  /// Check if sound is enabled
  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySoundEnabled) ?? true;
  }

  /// Set sound preference
  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  /// Check if vibration is enabled
  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVibrationEnabled) ?? true;
  }

  /// Set vibration preference
  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibrationEnabled, enabled);
  }

  /// Start timer with specified duration
  Future<void> startTimer(int seconds) async {
    // Cancel any existing timer
    _timer?.cancel();

    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    _isRunning = true;
    _isCompleted = false;

    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();

        // Alert at 5 seconds remaining
        if (_remainingSeconds == 5) {
          await _playCountdownSound();
        }
      } else {
        // Timer completed
        timer.cancel();
        _isRunning = false;
        _isCompleted = true;
        notifyListeners();

        await _onTimerComplete();
      }
    });

    debugPrint('RestTimerService: Timer started for $seconds seconds');
  }

  /// Pause timer
  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
    debugPrint('RestTimerService: Timer paused');
  }

  /// Resume timer
  void resumeTimer() {
    if (_remainingSeconds > 0 && !_isRunning) {
      startTimer(_remainingSeconds);
    }
  }

  /// Reset timer
  void resetTimer() {
    _timer?.cancel();
    _remainingSeconds = 0;
    _totalSeconds = 0;
    _isRunning = false;
    _isCompleted = false;
    notifyListeners();
    debugPrint('RestTimerService: Timer reset');
  }

  /// Add time to current timer
  void addTime(int seconds) {
    _remainingSeconds += seconds;
    _totalSeconds += seconds;
    notifyListeners();
    debugPrint('RestTimerService: Added $seconds seconds');
  }

  /// Skip rest (complete immediately)
  void skipRest() {
    _timer?.cancel();
    _remainingSeconds = 0;
    _isRunning = false;
    _isCompleted = true;
    notifyListeners();
    debugPrint('RestTimerService: Rest skipped');
  }

  /// Handle timer completion
  Future<void> _onTimerComplete() async {
    debugPrint('RestTimerService: Timer completed');

    // Play completion sound
    final soundEnabled = await isSoundEnabled();
    if (soundEnabled) {
      await _playCompletionSound();
    }

    // Trigger vibration
    final vibrationEnabled = await isVibrationEnabled();
    if (vibrationEnabled) {
      await _triggerVibration();
    }
  }

  /// Play countdown sound at 5 seconds
  Future<void> _playCountdownSound() async {
    try {
      // Short beep sound (using system notification sound)
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint('RestTimerService: Error playing countdown sound: $e');
    }
  }

  /// Play completion sound
  Future<void> _playCompletionSound() async {
    try {
      // Completion chime (using system notification sound)
      await _audioPlayer.play(AssetSource('sounds/complete.mp3'));
    } catch (e) {
      debugPrint('RestTimerService: Error playing completion sound: $e');
    }
  }

  /// Trigger vibration pattern
  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Pattern: wait 0ms, vibrate 200ms, wait 100ms, vibrate 200ms
        await Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
    } catch (e) {
      debugPrint('RestTimerService: Error triggering vibration: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
