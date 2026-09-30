import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Diálogo con el histórico de precio (EUR/USD según [currency]) de un item
/// concreto, identificado por su market_hash_name completo. Los puntos se
/// guardan como mucho una vez al día, la primera vez que se abre la app ese
/// día (ver StatsService.recordDailyItemPriceSnapshotsIfNeeded).
class PriceHistoryDialog extends StatelessWidget {
  const PriceHistoryDialog({
    super.key,
    required this.title,
    required this.marketHashName,
    required this.currency,
  });

  final String title;
  final String marketHashName;
  final String currency;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String marketHashName,
    required String currency,
  }) {
    return showDialog(
      context: context,
      builder: (_) => PriceHistoryDialog(
        title: title,
        marketHashName: marketHashName,
        currency: currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = StatsService.priceHistoryFor(marketHashName);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.show_chart, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: snapshots.length < 2
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Todavía no hay suficientes días registrados. Cada vez que abras la app se guarda el precio de hoy — vuelve en un par de días para ver la evolución.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              )
            : _Chart(snapshots: snapshots, currency: currency),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.snapshots, required this.currency});
  final List<dynamic> snapshots;
  final String currency;

  double _priceOf(dynamic s) => currency == 'USD' ? s.priceUsd : s.priceEur;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < snapshots.length; i++)
        FlSpot(i.toDouble(), _priceOf(snapshots[i])),
    ];
    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).fold<double>(maxY, (a, b) => a < b ? a : b);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minY <= 0 ? 0 : minY * 0.9,
          maxY: maxY <= 0 ? 1 : maxY * 1.1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppTheme.borderStrong, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) => Text(
                  formatPrice(value, currency),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (snapshots.length / 4).clamp(1, 999).roundToDouble(),
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= snapshots.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('dd/MM').format(snapshots[i].date),
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.csOrange,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.csOrange.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
