import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/case_ev_data.dart';
import '../../models/inventory_item.dart';
import '../../providers/services_providers.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/market_hash_name.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/cut_corner_card.dart';

/// Calculadora de valor esperado (EV) de abrir una caja: usa las
/// probabilidades oficiales de Valve por rareza y el precio actual de Steam
/// Market de cada skin posible, para comparar con el coste de abrirla
/// (caja + llave).
///
/// Cobertura PARCIAL a propósito (ver lib/data/case_ev_data.dart): solo se
/// incluyen cajas cuyo contenido se ha verificado contra fuentes públicas,
/// para no arriesgarse a mostrar un EV falso por un nombre de skin mal
/// traducido.
class EvCalculatorScreen extends ConsumerStatefulWidget {
  const EvCalculatorScreen({super.key});

  @override
  ConsumerState<EvCalculatorScreen> createState() =>
      _EvCalculatorScreenState();
}

class _EvCalculatorScreenState extends ConsumerState<EvCalculatorScreen> {
  String? _selectedCase;
  bool _loading = false;
  _EvResult? _result;

  static const double _keyPriceUsd = 2.50;
  static const double _keyPriceEur = 2.25;

  Future<void> _calculate() async {
    final caseName = _selectedCase;
    if (caseName == null) return;
    final data = kCaseEvData[caseName];
    if (data == null) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    final market = ref.read(steamMarketServiceProvider);

    Future<double> priceFor(String hashName) async {
      final r = await market.getPrice(hashName, silent: true);
      return r.priceEur > 0 || r.priceUsd > 0
          ? (ref.read(settingsProvider).preferredCurrency == 'USD'
              ? r.priceUsd
              : r.priceEur)
          : 0.0;
    }

    final casePrice = await priceFor(caseName);

    final tierPrices = <SkinRarity, List<double>>{};
    for (final w in data.weapons) {
      final hash = buildMarketHashName(
          baseName: w.name, wear: SkinWear.fieldTested);
      final p = await priceFor(hash);
      tierPrices.putIfAbsent(w.rarity, () => []).add(p);
    }

    if (data.knifeBaseName != null && data.knifeFinishes.isNotEmpty) {
      final knifePrices = <double>[];
      for (final finish in data.knifeFinishes) {
        final hash = buildMarketHashName(
          baseName: '${data.knifeBaseName} | $finish',
          wear: SkinWear.fieldTested,
        );
        knifePrices.add(await priceFor(hash));
      }
      tierPrices[SkinRarity.rareSpecial] = knifePrices;
    }

    double ev = 0;
    final breakdown = <_TierBreakdown>[];
    for (final entry in tierPrices.entries) {
      final prices = entry.value.where((p) => p > 0).toList();
      final avg = prices.isEmpty
          ? 0.0
          : prices.reduce((a, b) => a + b) / prices.length;
      final tierEv = entry.key.dropChance * avg;
      ev += tierEv;
      breakdown.add(_TierBreakdown(
        rarity: entry.key,
        itemCount: entry.value.length,
        avgPrice: avg,
        priceless: entry.value.where((p) => p <= 0).length,
      ));
    }
    breakdown.sort((a, b) => b.rarity.dropChance.compareTo(a.rarity.dropChance));

    if (!mounted) return;
    setState(() {
      _result = _EvResult(
        casePrice: casePrice,
        ev: ev,
        breakdown: breakdown,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider).preferredCurrency;
    final keyPrice = currency == 'USD' ? _keyPriceUsd : _keyPriceEur;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'CALCULADORA DE EV',
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
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1F25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A313B)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cobertura parcial: solo cajas con contenido verificado. El precio de cada skin se estima en condición "Curtida por el combate" (Field-Tested) — el desgaste real al abrir es aleatorio dentro del rango de esa skin.',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161A20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A313B)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCase,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF161A20),
                  hint: const Text('Elige una caja',
                      style: TextStyle(color: Colors.white54)),
                  icon: const Icon(Icons.expand_more, color: Colors.white54),
                  items: kCaseEvData.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedCase = v;
                    _result = null;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _selectedCase == null || _loading ? null : _calculate,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate_outlined),
              label: Text(_loading ? 'Consultando precios...' : 'CALCULAR EV'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 20),
              _ResultCard(
                result: _result!,
                currency: currency,
                keyPrice: keyPrice,
              ),
              const SizedBox(height: 18),
              const Text('DESGLOSE POR RAREZA',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              for (final b in _result!.breakdown)
                _TierRow(breakdown: b, currency: currency),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvResult {
  final double casePrice;
  final double ev;
  final List<_TierBreakdown> breakdown;
  const _EvResult({
    required this.casePrice,
    required this.ev,
    required this.breakdown,
  });
}

class _TierBreakdown {
  final SkinRarity rarity;
  final int itemCount;
  final double avgPrice;
  final int priceless;
  const _TierBreakdown({
    required this.rarity,
    required this.itemCount,
    required this.avgPrice,
    required this.priceless,
  });
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.currency,
    required this.keyPrice,
  });
  final _EvResult result;
  final String currency;
  final double keyPrice;

  @override
  Widget build(BuildContext context) {
    final totalCost = result.casePrice + keyPrice;
    final diff = result.ev - totalCost;
    final positive = diff >= 0;

    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: (positive ? AppTheme.csGreen : const Color(0xFFEF4444))
          .withValues(alpha: 0.5),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('Coste caja', formatPrice(result.casePrice, currency)),
          _line('Coste llave (aprox.)', formatPrice(keyPrice, currency)),
          const Divider(color: Color(0xFF2A313B), height: 20),
          _line('Coste total de abrir', formatPrice(totalCost, currency),
              bold: true),
          _line('Valor esperado (EV)', formatPrice(result.ev, currency),
              bold: true),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                positive ? Icons.trending_up : Icons.trending_down,
                color: positive ? AppTheme.csGreen : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  positive
                      ? '+${formatPrice(diff, currency)} de media por caja abierta'
                      : '${formatPrice(diff, currency)} de media por caja abierta',
                  style: TextStyle(
                    color: positive ? AppTheme.csGreen : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
          ],
        ),
      );
}

class _TierRow extends StatelessWidget {
  const _TierRow({required this.breakdown, required this.currency});
  final _TierBreakdown breakdown;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161A20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A313B)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(breakdown.rarity.labelEs,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${(breakdown.rarity.dropChance * 100).toStringAsFixed(2)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${breakdown.itemCount} items',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Media ${formatPrice(breakdown.avgPrice, currency)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppTheme.csOrange, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
