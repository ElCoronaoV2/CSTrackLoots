// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rank_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RankSnapshotAdapter extends TypeAdapter<RankSnapshot> {
  @override
  final int typeId = 11;

  @override
  RankSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RankSnapshot(
      accountId: fields[0] as String,
      date: fields[1] as DateTime,
      premierRating: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RankSnapshot obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.accountId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.premierRating);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
