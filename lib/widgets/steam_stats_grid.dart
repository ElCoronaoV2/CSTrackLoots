import 'package:flutter/material.dart';

import '../services/steam_stats_service.dart';
import '../theme/app_theme.dart';

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
      ('Daño/ronda (ADR)', stats.adr.toStringAsFixed(0)),
      ('Bombas plantadas', '${stats.plantedBombs}'),
      ('Bombas desactivadas', '${stats.defusedBombs}'),
      ('Rondas pistola ganadas', '${stats.pistolRoundWins}'),
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

/// Lista de las armas más usadas (kills + precisión), ordenadas por kills.
/// [maxShown] limita cuántas se muestran de golpe (el resto queda oculto).
class SteamWeaponStatsList extends StatelessWidget {
  const SteamWeaponStatsList({
    super.key,
    required this.weapons,
    required this.specialKills,
    this.maxShown = 8,
  });

  final List<WeaponStat> weapons;
  final List<WeaponStat> specialKills;
  final int maxShown;

  @override
  Widget build(BuildContext context) {
    if (weapons.isEmpty && specialKills.isEmpty) {
      return const Text(
        'Todavía no hay kills registrados con ningún arma.',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      );
    }
    final shown = weapons.take(maxShown).toList();
    return Column(
      children: [
        for (final w in shown) _WeaponRow(weapon: w),
        if (specialKills.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CUERPO A CUERPO Y GRANADAS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          for (final w in specialKills) _WeaponRow(weapon: w),
        ],
      ],
    );
  }
}

class _WeaponRow extends StatelessWidget {
  const _WeaponRow({required this.weapon});
  final WeaponStat weapon;

  @override
  Widget build(BuildContext context) {
    final accuracy = weapon.accuracyPercent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1318),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A313B)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(weapon.label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text('${weapon.kills} kills',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              accuracy == null ? '—' : '${accuracy.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppTheme.csOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de mapas jugados (rondas + % de victorias), ordenados por rondas.
class SteamMapStatsList extends StatelessWidget {
  const SteamMapStatsList({super.key, required this.maps});

  final List<MapStat> maps;

  @override
  Widget build(BuildContext context) {
    if (maps.isEmpty) {
      return const Text(
        'Todavía no hay rondas registradas en ningún mapa reconocido.',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      );
    }
    return Column(
      children: [for (final m in maps) _MapRow(map: m)],
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow({required this.map});
  final MapStat map;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1318),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A313B)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(map.label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text('${map.rounds} rondas',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${map.winRatePercent.toStringAsFixed(0)}% W',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppTheme.csGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
