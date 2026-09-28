import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/inventory_item.dart';
import '../../models/sale_record.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/cut_corner_card.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesListProvider);
    final summary = ref.watch(salesSummaryProvider);
    final settings = ref.watch(settingsProvider);
    final currency = settings.preferredCurrency;

    final total = currency == 'USD' ? summary.totalUsd : summary.totalEur;
    final otherTotal = currency == 'USD' ? summary.totalEur : summary.totalUsd;
    final otherCcy = currency == 'USD' ? 'EUR' : 'USD';

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'HISTORIAL DE VENTAS',
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
            CutCornerCard(
              color: AppTheme.bgCard,
              borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.45),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          color: Color(0xFFF59E0B), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'TOTAL INGRESADO ($currency)',
                        style: const TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatPrice(total, currency),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (otherTotal > 0)
                    Text(
                      '≈ ${formatPrice(otherTotal, otherCcy)}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: AppTheme.borderStrong),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Ventas',
                          value: '${summary.totalRecords}',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          icon: Icons.numbers,
                          label: 'Unidades',
                          value: '${summary.totalQuantity}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (sales.isEmpty)
              CutCornerCard(
                color: AppTheme.bgCard,
                borderColor: AppTheme.borderStrong,
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: const [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: Colors.white24),
                    SizedBox(height: 12),
                    Text(
                      'Aún no hay ventas registradas',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Cuando vendas unidades de un item del inventario, aparecerán aquí con el total.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              for (final s in sales) _SaleTile(sale: s, currency: currency),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale, required this.currency});
  final SaleRecord sale;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(sale.soldAt);
    final unit = currency == 'USD' ? sale.unitPriceUsd : sale.unitPriceEur;
    final total = currency == 'USD' ? sale.totalUsd : sale.totalEur;
    final cat = sale.categoryIndex >= 0 && sale.categoryIndex < ItemCategory.values.length
        ? ItemCategory.values[sale.categoryIndex]
        : ItemCategory.other;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A313B)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sell_outlined,
                color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.itemName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${sale.accountName} · x${sale.quantity} · $dateStr · ${cat.label}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPrice(total, currency),
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                '${formatPrice(unit, currency)}/u',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
