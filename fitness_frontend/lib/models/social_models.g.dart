// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SocialProfileAdapter extends TypeAdapter<SocialProfile> {
  @override
  final int typeId = 22;

  @override
  SocialProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SocialProfile(
      id: fields[0] as String,
      displayName: fields[1] as String,
      avatarEmoji: fields[2] as String?,
      createdAt: fields[3] as DateTime,
      bio: fields[4] as String?,
      stats: (fields[5] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SocialProfile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.avatarEmoji)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.bio)
      ..writeByte(5)
      ..write(obj.stats);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutBuddyAdapter extends TypeAdapter<WorkoutBuddy> {
  @override
  final int typeId = 23;

  @override
  WorkoutBuddy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutBuddy(
      id: fields[0] as String,
      displayName: fields[1] as String,
      avatarEmoji: fields[2] as String?,
      connectedAt: fields[3] as DateTime,
      lastActivitySync: fields[4] as DateTime?,
      lastActivity: fields[5] as String?,
      sharedData: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutBuddy obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.avatarEmoji)
      ..writeByte(3)
      ..write(obj.connectedAt)
      ..writeByte(4)
      ..write(obj.lastActivitySync)
      ..writeByte(5)
      ..write(obj.lastActivity)
      ..writeByte(6)
      ..write(obj.sharedData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutBuddyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProgressUpdateAdapter extends TypeAdapter<ProgressUpdate> {
  @override
  final int typeId = 24;

  @override
  ProgressUpdate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgressUpdate(
      id: fields[0] as String,
      userId: fields[1] as String,
      userName: fields[2] as String,
      timestamp: fields[3] as DateTime,
      updateType: fields[4] as String,
      message: fields[5] as String,
      data: (fields[6] as Map).cast<String, dynamic>(),
      avatarEmoji: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProgressUpdate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.updateType)
      ..writeByte(5)
      ..write(obj.message)
      ..writeByte(6)
      ..write(obj.data)
      ..writeByte(7)
      ..write(obj.avatarEmoji);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressUpdateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
