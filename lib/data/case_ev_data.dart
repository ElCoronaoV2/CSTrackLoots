/// Datos de contenido de cajas para la calculadora de EV (valor esperado) y
/// de trade-up. Cobertura PARCIAL a propósito: solo se incluyen cajas cuyo
/// contenido (nombre real en inglés de cada skin + rareza) se ha podido
/// verificar contra fuentes públicas (csgodatabase, csgoskins.gg, dotesports,
/// etc.), en vez de traducir a ciegas el catálogo en español del usuario —
/// una traducción incorrecta daría un EV falso, que es peor que no tener la
/// función. Se irán añadiendo más cajas con el tiempo.
library;

/// Probabilidades oficiales de Valve por rareza (iguales para todas las
/// cajas). Dentro de cada rareza, la probabilidad se reparte a partes
/// iguales entre todos los items de esa rareza en la caja.
enum SkinRarity { milSpec, restricted, classified, covert, rareSpecial }

extension SkinRarityX on SkinRarity {
  double get dropChance {
    switch (this) {
      case SkinRarity.milSpec:
        return 0.7992;
      case SkinRarity.restricted:
        return 0.1598;
      case SkinRarity.classified:
        return 0.032;
      case SkinRarity.covert:
        return 0.0064;
      case SkinRarity.rareSpecial:
        return 0.0026;
    }
  }

  String get labelEs {
    switch (this) {
      case SkinRarity.milSpec:
        return 'Grado militar';
      case SkinRarity.restricted:
        return 'Restringido';
      case SkinRarity.classified:
        return 'Clasificado';
      case SkinRarity.covert:
        return 'Encubierto';
      case SkinRarity.rareSpecial:
        return 'Especial (cuchillo)';
    }
  }
}

class CaseSkinEntry {
  final String name;
  final SkinRarity rarity;
  const CaseSkinEntry(this.name, this.rarity);
}

class CaseEvData {
  /// Skins de arma normales (rarezas mil-spec a encubierto).
  final List<CaseSkinEntry> weapons;

  /// Nombre base del cuchillo especial de esta caja (p.ej. "★ Kukri Knife"),
  /// o null si esta caja no tiene cuchillo (o no se ha podido verificar).
  final String? knifeBaseName;

  /// Acabados del cuchillo especial (p.ej. "Fade", "Doppler"...).
  final List<String> knifeFinishes;

  const CaseEvData({
    required this.weapons,
    this.knifeBaseName,
    this.knifeFinishes = const [],
  });
}

/// Acabados "clásicos" (cajas 2015-2019: Bayonet, Karambit, M9, Butterfly,
/// Flip, Gut, Huntsman, Falchion, Shadow Daggers, Bowie, Ursus, Navaja,
/// Stiletto, Classic, y también el Kukri de 2024).
const List<String> kClassicKnifeFinishes = [
  'Fade',
  'Slaughter',
  'Crimson Web',
  'Case Hardened',
  'Blue Steel',
  'Stained',
  'Safari Mesh',
  'Scorched',
  'Boreal Forest',
  'Night',
  'Urban Masked',
  'Forest DDPAT',
];

/// Acabados "modernos" (cuchillos 2019+: Nomad, Paracord, Skeleton, Survival,
/// Talon).
const List<String> kModernKnifeFinishes = [
  'Doppler',
  'Marble Fade',
  'Tiger Tooth',
  'Damascus Steel',
  'Rust Coat',
  'Ultraviolet',
];

/// Cajas cubiertas, indexadas por su nombre en inglés (el mismo usado en
/// SeedItems.cases). Contenido verificado manualmente contra fuentes
/// públicas de precios/contenido de cajas de CS2.
final Map<String, CaseEvData> kCaseEvData = {
  'Kilowatt Case': const CaseEvData(
    weapons: [
      CaseSkinEntry('AK-47 | Inheritance', SkinRarity.covert),
      CaseSkinEntry('AWP | Chrome Cannon', SkinRarity.covert),
      CaseSkinEntry('M4A1-S | Black Lotus', SkinRarity.classified),
      CaseSkinEntry('USP-S | Jawbreaker', SkinRarity.classified),
      CaseSkinEntry('Zeus x27 | Olympus', SkinRarity.classified),
      CaseSkinEntry('Glock-18 | Block-18', SkinRarity.restricted),
      CaseSkinEntry('MP7 | Just Smile', SkinRarity.restricted),
      CaseSkinEntry('Five-SeveN | Hybrid', SkinRarity.restricted),
      CaseSkinEntry('Sawed-Off | Analog Input', SkinRarity.restricted),
      CaseSkinEntry('M4A4 | Etch Lord', SkinRarity.restricted),
      CaseSkinEntry('SSG 08 | Dezastre', SkinRarity.milSpec),
      CaseSkinEntry('MAC-10 | Light Box', SkinRarity.milSpec),
      CaseSkinEntry('UMP-45 | Motorized', SkinRarity.milSpec),
      CaseSkinEntry('Tec-9 | Slag', SkinRarity.milSpec),
      CaseSkinEntry('Dual Berettas | Hideout', SkinRarity.milSpec),
      CaseSkinEntry('Nova | Dark Sigil', SkinRarity.milSpec),
      CaseSkinEntry('XM1014 | Irezumi', SkinRarity.milSpec),
    ],
    knifeBaseName: '★ Kukri Knife',
    knifeFinishes: kClassicKnifeFinishes,
  ),
  'Fever Case': const CaseEvData(
    weapons: [
      CaseSkinEntry('AWP | PrintStream', SkinRarity.covert),
      CaseSkinEntry('FAMAS | Bad Trip', SkinRarity.covert),
      CaseSkinEntry('AK-47 | Searing Rage', SkinRarity.classified),
      CaseSkinEntry('Glock-18 | Shinobu', SkinRarity.classified),
      CaseSkinEntry('UMP-45 | K.O. Factory', SkinRarity.classified),
      CaseSkinEntry('Desert Eagle | Serpent Strike', SkinRarity.restricted),
      CaseSkinEntry('Zeus x27 | Tosai', SkinRarity.restricted),
      CaseSkinEntry('Galil AR | Control', SkinRarity.restricted),
      CaseSkinEntry('P90 | Wave Breaker', SkinRarity.restricted),
      CaseSkinEntry('Nova | Rising Sun', SkinRarity.restricted),
      CaseSkinEntry('USP-S | PC-GRN', SkinRarity.milSpec),
      CaseSkinEntry('M4A4 | Choppa', SkinRarity.milSpec),
      CaseSkinEntry('SSG 08 | Memorial', SkinRarity.milSpec),
      CaseSkinEntry('MP9 | Nexus', SkinRarity.milSpec),
      CaseSkinEntry('XM1014 | Mockingbird', SkinRarity.milSpec),
      CaseSkinEntry('MAG-7 | Resupply', SkinRarity.milSpec),
      CaseSkinEntry('P2000 | Sure Grip', SkinRarity.milSpec),
    ],
    // 4 tipos de cuchillo posibles (Nomad, Paracord, Skeleton, Survival);
    // se usa Nomad como representante para estimar precio del nivel.
    knifeBaseName: '★ Nomad Knife',
    knifeFinishes: kModernKnifeFinishes,
  ),
  'Gallery Case': const CaseEvData(
    weapons: [
      CaseSkinEntry('M4A1-S | Vaporwave', SkinRarity.covert),
      CaseSkinEntry('Glock-18 | Gold Toof', SkinRarity.covert),
      CaseSkinEntry('AK-47 | The Outsiders', SkinRarity.classified),
      CaseSkinEntry('UMP-45 | Neo-Noir', SkinRarity.classified),
      CaseSkinEntry('P250 | Epicenter', SkinRarity.classified),
      CaseSkinEntry('M4A4 | Turbine', SkinRarity.restricted),
      CaseSkinEntry('SSG 08 | Rapid Transit', SkinRarity.restricted),
      CaseSkinEntry('MAC-10 | Saiba Oni', SkinRarity.restricted),
      CaseSkinEntry('P90 | Randy Rush', SkinRarity.restricted),
      CaseSkinEntry('Dual Berettas | Hydro Strike', SkinRarity.restricted),
      CaseSkinEntry('Desert Eagle | Calligraffiti', SkinRarity.milSpec),
      CaseSkinEntry('USP-S | 27', SkinRarity.milSpec),
      CaseSkinEntry('AUG | Luxe Trim', SkinRarity.milSpec),
      CaseSkinEntry('SCAR-20 | Trail Blazer', SkinRarity.milSpec),
      CaseSkinEntry('MP5-SD | Statics', SkinRarity.milSpec),
      CaseSkinEntry('R8 Revolver | Tango', SkinRarity.milSpec),
      CaseSkinEntry('M249 | Hypnosis', SkinRarity.milSpec),
    ],
    knifeBaseName: '★ Kukri Knife',
    knifeFinishes: kClassicKnifeFinishes,
  ),
};
