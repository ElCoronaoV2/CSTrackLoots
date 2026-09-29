import '../models/rank_snapshot.dart';
import '../models/value_snapshot.dart';
import 'hive_service.dart';

/// Registra snapshots diarios (valor del inventario, rango por cuenta) para
/// los gráficos de evolución del dashboard de estadísticas. No hay datos
/// históricos previos a este feature: las gráficas empiezan a acumular
/// puntos desde que se instala esta versión.
class StatsService {
  /// Guarda el valor total de hoy si todavía no se ha registrado uno. Llamar
  /// una vez al arrancar la app (igual que el chequeo de reset semanal).
  static Future<void> recordDailySnapshotIfNeeded() async {
    final key = _todayKey();
    final box = HiveService.valueSnapshotsBox;
    if (box.containsKey(key)) return;

    double eur = 0;
    double usd = 0;
    for (final item in HiveService.inventoryBox.values) {
      if (item.sold) continue;
      eur += item.priceEur * item.quantity;
      usd += item.priceUsd * item.quantity;
    }

    await box.put(
      key,
      ValueSnapshot(date: DateTime.now(), totalEur: eur, totalUsd: usd),
    );
  }

  /// Guarda el Premier Rating de hoy de cada cuenta, si todavía no se ha
  /// registrado uno para ese día. Llamar una vez al arrancar la app.
  static Future<void> recordDailyRankSnapshotsIfNeeded() async {
    final box = HiveService.rankSnapshotsBox;
    final today = _todayKey();
    for (final acc in HiveService.accountsBox.values) {
      final key = '${acc.id}|$today';
      if (box.containsKey(key)) continue;
      await box.put(
        key,
        RankSnapshot(
          accountId: acc.id,
          date: DateTime.now(),
          premierRating: acc.premierRating,
        ),
      );
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}
