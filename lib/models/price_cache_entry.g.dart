// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceCacheEntryAdapter extends TypeAdapter<PriceCacheEntry> {
  @override
  final int typeId = 5;

  @override
  PriceCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceCacheEntry(
      marketHashName: fields[0] as String,
      priceEur: fields[1] as double,
      priceUsd: fields[2] as double,
      fetchedAt: fields[3] as DateTime?,
      failed: fields[4] as bool,
      iconUrl: fields[5] as String,
      iconFetchedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PriceCacheEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.marketHashName)
      ..writeByte(1)
      ..write(obj.priceEur)
      ..writeByte(2)
      ..write(obj.priceUsd)
      ..writeByte(3)
      ..write(obj.fetchedAt)
      ..writeByte(4)
      ..write(obj.failed)
      ..writeByte(5)
      ..write(obj.iconUrl)
      ..writeByte(6)
      ..write(obj.iconFetchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
