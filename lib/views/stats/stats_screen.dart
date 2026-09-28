import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/cs_account.dart';
import '../../models/inventory_item.dart';
import '../../models/sale_record.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/hive_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/cut_corner_card.dart';
import '../../widgets/item_icons.dart';
import '../../widgets/section_label.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryProvider);
    final accounts = ref.watch(accountsProvider);
    final sales = ref.watch(salesListProvider);
    final settings = ref.watch(settingsProvider);
    final currency = settings.preferredCurrency;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ESTADÍSTICAS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: BackgroundPattern(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            const SectionLabel('Valor del inventario en el tiempo'),
            const SizedBox(height: 12),
            _ValueOverTimeCard(currency: currency),
            const SizedBox(height: 18),
            const SectionLabel('Valor por categoría'),
            const SizedBox(height: 12),
            _CategoryValueCard(items: items, currency: currency),
            const SizedBox(height: 18),
            const SectionLabel('Ventas por mes'),
            const SizedBox(height: 12),
            _SalesByMonthCard(sales: sales, currency: currency),
            const SizedBox(height: 18),
            const SectionLabel('Mejores tasas de éxito'),
            const SizedBox(height: 12),
            _SuccessRateCard(accounts: accounts),
          ],
        ),
      ),
    );
  }
}

class _ValueOverTimeCard extends StatelessWidget {
  const _ValueOverTimeCard({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context) {
    final snapshots = HiveService.valueSnapshotsBox.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (snapshots.length < 2) {
      return _EmptyCard(
        icon: Icons.show_chart,
        text:
            'Todavía no hay suficientes días registrados. Cada vez que abras la app se guarda el valor de ese día — vuelve en un par de días para ver la evolución.',
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < snapshots.length; i++)
        FlSpot(
          i.toDouble(),
          currency == 'USD' ? snapshots[i].totalUsd : snapshots[i].totalEur,
        ),
    ];
    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);

    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: AppTheme.csCyan.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY <= 0 ? 1 : maxY * 1.15,
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
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toStringAsFixed(0),
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
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
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
                color: AppTheme.csCyan,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.csCyan.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryValueCard extends StatelessWidget {
  const _CategoryValueCard({required this.items, required this.currency});
  final List<InventoryItem> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final values = <ItemCategory, double>{};
    for (final item in items) {
      if (item.sold) continue;
      final v = currency == 'USD'
          ? item.priceUsd * item.quantity
          : item.priceEur * item.quantity;
      values[item.category] = (values[item.category] ?? 0) + v;
    }
    values.removeWhere((_, v) => v <= 0);

    if (values.isEmpty) {
      return _EmptyCard(
        icon: Icons.pie_chart_outline,
        text:
            'Todavía no hay precios registrados en el inventario. Refresca precios desde Inventario General para ver la distribución de valor.',
      );
    }

    final total = values.values.fold<double>(0, (a, b) => a + b);
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: AppTheme.csPurple.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: [
                  for (final e in entries)
                    PieChartSectionData(
                      value: e.value,
                      color: ItemCategoryIcon.colorFor(e.key),
                      title: '${(e.value / total * 100).toStringAsFixed(0)}%',
                      radius: 26,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: ItemCategoryIcon.colorFor(e.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key.label,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        Text(
                          formatPrice(e.value, currency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesByMonthCard extends StatelessWidget {
  const _SalesByMonthCard({required this.sales, required this.currency});
  final List<SaleRecord> sales;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final byMonth = <String, double>{};
    for (final s in sales) {
      final key = '${s.soldAt.year}-${s.soldAt.month.toString().padLeft(2, '0')}';
      final v = currency == 'USD' ? s.totalUsd : s.totalEur;
      byMonth[key] = (byMonth[key] ?? 0) + v;
    }

    if (byMonth.isEmpty) {
      return _EmptyCard(
        icon: Icons.bar_chart,
        text: 'Todavía no has vendido ningún item.',
      );
    }

    final keys = byMonth.keys.toList()..sort();
    final lastKeys = keys.length > 6 ? keys.sublist(keys.length - 6) : keys;
    final maxY = lastKeys
        .map((k) => byMonth[k]!)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: AppTheme.csGreen.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxY <= 0 ? 1 : maxY * 1.2,
            alignment: BarChartAlignment.spaceAround,
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
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= lastKeys.length) {
                      return const SizedBox.shrink();
                    }
                    final parts = lastKeys[i].split('-');
                    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('MMM', 'es').format(date),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < lastKeys.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: byMonth[lastKeys[i]]!,
                      color: AppTheme.csGreen,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessRateCard extends StatelessWidget {
  const _SuccessRateCard({required this.accounts});
  final List<CsAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final ranked = accounts.where((a) => a.totalWeeks > 0).toList()
      ..sort((a, b) => b.successRate.compareTo(a.successRate));

    if (ranked.isEmpty) {
      return _EmptyCard(
        icon: Icons.emoji_events_outlined,
        text:
            'Todavía no hay semanas registradas. Las tasas de éxito aparecen tras el primer reset semanal.',
      );
    }

    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: AppTheme.csOrange.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final a in ranked.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      a.alias,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (a.successRate / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: AppTheme.borderStrong,
                        color: AppTheme.csOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${a.successRate.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: AppTheme.borderStrong,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white24),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
