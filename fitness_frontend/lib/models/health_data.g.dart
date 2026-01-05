// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthSyncConfigAdapter extends TypeAdapter<HealthSyncConfig> {
  @override
  final int typeId = 29;

  @override
  HealthSyncConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthSyncConfig(
      id: fields[0] as String,
      isEnabled: fields[1] as bool,
      syncWorkouts: fields[2] as bool,
      syncCalories: fields[3] as bool,
      syncHeartRate: fields[4] as bool,
      syncSteps: fields[5] as bool,
      autoSync: fields[6] as bool,
      lastSyncTime: fields[7] as DateTime,
      platform: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HealthSyncConfig obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isEnabled)
      ..writeByte(2)
      ..write(obj.syncWorkouts)
      ..writeByte(3)
      ..write(obj.syncCalories)
      ..writeByte(4)
      ..write(obj.syncHeartRate)
      ..writeByte(5)
      ..write(obj.syncSteps)
      ..writeByte(6)
      ..write(obj.autoSync)
      ..writeByte(7)
      ..write(obj.lastSyncTime)
      ..writeByte(8)
      ..write(obj.platform);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HealthDataRecordAdapter extends TypeAdapter<HealthDataRecord> {
  @override
  final int typeId = 30;

  @override
  HealthDataRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthDataRecord(
      id: fields[0] as String,
      type: fields[1] as String,
      value: fields[2] as double,
      unit: fields[3] as String?,
      timestamp: fields[4] as DateTime,
      endTime: fields[5] as DateTime?,
      source: fields[6] as String,
      metadata: (fields[7] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, HealthDataRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthDataRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HealthSyncHistoryAdapter extends TypeAdapter<HealthSyncHistory> {
  @override
  final int typeId = 31;

  @override
  HealthSyncHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthSyncHistory(
      id: fields[0] as String,
      syncTime: fields[1] as DateTime,
      syncType: fields[2] as String,
      recordsProcessed: fields[3] as int,
      success: fields[4] as bool,
      errorMessage: fields[5] as String?,
      recordsByType: (fields[6] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, HealthSyncHistory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.syncTime)
      ..writeByte(2)
      ..write(obj.syncType)
      ..writeByte(3)
      ..write(obj.recordsProcessed)
      ..writeByte(4)
      ..write(obj.success)
      ..writeByte(5)
      ..write(obj.errorMessage)
      ..writeByte(6)
      ..write(obj.recordsByType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
