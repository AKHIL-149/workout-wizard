// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExportConfigAdapter extends TypeAdapter<ExportConfig> {
  @override
  final int typeId = 32;

  @override
  ExportConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExportConfig(
      id: fields[0] as String,
      exportType: fields[1] as String,
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime,
      includedFields: (fields[4] as List).cast<String>(),
      programId: fields[5] as String?,
      exerciseId: fields[6] as String?,
      includeCharts: fields[7] as bool,
      includeStatistics: fields[8] as bool,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ExportConfig obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exportType)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.includedFields)
      ..writeByte(5)
      ..write(obj.programId)
      ..writeByte(6)
      ..write(obj.exerciseId)
      ..writeByte(7)
      ..write(obj.includeCharts)
      ..writeByte(8)
      ..write(obj.includeStatistics)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExportHistoryAdapter extends TypeAdapter<ExportHistory> {
  @override
  final int typeId = 33;

  @override
  ExportHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExportHistory(
      id: fields[0] as String,
      exportDate: fields[1] as DateTime,
      exportType: fields[2] as String,
      recordCount: fields[3] as int,
      filePath: fields[4] as String,
      fileSize: fields[5] as int,
      success: fields[6] as bool,
      errorMessage: fields[7] as String?,
      metadata: (fields[8] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExportHistory obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exportDate)
      ..writeByte(2)
      ..write(obj.exportType)
      ..writeByte(3)
      ..write(obj.recordCount)
      ..writeByte(4)
      ..write(obj.filePath)
      ..writeByte(5)
      ..write(obj.fileSize)
      ..writeByte(6)
      ..write(obj.success)
      ..writeByte(7)
      ..write(obj.errorMessage)
      ..writeByte(8)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
