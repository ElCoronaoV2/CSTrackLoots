// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 4;

  @override
  InventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryItem(
      id: fields[0] as String,
      accountId: fields[1] as String,
      accountName: fields[2] as String,
      itemName: fields[3] as String,
      category: fields[4] as ItemCategory,
      priceEur: fields[5] as double,
      priceUsd: fields[6] as double,
      obtainedAt: fields[7] as DateTime?,
      sold: fields[8] as bool,
      soldAt: fields[9] as DateTime?,
      quantity: fields[10] as int,
      // Campos añadidos después del primer release: los registros
      // guardados antes de esto no tienen estas keys, así que se leen
      // como null y caen a sus valores por defecto.
      floatValue: fields[11] as double?,
      wear: fields[12] as SkinWear?,
      statTrak: fields[13] as bool? ?? false,
      stickers: (fields[14] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.accountName)
      ..writeByte(3)
      ..write(obj.itemName)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.priceEur)
      ..writeByte(6)
      ..write(obj.priceUsd)
      ..writeByte(7)
      ..write(obj.obtainedAt)
      ..writeByte(8)
      ..write(obj.sold)
      ..writeByte(9)
      ..write(obj.soldAt)
      ..writeByte(10)
      ..write(obj.quantity)
      ..writeByte(11)
      ..write(obj.floatValue)
      ..writeByte(12)
      ..write(obj.wear)
      ..writeByte(13)
      ..write(obj.statTrak)
      ..writeByte(14)
      ..write(obj.stickers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemCategoryAdapter extends TypeAdapter<ItemCategory> {
  @override
  final int typeId = 3;

  @override
  ItemCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemCategory.caseBox;
      case 1:
        return ItemCategory.skin;
      case 2:
        return ItemCategory.graffiti;
      case 3:
        return ItemCategory.knife;
      case 4:
        return ItemCategory.glove;
      case 5:
        return ItemCategory.other;
      default:
        return ItemCategory.caseBox;
    }
  }

  @override
  void write(BinaryWriter writer, ItemCategory obj) {
    switch (obj) {
      case ItemCategory.caseBox:
        writer.writeByte(0);
        break;
      case ItemCategory.skin:
        writer.writeByte(1);
        break;
      case ItemCategory.graffiti:
        writer.writeByte(2);
        break;
      case ItemCategory.knife:
        writer.writeByte(3);
        break;
      case ItemCategory.glove:
        writer.writeByte(4);
        break;
      case ItemCategory.other:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SkinWearAdapter extends TypeAdapter<SkinWear> {
  @override
  final int typeId = 8;

  @override
  SkinWear read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SkinWear.factoryNew;
      case 1:
        return SkinWear.minimalWear;
      case 2:
        return SkinWear.fieldTested;
      case 3:
        return SkinWear.wellWorn;
      case 4:
        return SkinWear.battleScarred;
      default:
        return SkinWear.factoryNew;
    }
  }

  @override
  void write(BinaryWriter writer, SkinWear obj) {
    switch (obj) {
      case SkinWear.factoryNew:
        writer.writeByte(0);
        break;
      case SkinWear.minimalWear:
        writer.writeByte(1);
        break;
      case SkinWear.fieldTested:
        writer.writeByte(2);
        break;
      case SkinWear.wellWorn:
        writer.writeByte(3);
        break;
      case SkinWear.battleScarred:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkinWearAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
