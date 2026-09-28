import 'package:flutter/material.dart';

import '../models/inventory_item.dart';

class ItemCategoryIcon {
  static IconData iconFor(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.caseBox:
        return Icons.inventory_2_outlined;
      case ItemCategory.skin:
        return Icons.shield_outlined;
      case ItemCategory.graffiti:
        return Icons.brush_outlined;
      case ItemCategory.knife:
        return Icons.colorize;
      case ItemCategory.glove:
        return Icons.back_hand_outlined;
      case ItemCategory.other:
        return Icons.help_outline;
    }
  }

  static Color colorFor(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.caseBox:
        return const Color(0xFFF59E0B);
      case ItemCategory.skin:
        return const Color(0xFF22D3EE);
      case ItemCategory.graffiti:
        return const Color(0xFFEC4899);
      case ItemCategory.knife:
        return const Color(0xFFEF4444);
      case ItemCategory.glove:
        return const Color(0xFFA855F7);
      case ItemCategory.other:
        return const Color(0xFF9CA3AF);
    }
  }
}
