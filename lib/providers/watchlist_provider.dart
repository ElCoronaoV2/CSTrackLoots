import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/inventory_item.dart';
import '../models/watchlist_item.dart';
import '../services/hive_service.dart';
import '../services/steam_market_service.dart';
import '../utils/market_hash_name.dart';
import 'services_providers.dart';

const _uuid = Uuid();

/// Notifier de la lista de seguimiento: items que el usuario NO tiene pero
/// quiere vigilar, con la misma alerta de precio que los items propios.
class WatchlistNotifier extends StateNotifier<List<WatchlistItem>> {
  WatchlistNotifier(this.ref) : super(<WatchlistItem>[]) {
    _load();
    HiveService.watchlistBox.listenable().addListener(_load);
  }

  final Ref ref;

  void _load() {
    final list = HiveService.watchlistBox.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    state = list;
  }

  @override
  void dispose() {
    HiveService.watchlistBox.listenable().removeListener(_load);
    super.dispose();
  }

  Future<WatchlistItem> addItem({
    required String itemName,
    required ItemCategory category,
    bool statTrak = false,
    SkinWear? wear,
  }) async {
    final entry = WatchlistItem(
      id: _uuid.v4(),
      itemName: itemName.trim(),
      category: category,
      statTrak: category.supportsWearDetails ? statTrak : false,
      wear: category.supportsWearDetails ? wear : null,
    );
    await HiveService.watchlistBox.put(entry.id, entry);
    _load();
    unawaited(_refreshOne(entry.id, force: true));
    return entry;
  }

  Future<void> removeItem(String id) async {
    await HiveService.watchlistBox.delete(id);
    _load();
  }

  /// Fija (o quita, con `threshold: null`) el umbral de alerta de precio.
  /// [below] = true avisa cuando el precio BAJE del umbral en vez de subir.
  /// Resetea `alerted` para que un umbral nuevo pueda volver a disparar.
  Future<void> setAlertThreshold(
    String id, {
    required String currency,
    required double? threshold,
    bool below = false,
  }) async {
    final item = HiveService.watchlistBox.get(id);
    if (item == null) return;
    item.alertThreshold = threshold;
    item.alertCurrency = currency;
    item.alertBelow = below;
    item.alerted = false;
    try {
      await item.save();
    } catch (_) {}
    _load();
  }

  Future<void> _checkPriceAlert(WatchlistItem item) async {
    final threshold = item.alertThreshold;
    if (threshold == null) return;
    final currency = item.alertCurrency ?? 'EUR';
    final price = currency == 'USD' ? item.priceUsd : item.priceEur;
    final crossed = item.alertBelow ? price <= threshold : price >= threshold;
    if (crossed) {
      if (!item.alerted) {
        item.alerted = true;
        try {
          await item.save();
        } catch (_) {}
        try {
          await ref.read(notificationServiceProvider).showPriceAlert(
                itemId: item.id,
                itemName: item.itemName,
                price: price,
                currency: currency,
                below: item.alertBelow,
              );
        } catch (_) {}
      }
    } else if (item.alerted) {
      item.alerted = false;
      try {
        await item.save();
      } catch (_) {}
    }
  }

  Future<void> _refreshOne(String id, {bool force = false}) async {
    final item = HiveService.watchlistBox.get(id);
    if (item == null) return;
    final market = ref.read(steamMarketServiceProvider);
    final hashName = buildMarketHashName(
      baseName: item.itemName,
      statTrak: item.statTrak,
      wear: item.wear,
    );
    try {
      final price = await market.getPrice(hashName, forceRefresh: force);
      if (price.status == PriceStatus.fresh && item.isInBox) {
        item.priceEur = price.priceEur;
        item.priceUsd = price.priceUsd;
        try {
          await item.save();
        } catch (_) {}
        await _checkPriceAlert(item);
      }
    } catch (_) {/* silencio */}
    _load();
  }

  Future<void> refreshOne(String id) => _refreshOne(id, force: true);

  /// Recarga los precios de toda la watchlist. [onProgress] recibe (done, total).
  Future<void> refreshAll({void Function(int done, int total)? onProgress}) async {
    final items = state.toList();
    final total = items.length;
    var done = 0;
    for (final item in items) {
      await _refreshOne(item.id, force: true);
      done++;
      onProgress?.call(done, total);
    }
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<WatchlistItem>>(
        (ref) => WatchlistNotifier(ref));
