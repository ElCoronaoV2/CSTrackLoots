import 'package:hive/hive.dart';

part 'cs_rank_enums.g.dart';

/// Mapas competitivos oficiales que el usuario puede registrar.
@HiveType(typeId: 1)
enum CsMap {
  @HiveField(0)
  mirage,
  @HiveField(1)
  inferno,
  @HiveField(2)
  dust2,
  @HiveField(3)
  nuke,
  @HiveField(4)
  ancient,
  @HiveField(5)
  anubis,
  @HiveField(6)
  vertigo,
  @HiveField(7)
  office,
}

extension CsMapX on CsMap {
  String get label {
    switch (this) {
      case CsMap.mirage:
        return 'Mirage';
      case CsMap.inferno:
        return 'Inferno';
      case CsMap.dust2:
        return 'Dust II';
      case CsMap.nuke:
        return 'Nuke';
      case CsMap.ancient:
        return 'Ancient';
      case CsMap.anubis:
        return 'Anubis';
      case CsMap.vertigo:
        return 'Vertigo';
      case CsMap.office:
        return 'Office';
    }
  }
}

/// Rango competitivo (mismo set para Competitivo y Wingman, aunque Wingman
/// típicamente no llega a Global Elite; mantenemos los 18 valores).
@HiveType(typeId: 2)
enum CompetitiveRank {
  @HiveField(0)
  silver1,
  @HiveField(1)
  silver2,
  @HiveField(2)
  silver3,
  @HiveField(3)
  silver4,
  @HiveField(4)
  silverElite,
  @HiveField(5)
  silverEliteMaster,
  @HiveField(6)
  goldNova1,
  @HiveField(7)
  goldNova2,
  @HiveField(8)
  goldNova3,
  @HiveField(9)
  goldNovaMaster,
  @HiveField(10)
  masterGuardian1,
  @HiveField(11)
  masterGuardian2,
  @HiveField(12)
  masterGuardianElite,
  @HiveField(13)
  distinguishedMasterGuardian,
  @HiveField(14)
  legendaryEagle,
  @HiveField(15)
  legendaryEagleMaster,
  @HiveField(16)
  supremeMasterFirstClass,
  @HiveField(17)
  globalElite,
}

extension CompetitiveRankX on CompetitiveRank {
  String get label {
    switch (this) {
      case CompetitiveRank.silver1:
        return 'Silver 1';
      case CompetitiveRank.silver2:
        return 'Silver 2';
      case CompetitiveRank.silver3:
        return 'Silver 3';
      case CompetitiveRank.silver4:
        return 'Silver 4';
      case CompetitiveRank.silverElite:
        return 'Silver Elite';
      case CompetitiveRank.silverEliteMaster:
        return 'Silver Elite Master';
      case CompetitiveRank.goldNova1:
        return 'Gold Nova 1';
      case CompetitiveRank.goldNova2:
        return 'Gold Nova 2';
      case CompetitiveRank.goldNova3:
        return 'Gold Nova 3';
      case CompetitiveRank.goldNovaMaster:
        return 'Gold Nova Master';
      case CompetitiveRank.masterGuardian1:
        return 'Master Guardian 1';
      case CompetitiveRank.masterGuardian2:
        return 'Master Guardian 2';
      case CompetitiveRank.masterGuardianElite:
        return 'Master Guardian Elite';
      case CompetitiveRank.distinguishedMasterGuardian:
        return 'Distinguished MG';
      case CompetitiveRank.legendaryEagle:
        return 'Legendary Eagle';
      case CompetitiveRank.legendaryEagleMaster:
        return 'Legendary Eagle Master';
      case CompetitiveRank.supremeMasterFirstClass:
        return 'Supreme Master 1st Class';
      case CompetitiveRank.globalElite:
        return 'Global Elite';
    }
  }

  /// Índice numérico 0-17 (útil para ordenar y mostrar progreso).
  int get indexValue => CompetitiveRank.values.indexOf(this);
}

/// Rangos Premier (asignados por tramos de rating).
/// La medalla cambia de color automáticamente según el rating numérico.
enum PremierTier {
  gray,    // 0-4999
  lightBlue, // 5000-9999
  blue,    // 10000-14999
  purple,  // 15000-19999
  pink,    // 20000-24999
  red,     // 25000-29999
  gold,    // 30000+
}

extension PremierTierX on PremierTier {
  String get label {
    switch (this) {
      case PremierTier.gray:
        return 'Gris';
      case PremierTier.lightBlue:
        return 'Celeste';
      case PremierTier.blue:
        return 'Azul';
      case PremierTier.purple:
        return 'Morado';
      case PremierTier.pink:
        return 'Rosa';
      case PremierTier.red:
        return 'Rojo';
      case PremierTier.gold:
        return 'Dorado';
    }
  }
}

/// Calcula la medalla Premier en función del rating numérico.
PremierTier tierForPremier(int rating) {
  if (rating >= 30000) return PremierTier.gold;
  if (rating >= 25000) return PremierTier.red;
  if (rating >= 20000) return PremierTier.pink;
  if (rating >= 15000) return PremierTier.purple;
  if (rating >= 10000) return PremierTier.blue;
  if (rating >= 5000) return PremierTier.lightBlue;
  return PremierTier.gray;
}
