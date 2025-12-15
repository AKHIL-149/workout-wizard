import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for managing user sessions with device fingerprinting
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static const String _userIdKey = 'user_fingerprint';
  static const String _sessionCountKey = 'session_count';
  static const String _firstVisitKey = 'first_visit';
  static const String _lastVisitKey = 'last_visit';
  static const String _totalTimeKey = 'total_time_spent';

  String? _userId;
  int _sessionCount = 0;
  DateTime? _firstVisit;
  DateTime? _lastVisit;
  DateTime? _sessionStart;
  int _totalTimeSpent = 0; // in seconds

  /// Initialize session
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Get or create user fingerprint
    _userId = prefs.getString(_userIdKey);
    if (_userId == null) {
      _userId = await _generateFingerprint();
      await prefs.setString(_userIdKey, _userId!);
    }

    // Load session data
    _sessionCount = prefs.getInt(_sessionCountKey) ?? 0;
    _totalTimeSpent = prefs.getInt(_totalTimeKey) ?? 0;

    final firstVisitStr = prefs.getString(_firstVisitKey);
    if (firstVisitStr != null) {
      _firstVisit = DateTime.parse(firstVisitStr);
    } else {
      _firstVisit = DateTime.now();
      await prefs.setString(_firstVisitKey, _firstVisit!.toIso8601String());
    }

    final lastVisitStr = prefs.getString(_lastVisitKey);
    if (lastVisitStr != null) {
      _lastVisit = DateTime.parse(lastVisitStr);
    }

    // Increment session count
    _sessionCount++;
    await prefs.setInt(_sessionCountKey, _sessionCount);

    // Update last visit
    _lastVisit = DateTime.now();
    await prefs.setString(_lastVisitKey, _lastVisit!.toIso8601String());

    // Start tracking session time
    _sessionStart = DateTime.now();
  }

  /// Generate unique device fingerprint
  Future<String> _generateFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = const Uuid().v4();

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceId = '${webInfo.userAgent}_${webInfo.vendor}_${webInfo.platform}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = '${androidInfo.id}_${androidInfo.device}_${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = '${iosInfo.identifierForVendor}_${iosInfo.model}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceId = '${windowsInfo.computerName}_${windowsInfo.numberOfCores}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceId = '${macInfo.computerName}_${macInfo.model}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceId = '${linuxInfo.id}_${linuxInfo.machineId}';
      }
    } catch (e) {
      // Fallback to random UUID
      deviceId = const Uuid().v4();
    }

    return deviceId.hashCode.toString();
  }

  /// End current session and save time spent
  Future<void> endSession() async {
    if (_sessionStart != null) {
      final sessionDuration = DateTime.now().difference(_sessionStart!).inSeconds;
      _totalTimeSpent += sessionDuration;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_totalTimeKey, _totalTimeSpent);
    }
  }

  /// Check if user is a returning visitor
  bool get isReturningUser => _sessionCount > 1;

  /// Check if user is a new visitor
  bool get isNewUser => _sessionCount == 1;

  /// Get user engagement level
  String get engagementLevel {
    if (_sessionCount >= 10) return 'Highly Engaged';
    if (_sessionCount >= 5) return 'Regular User';
    if (_sessionCount >= 2) return 'Returning Visitor';
    return 'New User';
  }

  /// Get average session time in minutes
  int get averageSessionTime {
    if (_sessionCount == 0) return 0;
    return (_totalTimeSpent / _sessionCount / 60).round();
  }

  // Getters
  String get userId => _userId ?? 'unknown';
  int get sessionCount => _sessionCount;
  DateTime? get firstVisit => _firstVisit;
  DateTime? get lastVisit => _lastVisit;
  int get totalTimeSpent => _totalTimeSpent;

  /// Get time-based greeting
  String get timeBasedGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  /// Get contextual welcome message
  String get welcomeMessage {
    if (isNewUser) {
      return 'Welcome to Workout Wizard! Let\'s find your perfect fitness program.';
    } else if (_lastVisit != null) {
      final daysSinceLastVisit = DateTime.now().difference(_lastVisit!).inDays;
      if (daysSinceLastVisit == 0) {
        return 'Welcome back! Ready for another great workout?';
      } else if (daysSinceLastVisit == 1) {
        return 'Good to see you again! Consistency is key!';
      } else if (daysSinceLastVisit <= 7) {
        return 'Welcome back! We missed you!';
      } else {
        return 'Long time no see! Let\'s get back on track!';
      }
    }
    return 'Welcome back to Workout Wizard!';
  }
}
