import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/inventory_item.dart';
import '../../models/watchlist_item.dart';
import '../../providers/settings_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../services/hive_service.dart' show SeedItems;
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/cut_corner_card.dart';
import '../../widgets/item_icons.dart';

/// Lista de seguimiento: items que el usuario NO tiene pero quiere vigilar
/// (por ejemplo antes de comprarlos, o para saber si merece la pena volver
/// a por ellos). No cuentan en el inventario ni en el valor total, pero sí
/// admiten la misma alerta de precio que los items propios.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(watchlistProvider);
    final currency = ref.watch(settingsProvider).preferredCurrency;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('LISTA DE SEGUIMIENTO'),
        actions: [
          IconButton(
            tooltip: 'Refrescar precios',
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: items.isEmpty
                ? null
                : () => _refreshAll(context, ref),
          ),
        ],
      ),
      body: BackgroundPattern(
        child: items.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 40),
                  CutCornerCard(
                    color: AppTheme.bgCard,
                    borderColor: AppTheme.borderStrong,
                    padding: const EdgeInsets.all(28),
                    child: const Column(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 48, color: Colors.white24),
                        SizedBox(height: 12),
                        Text(
                          'Aún no vigilas ningún item',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Añade una skin, caja o cuchillo que no tengas todavía para vigilar su precio y que te avisemos cuando llegue al que quieras.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: items
                    .map((it) => _WatchlistTile(item: it, currency: currency))
                    .toList(),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.csOrange,
        foregroundColor: Colors.black,
        onPressed: () => _AddWatchlistDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('VIGILAR ITEM',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Future<void> _refreshAll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Actualizando precios...'),
        duration: Duration(seconds: 2),
      ),
    );
    await ref.read(watchlistProvider.notifier).refreshAll(
          onProgress: (done, total) {
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text('Actualizando $done/$total...'),
                duration: const Duration(milliseconds: 600),
              ),
            );
          },
        );
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF22C55E),
        content: Text(
          'Precios actualizados.',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _WatchlistTile extends ConsumerWidget {
  const _WatchlistTile({required this.item, required this.currency});

  final WatchlistItem item;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ItemCategoryIcon.colorFor(item.category);
    final icon = ItemCategoryIcon.iconFor(item.category);
    final price = currency == 'USD' ? item.priceUsd : item.priceEur;
    final dateStr = DateFormat('dd/MM/yyyy').format(item.addedAt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.statTrak) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.csOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ST™',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        item.itemName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MiniChip(icon: Icons.category_outlined, text: item.category.label, color: color),
                    _MiniChip(icon: Icons.event_outlined, text: dateStr),
                    if (item.wear != null)
                      _MiniChip(icon: Icons.blur_circular, text: item.wear!.shortLabel),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPrice(price, currency),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: price > 0 ? AppTheme.csOrange : Colors.white38,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: item.alertThreshold != null
                        ? 'Alerta de precio activa'
                        : 'Poner alerta de precio',
                    onPressed: () => _setAlert(context, ref),
                    icon: Icon(
                      item.alertThreshold != null
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      size: 18,
                      color: item.alertThreshold != null
                          ? AppTheme.csOrange
                          : Colors.white54,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: 'Dejar de vigilar',
                    onPressed: () => _confirmRemove(context, ref),
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Dejar de vigilar?'),
        content: Text('Se quitará "${item.itemName}" de la lista de seguimiento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(watchlistProvider.notifier).removeItem(item.id);
    }
  }

  Future<void> _setAlert(BuildContext context, WidgetRef ref) async {
    final current = item.alertCurrency == currency ? item.alertThreshold : null;
    final ctrl = TextEditingController(
      text: current != null ? current.toStringAsFixed(2) : '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.notifications_active_outlined, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Expanded(child: Text('Alerta de precio')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Te avisamos con una notificación cuando "${item.itemName}" alcance este precio o más. Déjalo vacío para quitar la alerta.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Precio ($currency)',
                prefixIcon: Icon(currency == 'USD' ? Icons.attach_money : Icons.euro),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final text = ctrl.text;
    ctrl.dispose();
    if (confirmed != true) return;

    final trimmed = text.trim().replaceAll(',', '.');
    final value = trimmed.isEmpty ? null : double.tryParse(trimmed);
    await ref.read(watchlistProvider.notifier).setAlertThreshold(
          item.id,
          currency: currency,
          threshold: value,
        );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF111418),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A313B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: c, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AddWatchlistDialog extends ConsumerStatefulWidget {
  const _AddWatchlistDialog();

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const _AddWatchlistDialog(),
    );
  }

  @override
  ConsumerState<_AddWatchlistDialog> createState() => _AddWatchlistDialogState();
}

class _AddWatchlistDialogState extends ConsumerState<_AddWatchlistDialog> {
  final _nameCtrl = TextEditingController();
  ItemCategory _category = ItemCategory.skin;
  SkinWear? _wear;
  bool _statTrak = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canConfirm => _nameCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.visibility_outlined, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Text('Vigilar item'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No cuenta en tu inventario ni en el valor total: solo vigilamos su precio.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
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
                      hintText: 'ej. Kilowatt Case, AK-47 | Redline...',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
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
                      if (!c.supportsWearDetails) {
                        _wear = null;
                        _statTrak = false;
                      }
                    }),
                  );
                }).toList(),
              ),
              if (_category.supportsWearDetails) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Desgaste',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                    const Spacer(),
                    FilterChip(
                      label: const Text('StatTrak™'),
                      selected: _statTrak,
                      onSelected: (v) => setState(() => _statTrak = v),
                      selectedColor: AppTheme.csOrange.withValues(alpha: 0.3),
                      checkmarkColor: AppTheme.csOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Sin especificar'),
                      selected: _wear == null,
                      onSelected: (_) => setState(() => _wear = null),
                    ),
                    ...SkinWear.values.map(
                      (w) => ChoiceChip(
                        label: Text(w.shortLabel),
                        selected: _wear == w,
                        onSelected: (_) => setState(() => _wear = w),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _canConfirm
              ? () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  await ref.read(watchlistProvider.notifier).addItem(
                        itemName: _nameCtrl.text,
                        category: _category,
                        statTrak: _statTrak,
                        wear: _wear,
                      );
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF22C55E),
                      content: Text(
                        'Añadido a seguimiento.',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }
              : null,
          icon: const Icon(Icons.check),
          label: const Text('VIGILAR'),
        ),
      ],
    );
  }
}
