import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../providers/services_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/hive_service.dart' show SeedItems;
import '../../services/skinport_service.dart';
import '../../services/steam_market_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/market_hash_name.dart';
import '../../widgets/wear_details_fields.dart' show parseFloatField;

/// Herramienta de consulta: buscas un item por nombre y, si tiene desgaste,
/// ves su precio en Steam y Skinport para las 5 condiciones a la vez, para
/// decidir cuál conviene elegir antes de seleccionar un drop o abrir una caja.
class SkinCompareScreen extends ConsumerStatefulWidget {
  const SkinCompareScreen({super.key});

  @override
  ConsumerState<SkinCompareScreen> createState() => _SkinCompareScreenState();
}

class _SkinCompareScreenState extends ConsumerState<SkinCompareScreen> {
  final _nameCtrl = TextEditingController();
  final _floatCtrl = TextEditingController();
  ItemCategory _category = ItemCategory.skin;
  bool _statTrak = false;
  bool _loading = false;
  String? _error;
  List<_WearPriceRow> _rows = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  double? get _typedFloat => parseFloatField(_floatCtrl.text);
  SkinWear? get _suggestedWear {
    final f = _typedFloat;
    return f == null ? null : approximateWearFromFloat(f);
  }

  Future<void> _fetchPrices() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _rows = [];
    });

    final steam = ref.read(steamMarketServiceProvider);
    final skinport = ref.read(skinportServiceProvider);
    final currency = ref.read(settingsProvider).preferredCurrency;
    final wears =
        _category.supportsWearDetails ? SkinWear.values : const <SkinWear?>[null];

    final rows = <_WearPriceRow>[];
    for (final w in wears) {
      final hashName = buildMarketHashName(
        baseName: name,
        statTrak: _statTrak,
        wear: w,
      );
      final steamPrice = await steam.getPrice(hashName);
      final skinportPrice =
          await skinport.getPrice(hashName, currency: currency);
      rows.add(_WearPriceRow(
        wear: w,
        hashName: hashName,
        steam: steamPrice,
        skinport: skinportPrice,
      ));
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _rows = rows;
      _error = rows.every((r) => r.steam.failed && r.skinport == null)
          ? 'No se encontraron precios. Revisa que el nombre sea exacto, tal como aparece en Steam.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider).preferredCurrency;

    return Scaffold(
      appBar: AppBar(title: const Text('COMPARADOR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Busca una skin, cuchillo, guante, caja o grafiti y compara su precio en Steam y Skinport. Con armas/cuchillos/guantes puedes ver las 5 condiciones a la vez para saber cuál conviene elegir.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Text('Categoría',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ItemCategory.values.map((c) {
              final selected = c == _category;
              return ChoiceChip(
                label: Text(c.label),
                selected: selected,
                onSelected: (_) => setState(() {
                  _category = c;
                  _rows = [];
                  _error = null;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue value) {
              if (value.text.isEmpty) return const Iterable<String>.empty();
              final q = value.text.toLowerCase();
              return SeedItems.forCategory(_category)
                  .where((s) => s.toLowerCase().contains(q))
                  .take(8);
            },
            onSelected: (sel) {
              _nameCtrl.text = sel;
              _nameCtrl.selection =
                  TextSelection.fromPosition(TextPosition(offset: sel.length));
              setState(() {});
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              controller.text = _nameCtrl.text;
              controller.selection = _nameCtrl.selection;
              controller.addListener(() {
                if (_nameCtrl.text != controller.text) {
                  _nameCtrl.text = controller.text;
                  _nameCtrl.selection = controller.selection;
                  setState(() {});
                }
              });
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Nombre del item',
                  hintText: 'ej. AK-47 | Redline, Kilowatt Case...',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (_) => _fetchPrices(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  color: const Color(0xFF1B1F25),
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 320,
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (ctx, i) {
                        final option = options.elementAt(i);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Text(option),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          if (_category.supportsWearDetails) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _floatCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Float (opcional)',
                      hintText: '0.00 - 1.00',
                      prefixIcon: Icon(Icons.blur_circular),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Text('StatTrak™'),
                  selected: _statTrak,
                  onSelected: (v) => setState(() => _statTrak = v),
                  selectedColor: AppTheme.csOrange.withValues(alpha: 0.3),
                  checkmarkColor: AppTheme.csOrange,
                ),
              ],
            ),
            if (_suggestedWear != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.csOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Float ${_typedFloat!.toStringAsFixed(4)} ≈ ${_suggestedWear!.labelEs} (rango estándar; cada skin puede variar el suyo).',
                  style: const TextStyle(color: AppTheme.csOrange, fontSize: 11),
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed:
                _loading || _nameCtrl.text.trim().isEmpty ? null : _fetchPrices,
            icon: const Icon(Icons.price_check),
            label: const Text('Consultar precios'),
          ),
          if (_loading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ],
          if (_rows.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._rows.map((r) => _PriceRowCard(
                  row: r,
                  currency: currency,
                  highlighted:
                      _suggestedWear != null && r.wear == _suggestedWear,
                )),
          ],
        ],
      ),
    );
  }
}

class _WearPriceRow {
  const _WearPriceRow({
    required this.wear,
    required this.hashName,
    required this.steam,
    required this.skinport,
  });

  final SkinWear? wear;
  final String hashName;
  final PriceResult steam;
  final SkinportPrice? skinport;
}

class _PriceRowCard extends StatelessWidget {
  const _PriceRowCard({
    required this.row,
    required this.currency,
    required this.highlighted,
  });

  final _WearPriceRow row;
  final String currency;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final steamPrice = currency == 'USD' ? row.steam.priceUsd : row.steam.priceEur;
    final skinportPrice = row.skinport?.minPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.csOrange.withValues(alpha: 0.08)
            : const Color(0xFF161A20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? AppTheme.csOrange : const Color(0xFF2A313B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                row.wear?.labelEs ?? 'Precio',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              if (highlighted) ...[
                const SizedBox(width: 6),
                const Icon(Icons.blur_circular,
                    size: 14, color: AppTheme.csOrange),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PriceTile(
                  label: 'Steam Market',
                  value: row.steam.failed ? null : steamPrice,
                  currency: currency,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PriceTile(
                  label: 'Skinport',
                  value: skinportPrice,
                  currency: currency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({
    required this.label,
    required this.value,
    required this.currency,
  });

  final String label;
  final double? value;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1318),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A313B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            v == null ? '—' : formatPrice(v, currency),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
