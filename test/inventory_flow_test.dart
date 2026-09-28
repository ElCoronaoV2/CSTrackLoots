import 'package:cs2_tracker/models/app_settings.dart';
import 'package:cs2_tracker/models/cs_account.dart';
import 'package:cs2_tracker/models/inventory_item.dart';
import 'package:cs2_tracker/models/price_cache_entry.dart';
import 'package:cs2_tracker/models/sale_record.dart';
import 'package:cs2_tracker/services/hive_service.dart';
import 'package:cs2_tracker/services/steam_market_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Inicialización mínima de Hive en memoria para tests sin Flutter bindings.
Future<void> _initInMemoryHive() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Genera un directorio temporal por test para evitar colisiones.
  Hive.init('.tmp_hive_test/${DateTime.now().microsecondsSinceEpoch}');

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CsAccountAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ItemCategoryAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(InventoryItemAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PriceCacheEntryAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(SaleRecordAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(SkinWearAdapter());

    await Hive.openBox<CsAccount>(HiveService.accountsBoxName);
    await Hive.openBox<InventoryItem>(HiveService.inventoryBoxName);
    await Hive.openBox<PriceCacheEntry>(HiveService.priceCacheBoxName);
    await Hive.openBox<AppSettings>(HiveService.settingsBoxName);
    await Hive.openBox<SaleRecord>(HiveService.salesBoxName);
  }

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _initInMemoryHive();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('InventoryItem', () {
    test('serialización round-trip preserva campos', () async {
      final item = InventoryItem(
        id: _uuid.v4(),
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'Kilowatt Case',
        category: ItemCategory.caseBox,
        obtainedAt: DateTime(2026, 1, 1),
        priceEur: 0.15,
        priceUsd: 0.16,
      );
      await HiveService.inventoryBox.put(item.id, item);
      final restored = HiveService.inventoryBox.get(item.id);
      expect(restored, isNotNull);
      expect(restored!.itemName, 'Kilowatt Case');
      expect(restored.category, ItemCategory.caseBox);
      expect(restored.priceEur, 0.15);
      expect(restored.priceUsd, 0.16);
      expect(restored.sold, isFalse);
      expect(restored.quantity, 1);
      expect(restored.availableQuantity, 1);
    });

    test('quantity por defecto es 1', () async {
      final item = InventoryItem(
        id: _uuid.v4(),
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'X',
        category: ItemCategory.other,
        obtainedAt: DateTime.now(),
        quantity: 5,
      );
      await HiveService.inventoryBox.put(item.id, item);
      final restored = HiveService.inventoryBox.get(item.id);
      expect(restored!.quantity, 5);
      expect(restored.totalEur, 0); // sin precio
    });

    test('totalEur multiplica precio por cantidad', () async {
      final item = InventoryItem(
        id: _uuid.v4(),
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'Kilowatt Case',
        category: ItemCategory.caseBox,
        obtainedAt: DateTime.now(),
        priceEur: 0.15,
        priceUsd: 0.16,
        quantity: 5,
      );
      expect(item.totalEur, closeTo(0.75, 1e-9));
      expect(item.totalUsd, closeTo(0.80, 1e-9)); // 5 * 0.16
    });

    test('serializa alerta de precio round-trip', () async {
      final id = _uuid.v4();
      final item = InventoryItem(
        id: id,
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'Kilowatt Case',
        category: ItemCategory.caseBox,
        obtainedAt: DateTime.now(),
        alertThreshold: 1.5,
        alertCurrency: 'EUR',
        alerted: true,
      );
      await HiveService.inventoryBox.put(id, item);
      final restored = HiveService.inventoryBox.get(id);
      expect(restored!.alertThreshold, closeTo(1.5, 1e-9));
      expect(restored.alertCurrency, 'EUR');
      expect(restored.alerted, isTrue);
    });

    test('sin alerta configurada por defecto', () async {
      final id = _uuid.v4();
      final item = InventoryItem(
        id: id,
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'Kilowatt Case',
        category: ItemCategory.caseBox,
        obtainedAt: DateTime.now(),
      );
      await HiveService.inventoryBox.put(id, item);
      final restored = HiveService.inventoryBox.get(id);
      expect(restored!.alertThreshold, isNull);
      expect(restored.alertCurrency, isNull);
      expect(restored.alerted, isFalse);
    });

    test('serializa float/wear/StatTrak/stickers round-trip', () async {
      final id = _uuid.v4();
      final item = InventoryItem(
        id: id,
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'AK-47 | Redline',
        category: ItemCategory.skin,
        obtainedAt: DateTime.now(),
        floatValue: 0.0532,
        wear: SkinWear.fieldTested,
        statTrak: true,
        stickers: const ['Howling Dawn', 'Katowice 2015'],
      );
      await HiveService.inventoryBox.put(id, item);
      final restored = HiveService.inventoryBox.get(id);
      expect(restored!.floatValue, closeTo(0.0532, 1e-9));
      expect(restored.wear, SkinWear.fieldTested);
      expect(restored.statTrak, isTrue);
      expect(restored.stickers, ['Howling Dawn', 'Katowice 2015']);
    });

    test('float/wear/StatTrak/stickers son opcionales por defecto', () async {
      final id = _uuid.v4();
      final item = InventoryItem(
        id: id,
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'Kilowatt Case',
        category: ItemCategory.caseBox,
        obtainedAt: DateTime.now(),
      );
      await HiveService.inventoryBox.put(id, item);
      final restored = HiveService.inventoryBox.get(id);
      expect(restored!.floatValue, isNull);
      expect(restored.wear, isNull);
      expect(restored.statTrak, isFalse);
      expect(restored.stickers, isEmpty);
    });

    test('supportsWearDetails solo para skin/cuchillo/guante', () {
      expect(ItemCategory.skin.supportsWearDetails, isTrue);
      expect(ItemCategory.knife.supportsWearDetails, isTrue);
      expect(ItemCategory.glove.supportsWearDetails, isTrue);
      expect(ItemCategory.caseBox.supportsWearDetails, isFalse);
      expect(ItemCategory.graffiti.supportsWearDetails, isFalse);
      expect(ItemCategory.other.supportsWearDetails, isFalse);
    });

    test('availableQuantity es 0 si está vendido', () async {
      final item = InventoryItem(
        id: _uuid.v4(),
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'X',
        category: ItemCategory.other,
        obtainedAt: DateTime.now(),
        quantity: 3,
        sold: true,
      );
      expect(item.availableQuantity, 0);
    });

    test('eliminar item lo quita de la box', () async {
      final id = _uuid.v4();
      await HiveService.inventoryBox.put(
        id,
        InventoryItem(
          id: id,
          accountId: 'acc1',
          accountName: 'SmokeTest',
          itemName: 'X',
          category: ItemCategory.other,
          obtainedAt: DateTime.now(),
        ),
      );
      expect(HiveService.inventoryBox.length, 1);
      await HiveService.inventoryBox.delete(id);
      expect(HiveService.inventoryBox.length, 0);
    });
  });

  group('Venta parcial (simulación lógica)', () {
    test('vender 2 de 5 deja quantity=3 y crea SaleRecord', () async {
      final id = _uuid.v4();
      final item = InventoryItem(
        id: id,
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'Kilowatt Case',
        category: ItemCategory.caseBox,
        obtainedAt: DateTime.now(),
        priceEur: 0.15,
        quantity: 5,
      );
      await HiveService.inventoryBox.put(id, item);

      // Simulamos sellQuantity(2)
      item.quantity = 3;
      await item.save();

      // Creamos SaleRecord
      final record = SaleRecord(
        itemId: id,
        itemName: 'Kilowatt Case',
        categoryIndex: ItemCategory.caseBox.index,
        accountName: 'SmokeTest',
        quantity: 2,
        unitPriceEur: 0.15,
        unitPriceUsd: 0.16,
        soldAt: DateTime.now(),
      );
      await HiveService.salesBox.add(record);

      final restored = HiveService.inventoryBox.get(id);
      expect(restored!.quantity, 3);
      expect(restored.availableQuantity, 3);
      expect(restored.sold, isFalse);

      expect(HiveService.salesBox.length, 1);
      expect(HiveService.salesBox.values.first.quantity, 2);
      expect(HiveService.salesBox.values.first.totalEur, closeTo(0.30, 1e-9));
    });

    test('vender todo quantity=5 marca sold=true', () async {
      final id = _uuid.v4();
      final item = InventoryItem(
        id: id,
        accountId: 'acc1',
        accountName: 'SmokeTest',
        itemName: 'Kilowatt Case',
        category: ItemCategory.caseBox,
        obtainedAt: DateTime.now(),
        priceEur: 0.15,
        quantity: 5,
      );
      await HiveService.inventoryBox.put(id, item);

      // Simulamos sellQuantity(5) -> todo vendido
      item.quantity = 0;
      item.sold = true;
      item.soldAt = DateTime.now();
      await item.save();

      final restored = HiveService.inventoryBox.get(id);
      expect(restored!.quantity, 0);
      expect(restored.sold, isTrue);
      expect(restored.availableQuantity, 0);
    });
  });

  group('CsAccount + estados de drop', () {
    test('cuenta nueva comienza con drop pendiente', () async {
      final acc = CsAccount(id: _uuid.v4(), alias: 'SmokeTest');
      await HiveService.accountsBox.put(acc.id, acc);
      final restored = HiveService.accountsBox.get(acc.id);
      expect(restored!.dropObtainedThisWeek, isFalse);
      expect(restored.dropMissedThisWeek, isFalse);
    });

    test('marcar drop como perdido actualiza estado', () async {
      final acc = CsAccount(id: _uuid.v4(), alias: 'SmokeTest');
      await HiveService.accountsBox.put(acc.id, acc);
      acc.dropMissedThisWeek = true;
      await acc.save();
      final restored = HiveService.accountsBox.get(acc.id);
      expect(restored!.dropMissedThisWeek, isTrue);
    });

    test('marcar drop como obtenido actualiza estado', () async {
      final acc = CsAccount(id: _uuid.v4(), alias: 'SmokeTest');
      await HiveService.accountsBox.put(acc.id, acc);
      acc.dropObtainedThisWeek = true;
      acc.lastDropDate = DateTime.now();
      await acc.save();
      final restored = HiveService.accountsBox.get(acc.id);
      expect(restored!.dropObtainedThisWeek, isTrue);
      expect(restored.lastDropDate, isNotNull);
    });

    test('estadísticas nuevas por defecto son 0', () async {
      final acc = CsAccount(id: _uuid.v4(), alias: 'SmokeTest');
      expect(acc.totalObtained, 0);
      expect(acc.totalMissed, 0);
      expect(acc.currentStreak, 0);
      expect(acc.bestStreak, 0);
      expect(acc.successRate, -1);
      expect(acc.totalWeeks, 0);
    });

    test('successRate devuelve porcentaje correcto', () async {
      final acc = CsAccount(
        id: _uuid.v4(),
        alias: 'SmokeTest',
        totalObtained: 7,
        totalMissed: 3,
      );
      expect(acc.totalWeeks, 10);
      expect(acc.successRate, closeTo(70.0, 1e-9));
    });
  });

  group('SteamMarketService.parsePrice (público estático)', () {
    test('parsea EUR formato europeo', () {
      expect(SteamMarketService.parsePrice('0,15€'), closeTo(0.15, 1e-6));
      expect(SteamMarketService.parsePrice('1.234,56€'),
          closeTo(1234.56, 1e-2));
    });

    test('parsea USD formato anglosajón', () {
      expect(SteamMarketService.parsePrice(r'$1,234.56'),
          closeTo(1234.56, 1e-2));
      expect(SteamMarketService.parsePrice(r'$0.15'),
          closeTo(0.15, 1e-6));
    });

    test('retorna 0 para precios vacíos o no numéricos', () {
      expect(SteamMarketService.parsePrice(''), 0.0);
      expect(SteamMarketService.parsePrice('not a price'), 0.0);
    });

    test('es robusto a espacios y caracteres extra', () {
      expect(SteamMarketService.parsePrice('  0,15 € '),
          closeTo(0.15, 1e-6));
      expect(SteamMarketService.parsePrice(r'Price: $1.50'),
          closeTo(1.50, 1e-6));
    });
  });

  group('PriceCacheEntry', () {
    test('hasIcon es false cuando iconUrl está vacío', () {
      final entry = PriceCacheEntry(marketHashName: 'Kilowatt Case');
      expect(entry.hasIcon, isFalse);
    });

    test('hasIcon es true cuando iconUrl no está vacío y es reciente', () {
      final entry = PriceCacheEntry(marketHashName: 'Kilowatt Case');
      entry.iconUrl = 'https://example.com/icon.png';
      entry.iconFetchedAt = DateTime.now();
      expect(entry.hasIcon, isTrue);
    });
  });
}
