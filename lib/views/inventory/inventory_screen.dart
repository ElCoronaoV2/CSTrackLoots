import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/csv_export_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/cut_corner_card.dart';
import '../../widgets/inventory_item_tile.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/section_label.dart';
import 'add_item_dialog.dart';
import 'sales_history_screen.dart';

/// Opciones del menú "más opciones" del AppBar de Inventario.
enum _InventoryMenuAction { salesHistory, exportCsv }

Future<void> _refreshAll(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Actualizando precios desde Steam (ignorando caché)...'),
      duration: Duration(seconds: 2),
    ),
  );
  final scaffold = ScaffoldMessenger.of(context);
  await ref.read(inventoryProvider.notifier).refreshPrices(
        force: true,
        onProgress: (done, total) {
          scaffold.clearSnackBars();
          scaffold.showSnackBar(
            SnackBar(
              content: Text('Actualizando $done/$total...'),
              duration: const Duration(milliseconds: 600),
            ),
          );
        },
      );
  scaffold.clearSnackBars();
  scaffold.showSnackBar(
    const SnackBar(
      backgroundColor: Color(0xFF22C55E),
      content: Text(
        'Precios actualizados.',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _selectionMode = false;
  final Set<String> _selected = {};
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selected.clear();
    });
  }

  Future<void> _sellSelected() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Vender seleccionados?'),
        content: Text(
          'Se venderán las $count unidades seleccionadas al precio actual de cada una. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('VENDER'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final sold = await ref
        .read(inventoryProvider.notifier)
        .sellItemsFully(_selected.toList());
    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFF59E0B),
        content: Text(
          'Vendidos $sold items.',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(inventorySummaryProvider);
    final filtered = ref.watch(filteredInventoryProvider);
    final filter = ref.watch(inventoryFilterProvider);
    final settings = ref.watch(settingsProvider);
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
        appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        leading: IconButton(
          icon: Icon(_selectionMode ? Icons.close : Icons.arrow_back, size: 22),
          onPressed: _selectionMode
              ? _toggleSelectionMode
              : () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _selectionMode
                    ? '${_selected.length} SELECCIONADOS'
                    : 'INVENTARIO GENERAL',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_selectionMode) ...[
              IconButton(
                tooltip: 'Venta rápida por lote',
                icon: const Icon(Icons.checklist, size: 22),
                onPressed: _toggleSelectionMode,
              ),
              IconButton(
                tooltip: 'Refrescar precios',
                icon: const Icon(Icons.refresh, size: 22),
                onPressed: () => _refreshAll(context, ref),
              ),
              PopupMenuButton<_InventoryMenuAction>(
                tooltip: 'Más opciones',
                icon: const Icon(Icons.more_vert, size: 22),
                onSelected: (action) async {
                  switch (action) {
                    case _InventoryMenuAction.salesHistory:
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SalesHistoryScreen(),
                        ),
                      );
                      break;
                    case _InventoryMenuAction.exportCsv:
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await CsvExportService().exportInventory(filtered);
                      } catch (_) {
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('No se pudo exportar el CSV.')),
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _InventoryMenuAction.salesHistory,
                    child: ListTile(
                      leading: Icon(Icons.receipt_long_outlined),
                      title: Text('Historial de ventas'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _InventoryMenuAction.exportCsv,
                    child: ListTile(
                      leading: Icon(Icons.ios_share),
                      title: Text('Exportar inventario a CSV'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      body: BackgroundPattern(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            const OfflineBanner(),
            if (!_selectionMode) ...[
              _SummaryCard(
                totalEur: summary.totalEur,
                totalUsd: summary.totalUsd,
                unrealizedProfitEur: summary.unrealizedProfitEur,
                unrealizedProfitUsd: summary.unrealizedProfitUsd,
                totalCostEur: summary.totalCostEur,
                totalCostUsd: summary.totalCostUsd,
                currency: settings.preferredCurrency,
                numCases: summary.numCases,
                numSkins: summary.numSkins,
                numGrafitis: summary.numGrafitis,
                numKnives: summary.numKnives,
                numGloves: summary.numGloves,
                numOther: summary.numOther,
                totalActive: summary.totalActive,
              ),
              const SizedBox(height: 18),
              const SectionLabel('Todas las cuentas'),
              const SizedBox(height: 12),
              _FiltersBar(
                filter: filter,
                accounts: accounts,
                searchController: _searchController,
                onChange: (f) =>
                    ref.read(inventoryFilterProvider.notifier).state = f,
              ),
              const SizedBox(height: 14),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.csOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.csOrange.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Toca los items que quieras vender en bloque y pulsa "Vender seleccionados" abajo.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
            if (filtered.isEmpty)
              CutCornerCard(
                color: AppTheme.bgCard,
                borderColor: AppTheme.borderStrong,
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: const [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.white24),
                    SizedBox(height: 12),
                    Text(
                      'No hay items que mostrar',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Registra un drop semanal o añade un item manualmente desde el botón inferior.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              )
          else
            ...filtered.map(
              (it) => InventoryItemTile(
                item: it,
                currency: settings.preferredCurrency,
                onQuantitySold: () {},
                onDelete: () {},
                selectionMode: _selectionMode,
                selected: _selected.contains(it.id),
                onSelectedChanged: (v) => setState(() {
                  if (v) {
                    _selected.add(it.id);
                  } else {
                    _selected.remove(it.id);
                  }
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectionMode
          ? FloatingActionButton.extended(
              backgroundColor: _selected.isEmpty
                  ? Colors.white24
                  : const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              onPressed: _selected.isEmpty ? null : _sellSelected,
              icon: const Icon(Icons.sell_outlined),
              label: Text('VENDER SELECCIONADOS (${_selected.length})',
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            )
          : FloatingActionButton.extended(
              backgroundColor: AppTheme.csOrange,
              foregroundColor: Colors.black,
              onPressed: () => AddItemDialog.show(context),
              icon: const Icon(Icons.add),
              label: const Text('AÑADIR ITEM',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalEur,
    required this.totalUsd,
    required this.unrealizedProfitEur,
    required this.unrealizedProfitUsd,
    required this.totalCostEur,
    required this.totalCostUsd,
    required this.currency,
    required this.numCases,
    required this.numSkins,
    required this.numGrafitis,
    required this.numKnives,
    required this.numGloves,
    required this.numOther,
    required this.totalActive,
  });

  final double totalEur;
  final double totalUsd;
  final double unrealizedProfitEur;
  final double unrealizedProfitUsd;
  final double totalCostEur;
  final double totalCostUsd;
  final String currency;
  final int numCases;
  final int numSkins;
  final int numGrafitis;
  final int numKnives;
  final int numGloves;
  final int numOther;
  final int totalActive;

  @override
  Widget build(BuildContext context) {
    final total = currency == 'USD' ? totalUsd : totalEur;
    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: AppTheme.csOrange.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppTheme.csOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'VALOR TOTAL ($currency)',
                style: const TextStyle(
                  color: Colors.white70,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatPrice(total, currency),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          if (currency == 'EUR' && totalUsd > 0)
            Text(
              '≈ ${formatPrice(totalUsd, 'USD')}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          if (currency == 'USD' && totalEur > 0)
            Text(
              '≈ ${formatPrice(totalEur, 'EUR')}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          if (totalCostEur > 0 || totalCostUsd > 0) ...[
            const SizedBox(height: 6),
            Builder(builder: (context) {
              final profit =
                  currency == 'USD' ? unrealizedProfitUsd : unrealizedProfitEur;
              final positive = profit >= 0;
              return Row(
                children: [
                  Icon(
                    positive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: positive ? AppTheme.csGreen : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${positive ? '+' : ''}${formatPrice(profit, currency)} vs. lo pagado',
                    style: TextStyle(
                      color: positive ? AppTheme.csGreen : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            }),
          ],
          const SizedBox(height: 14),
          Container(height: 1, color: AppTheme.borderStrong),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(icon: Icons.inventory_2_outlined, label: 'Cajas', count: numCases, color: AppTheme.csOrange),
              _Pill(icon: Icons.shield_outlined, label: 'Skins', count: numSkins, color: AppTheme.csCyan),
              _Pill(icon: Icons.brush_outlined, label: 'Graffiti', count: numGrafitis, color: AppTheme.csPink),
              _Pill(icon: Icons.colorize, label: 'Cuchillos', count: numKnives, color: AppTheme.csRed),
              _Pill(icon: Icons.back_hand_outlined, label: 'Guantes', count: numGloves, color: AppTheme.csPurple),
              if (numOther > 0)
                _Pill(icon: Icons.help_outline, label: 'Otros', count: numOther, color: Colors.white60),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'El valor total se calcula en base a los precios de mercado de CS2.',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.filter,
    required this.accounts,
    required this.onChange,
    required this.searchController,
  });

  final InventoryFilter filter;
  final List accounts;
  final ValueChanged<InventoryFilter> onChange;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161A20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A313B)),
          ),
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Buscar por nombre...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: filter.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        searchController.clear();
                        onChange(filter.copyWith(searchQuery: ''));
                      },
                    ),
            ),
            onChanged: (v) => onChange(filter.copyWith(searchQuery: v)),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: filter.category == null,
                onSelected: (_) =>
                    onChange(filter.copyWith(clearCategory: true)),
              ),
              const SizedBox(width: 6),
              ...ItemCategory.values.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(c.label),
                    selected: filter.category == c,
                    onSelected: (_) => onChange(filter.copyWith(category: c)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                avatar: Icon(
                  Icons.star,
                  size: 16,
                  color: filter.favoritesOnly ? Colors.black : AppTheme.csOrange,
                ),
                label: const Text('Favoritos'),
                selected: filter.favoritesOnly,
                onSelected: (v) => onChange(filter.copyWith(favoritesOnly: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A313B)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: filter.accountId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF161A20),
                    hint: const Text('Todas las cuentas', style: TextStyle(color: Colors.white54)),
                    icon: const Icon(Icons.expand_more, color: Colors.white54),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas las cuentas'),
                      ),
                      ...accounts.map<DropdownMenuItem<String?>>((a) {
                        return DropdownMenuItem<String?>(
                          value: a.id,
                          child: Text(a.alias),
                        );
                      }),
                    ],
                    onChanged: (v) => onChange(
                      v == null
                          ? filter.copyWith(clearAccountId: true)
                          : filter.copyWith(accountId: v),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: [
                Checkbox(
                  value: filter.includeSold,
                  onChanged: (v) =>
                      onChange(filter.copyWith(includeSold: v ?? false)),
                ),
                const Text('Incluir vendidos', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.sort, size: 16, color: Colors.white54),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A313B)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InventorySort>(
                    value: filter.sort,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF161A20),
                    icon: const Icon(Icons.expand_more, color: Colors.white54),
                    items: [
                      for (final s in InventorySort.values)
                        DropdownMenuItem(value: s, child: Text(s.label)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      onChange(filter.copyWith(sort: v));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
