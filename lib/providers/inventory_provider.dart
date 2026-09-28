import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/cs_account.dart';
import '../models/inventory_item.dart';
import '../models/sale_record.dart';
import '../services/hive_service.dart';
import '../services/steam_market_service.dart';
import 'accounts_provider.dart';
import 'services_providers.dart';

const _uuid = Uuid();

/// Modos de ordenación del inventario.
enum InventorySort {
  dateDesc,
  dateAsc,
  priceDesc,
  priceAsc,
  nameAsc,
  nameDesc,
}

extension InventorySortLabel on InventorySort {
  String get label {
    switch (this) {
      case InventorySort.dateDesc:
        return 'Fecha (nuevo primero)';
      case InventorySort.dateAsc:
        return 'Fecha (antiguo primero)';
      case InventorySort.priceDesc:
        return 'Precio (mayor primero)';
      case InventorySort.priceAsc:
        return 'Precio (menor primero)';
      case InventorySort.nameAsc:
        return 'Nombre (A-Z)';
      case InventorySort.nameDesc:
        return 'Nombre (Z-A)';
    }
  }
}

/// Notifier del inventario. Mantiene cache en memoria sincronizado con Hive.
class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  InventoryNotifier(this.ref) : super(<InventoryItem>[]) {
    _load();
    HiveService.inventoryBox.listenable().addListener(_load);
  }

  final Ref ref;

  void _load() {
    final list = HiveService.inventoryBox.values.toList()
      ..sort((a, b) => b.obtainedAt.compareTo(a.obtainedAt));
    state = list;
  }

  @override
  void dispose() {
    HiveService.inventoryBox.listenable().removeListener(_load);
    super.dispose();
  }

  /// Busca un item sin vender con el mismo nombre (case-insensitive) en la
  /// misma cuenta, para apilar cantidades en vez de crear filas duplicadas
  /// (p.ej. 3 "Kilowatt Case" ya en inventario + 1 nuevo del drop = 1 fila x4).
  ///
  /// Las skins/cuchillos/guantes NUNCA se apilan aunque compartan nombre:
  /// cada uno es un item físicamente distinto (float, patrón, stickers
  /// propios), así que agruparlos perdería esa información.
  InventoryItem? _findStackable({
    required String name,
    required String accountId,
    required ItemCategory category,
  }) {
    if (category.supportsWearDetails) return null;
    final lower = name.toLowerCase();
    for (final item in HiveService.inventoryBox.values) {
      if (item.sold) continue;
      if (item.accountId != accountId) continue;
      if (item.itemName.trim().toLowerCase() == lower) return item;
    }
    return null;
  }

  /// Apila `qty` unidades sobre un item existente (mismo precio unitario;
  /// el total mostrado se recalcula solo con `quantity`), actualizando la
  /// fecha a la más reciente para que el stack suba al tope del listado.
  Future<InventoryItem> _stackOnto(
    InventoryItem existing, {
    required int qty,
    required DateTime when,
  }) async {
    existing.quantity += qty;
    existing.obtainedAt = when;
    try {
      await existing.save();
    } catch (_) {}
    return existing;
  }

  /// Inserta 1 o 2 items en el inventario (apilando sobre items iguales ya
  /// existentes en la misma cuenta), marca la cuenta como completada y
  /// dispara la consulta de precios + icono en background.
  Future<void> registerDrop({
    required CsAccount account,
    required List<
        ({
          String itemName,
          ItemCategory category,
          int quantity,
          double? floatValue,
          SkinWear? wear,
          bool statTrak,
          List<String> stickers,
        })> items,
    required DateTime when,
  }) async {
    final entries = <InventoryItem>[];
    for (final it in items) {
      final name = it.itemName.trim();
      if (name.isEmpty) continue;
      final qty = it.quantity <= 0 ? 1 : it.quantity;
      final existing =
          _findStackable(name: name, accountId: account.id, category: it.category);
      if (existing != null) {
        entries.add(await _stackOnto(existing, qty: qty, when: when));
        continue;
      }
      final entry = InventoryItem(
        id: _uuid.v4(),
        accountId: account.id,
        accountName: account.alias,
        itemName: name,
        category: it.category,
        quantity: qty,
        obtainedAt: when,
        floatValue: it.floatValue,
        wear: it.wear,
        statTrak: it.statTrak,
        stickers: it.stickers,
      );
      await HiveService.inventoryBox.put(entry.id, entry);
      entries.add(entry);
    }
    _load();

    // Marcar la cuenta como drop obtenido.
    await ref.read(accountsProvider.notifier).markDropObtained(account.id, when);

    // Disparar consultas de precio + icono en background.
    _enrichItems(entries);
  }

  /// Añade un item al inventario sin tocar el estado de drop de ninguna cuenta,
  /// apilando sobre un item igual ya existente en la misma cuenta si lo hay.
  /// Si `account` es null, se guarda con `accountName = "Manual"` y un accountId
  /// especial para que no coincida con ninguna cuenta real.
  Future<InventoryItem> addManualItem({
    required String itemName,
    required ItemCategory category,
    required DateTime obtainedAt,
    CsAccount? account,
    int quantity = 1,
    double? floatValue,
    SkinWear? wear,
    bool statTrak = false,
    List<String> stickers = const [],
  }) async {
    final name = itemName.trim();
    final qty = quantity <= 0 ? 1 : quantity;
    final accountId = account?.id ?? '__manual__';

    final existing =
        _findStackable(name: name, accountId: accountId, category: category);
    if (existing != null) {
      final stacked = await _stackOnto(existing, qty: qty, when: obtainedAt);
      _load();
      _enrichItems(<InventoryItem>[stacked]);
      return stacked;
    }

    final entry = InventoryItem(
      id: _uuid.v4(),
      accountId: accountId,
      accountName: account?.alias ?? 'Manual',
      itemName: name,
      category: category,
      quantity: qty,
      obtainedAt: obtainedAt,
      floatValue: floatValue,
      wear: wear,
      statTrak: statTrak,
      stickers: stickers,
    );
    await HiveService.inventoryBox.put(entry.id, entry);
    _load();

    _enrichItems(<InventoryItem>[entry]);
    return entry;
  }

  /// Fija (o quita, con `threshold: null`) el umbral de alerta de precio
  /// de un item, en la moneda indicada. Resetea `alerted` para que un
  /// umbral nuevo (o el mismo tras haber bajado el precio) pueda volver a
  /// disparar la notificación.
  Future<void> setAlertThreshold(
    String itemId, {
    required String currency,
    required double? threshold,
  }) async {
    final item = HiveService.inventoryBox.get(itemId);
    if (item == null) return;
    item.alertThreshold = threshold;
    item.alertCurrency = currency;
    item.alerted = false;
    try {
      await item.save();
    } catch (_) {}
    _load();
  }

  /// Comprueba si el precio actual de `item` cruza su umbral de alerta y,
  /// si es así (y no se había notificado ya), dispara una notificación
  /// local. Si el precio vuelve a bajar del umbral, resetea `alerted` para
  /// permitir re-alertar en una subida futura.
  Future<void> _checkPriceAlert(InventoryItem item) async {
    final threshold = item.alertThreshold;
    if (threshold == null) return;
    final currency = item.alertCurrency ?? 'EUR';
    final price = currency == 'USD' ? item.priceUsd : item.priceEur;
    if (price >= threshold) {
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

  /// Lanza en background las llamadas de precio (EUR+USD) e icono.
  /// Cada llamada actualiza su item correspondiente y dispara un _load().
  /// Protegido con try/catch y guard isInBox para no crashear si el usuario
  /// eliminó el item mientras Steam respondía.
  void _enrichItems(List<InventoryItem> items) {
    final market = ref.read(steamMarketServiceProvider);
    for (final e in items) {
      // ignore: unawaited_futures
      market
          .getPrice(e.itemName, silent: true)
          .then((result) async {
            if (result.status == PriceStatus.fresh && e.isInBox) {
              e.priceEur = result.priceEur;
              e.priceUsd = result.priceUsd;
              try {
                await e.save();
              } catch (_) {/* item borrado entre tanto */}
              await _checkPriceAlert(e);
              _load();
            }
          })
          .catchError((_) {/* silencio: nunca debe crashear */});
      // ignore: unawaited_futures
      market
          .getIconUrl(e.itemName, silent: true)
          .then((iconUrl) async {
            if (iconUrl.isNotEmpty && e.isInBox) {
              try {
                await e.save();
              } catch (_) {}
              _load();
            }
          })
          .catchError((_) {/* silencio */});
    }
  }

  /// Marca N unidades como vendidas. Si la cantidad llega a 0 se marca como
  /// vendido. Crea un SaleRecord por la venta.
  /// Devuelve la cantidad restante (-1 si el item no existe).
  Future<int> sellQuantity(String itemId, int qty) async {
    final item = HiveService.inventoryBox.get(itemId);
    if (item == null) return -1;
    final avail = item.availableQuantity;
    if (qty <= 0 || qty > avail) return -1;
    final soldNow = DateTime.now();

    // Si vende todo, marca sold=true; si no, resta quantity.
    if (qty == avail) {
      item.quantity = 0;
      item.sold = true;
      item.soldAt = soldNow;
    } else {
      item.quantity = avail - qty;
      item.sold = false;
      item.soldAt = null;
    }
    try {
      await item.save();
    } catch (_) {
      return -1;
    }

    // Crear SaleRecord.
    final record = SaleRecord(
      itemId: item.id,
      itemName: item.itemName,
      categoryIndex: item.category.index,
      accountName: item.accountName,
      quantity: qty,
      unitPriceEur: item.priceEur,
      unitPriceUsd: item.priceUsd,
      soldAt: soldNow,
    );
    await HiveService.salesBox.add(record);

    // Refrescar el provider de historial de ventas (escucha esta StateProvider).
    ref.read(salesListProvider.notifier).state = HiveService.salesBox.values
        .toList()
      ..sort((a, b) => b.soldAt.compareTo(a.soldAt));

    _load();
    return item.quantity;
  }

  /// Vuelve a poner unidades como disponibles (operación inversa de sellQuantity).
  /// Por simplicidad no borra el SaleRecord (queda como histórico).
  Future<void> unmarkSold(String itemId, {int qty = 1}) async {
    final item = HiveService.inventoryBox.get(itemId);
    if (item == null) return;
    final currentlyAvailable = item.availableQuantity;
    item.quantity = currentlyAvailable + qty;
    item.sold = false;
    item.soldAt = null;
    try {
      await item.save();
    } catch (_) {}
    _load();
  }

  Future<void> deleteItem(String itemId) async {
    await HiveService.inventoryBox.delete(itemId);
    _load();
  }

  /// Recarga los precios (e iconos) de TODO el inventario.
  ///
  /// [onProgress] recibe (done, total). [force] ignora caché para garantizar
  /// un refresco real desde Steam.
  Future<void> refreshPrices({
    bool force = true,
    void Function(int done, int total)? onProgress,
  }) async {
    final market = ref.read(steamMarketServiceProvider);
    final items = state.toList();
    final total = items.length;
    var done = 0;
    for (final item in items) {
      try {
        final price = await market.getPrice(item.itemName, forceRefresh: force);
        if (price.status == PriceStatus.fresh && item.isInBox) {
          item.priceEur = price.priceEur;
          item.priceUsd = price.priceUsd;
          try {
            await item.save();
          } catch (_) {}
          await _checkPriceAlert(item);
        }
        await market.getIconUrl(item.itemName, forceRefresh: force, silent: true);
      } catch (_) {/* silencio */}
      done++;
      onProgress?.call(done, total);
      _load();
    }
  }

  /// Recarga el precio de un solo item. [force] ignora caché.
  Future<void> refreshOne(String itemId, {bool force = true}) async {
    final item = HiveService.inventoryBox.get(itemId);
    if (item == null) return;
    final market = ref.read(steamMarketServiceProvider);
    try {
      final price = await market.getPrice(item.itemName, forceRefresh: force);
      if (price.status == PriceStatus.fresh && item.isInBox) {
        item.priceEur = price.priceEur;
        item.priceUsd = price.priceUsd;
        try {
          await item.save();
        } catch (_) {}
        await _checkPriceAlert(item);
      }
      await market.getIconUrl(item.itemName, forceRefresh: force, silent: true);
    } catch (_) {}
    _load();
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) => InventoryNotifier(ref));

/// Filtros del inventario (categoría y cuenta).
class InventoryFilter {
  final ItemCategory? category;
  final String? accountId;
  final bool includeSold;
  final InventorySort sort;
  const InventoryFilter({
    this.category,
    this.accountId,
    this.includeSold = false,
    this.sort = InventorySort.dateDesc,
  });

  InventoryFilter copyWith({
    ItemCategory? category,
    String? accountId,
    bool? includeSold,
    InventorySort? sort,
  }) =>
      InventoryFilter(
        category: category ?? this.category,
        accountId: accountId ?? this.accountId,
        includeSold: includeSold ?? this.includeSold,
        sort: sort ?? this.sort,
      );
}

final inventoryFilterProvider = StateProvider<InventoryFilter>((ref) => const InventoryFilter());

/// Lista filtrada y ordenada.
final filteredInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(inventoryProvider);
  final filter = ref.watch(inventoryFilterProvider);
  final filtered = items.where((it) {
    if (!filter.includeSold && it.sold) return false;
    if (filter.category != null && it.category != filter.category) return false;
    if (filter.accountId != null && it.accountId != filter.accountId) return false;
    return true;
  }).toList();
  switch (filter.sort) {
    case InventorySort.dateDesc:
      filtered.sort((a, b) => b.obtainedAt.compareTo(a.obtainedAt));
      break;
    case InventorySort.dateAsc:
      filtered.sort((a, b) => a.obtainedAt.compareTo(b.obtainedAt));
      break;
    case InventorySort.priceDesc:
      filtered.sort(
          (a, b) => (b.priceEur * b.quantity).compareTo(a.priceEur * a.quantity));
      break;
    case InventorySort.priceAsc:
      filtered.sort(
          (a, b) => (a.priceEur * a.quantity).compareTo(b.priceEur * b.quantity));
      break;
    case InventorySort.nameAsc:
      filtered.sort(
          (a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()));
      break;
    case InventorySort.nameDesc:
      filtered.sort(
          (a, b) => b.itemName.toLowerCase().compareTo(a.itemName.toLowerCase()));
      break;
  }
  return filtered;
});

/// Resumen de inventario (sólo items no vendidos).
class InventorySummary {
  final double totalEur;
  final double totalUsd;
  final int numCases;
  final int numSkins;
  final int numGrafitis;
  final int numKnives;
  final int numGloves;
  final int numOther;
  final int totalActive;

  const InventorySummary({
    required this.totalEur,
    required this.totalUsd,
    required this.numCases,
    required this.numSkins,
    required this.numGrafitis,
    required this.numKnives,
    required this.numGloves,
    required this.numOther,
    required this.totalActive,
  });
}

final inventorySummaryProvider = Provider<InventorySummary>((ref) {
  final items = ref.watch(inventoryProvider).where((i) => !i.sold).toList();
  double eur = 0, usd = 0;
  int cases = 0, skins = 0, grafs = 0, knives = 0, gloves = 0, other = 0;
  for (final i in items) {
    eur += i.priceEur * i.quantity;
    usd += i.priceUsd * i.quantity;
    switch (i.category) {
      case ItemCategory.caseBox:
        cases++;
        break;
      case ItemCategory.skin:
        skins++;
        break;
      case ItemCategory.graffiti:
        grafs++;
        break;
      case ItemCategory.knife:
        knives++;
        break;
      case ItemCategory.glove:
        gloves++;
        break;
      case ItemCategory.other:
        other++;
        break;
    }
  }
  return InventorySummary(
    totalEur: eur,
    totalUsd: usd,
    numCases: cases,
    numSkins: skins,
    numGrafitis: grafs,
    numKnives: knives,
    numGloves: gloves,
    numOther: other,
    totalActive: items.length,
  );
});

/// Resumen del historial de ventas (totales globales).
class SalesSummary {
  final double totalEur;
  final double totalUsd;
  final int totalQuantity;
  final int totalRecords;
  const SalesSummary({
    required this.totalEur,
    required this.totalUsd,
    required this.totalQuantity,
    required this.totalRecords,
  });
}

/// Provider simple que mantiene la lista actual de ventas.
/// Re-emite al añadir/eliminar registros (usado en historial).
final salesListProvider = StateProvider<List<SaleRecord>>((ref) {
  return HiveService.salesBox.values.toList()
    ..sort((a, b) => b.soldAt.compareTo(a.soldAt));
});

final salesSummaryProvider = Provider<SalesSummary>((ref) {
  final sales = ref.watch(salesListProvider);
  double eur = 0, usd = 0;
  int qty = 0;
  for (final s in sales) {
    eur += s.totalEur;
    usd += s.totalUsd;
    qty += s.quantity;
  }
  return SalesSummary(
    totalEur: eur,
    totalUsd: usd,
    totalQuantity: qty,
    totalRecords: sales.length,
  );
});
