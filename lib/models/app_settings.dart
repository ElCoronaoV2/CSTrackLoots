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

  AppSettings({
    this.preferredCurrency = 'EUR',
    this.notificationsEnabled = true,
    this.remind24hBeforeReset = true,
    this.lastProcessedResetEpochMs = 0,
  });
}
