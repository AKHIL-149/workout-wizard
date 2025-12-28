// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_performance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExercisePerformanceAdapter extends TypeAdapter<ExercisePerformance> {
  @override
  final int typeId = 11;

  @override
  ExercisePerformance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExercisePerformance(
      id: fields[0] as String,
      exerciseName: fields[1] as String,
      exerciseId: fields[2] as String?,
      sets: (fields[3] as List).cast<ExerciseSet>(),
      formCorrectionSessionId: fields[4] as String?,
      notes: fields[5] as String?,
      startTime: fields[6] as DateTime?,
      endTime: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ExercisePerformance obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.exerciseId)
      ..writeByte(3)
      ..write(obj.sets)
      ..writeByte(4)
      ..write(obj.formCorrectionSessionId)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExercisePerformanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
