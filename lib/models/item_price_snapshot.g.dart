// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_price_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemPriceSnapshotAdapter extends TypeAdapter<ItemPriceSnapshot> {
  @override
  final int typeId = 12;

  @override
  ItemPriceSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemPriceSnapshot(
      marketHashName: fields[0] as String,
      date: fields[1] as DateTime,
      priceEur: fields[2] as double,
      priceUsd: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ItemPriceSnapshot obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.marketHashName)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.priceEur)
      ..writeByte(3)
      ..write(obj.priceUsd);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemPriceSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
