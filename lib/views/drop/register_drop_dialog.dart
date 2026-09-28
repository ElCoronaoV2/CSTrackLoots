import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cs_account.dart';
import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../services/hive_service.dart' show SeedItems;

class _DropItem {
  TextEditingController name;
  ItemCategory category;
  _DropItem({String name = '', this.category = ItemCategory.caseBox})
      : name = TextEditingController(text: name);
}

/// Diálogo modal que permite registrar 1 o 2 objetos del drop semanal de CS2.
class RegisterDropDialog extends ConsumerStatefulWidget {
  const RegisterDropDialog({super.key, required this.account});
  final CsAccount account;

  static Future<void> show(BuildContext context, {required CsAccount account}) async {
    await showDialog(
      context: context,
      builder: (_) => RegisterDropDialog(account: account),
    );
  }

  @override
  ConsumerState<RegisterDropDialog> createState() => _RegisterDropDialogState();
}

class _RegisterDropDialogState extends ConsumerState<RegisterDropDialog> {
  final List<_DropItem> _items = [
    _DropItem(category: ItemCategory.caseBox),
    _DropItem(category: ItemCategory.caseBox),
  ];

  @override
  void dispose() {
    for (final i in _items) {
      i.name.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final canConfirm = _items.any((i) => i.name.text.trim().isNotEmpty);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(child: Text('Drop de ${widget.account.alias}')),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En CS2 un drop semanal ofrece 2 recompensas a elegir. Registra 1 o 2 items.',
              style: t.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < _items.length; i++) ...[
              _ItemRow(
                item: _items[i],
                index: i,
                onChanged: () => setState(() {}),
                onClear: _items[i].name.text.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _items[i].name.clear();
                        });
                      },
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1F25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A313B)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Al confirmar, la cuenta se marcará como "Drop conseguido" y los items se añadirán al Inventario General.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: canConfirm
              ? () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final validItems = _items
                      .where((i) => i.name.text.trim().isNotEmpty)
                      .map((i) => (
                            itemName: i.name.text.trim(),
                            category: i.category,
                          ))
                      .toList();
                  await ref.read(inventoryProvider.notifier).registerDrop(
                        account: widget.account,
                        items: validItems
                            .map((v) => (
                                  itemName: v.itemName,
                                  category: v.category,
                                  quantity: 1,
                                ))
                            .toList(),
                        when: DateTime.now(),
                      );
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF22C55E),
                      content: Text(
                        'Drop registrado (${validItems.length} item${validItems.length == 1 ? "" : "s"}).',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }
              : null,
          icon: const Icon(Icons.check),
          label: const Text('CONFIRMAR'),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onClear,
  });

  final _DropItem item;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Item ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            if (onClear == null)
              const Text(
                '(opcional)',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Autocomplete<String>(
                initialValue: TextEditingValue(text: item.name.text),
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) return const Iterable<String>.empty();
                  final query = value.text.toLowerCase();
                  return SeedItems.all
                      .where((s) => s.toLowerCase().contains(query))
                      .take(8);
                },
                onSelected: (selection) {
                  item.name.text = selection;
                  item.name.selection = TextSelection.fromPosition(
                    TextPosition(offset: selection.length),
                  );
                  onChanged();
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  // Mantener sincronizado el controller del item con el del autocomplete.
                  controller.text = item.name.text;
                  controller.selection = item.name.selection;
                  controller.addListener(() {
                    if (item.name.text != controller.text) {
                      item.name.text = controller.text;
                      item.name.selection = controller.selection;
                      onChanged();
                    }
                  });
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Buscar (ej. Kilowatt Case)',
                      prefixIcon: Icon(Icons.search),
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
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.cancel_outlined, color: Colors.white38),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: ItemCategory.values.map((c) {
            final selected = c == item.category;
            return ChoiceChip(
              label: Text(c.label),
              selected: selected,
              onSelected: (_) {
                item.category = c;
                onChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
