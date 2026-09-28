import 'package:hive/hive.dart';

part 'price_cache_entry.g.dart';

/// Entrada de caché para precios de Steam Market.
///   - Precio: TTL 2h.
///   - Icono: TTL 30 días (no cambia casi nunca).
@HiveType(typeId: 5)
class PriceCacheEntry extends HiveObject {
  @HiveField(0)
  final String marketHashName;

  @HiveField(1)
  double priceEur;

  @HiveField(2)
  double priceUsd;

  @HiveField(3)
  DateTime fetchedAt;

  /// Si la última consulta a Steam falló, lo marcamos para no spammear.
  @HiveField(4)
  bool failed;

  /// URL del icono en el CDN de Steam (community.akamai.steamstatic.com).
  /// String vacía si no se pudo obtener.
  @HiveField(5)
  String iconUrl;

  /// Última vez que se intentó resolver el icono (TTL 30 días).
  @HiveField(6)
  DateTime? iconFetchedAt;

  PriceCacheEntry({
    required this.marketHashName,
    this.priceEur = 0.0,
    this.priceUsd = 0.0,
    DateTime? fetchedAt,
    this.failed = false,
    this.iconUrl = '',
    this.iconFetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// TTL de 2 horas para entradas válidas; las fallidas se vuelven a intentar en 15 min.
  bool get isFresh => DateTime.now().difference(fetchedAt) < const Duration(hours: 2);
  bool get isFailedFresh =>
      DateTime.now().difference(fetchedAt) < const Duration(minutes: 15);

  /// TTL 30 días para el icono. Si nunca se resolvió, hay que consultar.
  bool get hasIcon =>
      iconUrl.isNotEmpty &&
      iconFetchedAt != null &&
      DateTime.now().difference(iconFetchedAt!) < const Duration(days: 30);
}
