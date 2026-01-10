// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_sync.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarSyncConfigAdapter extends TypeAdapter<CalendarSyncConfig> {
  @override
  final int typeId = 34;

  @override
  CalendarSyncConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarSyncConfig(
      id: fields[0] as String,
      isEnabled: fields[1] as bool,
      selectedCalendarId: fields[2] as String?,
      selectedCalendarName: fields[3] as String?,
      autoSync: fields[4] as bool,
      syncScheduledWorkouts: fields[5] as bool,
      syncCompletedWorkouts: fields[6] as bool,
      reminderMinutesBefore: fields[7] as int,
      lastSyncTime: fields[8] as DateTime,
      includeNotes: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarSyncConfig obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isEnabled)
      ..writeByte(2)
      ..write(obj.selectedCalendarId)
      ..writeByte(3)
      ..write(obj.selectedCalendarName)
      ..writeByte(4)
      ..write(obj.autoSync)
      ..writeByte(5)
      ..write(obj.syncScheduledWorkouts)
      ..writeByte(6)
      ..write(obj.syncCompletedWorkouts)
      ..writeByte(7)
      ..write(obj.reminderMinutesBefore)
      ..writeByte(8)
      ..write(obj.lastSyncTime)
      ..writeByte(9)
      ..write(obj.includeNotes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarSyncConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncedCalendarEventAdapter extends TypeAdapter<SyncedCalendarEvent> {
  @override
  final int typeId = 35;

  @override
  SyncedCalendarEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncedCalendarEvent(
      id: fields[0] as String,
      calendarEventId: fields[1] as String,
      calendarId: fields[2] as String,
      workoutId: fields[3] as String,
      workoutName: fields[4] as String,
      startTime: fields[5] as DateTime,
      endTime: fields[6] as DateTime,
      isCompleted: fields[7] as bool,
      syncedAt: fields[8] as DateTime,
      lastUpdated: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncedCalendarEvent obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.calendarEventId)
      ..writeByte(2)
      ..write(obj.calendarId)
      ..writeByte(3)
      ..write(obj.workoutId)
      ..writeByte(4)
      ..write(obj.workoutName)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.syncedAt)
      ..writeByte(9)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncedCalendarEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalendarSyncHistoryAdapter extends TypeAdapter<CalendarSyncHistory> {
  @override
  final int typeId = 36;

  @override
  CalendarSyncHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarSyncHistory(
      id: fields[0] as String,
      syncTime: fields[1] as DateTime,
      syncType: fields[2] as String,
      eventsProcessed: fields[3] as int,
      success: fields[4] as bool,
      errorMessage: fields[5] as String?,
      eventsByType: (fields[6] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, CalendarSyncHistory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.syncTime)
      ..writeByte(2)
      ..write(obj.syncType)
      ..writeByte(3)
      ..write(obj.eventsProcessed)
      ..writeByte(4)
      ..write(obj.success)
      ..writeByte(5)
      ..write(obj.errorMessage)
      ..writeByte(6)
      ..write(obj.eventsByType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarSyncHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
