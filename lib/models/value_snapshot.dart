import 'package:hive/hive.dart';

part 'value_snapshot.g.dart';

/// Snapshot diario del valor total del inventario (suma de items sin
/// vender), para poder graficar su evolución en el dashboard de
/// estadísticas. Se crea como mucho una vez al día, comprobado al abrir
/// la app (ver StatsService.recordDailySnapshotIfNeeded).
@HiveType(typeId: 9)
class ValueSnapshot extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double totalEur;

  @HiveField(2)
  final double totalUsd;

  ValueSnapshot({
    required this.date,
    required this.totalEur,
    required this.totalUsd,
  });
}
