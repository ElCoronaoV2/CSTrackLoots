import 'package:hive/hive.dart';

part 'cs_account.g.dart';

/// Cuenta de CS2 del usuario. Se identifica SOLO por alias (sin credenciales).
@HiveType(typeId: 0)
class CsAccount extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String alias;

  /// True si esta cuenta ya cobró el drop semanal en curso.
  @HiveField(2)
  bool dropObtainedThisWeek;

  /// Fecha del último drop registrado.
  @HiveField(3)
  DateTime? lastDropDate;

  /// Rating Premier (0 si no establecido).
  @HiveField(4)
  int premierRating;

  /// Rango competitivo por mapa (almacenamos el nombre del enum como String).
  @HiveField(5)
  Map<String, String> mapRanks;

  /// Rango Wingman (mismo enum que competitivo).
  @HiveField(6)
  String? wingmanRank;

  /// Orden manual (para futuras features de drag/sort).
  @HiveField(7)
  int sortIndex;

  /// True si el usuario marcó esta cuenta como "drop perdido esta semana"
  /// (no llegó a jugar / se olvidó). Estado visual en rojo.
  @HiveField(8)
  bool dropMissedThisWeek;

  // -- Estadísticas históricas (se actualizan en cada reset semanal automático) --

  /// Total de drops conseguidos en todas las semanas registradas.
  @HiveField(9)
  int totalObtained;

  /// Total de drops perdidos (marcado por el usuario o por no marcarlos).
  @HiveField(10)
  int totalMissed;

  /// Racha actual de drops conseguidos seguidos. Se resetea a 0 al perder uno.
  @HiveField(11)
  int currentStreak;

  /// Racha máxima histórica (récord personal del usuario para esta cuenta).
  @HiveField(12)
  int bestStreak;

  /// SteamID64 de esta cuenta concreta, para consultar sus stats de CS2 de
  /// por vida con la API key global guardada en Ajustes. Opcional: cada
  /// cuenta tiene el suyo, a diferencia de la API key (que es una sola).
  @HiveField(13)
  String? steamId64;

  CsAccount({
    required this.id,
    required this.alias,
    this.dropObtainedThisWeek = false,
    this.lastDropDate,
    this.premierRating = 0,
    Map<String, String>? mapRanks,
    this.wingmanRank,
    this.sortIndex = 0,
    this.dropMissedThisWeek = false,
    this.totalObtained = 0,
    this.totalMissed = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.steamId64,
  }) : mapRanks = mapRanks ?? <String, String>{};

  /// Total de semanas contabilizadas (obtenidos + perdidos).
  int get totalWeeks => totalObtained + totalMissed;

  /// Porcentaje de éxito (0..100). Devuelve -1 si no hay semanas registradas.
  double get successRate =>
      totalWeeks == 0 ? -1 : (totalObtained / totalWeeks) * 100.0;
}
