// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WatchlistItemAdapter extends TypeAdapter<WatchlistItem> {
  @override
  final int typeId = 10;

  @override
  WatchlistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WatchlistItem(
      id: fields[0] as String,
      itemName: fields[1] as String,
      category: fields[2] as ItemCategory,
      statTrak: fields[3] as bool,
      wear: fields[4] as SkinWear?,
      priceEur: fields[5] as double,
      priceUsd: fields[6] as double,
      addedAt: fields[7] as DateTime,
      alertThreshold: fields[8] as double?,
      alertCurrency: fields[9] as String?,
      alerted: fields[10] as bool,
      alertBelow: fields[11] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, WatchlistItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.statTrak)
      ..writeByte(4)
      ..write(obj.wear)
      ..writeByte(5)
      ..write(obj.priceEur)
      ..writeByte(6)
      ..write(obj.priceUsd)
      ..writeByte(7)
      ..write(obj.addedAt)
      ..writeByte(8)
      ..write(obj.alertThreshold)
      ..writeByte(9)
      ..write(obj.alertCurrency)
      ..writeByte(10)
      ..write(obj.alerted)
      ..writeByte(11)
      ..write(obj.alertBelow);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchlistItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
