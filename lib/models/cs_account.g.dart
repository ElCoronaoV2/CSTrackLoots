// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cs_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CsAccountAdapter extends TypeAdapter<CsAccount> {
  @override
  final int typeId = 0;

  @override
  CsAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CsAccount(
      id: fields[0] as String,
      alias: fields[1] as String,
      dropObtainedThisWeek: fields[2] as bool,
      lastDropDate: fields[3] as DateTime?,
      premierRating: fields[4] as int,
      mapRanks: (fields[5] as Map?)?.cast<String, String>(),
      wingmanRank: fields[6] as String?,
      sortIndex: fields[7] as int,
      dropMissedThisWeek: fields[8] as bool,
      totalObtained: fields[9] as int,
      totalMissed: fields[10] as int,
      currentStreak: fields[11] as int,
      bestStreak: fields[12] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CsAccount obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.alias)
      ..writeByte(2)
      ..write(obj.dropObtainedThisWeek)
      ..writeByte(3)
      ..write(obj.lastDropDate)
      ..writeByte(4)
      ..write(obj.premierRating)
      ..writeByte(5)
      ..write(obj.mapRanks)
      ..writeByte(6)
      ..write(obj.wingmanRank)
      ..writeByte(7)
      ..write(obj.sortIndex)
      ..writeByte(8)
      ..write(obj.dropMissedThisWeek)
      ..writeByte(9)
      ..write(obj.totalObtained)
      ..writeByte(10)
      ..write(obj.totalMissed)
      ..writeByte(11)
      ..write(obj.currentStreak)
      ..writeByte(12)
      ..write(obj.bestStreak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CsAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
