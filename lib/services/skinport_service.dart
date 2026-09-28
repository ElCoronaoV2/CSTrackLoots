import 'package:dio/dio.dart';

/// Precio de un item en Skinport, en la moneda consultada.
class SkinportPrice {
  final double minPrice;
  final double suggestedPrice;
  const SkinportPrice({required this.minPrice, required this.suggestedPrice});
}

/// Cliente para el catálogo público de Skinport (`GET /v1/items`).
///
/// Ese endpoint no pide API key, pero devuelve TODO el catálogo de golpe
/// (no se puede consultar un item suelto), así que se cachea en memoria
/// unas horas y se busca en local por `market_hash_name`.
///
/// Aviso: Skinport protege este endpoint con Cloudflare bot-management;
/// peticiones automatizadas pueden recibir 403 de forma intermitente. Si
/// pasa, [getPrice] devuelve `null` sin lanzar excepción — el precio de
/// Steam sigue funcionando igual, este es solo un dato complementario.
class SkinportService {
  SkinportService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {
            'Accept-Encoding': 'br',
            'Accept': 'application/json',
          },
        ));

  final Dio _dio;
  static const _itemsUrl = 'https://api.skinport.com/v1/items';
  static const _catalogTtl = Duration(hours: 4);

  Map<String, SkinportPrice>? _catalog;
  String? _catalogCurrency;
  DateTime? _fetchedAt;
  Future<Map<String, SkinportPrice>?>? _inFlight;

  bool get _isFresh =>
      _catalog != null &&
      _fetchedAt != null &&
      DateTime.now().difference(_fetchedAt!) < _catalogTtl;

  /// Precio en Skinport para `marketHashName`, o `null` si el catálogo no
  /// se pudo obtener (bloqueado, sin red...) o el item no está listado.
  Future<SkinportPrice?> getPrice(
    String marketHashName, {
    String currency = 'EUR',
  }) async {
    final catalog = await _catalogFor(currency);
    return catalog?[marketHashName];
  }

  Future<Map<String, SkinportPrice>?> _catalogFor(String currency) {
    if (_isFresh && _catalogCurrency == currency) {
      return Future.value(_catalog);
    }
    // Evita disparar varias peticiones en paralelo si se piden varios
    // precios casi a la vez (p.ej. varios items abiertos seguidos).
    return _inFlight ??=
        _fetchCatalog(currency).whenComplete(() => _inFlight = null);
  }

  Future<Map<String, SkinportPrice>?> _fetchCatalog(String currency) async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        _itemsUrl,
        queryParameters: <String, dynamic>{
          'app_id': 730,
          'currency': currency,
          'tradable': 0,
        },
      );
      final data = resp.data;
      if (resp.statusCode != 200 || data == null) return null;

      final map = <String, SkinportPrice>{};
      for (final raw in data) {
        if (raw is! Map) continue;
        final name = raw['market_hash_name'] as String?;
        if (name == null) continue;
        final min = (raw['min_price'] as num?)?.toDouble();
        final suggested = (raw['suggested_price'] as num?)?.toDouble();
        if (min == null && suggested == null) continue;
        map[name] = SkinportPrice(
          minPrice: min ?? suggested!,
          suggestedPrice: suggested ?? min!,
        );
      }
      _catalog = map;
      _catalogCurrency = currency;
      _fetchedAt = DateTime.now();
      return map;
    } catch (_) {
      return null;
    }
  }
}
