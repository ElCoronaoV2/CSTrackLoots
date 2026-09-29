import 'package:hive/hive.dart';

part 'rank_snapshot.g.dart';

/// Snapshot diario del Premier Rating de una cuenta, para graficar su
/// evolución. Se crea como mucho uno por cuenta y día, comprobado al abrir
/// la app (ver StatsService.recordDailyRankSnapshotsIfNeeded).
@HiveType(typeId: 11)
class RankSnapshot extends HiveObject {
  @HiveField(0)
  final String accountId;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int premierRating;

  RankSnapshot({
    required this.accountId,
    required this.date,
    required this.premierRating,
  });
}
