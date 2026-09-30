import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/app_lock_service.dart';
import '../services/hive_service.dart';

/// Estado de los ajustes expuesto a la UI.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(HiveService.settings);

  /// Aplica `update` sobre una copia nueva del estado y la persiste.
  /// Usar siempre copyWith (nunca mutar `state` in-place): StateNotifier
  /// compara por identidad, así que reasignar una instancia distinta es lo
  /// que hace que los widgets que observan este provider se actualicen.
  Future<void> _update(AppSettings Function(AppSettings) update) async {
    state = update(state);
    await HiveService.settingsBox.put(HiveService.settingsKey, state);
  }

  Future<void> setCurrency(String currency) =>
      _update((s) => s.copyWith(preferredCurrency: currency));

  Future<void> setNotificationsEnabled(bool enabled) =>
      _update((s) => s.copyWith(notificationsEnabled: enabled));

  Future<void> setAutoBackupEnabled(bool enabled) =>
      _update((s) => s.copyWith(autoBackupEnabled: enabled));

  /// Guarda la Steam Web API key del usuario (una sola, global: sirve para
  /// consultar el SteamID64 de cualquiera de sus cuentas). Se persiste
  /// solo en este dispositivo (Hive local), nunca en el repositorio.
  Future<void> setSteamApiKey(String apiKey) =>
      _update((s) => s.copyWith(steamApiKey: apiKey));

  Future<void> clearSteamApiKey() => _update((s) => s.clearSteamApiKey());

  /// Configura un PIN nuevo (lo hashea, nunca se guarda en claro) y activa
  /// el bloqueo de la app.
  Future<void> setPin(String pin) => _update(
        (s) => s.copyWith(
          pinHash: AppLockService().hashPin(pin),
          appLockEnabled: true,
        ),
      );

  /// Quita el PIN configurado y desactiva el bloqueo (y la huella, que
  /// necesita un PIN de respaldo).
  Future<void> clearPin() => _update((s) => s.clearPin());

  Future<void> setAppLockEnabled(bool enabled) =>
      _update((s) => s.copyWith(appLockEnabled: enabled));

  Future<void> setBiometricEnabled(bool enabled) =>
      _update((s) => s.copyWith(biometricEnabled: enabled));
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
