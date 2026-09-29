import 'package:dio/dio.dart';

/// Kills/disparos/aciertos de por vida con un arma o categoría concreta.
class WeaponStat {
  final String key;
  final String label;
  final int kills;
  final int shots;
  final int hits;

  const WeaponStat({
    required this.key,
    required this.label,
    required this.kills,
    required this.shots,
    required this.hits,
  });

  /// Null si el arma no tiene disparos registrados (cuchillo, granadas...).
  double? get accuracyPercent => shots == 0 ? null : hits / shots * 100;
}

/// Rondas jugadas/ganadas de por vida en un mapa concreto.
class MapStat {
  final String key;
  final String label;
  final int wins;
  final int rounds;

  const MapStat({
    required this.key,
    required this.label,
    required this.wins,
    required this.rounds,
  });

  double get winRatePercent => rounds == 0 ? 0 : wins / rounds * 100;
}

/// Nombres de armas conocidas por Valve en la API de stats de CS2, con
/// disparos/aciertos registrados (por eso tienen precisión calculable).
const Map<String, String> _gunLabels = {
  'glock': 'Glock-18',
  'hkp2000': 'P2000',
  'elite': 'Dual Berettas',
  'fiveseven': 'Five-SeveN',
  'deagle': 'Desert Eagle',
  'tec9': 'Tec-9',
  'p250': 'P250',
  'mag7': 'MAG-7',
  'sawedoff': 'Sawed-Off',
  'negev': 'Negev',
  'mac10': 'MAC-10',
  'ump45': 'UMP-45',
  'p90': 'P90',
  'bizon': 'PP-Bizon',
  'mp7': 'MP7',
  'mp9': 'MP9',
  'ak47': 'AK-47',
  'aug': 'AUG',
  'sg556': 'SG 553',
  'famas': 'FAMAS',
  'galilar': 'Galil AR',
  'm4a1': 'M4A4 / M4A1-S',
  'ssg08': 'SSG 08',
  'awp': 'AWP',
  'scar20': 'SCAR-20',
  'g3sg1': 'G3SG1',
  'm249': 'M249',
  'xm1014': 'XM1014',
  'nova': 'Nova',
};

/// Armas/categorías sin disparos registrados (cuchillo cuerpo a cuerpo,
/// granadas): solo tienen kills.
const Map<String, String> _specialKillLabels = {
  'knife': 'Cuchillo',
  'hegrenade': 'Granada',
  'molotov': 'Incendiaria / Molotov',
  'taser': 'Zeus x27',
};

/// Códigos de mapa conocidos (activos y legado/arms race). Un mapa que el
/// jugador nunca haya jugado no aparece en la respuesta de Steam, así que
/// esta lista solo filtra cuáles mostrar de entre los que sí tiene.
const Map<String, String> _mapLabels = {
  'de_dust2': 'Dust II',
  'de_inferno': 'Inferno',
  'de_nuke': 'Nuke',
  'de_train': 'Train',
  'de_mirage': 'Mirage',
  'de_ancient': 'Ancient',
  'de_anubis': 'Anubis',
  'de_overpass': 'Overpass',
  'de_vertigo': 'Vertigo',
  'de_cache': 'Cache',
  'de_cbble': 'Cobblestone',
  'cs_office': 'Office',
  'cs_italy': 'Italy',
  'cs_assault': 'Assault',
  'ar_shoots': 'Shoots (Arms Race)',
  'ar_baggage': 'Baggage (Arms Race)',
  'ar_pool_day': 'Pool Day (Arms Race)',
};

/// Estadísticas de por vida de CS2 leídas de Steam (ISteamUserStats).
/// Valve no expone el rango competitivo/Premier por esta API pública —
/// esto son solo contadores históricos, no el rango actual.
class Cs2LifetimeStats {
  final int kills;
  final int deaths;
  final int wins;
  final int matchesPlayed;
  final int mvps;
  final int headshotKills;
  final int shotsFired;
  final int roundsPlayed;
  final Duration timePlayed;

  final int plantedBombs;
  final int defusedBombs;
  final int damageDone;
  final int pistolRoundWins;
  final int enemyWeaponKills;
  final int blindKills;
  final int weaponsDonated;

  /// Por arma, ordenado por kills descendente. Solo incluye armas con al
  /// menos 1 kill o 1 disparo registrado.
  final List<WeaponStat> weapons;

  /// Kills sin disparos asociados (cuchillo, granadas), ordenado por kills.
  final List<WeaponStat> specialKills;

  /// Por mapa, ordenado por rondas jugadas descendente. Solo mapas jugados.
  final List<MapStat> maps;

  const Cs2LifetimeStats({
    required this.kills,
    required this.deaths,
    required this.wins,
    required this.matchesPlayed,
    required this.mvps,
    required this.headshotKills,
    required this.shotsFired,
    required this.roundsPlayed,
    required this.timePlayed,
    required this.plantedBombs,
    required this.defusedBombs,
    required this.damageDone,
    required this.pistolRoundWins,
    required this.enemyWeaponKills,
    required this.blindKills,
    required this.weaponsDonated,
    required this.weapons,
    required this.specialKills,
    required this.maps,
  });

  double get kdRatio => deaths == 0 ? kills.toDouble() : kills / deaths;
  double get headshotPercent => kills == 0 ? 0 : headshotKills / kills * 100;
  double get winRatePercent =>
      matchesPlayed == 0 ? 0 : wins / matchesPlayed * 100;

  /// Daño medio por ronda (ADR), calculado a partir del daño total y las
  /// rondas jugadas de por vida.
  double get adr => roundsPlayed == 0 ? 0 : damageDone / roundsPlayed;

  /// Precisión global: no viene como un único campo en la API, así que se
  /// deriva sumando aciertos/disparos de todas las armas con esos datos.
  double get accuracyPercent {
    final totalShots = weapons.fold<int>(0, (a, w) => a + w.shots);
    final totalHits = weapons.fold<int>(0, (a, w) => a + w.hits);
    return totalShots == 0 ? 0 : totalHits / totalShots * 100;
  }

  factory Cs2LifetimeStats.fromRaw(Map<String, num> raw) {
    int i(String key) => (raw[key] ?? 0).toInt();

    final weapons = <WeaponStat>[
      for (final entry in _gunLabels.entries)
        if (i('total_kills_${entry.key}') > 0 || i('total_shots_${entry.key}') > 0)
          WeaponStat(
            key: entry.key,
            label: entry.value,
            kills: i('total_kills_${entry.key}'),
            shots: i('total_shots_${entry.key}'),
            hits: i('total_hits_${entry.key}'),
          ),
    ]..sort((a, b) => b.kills.compareTo(a.kills));

    final specialKills = <WeaponStat>[
      for (final entry in _specialKillLabels.entries)
        if (i('total_kills_${entry.key}') > 0)
          WeaponStat(
            key: entry.key,
            label: entry.value,
            kills: i('total_kills_${entry.key}'),
            shots: 0,
            hits: 0,
          ),
    ]..sort((a, b) => b.kills.compareTo(a.kills));

    final maps = <MapStat>[
      for (final entry in _mapLabels.entries)
        if (i('total_rounds_map_${entry.key}') > 0)
          MapStat(
            key: entry.key,
            label: entry.value,
            wins: i('total_wins_map_${entry.key}'),
            rounds: i('total_rounds_map_${entry.key}'),
          ),
    ]..sort((a, b) => b.rounds.compareTo(a.rounds));

    return Cs2LifetimeStats(
      kills: i('total_kills'),
      deaths: i('total_deaths'),
      // 'total_wins' cuenta RONDAS ganadas, no partidas: con 'matchesPlayed'
      // (partidas) el % de victorias saldría por encima del 100%. La
      // partida ganada de verdad es 'total_matches_won'.
      wins: i('total_matches_won'),
      matchesPlayed: i('total_matches_played'),
      mvps: i('total_mvps'),
      headshotKills: i('total_kills_headshot'),
      shotsFired: i('total_shots_fired'),
      roundsPlayed: i('total_rounds_played'),
      timePlayed: Duration(seconds: i('total_time_played')),
      plantedBombs: i('total_planted_bombs'),
      defusedBombs: i('total_defused_bombs'),
      damageDone: i('total_damage_done'),
      pistolRoundWins: i('total_wins_pistolround'),
      enemyWeaponKills: i('total_kills_enemy_weapon'),
      blindKills: i('total_kills_enemy_blinded'),
      weaponsDonated: i('total_weapons_donated'),
      weapons: weapons,
      specialKills: specialKills,
      maps: maps,
    );
  }
}

/// Consulta ISteamUserStats/GetUserStatsForGame con la API key y el
/// SteamID64 que el usuario guardó localmente en Ajustes (nunca se
/// commitea ni viaja a CI). Devuelve `null` si el perfil/stats del juego
/// no son públicos, la key es inválida, o hay cualquier error de red.
class SteamStatsService {
  SteamStatsService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;
  static const _url =
      'https://api.steampowered.com/ISteamUserStats/GetUserStatsForGame/v2/';

  Future<Cs2LifetimeStats?> fetchLifetimeStats({
    required String apiKey,
    required String steamId64,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        _url,
        queryParameters: <String, dynamic>{
          'appid': 730,
          'key': apiKey,
          'steamid': steamId64,
        },
      );
      final playerStats = resp.data?['playerstats'];
      if (playerStats is! Map) return null;
      final statsList = playerStats['stats'];
      if (statsList is! List) return null;

      final raw = <String, num>{};
      for (final entry in statsList) {
        if (entry is! Map) continue;
        final name = entry['name'] as String?;
        final value = entry['value'];
        if (name != null && value is num) raw[name] = value;
      }
      return Cs2LifetimeStats.fromRaw(raw);
    } catch (_) {
      return null;
    }
  }
}
