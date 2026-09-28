import 'package:dio/dio.dart';

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
  final int shotsHit;
  final int roundsPlayed;
  final Duration timePlayed;

  const Cs2LifetimeStats({
    required this.kills,
    required this.deaths,
    required this.wins,
    required this.matchesPlayed,
    required this.mvps,
    required this.headshotKills,
    required this.shotsFired,
    required this.shotsHit,
    required this.roundsPlayed,
    required this.timePlayed,
  });

  double get kdRatio => deaths == 0 ? kills.toDouble() : kills / deaths;
  double get headshotPercent => kills == 0 ? 0 : headshotKills / kills * 100;
  double get accuracyPercent =>
      shotsFired == 0 ? 0 : shotsHit / shotsFired * 100;
  double get winRatePercent =>
      matchesPlayed == 0 ? 0 : wins / matchesPlayed * 100;

  factory Cs2LifetimeStats.fromRaw(Map<String, num> raw) {
    int i(String key) => (raw[key] ?? 0).toInt();
    return Cs2LifetimeStats(
      kills: i('total_kills'),
      deaths: i('total_deaths'),
      wins: i('total_wins'),
      matchesPlayed: i('total_matches_played'),
      mvps: i('total_mvps'),
      headshotKills: i('total_kills_headshot'),
      shotsFired: i('total_shots_fired'),
      shotsHit: i('total_shots_hit'),
      roundsPlayed: i('total_rounds_played'),
      timePlayed: Duration(seconds: i('total_time_played')),
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
