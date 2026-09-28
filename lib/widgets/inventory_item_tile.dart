import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../providers/services_providers.dart';
import '../services/hive_service.dart';
import '../services/skinport_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'item_icons.dart';

/// Tile de un item en el Inventario General.
/// Muestra el icono real (cargado en background desde Steam) si está disponible;
/// si falla la red, cae al icono genérico por categoría.
class InventoryItemTile extends ConsumerStatefulWidget {
  const InventoryItemTile({
    super.key,
    required this.item,
    required this.currency,
    required this.onQuantitySold,
    required this.onDelete,
  });

  final InventoryItem item;
  final String currency;
  final VoidCallback onQuantitySold;
  final VoidCallback onDelete;

  @override
  ConsumerState<InventoryItemTile> createState() => _InventoryItemTileState();
}

class _InventoryItemTileState extends ConsumerState<InventoryItemTile> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = ItemCategoryIcon.colorFor(item.category);
    final icon = ItemCategoryIcon.iconFor(item.category);
    final unitPrice = widget.currency == 'USD' ? item.priceUsd : item.priceEur;
    final totalPrice = unitPrice * item.quantity;
    final dateStr = DateFormat('dd/MM/yyyy').format(item.obtainedAt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.sold ? const Color(0xFF14171C) : const Color(0xFF161A20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.sold ? const Color(0xFF1F252D) : color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          _ItemImageBox(
            itemName: item.itemName,
            fallbackIcon: icon,
            fallbackColor: color,
            size: 46,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: item.sold ? Colors.white54 : Colors.white,
                          decoration: item.sold
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.quantity > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.csOrange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppTheme.csOrange
                                  .withValues(alpha: 0.45)),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            color: AppTheme.csOrange,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MiniChip(
                      icon: Icons.person_outline,
                      text: item.accountName,
                    ),
                    _MiniChip(
                      icon: Icons.category_outlined,
                      text: item.category.label,
                      color: color,
                    ),
                    _MiniChip(
                      icon: Icons.event_outlined,
                      text: dateStr,
                    ),
                    if (item.wear != null)
                      _MiniChip(
                        icon: Icons.blur_circular,
                        text: item.floatValue != null
                            ? '${item.wear!.shortLabel} ${item.floatValue!.toStringAsFixed(4)}'
                            : item.wear!.shortLabel,
                      ),
                    if (item.wear == null && item.floatValue != null)
                      _MiniChip(
                        icon: Icons.blur_circular,
                        text: item.floatValue!.toStringAsFixed(4),
                      ),
                    if (item.stickers.isNotEmpty)
                      _MiniChip(
                        icon: Icons.emoji_emotions_outlined,
                        text: item.stickers.length == 1
                            ? item.stickers.first
                            : '${item.stickers.length} stickers',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.quantity > 1 && unitPrice > 0)
                Text(
                  '${formatPrice(unitPrice, widget.currency)}/u',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              Text(
                formatPrice(totalPrice, widget.currency),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: item.sold
                      ? Colors.white38
                      : (totalPrice > 0 ? AppTheme.csOrange : Colors.white38),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Comparar con Skinport',
                    onPressed: () => _comparePrices(context),
                    icon: const Icon(Icons.compare_arrows,
                        size: 18, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmSell(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      item.sold ? Icons.undo : Icons.sell_outlined,
                      size: 16,
                      color: item.sold ? AppTheme.csCyan : Colors.white70,
                    ),
                    label: Text(
                      item.sold ? 'Devolver' : 'Vender',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            item.sold ? AppTheme.csCyan : Colors.white70,
                      ),
                    ),
                  ),
                  if (!item.sold)
                    IconButton(
                      tooltip: item.alertThreshold != null
                          ? 'Alerta de precio activa'
                          : 'Poner alerta de precio',
                      onPressed: () => _setAlert(context),
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
                    tooltip: 'Eliminar del inventario',
                    onPressed: () => _confirmDelete(context),
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

  Future<void> _confirmSell(BuildContext context) async {
    final item = widget.item;
    if (item.sold) {
      // Reabrir al menos 1 unidad.
      await ref
          .read(inventoryProvider.notifier)
          .unmarkSold(item.id, qty: 1);
      widget.onQuantitySold();
      return;
    }
    final available = item.quantity;
    final ctrl = TextEditingController(text: '$available');
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.sell_outlined, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Expanded(child: Text('Vender "${item.itemName}"')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Cuántas unidades vendiste? Disponibles: $available.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'ej. 1',
                ),
                onSubmitted: (_) {
                  final v = int.tryParse(ctrl.text) ?? 0;
                  Navigator.of(ctx).pop(v);
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final preset in [1, available >= 5 ? 5 : available, available])
                    if (preset > 0 && preset <= available)
                      ActionChip(
                        label: Text('x$preset'),
                        onPressed: () => Navigator.of(ctx).pop(preset),
                      ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(0),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(ctrl.text) ?? 0;
                Navigator.of(ctx).pop(v);
              },
              child: const Text('VENDER'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    final qty = result ?? 0;
    if (qty <= 0) return;
    final remaining = await ref
        .read(inventoryProvider.notifier)
        .sellQuantity(item.id, qty);
    if (remaining < 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la venta.')),
      );
      return;
    }
    final remainingStr =
        remaining == 0 ? '0 (vendido todo)' : '$remaining restantes';
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFF59E0B),
        content: Text(
          'Vendidas x$qty. Quedan $remainingStr.',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
    widget.onQuantitySold();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar item?'),
        content: Text(
          'Se eliminará "${widget.item.itemName}" del inventario general. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(inventoryProvider.notifier).deleteItem(widget.item.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text(
            'Item eliminado.',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      );
      widget.onDelete();
    }
  }

  Future<void> _comparePrices(BuildContext context) async {
    final item = widget.item;
    final steamPrice =
        widget.currency == 'USD' ? item.priceUsd : item.priceEur;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.compare_arrows, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Expanded(child: Text('Comparar precios')),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _PriceRow(
                label: 'Steam Community Market',
                value: formatPrice(steamPrice, widget.currency),
              ),
              const Divider(height: 24, color: Color(0xFF2A313B)),
              FutureBuilder<SkinportPrice?>(
                future: ref
                    .read(skinportServiceProvider)
                    .getPrice(item.itemName, currency: widget.currency),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final price = snapshot.data;
                  if (price == null) {
                    return const Text(
                      'Skinport no disponible ahora mismo (a veces bloquea peticiones automatizadas). El precio de Steam de arriba sigue siendo correcto.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    );
                  }
                  return _PriceRow(
                    label: 'Skinport (mínimo)',
                    value: formatPrice(price.minPrice, widget.currency),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _setAlert(BuildContext context) async {
    final item = widget.item;
    final current =
        item.alertCurrency == widget.currency ? item.alertThreshold : null;
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
                labelText: 'Precio (${widget.currency})',
                prefixIcon: Icon(
                  widget.currency == 'USD' ? Icons.attach_money : Icons.euro,
                ),
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
    if (confirmed != true || !mounted) return;

    final trimmed = text.trim().replaceAll(',', '.');
    final value = trimmed.isEmpty ? null : double.tryParse(trimmed);
    await ref.read(inventoryProvider.notifier).setAlertThreshold(
          item.id,
          currency: widget.currency,
          threshold: value,
        );
  }
}

/// Fila etiqueta + precio para el diálogo de comparación de precios.
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

/// Caja con icono: real (si está cacheado) o fallback genérico de categoría.
/// Se re-renderiza automáticamente cuando el price_cache_box cambia
/// para esa clave (itemName).
class _ItemImageBox extends StatelessWidget {
  const _ItemImageBox({
    required this.itemName,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.size,
  });

  final String itemName;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final box = HiveService.priceCacheBox;
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: <dynamic>[itemName]),
      builder: (context, _, _) {
        final cached = box.get(itemName);
        final iconUrl =
            (cached != null && cached.hasIcon) ? cached.iconUrl : null;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fallbackColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: fallbackColor.withValues(alpha: 0.45)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: iconUrl == null
                ? Icon(fallbackIcon, color: fallbackColor)
                : Image.network(
                    iconUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: size * 0.35,
                          height: size * 0.35,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(fallbackIcon, color: fallbackColor);
                    },
                  ),
          ),
        );
      },
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
