// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleRecordAdapter extends TypeAdapter<SaleRecord> {
  @override
  final int typeId = 7;

  @override
  SaleRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleRecord(
      itemId: fields[0] as String,
      itemName: fields[1] as String,
      categoryIndex: fields[2] as int,
      accountName: fields[3] as String,
      quantity: fields[4] as int,
      unitPriceEur: fields[5] as double,
      unitPriceUsd: fields[6] as double,
      soldAt: fields[7] as DateTime,
      unitCostEur: fields[8] as double? ?? 0.0,
      unitCostUsd: fields[9] as double? ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, SaleRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.categoryIndex)
      ..writeByte(3)
      ..write(obj.accountName)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.unitPriceEur)
      ..writeByte(6)
      ..write(obj.unitPriceUsd)
      ..writeByte(7)
      ..write(obj.soldAt)
      ..writeByte(8)
      ..write(obj.unitCostEur)
      ..writeByte(9)
      ..write(obj.unitCostUsd);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
