import 'package:flutter/material.dart';

import '../models/cs_rank_enums.dart';
import '../theme/app_theme.dart';

/// Medalla color-coded según el rating Premier.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rating, this.size = 56});
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tier = tierForPremier(rating);
    final color = AppTheme.premierTierColor(tier.label);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.55)],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rating',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.30,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
    );
  }
}

class PremierTierChip extends StatelessWidget {
  const PremierTierChip({super.key, required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    final tier = tierForPremier(rating);
    final color = AppTheme.premierTierColor(tier.label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tier.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class CompetitiveRankDropdown extends StatelessWidget {
  const CompetitiveRankDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CompetitiveRank? value;
  final ValueChanged<CompetitiveRank?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CompetitiveRank>(
      initialValue: value,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      dropdownColor: const Color(0xFF161A20),
      items: CompetitiveRank.values
          .map((r) => DropdownMenuItem<CompetitiveRank>(
                value: r,
                child: Text(r.label, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.expand_more, color: Colors.white54),
      isExpanded: true,
    );
  }
}

class MapRankRow extends StatelessWidget {
  const MapRankRow({
    super.key,
    required this.map,
    required this.rank,
    required this.onChanged,
  });

  final CsMap map;
  final CompetitiveRank? rank;
  final ValueChanged<CompetitiveRank?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              map.label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CompetitiveRankDropdown(value: rank, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
