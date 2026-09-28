import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/cs_account.dart';
import '../../models/inventory_item.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/hive_service.dart' show SeedItems;
import '../../widgets/wear_details_fields.dart';

/// Diálogo para añadir manualmente un item al inventario, sin pasar por el
/// flujo de drop de una cuenta. Útil para cargar inventario histórico.
class AddItemDialog extends ConsumerStatefulWidget {
  const AddItemDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const AddItemDialog(),
    );
  }

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  final _nameCtrl = TextEditingController();
  final _floatCtrl = TextEditingController();
  final _stickersCtrl = TextEditingController();
  ItemCategory _category = ItemCategory.skin;
  CsAccount? _selectedAccount; // null => "Sin cuenta" (manual)
  DateTime _date = DateTime.now();
  int _quantity = 1;
  SkinWear? _wear;
  bool _statTrak = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _floatCtrl.dispose();
    _stickersCtrl.dispose();
    super.dispose();
  }

  bool get _canConfirm => _nameCtrl.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2012, 1, 1),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF59E0B),
            surface: Color(0xFF161A20),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final dateStr = DateFormat('dd/MM/yyyy').format(_date);

    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.add_box_outlined, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Text('Añadir item al inventario'),
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
                'Carga items que ya tengas en Steam sin pasar por el flujo de drop semanal.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 14),
              // Nombre con autocomplete.
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
                  _nameCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: sel.length),
                  );
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
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              if (_category.supportsWearDetails)
                WearDetailsFields(
                  statTrak: _statTrak,
                  onStatTrakChanged: (v) => setState(() => _statTrak = v),
                  wear: _wear,
                  onWearChanged: (w) => setState(() => _wear = w),
                  floatController: _floatCtrl,
                  stickersController: _stickersCtrl,
                ),
              const SizedBox(height: 14),
              const Text('Cuenta (opcional)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A313B)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CsAccount?>(
                    value: _selectedAccount,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF161A20),
                    hint: const Text('Sin cuenta (manual)',
                        style: TextStyle(color: Colors.white54)),
                    icon: const Icon(Icons.expand_more, color: Colors.white54),
                    items: [
                      const DropdownMenuItem<CsAccount?>(
                        value: null,
                        child: Text('Sin cuenta (manual)'),
                      ),
                      ...accounts.map<DropdownMenuItem<CsAccount?>>((a) {
                        return DropdownMenuItem<CsAccount?>(
                          value: a,
                          child: Text(a.alias),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => _selectedAccount = v),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Cantidad',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Color(0xFFF59E0B), size: 28),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 64),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A313B)),
                    ),
                    child: Text(
                      'x$_quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline,
                        color: Color(0xFFF59E0B), size: 28),
                  ),
                  const SizedBox(width: 8),
                  const Text('unidades',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Fecha de obtención',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event, size: 18),
                label: Text(dateStr),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1F25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A313B)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.cloud_sync_outlined, size: 16, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al guardar, se consultará el precio oficial y el icono real desde Steam en segundo plano.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
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
                  await ref.read(inventoryProvider.notifier).addManualItem(
                        itemName: _nameCtrl.text,
                        category: _category,
                        obtainedAt: _date,
                        account: _selectedAccount,
                        quantity: _quantity,
                        floatValue: _category.supportsWearDetails
                            ? parseFloatField(_floatCtrl.text)
                            : null,
                        wear: _category.supportsWearDetails ? _wear : null,
                        statTrak:
                            _category.supportsWearDetails ? _statTrak : false,
                        stickers: _category.supportsWearDetails
                            ? parseStickersField(_stickersCtrl.text)
                            : const <String>[],
                      );
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF22C55E),
                      content: Text(
                        'Item añadido al inventario.',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }
              : null,
          icon: const Icon(Icons.check),
          label: const Text('AÑADIR'),
        ),
      ],
    );
  }
}
