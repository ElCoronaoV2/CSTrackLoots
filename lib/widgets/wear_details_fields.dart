import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../theme/app_theme.dart';

/// Sección de detalles de desgaste (float/wear/StatTrak™/stickers). Solo
/// tiene sentido para armas, cuchillos y guantes (ver
/// [ItemCategoryX.supportsWearDetails]). Sin estado propio: el padre posee
/// los valores y reacciona a los callbacks, igual que el resto de campos
/// de estos diálogos.
class WearDetailsFields extends StatelessWidget {
  const WearDetailsFields({
    super.key,
    required this.statTrak,
    required this.onStatTrakChanged,
    required this.wear,
    required this.onWearChanged,
    required this.floatController,
    required this.stickersController,
  });

  final bool statTrak;
  final ValueChanged<bool> onStatTrakChanged;
  final SkinWear? wear;
  final ValueChanged<SkinWear?> onWearChanged;
  final TextEditingController floatController;
  final TextEditingController stickersController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Text(
          'Detalles de desgaste (opcional)',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: floatController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Float',
                  hintText: '0.00 - 1.00',
                  prefixIcon: Icon(Icons.blur_circular),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilterChip(
              label: const Text('StatTrak™'),
              selected: statTrak,
              onSelected: onStatTrakChanged,
              selectedColor: AppTheme.csOrange.withValues(alpha: 0.3),
              checkmarkColor: AppTheme.csOrange,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Sin especificar'),
              selected: wear == null,
              onSelected: (_) => onWearChanged(null),
            ),
            ...SkinWear.values.map(
              (w) => ChoiceChip(
                label: Text(w.shortLabel),
                selected: wear == w,
                onSelected: (_) => onWearChanged(w),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: stickersController,
          decoration: const InputDecoration(
            labelText: 'Stickers',
            hintText: 'separados por coma, ej: Howling Dawn, Katowice 2015',
            prefixIcon: Icon(Icons.emoji_emotions_outlined),
          ),
        ),
      ],
    );
  }
}

/// Convierte el texto libre del campo de float en un valor válido 0.0-1.0,
/// o null si está vacío o no es un número en rango.
double? parseFloatField(String raw) {
  final text = raw.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  final value = double.tryParse(text);
  if (value == null || value < 0.0 || value > 1.0) return null;
  return value;
}

/// Convierte el texto libre de stickers (separados por coma) en una lista
/// limpia, sin entradas vacías.
List<String> parseStickersField(String raw) {
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
