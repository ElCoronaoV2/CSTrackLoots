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

/// Calculadora de trade-up contracts: 10 skins de la misma rareza (y misma
/// colección) dan 1 al azar de la rareza siguiente, DENTRO de esa misma
/// colección. Reutiliza los datos ya verificados de la calculadora de EV,
/// porque en las cajas modernas de Valve caja == colección (cada caja
/// introduce su propia colección exclusiva).
///
/// Simplificación: en el juego real el trade-up puede mezclar varias
/// colecciones a la vez; aquí solo se modela una colección sola, que es el
/// caso más habitual y el único que se puede calcular con datos verificados.
class TradeUpCalculatorScreen extends ConsumerStatefulWidget {
  const TradeUpCalculatorScreen({super.key});

  @override
  ConsumerState<TradeUpCalculatorScreen> createState() =>
      _TradeUpCalculatorScreenState();
}

class _TradeUpCalculatorScreenState
    extends ConsumerState<TradeUpCalculatorScreen> {
  String? _selectedCase;
  SkinRarity? _inputRarity;
  bool _loading = false;
  _TradeUpResult? _result;

  static const _tradeableRarities = [
    SkinRarity.milSpec,
    SkinRarity.restricted,
    SkinRarity.classified,
  ];

  SkinRarity _nextRarity(SkinRarity r) {
    switch (r) {
      case SkinRarity.milSpec:
        return SkinRarity.restricted;
      case SkinRarity.restricted:
        return SkinRarity.classified;
      case SkinRarity.classified:
        return SkinRarity.covert;
      case SkinRarity.covert:
      case SkinRarity.rareSpecial:
        return r;
    }
  }

  Future<void> _calculate() async {
    final caseName = _selectedCase;
    final rarity = _inputRarity;
    if (caseName == null || rarity == null) return;
    final data = kCaseEvData[caseName];
    if (data == null) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    final market = ref.read(steamMarketServiceProvider);
    Future<double> priceFor(String name) async {
      final hash = buildMarketHashName(baseName: name, wear: SkinWear.fieldTested);
      final r = await market.getPrice(hash, silent: true);
      return ref.read(settingsProvider).preferredCurrency == 'USD'
          ? r.priceUsd
          : r.priceEur;
    }

    final nextRarity = _nextRarity(rarity);
    final inputSkins = data.weapons.where((w) => w.rarity == rarity).toList();
    final outputSkins =
        data.weapons.where((w) => w.rarity == nextRarity).toList();

    final inputPrices = <double>[];
    for (final s in inputSkins) {
      inputPrices.add(await priceFor(s.name));
    }
    final outputPrices = <double>[];
    for (final s in outputSkins) {
      outputPrices.add(await priceFor(s.name));
    }

    final validInput = inputPrices.where((p) => p > 0).toList();
    final validOutput = outputPrices.where((p) => p > 0).toList();
    final avgInput = validInput.isEmpty
        ? 0.0
        : validInput.reduce((a, b) => a + b) / validInput.length;
    final avgOutput = validOutput.isEmpty
        ? 0.0
        : validOutput.reduce((a, b) => a + b) / validOutput.length;

    if (!mounted) return;
    setState(() {
      _result = _TradeUpResult(
        avgInputPrice: avgInput,
        avgOutputPrice: avgOutput,
        inputCount: inputSkins.length,
        outputCount: outputSkins.length,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider).preferredCurrency;
    final data = _selectedCase == null ? null : kCaseEvData[_selectedCase];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'CALCULADORA DE TRADE-UP',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 15,
            letterSpacing: 1,
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
                      'Simplificado a una sola colección (10 skins de la misma caja/rareza dan 1 de la rareza siguiente, de esa misma caja). El juego real también permite mezclar colecciones, pero eso no se puede calcular con datos verificados todavía.',
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
                  hint: const Text('Elige una colección (caja)',
                      style: TextStyle(color: Colors.white54)),
                  icon: const Icon(Icons.expand_more, color: Colors.white54),
                  items: kCaseEvData.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedCase = v;
                    _inputRarity = null;
                    _result = null;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (data != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A313B)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SkinRarity>(
                    value: _inputRarity,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF161A20),
                    hint: const Text('Rareza de entrada (las 10 que metes)',
                        style: TextStyle(color: Colors.white54)),
                    icon: const Icon(Icons.expand_more, color: Colors.white54),
                    items: _tradeableRarities
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                  '${r.labelEs} → ${_nextRarity(r).labelEs}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _inputRarity = v;
                      _result = null;
                    }),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _selectedCase == null || _inputRarity == null || _loading
                  ? null
                  : _calculate,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(_loading ? 'Consultando precios...' : 'CALCULAR TRADE-UP'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 20),
              _TradeUpResultCard(result: _result!, currency: currency),
            ],
          ],
        ),
      ),
    );
  }
}

class _TradeUpResult {
  final double avgInputPrice;
  final double avgOutputPrice;
  final int inputCount;
  final int outputCount;
  const _TradeUpResult({
    required this.avgInputPrice,
    required this.avgOutputPrice,
    required this.inputCount,
    required this.outputCount,
  });
}

class _TradeUpResultCard extends StatelessWidget {
  const _TradeUpResultCard({required this.result, required this.currency});
  final _TradeUpResult result;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cost = result.avgInputPrice * 10;
    final diff = result.avgOutputPrice - cost;
    final positive = diff >= 0;

    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: (positive ? AppTheme.csGreen : const Color(0xFFEF4444))
          .withValues(alpha: 0.5),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('Precio medio de entrada (${result.inputCount} posibles)',
              formatPrice(result.avgInputPrice, currency)),
          _line('Coste de 10 unidades', formatPrice(cost, currency), bold: true),
          const Divider(color: Color(0xFF2A313B), height: 20),
          _line('Precio medio de salida (${result.outputCount} posibles)',
              formatPrice(result.avgOutputPrice, currency), bold: true),
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
                      ? '+${formatPrice(diff, currency)} de media por trade-up'
                      : '${formatPrice(diff, currency)} de media por trade-up',
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
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 13)),
            ),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
          ],
        ),
      );
}
