import 'package:flutter/material.dart';

import '../services/steam_stats_service.dart';

/// Grid de estadísticas de por vida de CS2 (kills, K/D, victorias...),
/// usado tanto en la ficha de cuenta como allí donde se consulten stats
/// de Steam.
class SteamStatsGrid extends StatelessWidget {
  const SteamStatsGrid({super.key, required this.stats});

  final Cs2LifetimeStats stats;

  @override
  Widget build(BuildContext context) {
    final hours = stats.timePlayed.inMinutes / 60;
    final items = <(String, String)>[
      ('Kills', '${stats.kills}'),
      ('Muertes', '${stats.deaths}'),
      ('Ratio K/D', stats.kdRatio.toStringAsFixed(2)),
      ('Victorias', '${stats.wins}'),
      ('Partidas', '${stats.matchesPlayed}'),
      ('% victorias', '${stats.winRatePercent.toStringAsFixed(1)}%'),
      ('MVPs', '${stats.mvps}'),
      ('% headshot', '${stats.headshotPercent.toStringAsFixed(1)}%'),
      ('Precisión', '${stats.accuracyPercent.toStringAsFixed(1)}%'),
      ('Horas jugadas', hours.toStringAsFixed(0)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: items.map((e) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1318),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A313B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.$2,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              Text(e.$1,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
