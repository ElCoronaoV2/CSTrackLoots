import 'package:home_widget/home_widget.dart';

import 'hive_service.dart';
import '../utils/formatters.dart';

/// Actualiza el widget de pantalla de inicio de Android con el valor total
/// del inventario y cuántas cuentas tienen el drop semanal pendiente. Es un
/// "best effort": cualquier fallo se ignora en silencio (el widget es un
/// complemento, nunca debe romper el flujo normal de la app).
class HomeWidgetService {
  static const _providerName = 'InventoryWidgetProvider';

  static Future<void> update() async {
    try {
      final settings = HiveService.settings;
      final currency = settings.preferredCurrency;
      double total = 0;
      for (final item in HiveService.inventoryBox.values) {
        if (item.sold) continue;
        total += (currency == 'USD' ? item.priceUsd : item.priceEur) * item.quantity;
      }

      final pendingCount = HiveService.accountsBox.values
          .where((a) => !a.dropObtainedThisWeek && !a.dropMissedThisWeek)
          .length;
      final pendingLabel = pendingCount == 0
          ? 'Sin drops pendientes'
          : pendingCount == 1
              ? '1 drop pendiente'
              : '$pendingCount drops pendientes';

      await HomeWidget.saveWidgetData<String>(
          'inventory_value', formatPrice(total, currency));
      await HomeWidget.saveWidgetData<String>('pending_label', pendingLabel);
      await HomeWidget.updateWidget(name: _providerName);
    } catch (_) {
      // El widget es un extra: nunca debe interrumpir el flujo de la app.
    }
  }
}
