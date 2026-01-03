// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_rating.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgramRatingAdapter extends TypeAdapter<ProgramRating> {
  @override
  final int typeId = 25;

  @override
  ProgramRating read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgramRating(
      id: fields[0] as String,
      programId: fields[1] as String,
      programName: fields[2] as String,
      userId: fields[3] as String,
      userName: fields[4] as String,
      rating: fields[5] as int,
      review: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
      tags: (fields[9] as List).cast<String>(),
      helpfulCount: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProgramRating obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.programId)
      ..writeByte(2)
      ..write(obj.programName)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.userName)
      ..writeByte(5)
      ..write(obj.rating)
      ..writeByte(6)
      ..write(obj.review)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.helpfulCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramRatingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CommunityProgramMetaAdapter extends TypeAdapter<CommunityProgramMeta> {
  @override
  final int typeId = 26;

  @override
  CommunityProgramMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommunityProgramMeta(
      programId: fields[0] as String,
      programName: fields[1] as String,
      addedAt: fields[2] as DateTime,
      addedBy: fields[3] as String,
      downloadCount: fields[4] as int,
      ratingCount: fields[5] as int,
      averageRating: fields[6] as double,
      topTags: (fields[7] as List).cast<String>(),
      isFeatured: fields[8] as bool,
      featuredReason: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CommunityProgramMeta obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.programId)
      ..writeByte(1)
      ..write(obj.programName)
      ..writeByte(2)
      ..write(obj.addedAt)
      ..writeByte(3)
      ..write(obj.addedBy)
      ..writeByte(4)
      ..write(obj.downloadCount)
      ..writeByte(5)
      ..write(obj.ratingCount)
      ..writeByte(6)
      ..write(obj.averageRating)
      ..writeByte(7)
      ..write(obj.topTags)
      ..writeByte(8)
      ..write(obj.isFeatured)
      ..writeByte(9)
      ..write(obj.featuredReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityProgramMetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
