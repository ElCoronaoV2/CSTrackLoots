import 'package:hive/hive.dart';

part 'app_settings.g.dart';

/// Ajustes persistentes del usuario.
@HiveType(typeId: 6)
class AppSettings extends HiveObject {
  @HiveField(0)
  String preferredCurrency; // 'EUR' o 'USD'

  @HiveField(1)
  bool notificationsEnabled;

  @HiveField(2)
  bool remind24hBeforeReset;

  /// Para recordar el último reset procesado (epoch ms) entre arranques.
  @HiveField(3)
  int lastProcessedResetEpochMs;

  /// Si está activo, se guarda automáticamente un backup JSON en el
  /// almacenamiento del dispositivo cada [autoBackupIntervalDays] días.
  @HiveField(4)
  bool autoBackupEnabled;

  @HiveField(5)
  int autoBackupIntervalDays;

  /// Epoch ms del último backup automático (0 = nunca).
  @HiveField(6)
  int lastAutoBackupEpochMs;

  AppSettings({
    this.preferredCurrency = 'EUR',
    this.notificationsEnabled = true,
    this.remind24hBeforeReset = true,
    this.lastProcessedResetEpochMs = 0,
    this.autoBackupEnabled = true,
    this.autoBackupIntervalDays = 7,
    this.lastAutoBackupEpochMs = 0,
  });

  AppSettings copyWith({
    String? preferredCurrency,
    bool? notificationsEnabled,
    bool? remind24hBeforeReset,
    int? lastProcessedResetEpochMs,
    bool? autoBackupEnabled,
    int? autoBackupIntervalDays,
    int? lastAutoBackupEpochMs,
  }) {
    return AppSettings(
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      remind24hBeforeReset:
          remind24hBeforeReset ?? this.remind24hBeforeReset,
      lastProcessedResetEpochMs:
          lastProcessedResetEpochMs ?? this.lastProcessedResetEpochMs,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupIntervalDays:
          autoBackupIntervalDays ?? this.autoBackupIntervalDays,
      lastAutoBackupEpochMs:
          lastAutoBackupEpochMs ?? this.lastAutoBackupEpochMs,
    );
  }
}
