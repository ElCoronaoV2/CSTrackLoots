import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/cs_account.dart';
import '../models/cs_rank_enums.dart';
import '../models/inventory_item.dart';
import '../models/price_cache_entry.dart';
import '../models/sale_record.dart';

/// Nombre de las cajas y collections usadas en el autocompletado del drop.
/// Lista curada de CS2 a fecha del proyecto. El usuario puede escribir libremente.
/// Separada por categoría para que el autocompletado solo sugiera items
/// coherentes con la categoría seleccionada (ver [forCategory]).
class SeedItems {
  static const List<String> cases = <String>[
    // Cajas operacion / recientes (set active + disueltas previamente)
    'Kilowatt Case',
    'Fever Case',
    'Gallery Case',
    'Snakebite Case',
    'Operation Breakout Weapon Case',
    'Operation Phoenix Weapon Case',
    'Operation Vanguard Weapon Case',
    'Operation Bloodhound Weapon Case',
    'Chroma Case',
    'Chroma 2 Case',
    'Chroma 3 Case',
    'Gamma Case',
    'Gamma 2 Case',
    'Glove Case',
    'Spectrum Case',
    'Spectrum 2 Case',
    'Clutch Case',
    'Horizon Case',
    'Danger Zone Case',
    'Prisma Case',
    'Prisma 2 Case',
    'Shattered Web Case',
    'Fracture Case',
    'Operation Riptide Case',
    'Recoil Case',
    'Revolution Case',
    'Dreams & Nightmares Case',
    'Paris 2023 Mirage Souvenir Package',
    'Paris 2023 Inferno Souvenir Package',
    'Copenhagen 2024 Mirage Souvenir Package',
  ];

  /// Stickers y grafitis frecuentes en drops (placeholder, son texto libre normalmente).
  static const List<String> graffitis = <String>[
    'Sticker | Howling Dawn',
    'Sealed Graffiti | Recoil AK-47',
  ];

  /// Skins de armas muy conocidas.
  static const List<String> skins = <String>[
    'AK-47 | Redline',
    'AK-47 | Asiimov',
    'AK-47 | Neon Rider',
    'AK-47 | The Empress',
    'AK-47 | Bloodsport',
    'AWP | Dragon Lore',
    'AWP | Asiimov',
    'AWP | Hyper Beast',
    'AWP | Neo-Noir',
    'AWP | Duality',
    'M4A4 | Howl',
    'M4A4 | Neo-Noir',
    'M4A1-S | Hyper Beast',
    'M4A1-S | Printstream',
    'USP-S | Kill Confirmed',
    'USP-S | Cortex',
    'Glock-18 | Fade',
    'Desert Eagle | Blaze',
  ];

  static const List<String> knives = <String>[
    'Karambit | Doppler',
    'Karambit | Fade',
    'Karambit | Crimson Web',
    'Butterfly Knife | Fade',
    'M9 Bayonet | Doppler',
    'Bayonet | Crimson Web',
  ];

  static const List<String> gloves = <String>[
    "Sport Gloves | Pandora's Box",
    'Sport Gloves | Vice',
    'Specialist Gloves | Crimson Kimono',
  ];

  static const List<String> all = <String>[
    ...cases,
    ...graffitis,
    ...skins,
    ...knives,
    ...gloves,
  ];

  /// Lista de sugerencias para el autocompletado, acotada a la categoría
  /// seleccionada (p.ej. con "Caja" elegida, solo aparecen cajas). Para
  /// "Otro" no hay lista propia, así que se ofrece el listado completo.
  static List<String> forCategory(ItemCategory category) {
    switch (category) {
      case ItemCategory.caseBox:
        return cases;
      case ItemCategory.skin:
        return skins;
      case ItemCategory.graffiti:
        return graffitis;
      case ItemCategory.knife:
        return knives;
      case ItemCategory.glove:
        return gloves;
      case ItemCategory.other:
        return all;
    }
  }
}

/// Centraliza inicialización de Hive y acceso a las boxes.
class HiveService {
  static const String accountsBoxName = 'accounts';
  static const String inventoryBoxName = 'inventory';
  static const String priceCacheBoxName = 'price_cache';
  static const String settingsBoxName = 'settings';
  static const String salesBoxName = 'sales';
  static const String settingsKey = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Registro de adapters (uno por typeId).
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CsAccountAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CsMapAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CompetitiveRankAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ItemCategoryAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(InventoryItemAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PriceCacheEntryAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(SaleRecordAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(SkinWearAdapter());

    // Apertura de boxes.
    await Hive.openBox<CsAccount>(accountsBoxName);
    await Hive.openBox<InventoryItem>(inventoryBoxName);
    await Hive.openBox<PriceCacheEntry>(priceCacheBoxName);
    await Hive.openBox<SaleRecord>(salesBoxName);
    final settingsBox = await Hive.openBox<AppSettings>(settingsBoxName);

    if (settingsBox.get(settingsKey) == null) {
      await settingsBox.put(settingsKey, AppSettings());
    }
  }

  static Box<CsAccount> get accountsBox => Hive.box<CsAccount>(accountsBoxName);
  static Box<InventoryItem> get inventoryBox =>
      Hive.box<InventoryItem>(inventoryBoxName);
  static Box<PriceCacheEntry> get priceCacheBox =>
      Hive.box<PriceCacheEntry>(priceCacheBoxName);
  static Box<AppSettings> get settingsBox =>
      Hive.box<AppSettings>(settingsBoxName);
  static Box<SaleRecord> get salesBox => Hive.box<SaleRecord>(salesBoxName);

  static AppSettings get settings => settingsBox.get(settingsKey)!;
}
