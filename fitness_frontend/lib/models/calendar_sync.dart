import 'package:hive/hive.dart';

part 'calendar_sync.g.dart';

/// Calendar sync configuration
@HiveType(typeId: 34)
class CalendarSyncConfig {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final bool isEnabled;

  @HiveField(2)
  final String? selectedCalendarId;

  @HiveField(3)
  final String? selectedCalendarName;

  @HiveField(4)
  final bool autoSync;

  @HiveField(5)
  final bool syncScheduledWorkouts;

  @HiveField(6)
  final bool syncCompletedWorkouts;

  @HiveField(7)
  final int reminderMinutesBefore;

  @HiveField(8)
  final DateTime lastSyncTime;

  @HiveField(9)
  final bool includeNotes;

  CalendarSyncConfig({
    required this.id,
    this.isEnabled = false,
    this.selectedCalendarId,
    this.selectedCalendarName,
    this.autoSync = true,
    this.syncScheduledWorkouts = true,
    this.syncCompletedWorkouts = false,
    this.reminderMinutesBefore = 30,
    required this.lastSyncTime,
    this.includeNotes = true,
  });

  CalendarSyncConfig copyWith({
    String? id,
    bool? isEnabled,
    String? selectedCalendarId,
    String? selectedCalendarName,
    bool? autoSync,
    bool? syncScheduledWorkouts,
    bool? syncCompletedWorkouts,
    int? reminderMinutesBefore,
    DateTime? lastSyncTime,
    bool? includeNotes,
  }) {
    return CalendarSyncConfig(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      selectedCalendarId: selectedCalendarId ?? this.selectedCalendarId,
      selectedCalendarName: selectedCalendarName ?? this.selectedCalendarName,
      autoSync: autoSync ?? this.autoSync,
      syncScheduledWorkouts: syncScheduledWorkouts ?? this.syncScheduledWorkouts,
      syncCompletedWorkouts: syncCompletedWorkouts ?? this.syncCompletedWorkouts,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      includeNotes: includeNotes ?? this.includeNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isEnabled': isEnabled,
      'selectedCalendarId': selectedCalendarId,
      'selectedCalendarName': selectedCalendarName,
      'autoSync': autoSync,
      'syncScheduledWorkouts': syncScheduledWorkouts,
      'syncCompletedWorkouts': syncCompletedWorkouts,
      'reminderMinutesBefore': reminderMinutesBefore,
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'includeNotes': includeNotes,
    };
  }

  factory CalendarSyncConfig.fromJson(Map<String, dynamic> json) {
    return CalendarSyncConfig(
      id: json['id'] as String,
      isEnabled: json['isEnabled'] as bool? ?? false,
      selectedCalendarId: json['selectedCalendarId'] as String?,
      selectedCalendarName: json['selectedCalendarName'] as String?,
      autoSync: json['autoSync'] as bool? ?? true,
      syncScheduledWorkouts: json['syncScheduledWorkouts'] as bool? ?? true,
      syncCompletedWorkouts: json['syncCompletedWorkouts'] as bool? ?? false,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int? ?? 30,
      lastSyncTime: DateTime.parse(json['lastSyncTime'] as String),
      includeNotes: json['includeNotes'] as bool? ?? true,
    );
  }
}

/// Synced calendar event record
@HiveType(typeId: 35)
class SyncedCalendarEvent {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String calendarEventId;

  @HiveField(2)
  final String calendarId;

  @HiveField(3)
  final String workoutId; // Workout session or template ID

  @HiveField(4)
  final String workoutName;

  @HiveField(5)
  final DateTime startTime;

  @HiveField(6)
  final DateTime endTime;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final DateTime syncedAt;

  @HiveField(9)
  final DateTime? lastUpdated;

  SyncedCalendarEvent({
    required this.id,
    required this.calendarEventId,
    required this.calendarId,
    required this.workoutId,
    required this.workoutName,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    required this.syncedAt,
    this.lastUpdated,
  });

  SyncedCalendarEvent copyWith({
    String? id,
    String? calendarEventId,
    String? calendarId,
    String? workoutId,
    String? workoutName,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    DateTime? syncedAt,
    DateTime? lastUpdated,
  }) {
    return SyncedCalendarEvent(
      id: id ?? this.id,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      calendarId: calendarId ?? this.calendarId,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      syncedAt: syncedAt ?? this.syncedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calendarEventId': calendarEventId,
      'calendarId': calendarId,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isCompleted': isCompleted,
      'syncedAt': syncedAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory SyncedCalendarEvent.fromJson(Map<String, dynamic> json) {
    return SyncedCalendarEvent(
      id: json['id'] as String,
      calendarEventId: json['calendarEventId'] as String,
      calendarId: json['calendarId'] as String,
      workoutId: json['workoutId'] as String,
      workoutName: json['workoutName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      syncedAt: DateTime.parse(json['syncedAt'] as String),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }
}

/// Calendar sync history entry
@HiveType(typeId: 36)
class CalendarSyncHistory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime syncTime;

  @HiveField(2)
  final String syncType; // 'create', 'update', 'delete', 'full_sync'

  @HiveField(3)
  final int eventsProcessed;

  @HiveField(4)
  final bool success;

  @HiveField(5)
  final String? errorMessage;

  @HiveField(6)
  final Map<String, int> eventsByType;

  CalendarSyncHistory({
    required this.id,
    required this.syncTime,
    required this.syncType,
    required this.eventsProcessed,
    this.success = true,
    this.errorMessage,
    Map<String, int>? eventsByType,
  }) : eventsByType = eventsByType ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'syncTime': syncTime.toIso8601String(),
      'syncType': syncType,
      'eventsProcessed': eventsProcessed,
      'success': success,
      'errorMessage': errorMessage,
      'eventsByType': eventsByType,
    };
  }

  factory CalendarSyncHistory.fromJson(Map<String, dynamic> json) {
    return CalendarSyncHistory(
      id: json['id'] as String,
      syncTime: DateTime.parse(json['syncTime'] as String),
      syncType: json['syncType'] as String,
      eventsProcessed: json['eventsProcessed'] as int,
      success: json['success'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      eventsByType: Map<String, int>.from(json['eventsByType'] ?? {}),
    );
  }
}
