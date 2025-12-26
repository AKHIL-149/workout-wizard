import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Event types for analytics tracking
enum AnalyticsEvent {
  appOpened,
  profileCreated,
  recommendationsViewed,
  programClicked,
  programFavorited,
  searchPerformed,
  filterApplied,
  onboardingCompleted,
  achievementUnlocked,
  workoutCompleted,
  programStarted,
  // Form correction events
  formCorrectionStarted,
  formCorrectionCompleted,
  formViolationDetected,
  formScoreRecorded,
  exerciseFormImproved,
}

/// User action data model
class UserAction {
  final AnalyticsEvent event;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  UserAction({
    required this.event,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'event': event.toString(),
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory UserAction.fromJson(Map<String, dynamic> json) => UserAction(
    event: AnalyticsEvent.values.firstWhere(
      (e) => e.toString() == json['event'],
      orElse: () => AnalyticsEvent.appOpened,
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

/// Analytics service for tracking user behavior
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const String _actionsKey = 'user_actions';
  static const String _preferencesKey = 'user_preferences';
  static const int _maxActions = 1000; // Keep last 1000 actions

  List<UserAction> _actions = [];
  Map<String, dynamic> _preferences = {};

  /// Initialize analytics
  Future<void> initialize() async {
    await _loadActions();
    await _loadPreferences();
  }

  /// Track an event
  Future<void> trackEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? metadata,
  }) async {
    final action = UserAction(
      event: event,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _actions.insert(0, action);

    // Keep only last N actions
    if (_actions.length > _maxActions) {
      _actions = _actions.take(_maxActions).toList();
    }

    await _saveActions();

    // Update preferences based on actions
    _updatePreferences(event, metadata);
  }

  /// Log an event (alias for trackEvent)
  Future<void> logEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? parameters,
  }) async {
    await trackEvent(event, metadata: parameters);
  }

  /// Load actions from storage
  Future<void> _loadActions() async {
    final prefs = await SharedPreferences.getInstance();
    final actionsJson = prefs.getString(_actionsKey);
    if (actionsJson == null) return;

    try {
      final actionsList = json.decode(actionsJson) as List;
      _actions = actionsList
          .map((data) => UserAction.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _actions = [];
    }
  }

  /// Save actions to storage
  Future<void> _saveActions() async {
    final prefs = await SharedPreferences.getInstance();
    final actionsJson = json.encode(_actions.map((a) => a.toJson()).toList());
    await prefs.setString(_actionsKey, actionsJson);
  }

  /// Load preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsJson = prefs.getString(_preferencesKey);
    if (prefsJson == null) return;

    try {
      _preferences = json.decode(prefsJson) as Map<String, dynamic>;
    } catch (e) {
      _preferences = {};
    }
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesKey, json.encode(_preferences));
  }

  /// Update user preferences based on actions
  void _updatePreferences(AnalyticsEvent event, Map<String, dynamic>? metadata) {
    switch (event) {
      case AnalyticsEvent.programClicked:
        _incrementPreference('favorite_goals', metadata?['goal']);
        _incrementPreference('favorite_equipment', metadata?['equipment']);
        _incrementPreference('favorite_level', metadata?['level']);
        break;
      case AnalyticsEvent.searchPerformed:
        _incrementPreference('search_topics', metadata?['query']);
        break;
      case AnalyticsEvent.filterApplied:
        _incrementPreference('favorite_filters', metadata?['filter']);
        break;
      default:
        break;
    }
    _savePreferences();
  }

  /// Increment preference count
  void _incrementPreference(String category, dynamic value) {
    if (value == null) return;

    if (!_preferences.containsKey(category)) {
      _preferences[category] = <String, int>{};
    }

    final categoryMap = _preferences[category] as Map<String, dynamic>;
    final key = value.toString();
    categoryMap[key] = (categoryMap[key] as int? ?? 0) + 1;
  }

  /// Get most frequent preference
  String? getMostFrequentPreference(String category) {
    if (!_preferences.containsKey(category)) return null;

    final categoryMap = _preferences[category] as Map<String, dynamic>;
    if (categoryMap.isEmpty) return null;

    var maxKey = categoryMap.keys.first;
    var maxCount = categoryMap[maxKey] as int;

    for (final entry in categoryMap.entries) {
      if ((entry.value as int) > maxCount) {
        maxKey = entry.key;
        maxCount = entry.value as int;
      }
    }

    return maxKey;
  }

  /// Get activity stats
  Map<String, dynamic> getActivityStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: today.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);

    final todayActions = _actions.where((a) => a.timestamp.isAfter(today)).length;
    final weekActions = _actions.where((a) => a.timestamp.isAfter(thisWeek)).length;
    final monthActions = _actions.where((a) => a.timestamp.isAfter(thisMonth)).length;

    return {
      'today': todayActions,
      'this_week': weekActions,
      'this_month': monthActions,
      'total': _actions.length,
    };
  }

  /// Get event counts
  Map<String, int> getEventCounts() {
    final counts = <String, int>{};
    for (final action in _actions) {
      final eventName = action.event.toString().split('.').last;
      counts[eventName] = (counts[eventName] ?? 0) + 1;
    }
    return counts;
  }

  /// Get peak activity hour
  int? getPeakActivityHour() {
    if (_actions.isEmpty) return null;

    final hourCounts = <int, int>{};
    for (final action in _actions) {
      final hour = action.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    var maxHour = hourCounts.keys.first;
    var maxCount = hourCounts[maxHour]!;

    for (final entry in hourCounts.entries) {
      if (entry.value > maxCount) {
        maxHour = entry.key;
        maxCount = entry.value;
      }
    }

    return maxHour;
  }

  /// Get activity by day of week
  Map<String, int> getActivityByDayOfWeek() {
    final dayCounts = <String, int>{
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };

    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (final action in _actions) {
      final dayIndex = action.timestamp.weekday - 1;
      dayCounts[dayNames[dayIndex]] = dayCounts[dayNames[dayIndex]]! + 1;
    }

    return dayCounts;
  }

  /// Get recent actions
  List<UserAction> getRecentActions({int limit = 10}) {
    return _actions.take(limit).toList();
  }

  /// Clear all analytics data
  Future<void> clearAnalytics() async {
    _actions.clear();
    _preferences.clear();
    await _saveActions();
    await _savePreferences();
  }

  // Getters
  List<UserAction> get allActions => _actions;
  Map<String, dynamic> get preferences => _preferences;

  /// Export analytics data for backup
  Future<Map<String, dynamic>> exportAnalytics() async {
    return {
      'user_actions': _actions.map((action) => action.toJson()).toList(),
      'user_preferences': _preferences,
    };
  }

  /// Import analytics data from backup
  Future<void> importAnalytics(Map<String, dynamic> data, {bool merge = false}) async {
    if (data['user_actions'] != null) {
      final backupActions = (data['user_actions'] as List)
          .map((json) => UserAction.fromJson(json as Map<String, dynamic>))
          .toList();

      if (merge) {
        // Merge actions, avoiding duplicates by timestamp
        final existingTimestamps = _actions.map((a) => a.timestamp).toSet();
        final newActions = backupActions
            .where((action) => !existingTimestamps.contains(action.timestamp))
            .toList();
        _actions.addAll(newActions);

        // Keep only most recent actions (up to max size)
        _actions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        if (_actions.length > _maxActions) {
          _actions = _actions.sublist(0, _maxActions);
        }
      } else {
        _actions = backupActions;
      }

      await _saveActions();
    }

    if (data['user_preferences'] != null) {
      final backupPreferences = Map<String, dynamic>.from(data['user_preferences'] as Map);

      if (merge) {
        // Merge preferences, backup values take precedence for conflicts
        _preferences.addAll(backupPreferences);
      } else {
        _preferences = backupPreferences;
      }

      await _savePreferences();
    }
  }
}
