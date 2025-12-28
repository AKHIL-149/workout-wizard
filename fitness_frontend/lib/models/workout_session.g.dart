// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final int typeId = 12;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      id: fields[0] as String,
      programId: fields[1] as String?,
      workoutName: fields[2] as String?,
      weekNumber: fields[3] as int?,
      dayNumber: fields[4] as int?,
      exercises: (fields[5] as List).cast<ExercisePerformance>(),
      startTime: fields[6] as DateTime?,
      endTime: fields[7] as DateTime?,
      notes: fields[8] as String?,
      bodyweight: fields[9] as double?,
      location: fields[10] as String?,
      tags: (fields[11] as List?)?.cast<String>(),
      completed: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.programId)
      ..writeByte(2)
      ..write(obj.workoutName)
      ..writeByte(3)
      ..write(obj.weekNumber)
      ..writeByte(4)
      ..write(obj.dayNumber)
      ..writeByte(5)
      ..write(obj.exercises)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.bodyweight)
      ..writeByte(10)
      ..write(obj.location)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
