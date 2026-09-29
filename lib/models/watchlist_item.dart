import 'package:hive/hive.dart';

import 'inventory_item.dart';

part 'watchlist_item.g.dart';

/// Item que el usuario NO tiene todavía pero quiere vigilar (precio, para
/// decidir cuándo comprar o vender). No cuenta en el inventario ni en el
/// valor total: es solo una lista de seguimiento con alerta de precio,
/// reutilizando el mismo mecanismo de notificaciones que los items propios.
@HiveType(typeId: 10)
class WatchlistItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String itemName;

  @HiveField(2)
  ItemCategory category;

  @HiveField(3)
  bool statTrak;

  @HiveField(4)
  SkinWear? wear;

  @HiveField(5)
  double priceEur;

  @HiveField(6)
  double priceUsd;

  @HiveField(7)
  DateTime addedAt;

  /// Umbral de precio para la alerta (en la moneda [alertCurrency]).
  /// Null = sin alerta configurada para este item.
  @HiveField(8)
  double? alertThreshold;

  @HiveField(9)
  String? alertCurrency;

  /// True si ya se notificó para el umbral actual (evita repetir la
  /// notificación en cada refresco). Se resetea si el precio vuelve a
  /// cruzar el umbral en sentido contrario, permitiendo re-alertar más tarde.
  @HiveField(10)
  bool alerted;

  /// True = avisar cuando el precio BAJE de [alertThreshold] (para comprar
  /// barato). False (por defecto) = avisar cuando SUBA.
  @HiveField(11)
  bool alertBelow;

  WatchlistItem({
    required this.id,
    required this.itemName,
    required this.category,
    this.statTrak = false,
    this.wear,
    this.priceEur = 0.0,
    this.priceUsd = 0.0,
    DateTime? addedAt,
    this.alertThreshold,
    this.alertCurrency,
    this.alerted = false,
    this.alertBelow = false,
  }) : addedAt = addedAt ?? DateTime.now();

  bool get supportsWearDetails => category.supportsWearDetails;
}
