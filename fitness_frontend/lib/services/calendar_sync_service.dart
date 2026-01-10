import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:uuid/uuid.dart';
import '../models/calendar_sync.dart';

/// Service for syncing workouts with device calendar
class CalendarSyncService {
  static final CalendarSyncService _instance = CalendarSyncService._internal();
  factory CalendarSyncService() => _instance;
  CalendarSyncService._internal();

  static const String _configBoxName = 'calendar_sync_config';
  static const String _eventsBoxName = 'synced_calendar_events';
  static const String _historyBoxName = 'calendar_sync_history';

  final Uuid _uuid = const Uuid();
  DeviceCalendarPlugin? _deviceCalendar;

  /// Initialize Hive boxes and calendar plugin
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_configBoxName)) {
        await Hive.openBox<CalendarSyncConfig>(_configBoxName);
      }
      if (!Hive.isBoxOpen(_eventsBoxName)) {
        await Hive.openBox<SyncedCalendarEvent>(_eventsBoxName);
      }
      if (!Hive.isBoxOpen(_historyBoxName)) {
        await Hive.openBox<CalendarSyncHistory>(_historyBoxName);
      }

      _deviceCalendar = DeviceCalendarPlugin();

      // Create default config if none exists
      final config = getSyncConfig();
      if (config == null) {
        await _createDefaultConfig();
      }

      debugPrint('CalendarSyncService: Initialized');
    } catch (e) {
      debugPrint('CalendarSyncService: Error initializing: $e');
      rethrow;
    }
  }

  /// Get sync configuration
  CalendarSyncConfig? getSyncConfig() {
    try {
      final box = Hive.box<CalendarSyncConfig>(_configBoxName);
      return box.get('config');
    } catch (e) {
      debugPrint('CalendarSyncService: Error getting config: $e');
      return null;
    }
  }

  /// Update sync configuration
  Future<void> updateSyncConfig(CalendarSyncConfig config) async {
    try {
      final box = Hive.box<CalendarSyncConfig>(_configBoxName);
      await box.put('config', config);
      debugPrint('CalendarSyncService: Config updated');
    } catch (e) {
      debugPrint('CalendarSyncService: Error updating config: $e');
      rethrow;
    }
  }

  /// Create default configuration
  Future<void> _createDefaultConfig() async {
    final config = CalendarSyncConfig(
      id: _uuid.v4(),
      lastSyncTime: DateTime.now(),
    );
    await updateSyncConfig(config);
  }

  /// Check if calendar integration is available
  Future<bool> isAvailable() async {
    try {
      if (_deviceCalendar == null) return false;

      // Calendar integration is only available on iOS and Android
      if (!Platform.isIOS && !Platform.isAndroid) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('CalendarSyncService: Error checking availability: $e');
      return false;
    }
  }

  /// Request calendar permissions
  Future<bool> requestPermissions() async {
    try {
      if (_deviceCalendar == null) {
        throw Exception('Calendar plugin not initialized');
      }

      final permissionsGranted = await _deviceCalendar!.hasPermissions();
      if (permissionsGranted.isSuccess && permissionsGranted.data == true) {
        return true;
      }

      final result = await _deviceCalendar!.requestPermissions();
      final granted = result.isSuccess && result.data == true;

      if (granted) {
        debugPrint('CalendarSyncService: Permissions granted');

        // Enable sync after permissions granted
        final config = getSyncConfig();
        if (config != null) {
          await updateSyncConfig(config.copyWith(isEnabled: true));
        }
      }

      return granted;
    } catch (e) {
      debugPrint('CalendarSyncService: Error requesting permissions: $e');
      return false;
    }
  }

  /// Get available calendars
  Future<List<Calendar>> getCalendars() async {
    try {
      if (_deviceCalendar == null) {
        throw Exception('Calendar plugin not initialized');
      }

      final result = await _deviceCalendar!.retrieveCalendars();
      if (result.isSuccess && result.data != null) {
        return result.data!;
      }

      return [];
    } catch (e) {
      debugPrint('CalendarSyncService: Error getting calendars: $e');
      return [];
    }
  }

  /// Create calendar event for workout
  Future<String?> createWorkoutEvent({
    required String workoutId,
    required String workoutName,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      final config = getSyncConfig();
      if (config == null || !config.isEnabled || config.selectedCalendarId == null) {
        debugPrint('CalendarSyncService: Calendar sync not enabled');
        return null;
      }

      if (_deviceCalendar == null) {
        throw Exception('Calendar plugin not initialized');
      }

      // Create event
      final event = Event(
        config.selectedCalendarId,
        title: workoutName,
        start: TZDateTime.from(startTime, local),
        end: TZDateTime.from(endTime, local),
        description: notes,
      );

      // Add reminder if configured
      if (config.reminderMinutesBefore > 0) {
        event.reminders = [
          Reminder(minutes: config.reminderMinutesBefore),
        ];
      }

      final result = await _deviceCalendar!.createOrUpdateEvent(event);

      if (result?.isSuccess == true && result?.data != null) {
        final eventId = result!.data!;

        // Save synced event record
        final syncedEvent = SyncedCalendarEvent(
          id: _uuid.v4(),
          calendarEventId: eventId,
          calendarId: config.selectedCalendarId!,
          workoutId: workoutId,
          workoutName: workoutName,
          startTime: startTime,
          endTime: endTime,
          syncedAt: DateTime.now(),
        );

        await _saveSyncedEvent(syncedEvent);

        // Update last sync time
        await updateSyncConfig(config.copyWith(lastSyncTime: DateTime.now()));

        // Record sync history
        await _addSyncHistory(
          syncType: 'create',
          eventsProcessed: 1,
          eventsByType: {'created': 1},
        );

        debugPrint('CalendarSyncService: Workout event created: $eventId');
        return eventId;
      }

      return null;
    } catch (e) {
      debugPrint('CalendarSyncService: Error creating event: $e');
      await _addSyncHistory(
        syncType: 'create',
        eventsProcessed: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Update calendar event when workout is completed
  Future<bool> updateWorkoutEvent({
    required String workoutId,
    bool isCompleted = true,
  }) async {
    try {
      final config = getSyncConfig();
      if (config == null || !config.isEnabled) {
        return false;
      }

      final syncedEvent = getSyncedEventByWorkoutId(workoutId);
      if (syncedEvent == null) {
        debugPrint('CalendarSyncService: No synced event found for workout');
        return false;
      }

      if (_deviceCalendar == null) {
        throw Exception('Calendar plugin not initialized');
      }

      // Get existing event
      final result = await _deviceCalendar!.retrieveEvents(
        syncedEvent.calendarId,
        RetrieveEventsParams(
          eventIds: [syncedEvent.calendarEventId],
        ),
      );

      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        final event = result.data!.first;

        // Update event title to show completion
        if (isCompleted) {
          event.title = '✓ ${syncedEvent.workoutName}';
        }

        final updateResult = await _deviceCalendar!.createOrUpdateEvent(event);

        if (updateResult?.isSuccess == true) {
          // Update synced event record
          final updated = syncedEvent.copyWith(
            isCompleted: isCompleted,
            lastUpdated: DateTime.now(),
          );
          await _saveSyncedEvent(updated);

          // Record sync history
          await _addSyncHistory(
            syncType: 'update',
            eventsProcessed: 1,
            eventsByType: {'updated': 1},
          );

          debugPrint('CalendarSyncService: Workout event updated');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('CalendarSyncService: Error updating event: $e');
      await _addSyncHistory(
        syncType: 'update',
        eventsProcessed: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Delete calendar event
  Future<bool> deleteWorkoutEvent(String workoutId) async {
    try {
      final config = getSyncConfig();
      if (config == null || !config.isEnabled) {
        return false;
      }

      final syncedEvent = getSyncedEventByWorkoutId(workoutId);
      if (syncedEvent == null) {
        return false;
      }

      if (_deviceCalendar == null) {
        throw Exception('Calendar plugin not initialized');
      }

      final result = await _deviceCalendar!.deleteEvent(
        syncedEvent.calendarId,
        syncedEvent.calendarEventId,
      );

      if (result?.isSuccess == true) {
        // Remove synced event record
        await _deleteSyncedEvent(syncedEvent.id);

        // Record sync history
        await _addSyncHistory(
          syncType: 'delete',
          eventsProcessed: 1,
          eventsByType: {'deleted': 1},
        );

        debugPrint('CalendarSyncService: Workout event deleted');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('CalendarSyncService: Error deleting event: $e');
      await _addSyncHistory(
        syncType: 'delete',
        eventsProcessed: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Save synced event to local storage
  Future<void> _saveSyncedEvent(SyncedCalendarEvent event) async {
    try {
      final box = Hive.box<SyncedCalendarEvent>(_eventsBoxName);
      await box.put(event.id, event);
    } catch (e) {
      debugPrint('CalendarSyncService: Error saving synced event: $e');
    }
  }

  /// Delete synced event from local storage
  Future<void> _deleteSyncedEvent(String eventId) async {
    try {
      final box = Hive.box<SyncedCalendarEvent>(_eventsBoxName);
      await box.delete(eventId);
    } catch (e) {
      debugPrint('CalendarSyncService: Error deleting synced event: $e');
    }
  }

  /// Get synced event by workout ID
  SyncedCalendarEvent? getSyncedEventByWorkoutId(String workoutId) {
    try {
      final box = Hive.box<SyncedCalendarEvent>(_eventsBoxName);
      return box.values.firstWhere(
        (e) => e.workoutId == workoutId,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all synced events
  List<SyncedCalendarEvent> getAllSyncedEvents() {
    try {
      final box = Hive.box<SyncedCalendarEvent>(_eventsBoxName);
      return box.values.toList()
        ..sort((a, b) => b.syncedAt.compareTo(a.syncedAt));
    } catch (e) {
      debugPrint('CalendarSyncService: Error getting synced events: $e');
      return [];
    }
  }

  /// Add sync history entry
  Future<void> _addSyncHistory({
    required String syncType,
    required int eventsProcessed,
    bool success = true,
    String? errorMessage,
    Map<String, int>? eventsByType,
  }) async {
    try {
      final history = CalendarSyncHistory(
        id: _uuid.v4(),
        syncTime: DateTime.now(),
        syncType: syncType,
        eventsProcessed: eventsProcessed,
        success: success,
        errorMessage: errorMessage,
        eventsByType: eventsByType,
      );

      final box = Hive.box<CalendarSyncHistory>(_historyBoxName);
      await box.put(history.id, history);

      // Keep only last 100 sync history entries
      if (box.length > 100) {
        final keys = box.keys.toList();
        for (var i = 0; i < box.length - 100; i++) {
          await box.delete(keys[i]);
        }
      }
    } catch (e) {
      debugPrint('CalendarSyncService: Error adding sync history: $e');
    }
  }

  /// Get sync history
  List<CalendarSyncHistory> getSyncHistory({int limit = 20}) {
    try {
      final box = Hive.box<CalendarSyncHistory>(_historyBoxName);
      final history = box.values.toList()
        ..sort((a, b) => b.syncTime.compareTo(a.syncTime));

      return history.take(limit).toList();
    } catch (e) {
      debugPrint('CalendarSyncService: Error getting sync history: $e');
      return [];
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    try {
      final config = getSyncConfig();
      final events = getAllSyncedEvents();
      final history = getSyncHistory();

      final completedEvents = events.where((e) => e.isCompleted).length;
      final successfulSyncs = history.where((h) => h.success).length;
      final failedSyncs = history.where((h) => !h.success).length;

      return {
        'isEnabled': config?.isEnabled ?? false,
        'selectedCalendar': config?.selectedCalendarName,
        'lastSyncTime': config?.lastSyncTime,
        'totalEvents': events.length,
        'completedEvents': completedEvents,
        'totalSyncs': history.length,
        'successfulSyncs': successfulSyncs,
        'failedSyncs': failedSyncs,
      };
    } catch (e) {
      debugPrint('CalendarSyncService: Error getting stats: $e');
      return {
        'isEnabled': false,
        'selectedCalendar': null,
        'totalEvents': 0,
        'completedEvents': 0,
        'totalSyncs': 0,
        'successfulSyncs': 0,
        'failedSyncs': 0,
      };
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await Hive.box<CalendarSyncConfig>(_configBoxName).clear();
      await Hive.box<SyncedCalendarEvent>(_eventsBoxName).clear();
      await Hive.box<CalendarSyncHistory>(_historyBoxName).clear();
      debugPrint('CalendarSyncService: All data cleared');
    } catch (e) {
      debugPrint('CalendarSyncService: Error clearing data: $e');
      rethrow;
    }
  }
}
