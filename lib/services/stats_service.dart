import '../models/value_snapshot.dart';
import 'hive_service.dart';

/// Registra un snapshot diario del valor del inventario (para el gráfico de
/// evolución del dashboard de estadísticas). No hay datos históricos previos
/// a este feature: la gráfica empieza a acumular puntos desde que se instala
/// esta versión.
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

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}
