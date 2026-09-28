import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/hive_service.dart';

/// Estado de los ajustes expuesto a la UI.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(HiveService.settings);

  Future<void> setCurrency(String currency) async {
    state.preferredCurrency = currency;
    await state.save();
    state = AppSettings(
      preferredCurrency: currency,
      notificationsEnabled: state.notificationsEnabled,
      remind24hBeforeReset: state.remind24hBeforeReset,
      lastProcessedResetEpochMs: state.lastProcessedResetEpochMs,
    );
    // Necesitamos persistir también el nuevo objeto recién creado.
    await HiveService.settingsBox.put(HiveService.settingsKey, state);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state.notificationsEnabled = enabled;
    await HiveService.settingsBox.put(HiveService.settingsKey, state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
