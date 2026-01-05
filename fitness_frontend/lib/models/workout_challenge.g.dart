// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_challenge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutChallengeAdapter extends TypeAdapter<WorkoutChallenge> {
  @override
  final int typeId = 27;

  @override
  WorkoutChallenge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutChallenge(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      creatorId: fields[3] as String,
      creatorName: fields[4] as String,
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime,
      challengeType: fields[7] as String,
      goalCriteria: (fields[8] as Map).cast<String, dynamic>(),
      isPublic: fields[9] as bool,
      participantIds: (fields[10] as List).cast<String>(),
      createdAt: fields[11] as DateTime,
      icon: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutChallenge obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.creatorId)
      ..writeByte(4)
      ..write(obj.creatorName)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.challengeType)
      ..writeByte(8)
      ..write(obj.goalCriteria)
      ..writeByte(9)
      ..write(obj.isPublic)
      ..writeByte(10)
      ..write(obj.participantIds)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutChallengeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChallengeProgressAdapter extends TypeAdapter<ChallengeProgress> {
  @override
  final int typeId = 28;

  @override
  ChallengeProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChallengeProgress(
      id: fields[0] as String,
      challengeId: fields[1] as String,
      userId: fields[2] as String,
      userName: fields[3] as String,
      joinedAt: fields[4] as DateTime,
      progressData: (fields[5] as Map).cast<String, dynamic>(),
      lastUpdated: fields[6] as DateTime,
      isCompleted: fields[7] as bool,
      avatarEmoji: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChallengeProgress obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.challengeId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.userName)
      ..writeByte(4)
      ..write(obj.joinedAt)
      ..writeByte(5)
      ..write(obj.progressData)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.avatarEmoji);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
