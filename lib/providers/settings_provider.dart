import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
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

  /// Guarda la Steam Web API key + SteamID64 del usuario. Se persisten
  /// solo en este dispositivo (Hive local), nunca en el repositorio.
  Future<void> setSteamCredentials({
    required String apiKey,
    required String steamId64,
  }) =>
      _update((s) => s.copyWith(steamApiKey: apiKey, steamId64: steamId64));

  Future<void> clearSteamCredentials() =>
      _update((s) => s.clearSteamCredentials());
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
