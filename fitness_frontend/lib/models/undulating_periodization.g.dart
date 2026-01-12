// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'undulating_periodization.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UndulatingPeriodizationProgramAdapter
    extends TypeAdapter<UndulatingPeriodizationProgram> {
  @override
  final int typeId = 46;

  @override
  UndulatingPeriodizationProgram read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UndulatingPeriodizationProgram(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      cycles: (fields[3] as List).cast<UndulatingCycle>(),
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime?,
      currentWeek: fields[6] as int,
      currentDayInCycle: fields[7] as int,
      currentCycleId: fields[8] as String,
      isActive: fields[9] as bool,
      baselineMaxes: (fields[10] as Map).cast<String, double>(),
      undulationType: fields[11] as String,
      progressionRate: fields[12] as double,
      settings: (fields[13] as Map).cast<String, dynamic>(),
      createdAt: fields[14] as DateTime,
      completedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UndulatingPeriodizationProgram obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.cycles)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.currentWeek)
      ..writeByte(7)
      ..write(obj.currentDayInCycle)
      ..writeByte(8)
      ..write(obj.currentCycleId)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.baselineMaxes)
      ..writeByte(11)
      ..write(obj.undulationType)
      ..writeByte(12)
      ..write(obj.progressionRate)
      ..writeByte(13)
      ..write(obj.settings)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UndulatingPeriodizationProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UndulatingCycleAdapter extends TypeAdapter<UndulatingCycle> {
  @override
  final int typeId = 47;

  @override
  UndulatingCycle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UndulatingCycle(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      workoutDays: (fields[3] as List).cast<UndulatingWorkoutDay>(),
      repeatCount: fields[4] as int,
      status: fields[5] as String,
      startDate: fields[6] as DateTime?,
      endDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UndulatingCycle obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.workoutDays)
      ..writeByte(4)
      ..write(obj.repeatCount)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UndulatingCycleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UndulatingWorkoutDayAdapter extends TypeAdapter<UndulatingWorkoutDay> {
  @override
  final int typeId = 48;

  @override
  UndulatingWorkoutDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UndulatingWorkoutDay(
      id: fields[0] as String,
      name: fields[1] as String,
      dayType: fields[2] as String,
      intensityPercent: fields[3] as double,
      repsMin: fields[4] as int,
      repsMax: fields[5] as int,
      setsPerExercise: fields[6] as int,
      restSeconds: fields[7] as int,
      focusExercises: (fields[8] as List).cast<String>(),
      notes: (fields[9] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, UndulatingWorkoutDay obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dayType)
      ..writeByte(3)
      ..write(obj.intensityPercent)
      ..writeByte(4)
      ..write(obj.repsMin)
      ..writeByte(5)
      ..write(obj.repsMax)
      ..writeByte(6)
      ..write(obj.setsPerExercise)
      ..writeByte(7)
      ..write(obj.restSeconds)
      ..writeByte(8)
      ..write(obj.focusExercises)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UndulatingWorkoutDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UndulatingProgressionEntryAdapter
    extends TypeAdapter<UndulatingProgressionEntry> {
  @override
  final int typeId = 49;

  @override
  UndulatingProgressionEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UndulatingProgressionEntry(
      id: fields[0] as String,
      programId: fields[1] as String,
      cycleId: fields[2] as String,
      workoutDayId: fields[3] as String,
      weekNumber: fields[4] as int,
      timestamp: fields[5] as DateTime,
      workingMaxes: (fields[6] as Map).cast<String, double>(),
      actualPerformance: (fields[7] as Map).cast<String, double>(),
      plannedIntensity: fields[8] as double,
      actualIntensity: fields[9] as double,
      plannedVolume: fields[10] as int,
      actualVolume: fields[11] as int,
      notes: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UndulatingProgressionEntry obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.programId)
      ..writeByte(2)
      ..write(obj.cycleId)
      ..writeByte(3)
      ..write(obj.workoutDayId)
      ..writeByte(4)
      ..write(obj.weekNumber)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.workingMaxes)
      ..writeByte(7)
      ..write(obj.actualPerformance)
      ..writeByte(8)
      ..write(obj.plannedIntensity)
      ..writeByte(9)
      ..write(obj.actualIntensity)
      ..writeByte(10)
      ..write(obj.plannedVolume)
      ..writeByte(11)
      ..write(obj.actualVolume)
      ..writeByte(12)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UndulatingProgressionEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
