import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/cs_account.dart';
import '../models/cs_rank_enums.dart';
import '../models/inventory_item.dart';
import '../models/item_price_snapshot.dart';
import '../models/price_cache_entry.dart';
import '../models/rank_snapshot.dart';
import '../models/sale_record.dart';
import '../models/value_snapshot.dart';
import '../models/watchlist_item.dart';

/// Nombre de las cajas y collections usadas en el autocompletado del drop.
/// Lista curada de CS2 a fecha del proyecto. El usuario puede escribir libremente.
/// Separada por categoría para que el autocompletado solo sugiera items
/// coherentes con la categoría seleccionada (ver [forCategory]).
class SeedItems {
  /// Todas las cajas de armas, maletines de eSports, cajas de grafitis y
  /// cajas de kits de música oficiales de Valve, en orden cronológico
  /// (fuente: catálogo verificado con nombre EN/ES de cada una). Los
  /// souvenir package de majors no están (son 400+, uno por mapa/torneo);
  /// para eso sirve "Otro" con texto libre.
  static const List<String> cases = <String>[
    'CS:GO Weapon Case',
    'eSports 2013 Case',
    'Operation Bravo Case',
    'CS:GO Weapon Case 2',
    'eSports 2013 Winter Case',
    'Winter Offensive Weapon Case',
    'CS:GO Weapon Case 3',
    'Operation Phoenix Weapon Case',
    'Huntsman Weapon Case',
    'Operation Breakout Weapon Case',
    'eSports 2014 Summer Case',
    'Operation Vanguard Weapon Case',
    'Chroma Case',
    'Chroma 2 Case',
    'Falchion Case',
    'Shadow Case',
    'Revolver Case',
    'Operation Wildfire Case',
    'Chroma 3 Case',
    'Community Graffiti Box 1',
    'Gamma Case',
    'Gamma 2 Case',
    'CS:GO Graffiti Box',
    'Perfect World Graffiti Box',
    'StatTrak™ Radicals Box',
    'Glove Case',
    'Spectrum Case',
    'Operation Hydra Case',
    'Spectrum 2 Case',
    'Clutch Case',
    'Horizon Case',
    'Danger Zone Case',
    'Prisma Case',
    'Shattered Web Case',
    'CS20 Case',
    'Prisma 2 Case',
    'Masterminds Music Kit Box',
    'StatTrak™ Masterminds Music Kit Box',
    'Fracture Case',
    'Operation Broken Fang Case',
    'Snakebite Case',
    'Tacticians Music Kit Box',
    'StatTrak™ Tacticians Music Kit Box',
    'Operation Riptide Case',
    'Dreams & Nightmares Case',
    'Recoil Case',
    'Initiators Music Kit Box',
    'StatTrak™ Initiators Music Kit Box',
    'Revolution Case',
    'Kilowatt Case',
    'NIGHTMODE Music Kit Box',
    'StatTrak™ NIGHTMODE Music Kit Box',
    'Masterminds 2 Music Kit Box',
    'StatTrak™ Masterminds 2 Music Kit Box',
    'Gallery Case',
    'Fever Case',
    'Deluge Music Kit Box',
    'StatTrak™ Deluge Music Kit Box',
  ];

  /// Stickers y grafitis frecuentes en drops (texto libre normalmente, esto
  /// es solo para agilizar el autocompletado con las más habituales).
  static const List<String> graffitis = <String>[
    'Sticker | Howling Dawn',
    'Sealed Graffiti | Recoil AK-47',
    'Sealed Graffiti | Dust',
    'Sealed Graffiti | Bloodhound',
    'Sealed Graffiti | Hot Dog',
    'Sealed Graffiti | Complex Piece',
    'Sealed Graffiti | Silver Whale',
    'Sealed Graffiti | Skull',
    'Sealed Graffiti | Crown (Foil)',
    'Sealed Graffiti | Space Face',
  ];

  /// Skins por arma, agrupadas para que sea fácil ampliar. Cubre prácticamente
  /// todas las armas del juego con sus skins más conocidas/negociadas.
  static const List<String> _akSkins = <String>[
    'AK-47 | Redline',
    'AK-47 | Asiimov',
    'AK-47 | Neon Rider',
    'AK-47 | The Empress',
    'AK-47 | Bloodsport',
    'AK-47 | Fire Serpent',
    'AK-47 | Vulcan',
    'AK-47 | Fuel Injector',
    'AK-47 | Wasteland Rebel',
    'AK-47 | Case Hardened',
    'AK-47 | Jaguar',
    'AK-47 | Point Disarray',
    'AK-47 | Aquamarine Revenge',
    'AK-47 | Neon Revolution',
    'AK-47 | Nightwish',
    'AK-47 | Head Shot',
    'AK-47 | Legion of Anubis',
    'AK-47 | Gold Arabesque',
    'AK-47 | Panthera Onca',
    'AK-47 | Slate',
    'AK-47 | Frontside Misty',
    'AK-47 | Phantom Disruptor',
    'AK-47 | Ice Coaled',
    'AK-47 | Elite Build',
    'AK-47 | Safari Mesh',
    'AK-47 | Rat Rod',
    'AK-47 | Uncharted',
    'AK-47 | Leet Museo',
  ];
  static const List<String> _m4a4Skins = <String>[
    'M4A4 | Howl',
    'M4A4 | Neo-Noir',
    'M4A4 | Asiimov',
    'M4A4 | Poseidon',
    'M4A4 | Buzz Kill',
    'M4A4 | Desolate Space',
    'M4A4 | Bullet Rain',
    'M4A4 | The Emperor',
    'M4A4 | Royal Paladin',
    'M4A4 | Evil Daimyo',
    'M4A4 | X-Ray',
    'M4A4 | In Living Color',
    'M4A4 | Hellfire',
    'M4A4 | Griffin',
    'M4A4 | Radiation Hazard',
    'M4A4 | Faded Zebra',
    'M4A4 | 龍王 (Dragon King)',
    'M4A4 | Tooth Fairy',
  ];
  static const List<String> _m4a1sSkins = <String>[
    'M4A1-S | Hyper Beast',
    'M4A1-S | Printstream',
    'M4A1-S | Golden Coil',
    'M4A1-S | Knight',
    'M4A1-S | Player Two',
    'M4A1-S | Cyrex',
    'M4A1-S | Guardian',
    'M4A1-S | Icarus Fell',
    'M4A1-S | Decimator',
    "M4A1-S | Chantico's Fire",
    'M4A1-S | Master Piece',
    'M4A1-S | Mecha Industries',
    'M4A1-S | Nitro',
    'M4A1-S | Welcome to the Jungle',
    'M4A1-S | Hot Rod',
    'M4A1-S | Atomic Alloy',
    'M4A1-S | Blood Tiger',
    'M4A1-S | Dark Water',
    'M4A1-S | Emphorosaur-S',
  ];
  static const List<String> _awpSkins = <String>[
    'AWP | Dragon Lore',
    'AWP | Asiimov',
    'AWP | Hyper Beast',
    'AWP | Neo-Noir',
    'AWP | Duality',
    'AWP | Gungnir',
    'AWP | Medusa',
    'AWP | Fade',
    'AWP | Wildfire',
    "AWP | Man-o'-war",
    'AWP | Lightning Strike',
    'AWP | Electric Hive',
    'AWP | Redline',
    'AWP | Corticera',
    'AWP | Elite Build',
    'AWP | Containment Breach',
    'AWP | Chromatic Aberration',
    'AWP | Oni Taiji',
    'AWP | Atheris',
    'AWP | Pit Viper',
    'AWP | Exoskeleton',
    'AWP | PAW',
    'AWP | Worm God',
    'AWP | Silk Tiger',
  ];
  static const List<String> _deagleSkins = <String>[
    'Desert Eagle | Blaze',
    'Desert Eagle | Printstream',
    'Desert Eagle | Code Red',
    'Desert Eagle | Kumicho Dragon',
    'Desert Eagle | Conspiracy',
    'Desert Eagle | Golden Koi',
    'Desert Eagle | Hypnotic',
    'Desert Eagle | Emerald Jörmungandr',
    'Desert Eagle | Sunset Storm',
    'Desert Eagle | Ocean Drive',
    'Desert Eagle | Mecha Industries',
    'Desert Eagle | Cobalt Disruption',
    'Desert Eagle | Crimson Web',
  ];
  static const List<String> _glockSkins = <String>[
    'Glock-18 | Fade',
    'Glock-18 | Water Elemental',
    'Glock-18 | Dragon Tattoo',
    'Glock-18 | Bullet Queen',
    'Glock-18 | Moonrise',
    'Glock-18 | Twilight Galaxy',
    'Glock-18 | Wasteland Rebel',
    'Glock-18 | Neo-Noir',
    'Glock-18 | Snack Attack',
    'Glock-18 | Vogue',
    'Glock-18 | Gamma Doppler',
    'Glock-18 | Weasel',
  ];
  static const List<String> _uspSkins = <String>[
    'USP-S | Kill Confirmed',
    'USP-S | Cortex',
    'USP-S | Neo-Noir',
    'USP-S | Orion',
    'USP-S | Caiman',
    'USP-S | Overgrowth',
    'USP-S | Printstream',
    'USP-S | The Traitor',
    'USP-S | Torque',
    'USP-S | Serum',
    'USP-S | Whiteout',
    'USP-S | Royal Blue',
  ];
  static const List<String> _pistolSkins = <String>[
    'P250 | Sand Dune',
    'P250 | Asiimov',
    'P250 | Mehndi',
    'P250 | Nuclear Threat',
    'P250 | See Ya Later',
    'P250 | Splash',
    'P250 | Undertow',
    'P250 | Wingshot',
    'P250 | Whiteout',
    'P250 | Valence',
    'P250 | Cartel',
    'Five-SeveN | Case Hardened',
    'Five-SeveN | Monkey Business',
    'Five-SeveN | Hyper Beast',
    'Five-SeveN | Angry Mob',
    'Five-SeveN | Fowl Play',
    'Five-SeveN | Copper Galaxy',
    'Five-SeveN | Retrobution',
    'Five-SeveN | Nitro',
    'Five-SeveN | Scumbria',
    'Tec-9 | Fuel Injector',
    'Tec-9 | Nuclear Threat',
    'Tec-9 | Bamboo Forest',
    'Tec-9 | Decimator',
    'Tec-9 | Titanium Bit',
    'Tec-9 | Avalanche',
    'CZ75-Auto | Tigris',
    'CZ75-Auto | The Fuschia Is Now',
    'CZ75-Auto | Xiangliu',
    'CZ75-Auto | Vaporwave',
    'CZ75-Auto | Yellow Jacket',
    'CZ75-Auto | Victoria',
    'P2000 | Fire Elemental',
    'P2000 | Ocean Foam',
    'P2000 | Corticera',
    'P2000 | Woodsman',
    'P2000 | Amber Fade',
    'Dual Berettas | Cobra Strike',
    'Dual Berettas | Dezastre',
    'Dual Berettas | Colony',
    'Dual Berettas | Marina',
    'R8 Revolver | Fade',
    'R8 Revolver | Amber Fade',
    'R8 Revolver | Crimson Web',
    'R8 Revolver | Skull Crusher',
  ];
  static const List<String> _smgSkins = <String>[
    'P90 | Asiimov',
    'P90 | Death by Kitty',
    'P90 | Trigon',
    'P90 | Emerald Dragon',
    'P90 | Nostalgia',
    'P90 | Chopper',
    'P90 | Sunset Motel',
    'P90 | Shallow Grave',
    'P90 | Cold Blooded',
    'MP7 | Neon Ply',
    'MP7 | Bloodsport',
    'MP7 | Nemesis',
    'MP7 | Whiteout',
    'MP7 | Fade',
    'MP7 | Skulls',
    'MP7 | Ocean Foam',
    'MP9 | Hot Rod',
    'MP9 | Bulldozer',
    'MP9 | Airlock',
    'MP9 | Rose Iron',
    'MP9 | Deadly Poison',
    'MAC-10 | Neon Rider',
    'MAC-10 | Fade',
    'MAC-10 | Curse',
    'MAC-10 | Heat',
    'MAC-10 | Stalker',
    'MAC-10 | Disco Tech',
    'MAC-10 | Gold Brick',
    'UMP-45 | Primal Saber',
    'UMP-45 | Blaze',
    'UMP-45 | Momentum',
    'UMP-45 | Grand Prix',
    'UMP-45 | Arctic Wolf',
    'PP-Bizon | Judgement of Anubis',
    'PP-Bizon | Fuel Rod',
    'PP-Bizon | Osiris',
    'PP-Bizon | High Roller',
  ];
  static const List<String> _rifleSkins = <String>[
    'FAMAS | Roll Cage',
    'FAMAS | Afterimage',
    'FAMAS | Pulse',
    'FAMAS | Neural Net',
    'FAMAS | Mecha Industries',
    'Galil AR | Chatterbox',
    'Galil AR | Cerberus',
    'Galil AR | Eco',
    'Galil AR | Firestarter',
    'Galil AR | Sandstorm',
    'Galil AR | Chromatic Aberration',
    'AUG | Chameleon',
    'AUG | Akihabara Accept',
    'AUG | Torque',
    'AUG | Hot Rod',
    'AUG | Fleet Flock',
    'SG 553 | Integrale',
    'SG 553 | Cyrex',
    'SG 553 | Pulse',
    'SG 553 | Ultraviolet',
    'SG 553 | Tiger Moth',
  ];
  static const List<String> _sniperSkins = <String>[
    'SSG 08 | Dragonfire',
    'SSG 08 | Blood in the Water',
    'SSG 08 | Big Iron',
    'SSG 08 | Acid Fade',
    'SCAR-20 | Cardiac',
    'SCAR-20 | Bloodsport',
    'SCAR-20 | Powercore',
    'SCAR-20 | Splash Jam',
    'G3SG1 | The Executioner',
    'G3SG1 | Flux',
    'G3SG1 | Orange Crash',
    'G3SG1 | Chronos',
  ];
  static const List<String> _heavySkins = <String>[
    'Nova | Hyper Beast',
    'Nova | Antique',
    'Nova | Koi',
    'Nova | Wild Six',
    'XM1014 | Tranquility',
    'XM1014 | Seasons',
    'XM1014 | Incinegator',
    'XM1014 | Blaze Orange',
    'MAG-7 | Cinqedea',
    'MAG-7 | Popdog',
    'MAG-7 | Justice',
    'Sawed-Off | The Kraken',
    'Sawed-Off | Wasteland Princess',
    'Sawed-Off | Serenity',
    'M249 | Nebula Crusader',
    'M249 | System Lock',
    'M249 | Aztec',
    'Negev | Mjölnir',
    'Negev | Power Loader',
    'Negev | Loudmouth',
  ];

  static const List<String> skins = <String>[
    ..._akSkins,
    ..._m4a4Skins,
    ..._m4a1sSkins,
    ..._awpSkins,
    ..._deagleSkins,
    ..._glockSkins,
    ..._uspSkins,
    ..._pistolSkins,
    ..._smgSkins,
    ..._rifleSkins,
    ..._sniperSkins,
    ..._heavySkins,
  ];

  static const List<String> knives = <String>[
    'Karambit | Doppler',
    'Karambit | Fade',
    'Karambit | Crimson Web',
    'Karambit | Tiger Tooth',
    'Karambit | Marble Fade',
    'Karambit | Case Hardened',
    'Karambit | Slaughter',
    'Karambit | Lore',
    'Karambit | Autotronic',
    'Karambit | Black Laminate',
    'Butterfly Knife | Fade',
    'Butterfly Knife | Doppler',
    'Butterfly Knife | Crimson Web',
    'Butterfly Knife | Tiger Tooth',
    'Butterfly Knife | Marble Fade',
    'Butterfly Knife | Slaughter',
    'M9 Bayonet | Doppler',
    'M9 Bayonet | Marble Fade',
    'M9 Bayonet | Tiger Tooth',
    'M9 Bayonet | Crimson Web',
    'M9 Bayonet | Case Hardened',
    'Bayonet | Crimson Web',
    'Bayonet | Doppler',
    'Bayonet | Marble Fade',
    'Talon Knife | Doppler',
    'Talon Knife | Fade',
    'Flip Knife | Fade',
    'Flip Knife | Doppler',
    'Gut Knife | Fade',
    'Gut Knife | Doppler',
    'Huntsman Knife | Fade',
    'Huntsman Knife | Crimson Web',
    'Falchion Knife | Fade',
    'Falchion Knife | Marble Fade',
    'Shadow Daggers | Fade',
    'Shadow Daggers | Doppler',
    'Bowie Knife | Doppler',
    'Bowie Knife | Marble Fade',
    'Ursus Knife | Doppler',
    'Navaja Knife | Doppler',
    'Stiletto Knife | Doppler',
    'Paracord Knife | Fade',
    'Survival Knife | Fade',
    'Classic Knife | Doppler',
    'Skeleton Knife | Fade',
    'Nomad Knife | Doppler',
  ];

  static const List<String> gloves = <String>[
    "Sport Gloves | Pandora's Box",
    'Sport Gloves | Vice',
    'Sport Gloves | Amphibious',
    'Sport Gloves | Superconductor',
    'Sport Gloves | Hedge Maze',
    'Specialist Gloves | Crimson Kimono',
    'Specialist Gloves | Fade',
    'Specialist Gloves | Emerald Web',
    'Specialist Gloves | Marble Fade',
    'Driver Gloves | King Snake',
    'Driver Gloves | Crimson Weave',
    'Driver Gloves | Lunar Weave',
    'Hand Wraps | Cobalt Skulls',
    'Hand Wraps | Leather',
    'Hand Wraps | Spruce DDPAT',
    'Moto Gloves | Spearmint',
    'Moto Gloves | Boom!',
    'Moto Gloves | Cool Mint',
    'Hydra Gloves | Case Hardened',
    'Hydra Gloves | Emerald',
    'Broken Fang Gloves | Jade',
    'Broken Fang Gloves | Unhinged',
    'Bloodhound Gloves | Charred',
    'Bloodhound Gloves | Guerrilla',
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
  static const String valueSnapshotsBoxName = 'value_snapshots';
  static const String watchlistBoxName = 'watchlist';
  static const String rankSnapshotsBoxName = 'rank_snapshots';
  static const String itemPriceSnapshotsBoxName = 'item_price_snapshots';
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
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ValueSnapshotAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(WatchlistItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(RankSnapshotAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(ItemPriceSnapshotAdapter());
    }

    // Apertura de boxes.
    await Hive.openBox<CsAccount>(accountsBoxName);
    await Hive.openBox<InventoryItem>(inventoryBoxName);
    await Hive.openBox<PriceCacheEntry>(priceCacheBoxName);
    await Hive.openBox<SaleRecord>(salesBoxName);
    await Hive.openBox<ValueSnapshot>(valueSnapshotsBoxName);
    await Hive.openBox<WatchlistItem>(watchlistBoxName);
    await Hive.openBox<RankSnapshot>(rankSnapshotsBoxName);
    await Hive.openBox<ItemPriceSnapshot>(itemPriceSnapshotsBoxName);
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
  static Box<ValueSnapshot> get valueSnapshotsBox =>
      Hive.box<ValueSnapshot>(valueSnapshotsBoxName);
  static Box<WatchlistItem> get watchlistBox =>
      Hive.box<WatchlistItem>(watchlistBoxName);
  static Box<RankSnapshot> get rankSnapshotsBox =>
      Hive.box<RankSnapshot>(rankSnapshotsBoxName);
  static Box<ItemPriceSnapshot> get itemPriceSnapshotsBox =>
      Hive.box<ItemPriceSnapshot>(itemPriceSnapshotsBoxName);

  static AppSettings get settings => settingsBox.get(settingsKey)!;
}
