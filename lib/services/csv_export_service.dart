import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/inventory_item.dart';
import '../models/sale_record.dart';
import '../utils/es_names.dart';

/// Exporta ventas o inventario a un CSV y abre el share sheet del sistema,
/// para llevar registro externo (hoja de cálculo, declaración de impuestos...).
class CsvExportService {
  /// Escapa un valor para una celda CSV: si contiene comas, comillas o
  /// saltos de línea, lo envuelve en comillas dobles (duplicando las que
  /// ya tuviera dentro), tal cual exige el formato CSV estándar (RFC 4180).
  String _cell(Object? value) {
    final s = value?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String _row(List<Object?> values) => values.map(_cell).join(',');

  Future<String> _writeAndShare(String contents, String filenamePrefix) async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final path = '${dir.path}/${filenamePrefix}_$ts.csv';
    final file = File(path);
    // BOM UTF-8 para que Excel abra bien los acentos.
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...contents.codeUnits]);

    await Share.shareXFiles(
      [XFile(path, mimeType: 'text/csv')],
      subject: 'CS2 Tracker — export CSV',
    );
    return path;
  }

  /// Exporta el historial de ventas completo.
  Future<String> exportSales(List<SaleRecord> sales) async {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final buffer = StringBuffer();
    buffer.writeln(_row([
      'Fecha',
      'Cuenta',
      'Item',
      'Categoría',
      'Cantidad',
      'Precio unitario EUR',
      'Precio unitario USD',
      'Total EUR',
      'Total USD',
      'Coste unitario EUR',
      'Coste unitario USD',
      'Beneficio EUR',
      'Beneficio USD',
    ]));
    for (final s in sales) {
      final cat = s.categoryIndex >= 0 && s.categoryIndex < ItemCategory.values.length
          ? ItemCategory.values[s.categoryIndex]
          : ItemCategory.other;
      buffer.writeln(_row([
        dateFmt.format(s.soldAt),
        s.accountName,
        displayItemName(s.itemName, cat),
        cat.label,
        s.quantity,
        s.unitPriceEur.toStringAsFixed(2),
        s.unitPriceUsd.toStringAsFixed(2),
        s.totalEur.toStringAsFixed(2),
        s.totalUsd.toStringAsFixed(2),
        s.unitCostEur.toStringAsFixed(2),
        s.unitCostUsd.toStringAsFixed(2),
        s.profitEur.toStringAsFixed(2),
        s.profitUsd.toStringAsFixed(2),
      ]));
    }
    return _writeAndShare(buffer.toString(), 'cs2_tracker_ventas');
  }

  /// Exporta el inventario actual (por defecto solo lo no vendido).
  Future<String> exportInventory(List<InventoryItem> items) async {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final buffer = StringBuffer();
    buffer.writeln(_row([
      'Cuenta',
      'Item',
      'Categoría',
      'Cantidad',
      'Fecha obtención',
      'Vendido',
      'Precio unitario EUR',
      'Precio unitario USD',
      'Total EUR',
      'Total USD',
      'Coste unitario EUR',
      'Coste unitario USD',
      'StatTrak',
      'Desgaste',
      'Float',
      'Favorito',
    ]));
    for (final it in items) {
      buffer.writeln(_row([
        it.accountName,
        displayItemName(it.itemName, it.category),
        it.category.label,
        it.quantity,
        dateFmt.format(it.obtainedAt),
        it.sold ? 'Sí' : 'No',
        it.priceEur.toStringAsFixed(2),
        it.priceUsd.toStringAsFixed(2),
        it.totalEur.toStringAsFixed(2),
        it.totalUsd.toStringAsFixed(2),
        it.costEur.toStringAsFixed(2),
        it.costUsd.toStringAsFixed(2),
        it.statTrak ? 'Sí' : 'No',
        it.wear?.labelEs ?? '',
        it.floatValue?.toStringAsFixed(4) ?? '',
        it.isFavorite ? 'Sí' : 'No',
      ]));
    }
    return _writeAndShare(buffer.toString(), 'cs2_tracker_inventario');
  }
}
