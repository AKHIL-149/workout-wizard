// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_periodization.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlockPeriodizationProgramAdapter
    extends TypeAdapter<BlockPeriodizationProgram> {
  @override
  final int typeId = 40;

  @override
  BlockPeriodizationProgram read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockPeriodizationProgram(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      blocks: (fields[3] as List).cast<TrainingBlock>(),
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime?,
      currentBlockId: fields[6] as String,
      currentBlockIndex: fields[7] as int,
      isActive: fields[8] as bool,
      autoProgress: fields[9] as bool,
      settings: (fields[10] as Map).cast<String, dynamic>(),
      createdAt: fields[11] as DateTime,
      completedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BlockPeriodizationProgram obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.blocks)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.currentBlockId)
      ..writeByte(7)
      ..write(obj.currentBlockIndex)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.autoProgress)
      ..writeByte(10)
      ..write(obj.settings)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockPeriodizationProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrainingBlockAdapter extends TypeAdapter<TrainingBlock> {
  @override
  final int typeId = 41;

  @override
  TrainingBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingBlock(
      id: fields[0] as String,
      name: fields[1] as String,
      blockType: fields[2] as String,
      durationWeeks: fields[3] as int,
      sessionsPerWeek: fields[4] as int,
      intensityMin: fields[5] as double,
      intensityMax: fields[6] as double,
      repsMin: fields[7] as int,
      repsMax: fields[8] as int,
      setsPerExercise: fields[9] as int,
      restSeconds: fields[10] as int,
      focusExercises: (fields[11] as List).cast<String>(),
      progressionRules: (fields[12] as Map).cast<String, dynamic>(),
      includeDeload: fields[13] as bool,
      startDate: fields[14] as DateTime?,
      endDate: fields[15] as DateTime?,
      status: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingBlock obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.blockType)
      ..writeByte(3)
      ..write(obj.durationWeeks)
      ..writeByte(4)
      ..write(obj.sessionsPerWeek)
      ..writeByte(5)
      ..write(obj.intensityMin)
      ..writeByte(6)
      ..write(obj.intensityMax)
      ..writeByte(7)
      ..write(obj.repsMin)
      ..writeByte(8)
      ..write(obj.repsMax)
      ..writeByte(9)
      ..write(obj.setsPerExercise)
      ..writeByte(10)
      ..write(obj.restSeconds)
      ..writeByte(11)
      ..write(obj.focusExercises)
      ..writeByte(12)
      ..write(obj.progressionRules)
      ..writeByte(13)
      ..write(obj.includeDeload)
      ..writeByte(14)
      ..write(obj.startDate)
      ..writeByte(15)
      ..write(obj.endDate)
      ..writeByte(16)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlockProgressionEntryAdapter extends TypeAdapter<BlockProgressionEntry> {
  @override
  final int typeId = 42;

  @override
  BlockProgressionEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockProgressionEntry(
      id: fields[0] as String,
      programId: fields[1] as String,
      blockId: fields[2] as String,
      timestamp: fields[3] as DateTime,
      weekNumber: fields[4] as int,
      eventType: fields[5] as String,
      metrics: (fields[6] as Map).cast<String, dynamic>(),
      notes: fields[7] as String?,
      performanceData: (fields[8] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, BlockProgressionEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.programId)
      ..writeByte(2)
      ..write(obj.blockId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.weekNumber)
      ..writeByte(5)
      ..write(obj.eventType)
      ..writeByte(6)
      ..write(obj.metrics)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.performanceData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockProgressionEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
