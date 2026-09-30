import 'package:hive/hive.dart';

part 'item_price_snapshot.g.dart';

/// Snapshot diario del precio de un item concreto (identificado por su
/// market_hash_name completo, con StatTrak™/desgaste incluidos), para
/// graficar su evolución. Se crea como mucho uno por item y día.
@HiveType(typeId: 12)
class ItemPriceSnapshot extends HiveObject {
  @HiveField(0)
  final String marketHashName;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double priceEur;

  @HiveField(3)
  final double priceUsd;

  ItemPriceSnapshot({
    required this.marketHashName,
    required this.date,
    required this.priceEur,
    required this.priceUsd,
  });
}
