import 'hive_service.dart';
import 'notification_service.dart';
import 'weekly_reset_service.dart';

/// Orquesta el ciclo semanal:
/// - Detecta si hemos cruzado un reset y, en ese caso, marca todas las cuentas
///   como `dropObtainedThisWeek = false`.
/// - Actualiza las estadísticas por cuenta:
///   * `dropObtainedThisWeek = true` => suma a totalObtained + racha.
///   * `dropMissedThisWeek = true`   => suma a totalMissed, racha rota.
///   * pendiente sin marcar          => se cuenta como perdido (consistente
///     con "se te olvidó marcarlo").
/// - Reprograma las notificaciones del siguiente ciclo.
class DropCycleOrchestrator {
  DropCycleOrchestrator(this._resetService, this._notifications);

  final WeeklyResetService _resetService;
  final NotificationService _notifications;

  /// Llamar al arrancar la app.
  /// Devuelve `true` si se procesó un reset nuevo.
  Future<bool> runStartupCheck() async {
    final settings = HiveService.settings;
    final lastProcessed = settings.lastProcessedResetEpochMs;
    final lastReset = _resetService.lastReset();
    final lastResetMs = lastReset.millisecondsSinceEpoch;

    bool processedReset = false;
    if (lastProcessed < lastResetMs) {
      // Cruzamos un reset desde la última vez: consolidar estadísticas y reset
      // de estados de la semana.
      var obtained = 0;
      var missed = 0;
      for (final acc in HiveService.accountsBox.values) {
        if (acc.dropObtainedThisWeek) {
          obtained++;
        } else {
          missed++;
        }
        _updateStatsForAccount(acc);
        acc.dropObtainedThisWeek = false;
        acc.dropMissedThisWeek = false;
        try {
          await acc.save();
        } catch (_) {}
      }
      settings.lastProcessedResetEpochMs = lastResetMs;
      try {
        await settings.save();
      } catch (_) {}
      processedReset = true;

      // Solo tiene sentido el resumen si había al menos una cuenta activa
      // esa semana (evita la notificación vacía "0/0" en el primer arranque).
      if (settings.notificationsEnabled && (obtained + missed) > 0) {
        double totalValue = 0;
        for (final item in HiveService.inventoryBox.values) {
          if (item.sold) continue;
          totalValue += (settings.preferredCurrency == 'USD'
                  ? item.priceUsd
                  : item.priceEur) *
              item.quantity;
        }
        try {
          await _notifications.showWeeklySummary(
            obtained: obtained,
            missed: missed,
            totalValue: totalValue,
            currency: settings.preferredCurrency,
          );
        } catch (_) {}
      }
    }

    await _reschedule();

    return processedReset;
  }

  /// Aplica las reglas de estadística según el estado del drop al cierre de la
  /// semana:
  /// - marcado como obtenido -> +1 a obtenidos, racha sube (best si supera).
  /// - marcado como perdido  -> +1 a perdidos, racha rota.
  /// - sin marcar (pendiente) -> +1 a perdidos (se te olvidó), racha rota.
  void _updateStatsForAccount(dynamic acc) {
    if (acc.dropObtainedThisWeek) {
      acc.totalObtained = (acc.totalObtained as int) + 1;
      acc.currentStreak = (acc.currentStreak as int) + 1;
      if (acc.currentStreak > acc.bestStreak) {
        acc.bestStreak = acc.currentStreak;
      }
    } else {
      // Tanto "marcado perdido" como "no marcado" cuentan como drop perdido.
      acc.totalMissed = (acc.totalMissed as int) + 1;
      acc.currentStreak = 0;
    }
  }

  /// Llamar tras cambios de estado de drops (registrar drop / crear cuenta)
  /// para reprogramar el aviso de 24h con el estado actualizado.
  Future<void> rescheduleReminders() => _reschedule();

  Future<void> _reschedule() async {
    final settings = HiveService.settings;
    if (!settings.notificationsEnabled) {
      await _notifications.cancelAll();
      return;
    }
    final anyPending = HiveService.accountsBox.values
        .any((a) => !a.dropObtainedThisWeek && !a.dropMissedThisWeek);
    await _notifications.scheduleResetNotifications(anyPendingDrops: anyPending);
  }

  Future<void> disableNotifications() async {
    final settings = HiveService.settings;
    settings.notificationsEnabled = false;
    await settings.save();
    await _notifications.cancelAll();
  }

  Future<void> enableNotifications() async {
    final settings = HiveService.settings;
    settings.notificationsEnabled = true;
    await settings.save();
    await _reschedule();
  }
}
