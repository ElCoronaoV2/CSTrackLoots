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

  /// Steam Web API key del usuario (propia, gratuita, revocable en
  /// steamcommunity.com/dev/apikey). Se guarda SOLO en este dispositivo:
  /// nunca viaja al repositorio, a CI ni al APK distribuido.
  @HiveField(7)
  String? steamApiKey;

  AppSettings({
    this.preferredCurrency = 'EUR',
    this.notificationsEnabled = true,
    this.remind24hBeforeReset = true,
    this.lastProcessedResetEpochMs = 0,
    this.autoBackupEnabled = true,
    this.autoBackupIntervalDays = 7,
    this.lastAutoBackupEpochMs = 0,
    this.steamApiKey,
  });

  /// Copia el estado cambiando solo los campos indicados. Para borrar
  /// steamApiKey usa [clearSteamApiKey] en vez de esto: aquí un valor
  /// null en ese campo significa "no tocar".
  AppSettings copyWith({
    String? preferredCurrency,
    bool? notificationsEnabled,
    bool? remind24hBeforeReset,
    int? lastProcessedResetEpochMs,
    bool? autoBackupEnabled,
    int? autoBackupIntervalDays,
    int? lastAutoBackupEpochMs,
    String? steamApiKey,
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
      steamApiKey: steamApiKey ?? this.steamApiKey,
    );
  }

  /// Copia el estado quitando la API key guardada (a diferencia de
  /// [copyWith], aquí sí se puede poner a null explícitamente).
  AppSettings clearSteamApiKey() {
    return AppSettings(
      preferredCurrency: preferredCurrency,
      notificationsEnabled: notificationsEnabled,
      remind24hBeforeReset: remind24hBeforeReset,
      lastProcessedResetEpochMs: lastProcessedResetEpochMs,
      autoBackupEnabled: autoBackupEnabled,
      autoBackupIntervalDays: autoBackupIntervalDays,
      lastAutoBackupEpochMs: lastAutoBackupEpochMs,
    );
  }
}
