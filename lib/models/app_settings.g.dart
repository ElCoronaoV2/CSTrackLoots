// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      preferredCurrency: fields[0] as String,
      notificationsEnabled: fields[1] as bool,
      remind24hBeforeReset: fields[2] as bool,
      lastProcessedResetEpochMs: fields[3] as int,
      // Añadidos después del primer release: registros guardados antes de
      // esto no tienen estas keys, así que caen a sus valores por defecto.
      autoBackupEnabled: fields[4] as bool? ?? true,
      autoBackupIntervalDays: fields[5] as int? ?? 7,
      lastAutoBackupEpochMs: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.preferredCurrency)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.remind24hBeforeReset)
      ..writeByte(3)
      ..write(obj.lastProcessedResetEpochMs)
      ..writeByte(4)
      ..write(obj.autoBackupEnabled)
      ..writeByte(5)
      ..write(obj.autoBackupIntervalDays)
      ..writeByte(6)
      ..write(obj.lastAutoBackupEpochMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
