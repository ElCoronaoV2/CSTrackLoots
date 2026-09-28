// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'value_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ValueSnapshotAdapter extends TypeAdapter<ValueSnapshot> {
  @override
  final int typeId = 9;

  @override
  ValueSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ValueSnapshot(
      date: fields[0] as DateTime,
      totalEur: fields[1] as double,
      totalUsd: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ValueSnapshot obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalEur)
      ..writeByte(2)
      ..write(obj.totalUsd);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
