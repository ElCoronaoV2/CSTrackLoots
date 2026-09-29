import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/price_cache_entry.dart';
import 'hive_service.dart';

/// Estado de un precio individual: ayuda a la UI a distinguir
/// "no se ha consultado todavía", "falló la consulta" y "Steam devolvió 0".
enum PriceStatus { fresh, cached, loading, notFound, failed }

class PriceResult {
  final String marketHashName;
  final double priceEur;
  final double priceUsd;
  final PriceStatus status;

  const PriceResult({
    required this.marketHashName,
    required this.priceEur,
    required this.priceUsd,
    required this.status,
  });

  bool get failed => status == PriceStatus.failed || status == PriceStatus.notFound;
}

/// Servicio para consultar precios e iconos en Steam Community Market.
///
/// Endpoints usados:
///   - Precio: `https://steamcommunity.com/market/priceoverview/?appid=730&currency={1|3}&market_hash_name=...`
///       (currency 1 = USD, 3 = EUR)
///   - Icono:  `https://steamcommunity.com/market/search/render/?norender=1&appid=730&query={name}&count=1`
///       Devuelve `asset_description.icon_url` (path). Se concatena con la base
///       del CDN: `https://community.akamai.steamstatic.com/economy/image/{icon_url}/128x128`
///
/// Caché local en Hive (`price_cache`) con TTL diferenciados:
///   - Precio: 2h.
///   - Icono: 30 días (no cambia).
/// Backoff ante HTTP 429: reutiliza la última entrada cacheada aunque esté vencida.
class SteamMarketService {
  SteamMarketService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    _dio.options.headers['User-Agent'] = 'cs2_tracker/1.0 (flutter app)';
  }

  /// True cuando la última consulta a Steam no pudo completarse (sin red,
  /// timeout o HTTP 429 sostenido). Un "not found" (item que no existe con
  /// ese nombre) SÍ es una respuesta válida de Steam, así que no cuenta como
  /// offline. La UI puede escuchar esto para mostrar un aviso de "sin conexión,
  /// mostrando precios en caché".
  final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  final Dio _dio;
  static const String _priceBase =
      'https://steamcommunity.com/market/priceoverview/';
  static const String _searchBase =
      'https://steamcommunity.com/market/search/render/';
  static const String _iconCdnBase =
      'https://community.akamai.steamstatic.com/economy/image/';

  /// Pausa mínima entre peticiones consecutivas a Steam. Steam bloquea
  /// temporalmente con HTTP 429 cuando un cliente hace muchas consultas en
  /// poco tiempo. 700ms es suficiente para la mayoría de lotes.
  static const Duration _throttle = Duration(milliseconds: 700);
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _respectThrottle() async {
    final elapsed = DateTime.now().difference(_lastRequest);
    if (elapsed < _throttle) {
      await Future<void>.delayed(_throttle - elapsed);
    }
    _lastRequest = DateTime.now();
  }

  /// Construye la URL completa del icono en el CDN de Steam a partir del path.
  /// Si el path ya es una URL completa, la devuelve tal cual.
  static String buildIconUrl(String iconPath) {
    final p = iconPath.trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return '$_iconCdnBase$p/128x128';
  }

  /// Convierte un string de precio tipo "1,23 €" o "$1.23" en double.
  /// Maneja tanto formato europeo (coma decimal) como anglosajón.
  static double parsePrice(String raw) {
    if (raw.isEmpty) return 0.0;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9,.\-]'), '').trim();
    if (cleaned.isEmpty) return 0.0;
    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');
    String normalized;
    if (hasComma && hasDot) {
      if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
        normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = cleaned.replaceAll(',', '');
      }
    } else if (hasComma) {
      normalized = cleaned.replaceAll(',', '.');
    } else {
      normalized = cleaned;
    }
    return double.tryParse(normalized) ?? 0.0;
  }

  /// Devuelve el precio de un item.
  ///
  /// - [forceRefresh] = true ignora la caché (siempre consulta Steam).
  /// - [silent] = true suprime throttling (útil para reintentos tras error).
  ///
  /// Estados posibles (PriceStatus):
  /// - [PriceStatus.cached]: viene de caché fresca.
  /// - [PriceStatus.fresh]: consultado en Steam en este momento.
  /// - [PriceStatus.notFound]: Steam respondió success=false (el item no existe
  ///   o el nombre no es exacto, p.ej. falta el desgaste de una skin).
  /// - [PriceStatus.failed]: error de red o HTTP 429 sostenido.
  Future<PriceResult> getPrice(
    String marketHashName, {
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    final key = marketHashName.trim();
    if (key.isEmpty) {
      return const PriceResult(
        marketHashName: '',
        priceEur: 0,
        priceUsd: 0,
        status: PriceStatus.failed,
      );
    }

    final box = HiveService.priceCacheBox;
    final cached = box.get(key);

    // Si hay caché fresca válida, devuélvela (a no ser que pidan forceRefresh).
    if (!forceRefresh && cached != null && !cached.failed && cached.isFresh) {
      return PriceResult(
        marketHashName: key,
        priceEur: cached.priceEur,
        priceUsd: cached.priceUsd,
        status: PriceStatus.cached,
      );
    }
    if (!forceRefresh && cached != null && cached.failed && cached.isFailedFresh) {
      // Backoff reciente: devolvemos lo último que tengamos (puede ser 0).
      return PriceResult(
        marketHashName: key,
        priceEur: cached.priceEur,
        priceUsd: cached.priceUsd,
        status: PriceStatus.failed,
      );
    }

    if (!silent) await _respectThrottle();

    double newEur = 0.0;
    double newUsd = 0.0;
    bool anySuccess = false;
    bool anyNotFound = false;
    bool anyRateLimit = false;

    Future<(double, PriceStatus)> fetch(String currency) async {
      try {
        final resp = await _dio.get(
          _priceBase,
          queryParameters: <String, dynamic>{
            'appid': 730,
            'currency': currency,
            'market_hash_name': key,
          },
          options: Options(responseType: ResponseType.json),
        );
        if (resp.statusCode == 200 && resp.data is Map) {
          final data = resp.data as Map;
          final success = data['success'] == true;
          if (!success) return (0.0, PriceStatus.notFound);
          final priceStr =
              (data['median_price'] ?? data['lowest_price'] ?? '') as String;
          return (parsePrice(priceStr), PriceStatus.fresh);
        }
        if (resp.statusCode == 429) {
          anyRateLimit = true;
          return (0.0, PriceStatus.failed);
        }
        return (0.0, PriceStatus.failed);
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          anyRateLimit = true;
        }
        return (0.0, PriceStatus.failed);
      } catch (_) {
        return (0.0, PriceStatus.failed);
      }
    }

    final results = await Future.wait([
      fetch('3'), // EUR
      fetch('1'), // USD
    ]);
    newEur = results[0].$1;
    newUsd = results[1].$1;
    final eurStatus = results[0].$2;
    final usdStatus = results[1].$2;

    // Si Steam devolvió success=false en alguna moneda, el item no existe
    // con ese nombre exacto (frecuente en skins sin desgaste).
    if (eurStatus == PriceStatus.notFound || usdStatus == PriceStatus.notFound) {
      anyNotFound = true;
    }
    anySuccess = eurStatus == PriceStatus.fresh || usdStatus == PriceStatus.fresh;

    // Éxito o "no encontrado" son ambos respuestas reales de Steam: prueban
    // que hay conexión, aunque el segundo caso no encuentre el item.
    if (anySuccess || anyNotFound) offline.value = false;

    // HTTP 429 con caché previa: actualizamos marca de fallo pero conservamos
    // el último precio conocido para no mostrar guiones a la primera.
    if (anyRateLimit && !anySuccess && cached != null) {
      offline.value = true;
      final updated = PriceCacheEntry(
        marketHashName: key,
        priceEur: cached.priceEur,
        priceUsd: cached.priceUsd,
        fetchedAt: DateTime.now(),
        failed: true,
        iconUrl: cached.iconUrl,
        iconFetchedAt: cached.iconFetchedAt,
      );
      await box.put(key, updated);
      return PriceResult(
        marketHashName: key,
        priceEur: cached.priceEur,
        priceUsd: cached.priceUsd,
        status: PriceStatus.failed,
      );
    }

    if (!anySuccess) {
      final newStatus =
          anyNotFound ? PriceStatus.notFound : PriceStatus.failed;
      if (newStatus == PriceStatus.failed) offline.value = true;
      final failed = PriceCacheEntry(
        marketHashName: key,
        priceEur: cached?.priceEur ?? 0,
        priceUsd: cached?.priceUsd ?? 0,
        fetchedAt: DateTime.now(),
        failed: true,
        iconUrl: cached?.iconUrl ?? '',
        iconFetchedAt: cached?.iconFetchedAt,
      );
      await box.put(key, failed);
      return PriceResult(
        marketHashName: key,
        priceEur: failed.priceEur,
        priceUsd: failed.priceUsd,
        status: newStatus,
      );
    }

    final entry = PriceCacheEntry(
      marketHashName: key,
      priceEur: newEur,
      priceUsd: newUsd,
      fetchedAt: DateTime.now(),
      failed: false,
      iconUrl: cached?.iconUrl ?? '',
      iconFetchedAt: cached?.iconFetchedAt,
    );
    await box.put(key, entry);

    return PriceResult(
      marketHashName: key,
      priceEur: newEur,
      priceUsd: newUsd,
      status: PriceStatus.fresh,
    );
  }

  /// Devuelve la URL del icono del item, usando caché de 30 días.
  /// Devuelve string vacío si no se pudo obtener.
  ///
  /// [forceRefresh] = true ignora la caché de icono.
  Future<String> getIconUrl(
    String marketHashName, {
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    final key = marketHashName.trim();
    if (key.isEmpty) return '';

    final box = HiveService.priceCacheBox;
    final cached = box.get(key);

    if (!forceRefresh && cached != null && cached.hasIcon) {
      return cached.iconUrl;
    }

    if (!silent) await _respectThrottle();

    try {
      final resp = await _dio.get(
        _searchBase,
        queryParameters: <String, dynamic>{
          'norender': 1,
          'appid': 730,
          'query': key,
          'count': 1,
        },
        options: Options(responseType: ResponseType.json),
      );
      if (resp.statusCode != 200 || resp.data is! Map) {
        return cached?.iconUrl ?? '';
      }

      final data = resp.data as Map;
      final results = data['results'];
      if (results is! List || results.isEmpty) return cached?.iconUrl ?? '';

      final first = results.first;
      if (first is! Map) return cached?.iconUrl ?? '';

      String? iconPath;
      final assetDesc = first['asset_description'];
      if (assetDesc is Map && assetDesc['icon_url'] is String) {
        iconPath = assetDesc['icon_url'] as String;
      } else if (first['icon_url'] is String) {
        iconPath = first['icon_url'] as String;
      }

      if (iconPath == null || iconPath.isEmpty) return cached?.iconUrl ?? '';

      final fullUrl = buildIconUrl(iconPath);

      final entry = PriceCacheEntry(
        marketHashName: key,
        priceEur: cached?.priceEur ?? 0,
        priceUsd: cached?.priceUsd ?? 0,
        fetchedAt: cached?.fetchedAt ?? DateTime.now(),
        failed: cached?.failed ?? false,
        iconUrl: fullUrl,
        iconFetchedAt: DateTime.now(),
      );
      await box.put(key, entry);
      return fullUrl;
    } on DioException {
      return cached?.iconUrl ?? '';
    } catch (_) {
      return cached?.iconUrl ?? '';
    }
  }
}
