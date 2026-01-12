// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linear_periodization.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LinearPeriodizationProgramAdapter
    extends TypeAdapter<LinearPeriodizationProgram> {
  @override
  final int typeId = 43;

  @override
  LinearPeriodizationProgram read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LinearPeriodizationProgram(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      phases: (fields[3] as List).cast<LinearPhase>(),
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime?,
      currentWeek: fields[6] as int,
      currentPhaseId: fields[7] as String,
      isActive: fields[8] as bool,
      baselineMaxes: (fields[9] as Map).cast<String, double>(),
      progressionScheme: fields[10] as String,
      progressionRate: fields[11] as double,
      settings: (fields[12] as Map).cast<String, dynamic>(),
      createdAt: fields[13] as DateTime,
      completedAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LinearPeriodizationProgram obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.phases)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.currentWeek)
      ..writeByte(7)
      ..write(obj.currentPhaseId)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.baselineMaxes)
      ..writeByte(10)
      ..write(obj.progressionScheme)
      ..writeByte(11)
      ..write(obj.progressionRate)
      ..writeByte(12)
      ..write(obj.settings)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinearPeriodizationProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LinearPhaseAdapter extends TypeAdapter<LinearPhase> {
  @override
  final int typeId = 44;

  @override
  LinearPhase read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LinearPhase(
      id: fields[0] as String,
      name: fields[1] as String,
      phaseType: fields[2] as String,
      durationWeeks: fields[3] as int,
      startingIntensity: fields[4] as double,
      endingIntensity: fields[5] as double,
      startingVolume: fields[6] as int,
      endingVolume: fields[7] as int,
      repsPerSet: fields[8] as int,
      sessionsPerWeek: fields[9] as int,
      focusExercises: (fields[10] as List).cast<String>(),
      progressionRules: (fields[11] as Map).cast<String, dynamic>(),
      includeDeload: fields[12] as bool,
      startDate: fields[13] as DateTime?,
      endDate: fields[14] as DateTime?,
      status: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LinearPhase obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phaseType)
      ..writeByte(3)
      ..write(obj.durationWeeks)
      ..writeByte(4)
      ..write(obj.startingIntensity)
      ..writeByte(5)
      ..write(obj.endingIntensity)
      ..writeByte(6)
      ..write(obj.startingVolume)
      ..writeByte(7)
      ..write(obj.endingVolume)
      ..writeByte(8)
      ..write(obj.repsPerSet)
      ..writeByte(9)
      ..write(obj.sessionsPerWeek)
      ..writeByte(10)
      ..write(obj.focusExercises)
      ..writeByte(11)
      ..write(obj.progressionRules)
      ..writeByte(12)
      ..write(obj.includeDeload)
      ..writeByte(13)
      ..write(obj.startDate)
      ..writeByte(14)
      ..write(obj.endDate)
      ..writeByte(15)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinearPhaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LinearProgressionEntryAdapter extends TypeAdapter<LinearProgressionEntry> {
  @override
  final int typeId = 45;

  @override
  LinearProgressionEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LinearProgressionEntry(
      id: fields[0] as String,
      programId: fields[1] as String,
      phaseId: fields[2] as String,
      weekNumber: fields[3] as int,
      timestamp: fields[4] as DateTime,
      workingMaxes: (fields[5] as Map).cast<String, double>(),
      actualPerformance: (fields[6] as Map).cast<String, double>(),
      plannedIntensity: fields[7] as double,
      actualIntensity: fields[8] as double,
      plannedVolume: fields[9] as int,
      actualVolume: fields[10] as int,
      notes: fields[11] as String?,
      deloadWeek: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LinearProgressionEntry obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.programId)
      ..writeByte(2)
      ..write(obj.phaseId)
      ..writeByte(3)
      ..write(obj.weekNumber)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.workingMaxes)
      ..writeByte(6)
      ..write(obj.actualPerformance)
      ..writeByte(7)
      ..write(obj.plannedIntensity)
      ..writeByte(8)
      ..write(obj.actualIntensity)
      ..writeByte(9)
      ..write(obj.plannedVolume)
      ..writeByte(10)
      ..write(obj.actualVolume)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.deloadWeek);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinearProgressionEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
