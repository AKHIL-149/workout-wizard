// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'third_party_integration.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThirdPartyIntegrationAdapter extends TypeAdapter<ThirdPartyIntegration> {
  @override
  final int typeId = 37;

  @override
  ThirdPartyIntegration read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThirdPartyIntegration(
      id: fields[0] as String,
      provider: fields[1] as String,
      isConnected: fields[2] as bool,
      accessToken: fields[3] as String?,
      refreshToken: fields[4] as String?,
      tokenExpiresAt: fields[5] as DateTime?,
      userId: fields[6] as String?,
      userName: fields[7] as String?,
      autoSync: fields[8] as bool,
      lastSyncTime: fields[9] as DateTime?,
      connectedAt: fields[10] as DateTime,
      settings: (fields[11] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ThirdPartyIntegration obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.provider)
      ..writeByte(2)
      ..write(obj.isConnected)
      ..writeByte(3)
      ..write(obj.accessToken)
      ..writeByte(4)
      ..write(obj.refreshToken)
      ..writeByte(5)
      ..write(obj.tokenExpiresAt)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.userName)
      ..writeByte(8)
      ..write(obj.autoSync)
      ..writeByte(9)
      ..write(obj.lastSyncTime)
      ..writeByte(10)
      ..write(obj.connectedAt)
      ..writeByte(11)
      ..write(obj.settings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThirdPartyIntegrationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IntegrationSyncActivityAdapter extends TypeAdapter<IntegrationSyncActivity> {
  @override
  final int typeId = 38;

  @override
  IntegrationSyncActivity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IntegrationSyncActivity(
      id: fields[0] as String,
      integrationId: fields[1] as String,
      provider: fields[2] as String,
      activityType: fields[3] as String,
      externalId: fields[4] as String,
      workoutId: fields[5] as String?,
      activityDate: fields[6] as DateTime,
      syncedAt: fields[7] as DateTime,
      activityData: (fields[8] as Map).cast<String, dynamic>(),
      syncDirection: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, IntegrationSyncActivity obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.integrationId)
      ..writeByte(2)
      ..write(obj.provider)
      ..writeByte(3)
      ..write(obj.activityType)
      ..writeByte(4)
      ..write(obj.externalId)
      ..writeByte(5)
      ..write(obj.workoutId)
      ..writeByte(6)
      ..write(obj.activityDate)
      ..writeByte(7)
      ..write(obj.syncedAt)
      ..writeByte(8)
      ..write(obj.activityData)
      ..writeByte(9)
      ..write(obj.syncDirection);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntegrationSyncActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IntegrationSyncHistoryAdapter extends TypeAdapter<IntegrationSyncHistory> {
  @override
  final int typeId = 39;

  @override
  IntegrationSyncHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IntegrationSyncHistory(
      id: fields[0] as String,
      integrationId: fields[1] as String,
      provider: fields[2] as String,
      syncTime: fields[3] as DateTime,
      syncType: fields[4] as String,
      activitiesProcessed: fields[5] as int,
      success: fields[6] as bool,
      errorMessage: fields[7] as String?,
      activitiesByType: (fields[8] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, IntegrationSyncHistory obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.integrationId)
      ..writeByte(2)
      ..write(obj.provider)
      ..writeByte(3)
      ..write(obj.syncTime)
      ..writeByte(4)
      ..write(obj.syncType)
      ..writeByte(5)
      ..write(obj.activitiesProcessed)
      ..writeByte(6)
      ..write(obj.success)
      ..writeByte(7)
      ..write(obj.errorMessage)
      ..writeByte(8)
      ..write(obj.activitiesByType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntegrationSyncHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
