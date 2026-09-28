import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import 'cut_corner_card.dart';

/// Cabecera grande con cuenta atrás al próximo reset y resumen de cuentas por estado.
///
/// Colores por estado:
///   - Pendientes → naranja (CS)
///   - Perdidas → rojo (nuevo)
///   - Completadas → verde
class CountdownHeader extends StatelessWidget {
  const CountdownHeader({
    super.key,
    required this.countdown,
    required this.total,
    required this.pending,
    required this.missed,
    required this.completed,
    required this.nextResetDate,
  });

  final Duration countdown;
  final int total;
  final int pending;
  final int missed;
  final int completed;
  final DateTime nextResetDate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: AppTheme.csOrange.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: AppTheme.csOrange, size: 18),
              const SizedBox(width: 8),
              Text(
                'PRÓXIMO RESET',
                style: t.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _format(countdown),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatResetDate(nextResetDate),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppTheme.borderStrong),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Cuentas',
                  value: '$total',
                  icon: Icons.people_alt_outlined,
                  color: Colors.white,
                ),
              ),
              _VDivider(),
              Expanded(
                child: _Stat(
                  label: 'Pendientes',
                  value: '$pending',
                  icon: Icons.flag_outlined,
                  color: AppTheme.csOrange,
                ),
              ),
              _VDivider(),
              Expanded(
                child: _Stat(
                  label: 'Perdidas',
                  value: '$missed',
                  icon: Icons.close_rounded,
                  color: AppTheme.csRed,
                ),
              ),
              _VDivider(),
              Expanded(
                child: _Stat(
                  label: 'Completadas',
                  value: '$completed',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.csGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatResetDate(DateTime next) {
    final local = next.toLocal();
    final left = DateFormat("EEEE d MMM yyyy", 'es').format(local);
    final right = DateFormat('HH:mm:ss').format(local);
    return '${_capitalize(left)} / $right';
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _format(Duration d) {
    if (d.isNegative || d == Duration.zero) return '¡AHORA!';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    String pad(int n) => n.toString().padLeft(2, '0');
    if (days > 0) {
      return '${days}d ${pad(hours)}:${pad(minutes)}:${pad(seconds)}';
    }
    return '${pad(hours)}:${pad(minutes)}:${pad(seconds)}';
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppTheme.borderStrong);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
