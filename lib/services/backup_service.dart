import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../models/cs_account.dart';
import '../models/inventory_item.dart';
import '../models/sale_record.dart';
import 'hive_service.dart';

/// Servicio de backup/restore: exporta cuentas, inventario y ventas a un JSON
/// portable, y permite restaurarlo desde un archivo seleccionado por el usuario.
class BackupService {
  /// Construye un Map JSON-serializable con TODO el estado de la app.
  Map<String, dynamic> buildBackupJson() {
    final accounts = HiveService.accountsBox.values
        .map((a) => {
              'id': a.id,
              'alias': a.alias,
              'dropObtainedThisWeek': a.dropObtainedThisWeek,
              'dropMissedThisWeek': a.dropMissedThisWeek,
              'lastDropDate': a.lastDropDate?.toIso8601String(),
              'premierRating': a.premierRating,
              'mapRanks': a.mapRanks,
              'wingmanRank': a.wingmanRank,
              'sortIndex': a.sortIndex,
              'totalObtained': a.totalObtained,
              'totalMissed': a.totalMissed,
              'currentStreak': a.currentStreak,
              'bestStreak': a.bestStreak,
              'steamId64': a.steamId64,
            })
        .toList();

    final inventory = HiveService.inventoryBox.values.map((i) => {
          'id': i.id,
          'accountId': i.accountId,
          'accountName': i.accountName,
          'itemName': i.itemName,
          'category': i.category.name,
          'priceEur': i.priceEur,
          'priceUsd': i.priceUsd,
          'obtainedAt': i.obtainedAt.toIso8601String(),
          'sold': i.sold,
          'soldAt': i.soldAt?.toIso8601String(),
          'quantity': i.quantity,
          'floatValue': i.floatValue,
          'wear': i.wear?.name,
          'statTrak': i.statTrak,
          'stickers': i.stickers,
          'alertThreshold': i.alertThreshold,
          'alertCurrency': i.alertCurrency,
          'alerted': i.alerted,
          'alertBelow': i.alertBelow,
        }).toList();

    final sales = HiveService.salesBox.values.map((s) => {
          'itemId': s.itemId,
          'itemName': s.itemName,
          'categoryIndex': s.categoryIndex,
          'accountName': s.accountName,
          'quantity': s.quantity,
          'unitPriceEur': s.unitPriceEur,
          'unitPriceUsd': s.unitPriceUsd,
          'soldAt': s.soldAt.toIso8601String(),
        }).toList();

    return {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'cs2_tracker',
      'lastProcessedResetEpochMs':
          HiveService.settings.lastProcessedResetEpochMs,
      'accounts': accounts,
      'inventory': inventory,
      'sales': sales,
    };
  }

  /// Exporta a un archivo temporal y abre el share sheet del sistema.
  /// Devuelve el path del archivo generado.
  Future<String> exportAndShare() async {
    final json = buildBackupJson();
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final path = '${dir.path}/cs2_tracker_backup_$ts.json';
    final file = File(path);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));

    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/json')],
      subject: 'CS2 Tracker — backup',
      text: 'Backup de mi CS2 Tracker',
    );
    return path;
  }

  /// Backup automático silencioso: guarda un JSON en una carpeta propia de
  /// la app en el almacenamiento del dispositivo (visible con un gestor de
  /// archivos en Android/data/<paquete>/files/backups), sin compartir ni
  /// pedir permisos adicionales. Respeta el intervalo configurado en
  /// Ajustes y conserva solo los últimos 10 backups automáticos.
  ///
  /// No hace nada si el auto-backup está desactivado, todavía no toca el
  /// intervalo, o el almacenamiento externo no está disponible.
  Future<void> autoBackupIfNeeded() async {
    final settings = HiveService.settings;
    if (!settings.autoBackupEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final intervalMs =
        settings.autoBackupIntervalDays * Duration.millisecondsPerDay;
    if (now - settings.lastAutoBackupEpochMs < intervalMs) return;

    final root = await getExternalStorageDirectory();
    if (root == null) return;

    final backupsDir = Directory('${root.path}/backups');
    await backupsDir.create(recursive: true);

    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final path = '${backupsDir.path}/cs2_tracker_backup_$ts.json';
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(buildBackupJson()),
    );

    // Limpieza: conservar solo los últimos 10 backups automáticos.
    final files = backupsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    for (final f in files.skip(10)) {
      try {
        await f.delete();
      } catch (_) {}
    }

    settings.lastAutoBackupEpochMs = now;
    try {
      await settings.save();
    } catch (_) {}
  }

  /// Restaura desde un JSON. Devuelve estadísticas (cuentas, items, ventas).
  Future<({int accounts, int items, int sales})> restoreFromPicker() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    if (files.isEmpty) {
      throw const BackupCancelledException();
    }
    final path = files.single.path;
    if (path == null) {
      throw const BackupCancelledException();
    }
    final file = File(path);
    final raw = await file.readAsString();
    return restoreFromString(raw);
  }

  /// Restaura desde un string JSON. **SOBRESCRIBE** todo el contenido actual.
  Future<({int accounts, int items, int sales})> restoreFromString(
    String raw,
  ) async {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['app'] != 'cs2_tracker') {
      throw const FormatException('Archivo no es un backup de CS2 Tracker.');
    }

    // 1) Limpiar todas las cajas.
    await HiveService.accountsBox.clear();
    await HiveService.inventoryBox.clear();
    await HiveService.salesBox.clear();

    // 2) Restaurar cuentas.
    final accs = (data['accounts'] as List?) ?? const [];
    for (final raw in accs) {
      final m = raw as Map<String, dynamic>;
      final acc = CsAccount(
        id: m['id'] as String,
        alias: m['alias'] as String,
        dropObtainedThisWeek: m['dropObtainedThisWeek'] as bool? ?? false,
        dropMissedThisWeek: m['dropMissedThisWeek'] as bool? ?? false,
        lastDropDate: m['lastDropDate'] == null
            ? null
            : DateTime.parse(m['lastDropDate'] as String),
        premierRating: m['premierRating'] as int? ?? 0,
        mapRanks: m['mapRanks'] is Map
            ? Map<String, String>.from(m['mapRanks'] as Map)
            : <String, String>{},
        wingmanRank: m['wingmanRank'] as String?,
        sortIndex: m['sortIndex'] as int? ?? 0,
        totalObtained: m['totalObtained'] as int? ?? 0,
        totalMissed: m['totalMissed'] as int? ?? 0,
        currentStreak: m['currentStreak'] as int? ?? 0,
        bestStreak: m['bestStreak'] as int? ?? 0,
        steamId64: m['steamId64'] as String?,
      );
      await HiveService.accountsBox.put(acc.id, acc);
    }

    // 3) Restaurar inventario.
    final invs = (data['inventory'] as List?) ?? const [];
    for (final raw in invs) {
      final m = raw as Map<String, dynamic>;
      final catName = m['category'] as String? ?? 'other';
      final cat = ItemCategory.values.firstWhere(
        (c) => c.name == catName,
        orElse: () => ItemCategory.other,
      );
      final wearName = m['wear'] as String?;
      final wear = wearName == null
          ? null
          : SkinWear.values.firstWhere(
              (w) => w.name == wearName,
              orElse: () => SkinWear.factoryNew,
            );
      final item = InventoryItem(
        id: m['id'] as String,
        accountId: m['accountId'] as String,
        accountName: m['accountName'] as String,
        itemName: m['itemName'] as String,
        category: cat,
        priceEur: (m['priceEur'] as num?)?.toDouble() ?? 0,
        priceUsd: (m['priceUsd'] as num?)?.toDouble() ?? 0,
        obtainedAt: DateTime.parse(m['obtainedAt'] as String),
        sold: m['sold'] as bool? ?? false,
        soldAt: m['soldAt'] == null
            ? null
            : DateTime.parse(m['soldAt'] as String),
        quantity: m['quantity'] as int? ?? 1,
        floatValue: (m['floatValue'] as num?)?.toDouble(),
        wear: wear,
        statTrak: m['statTrak'] as bool? ?? false,
        stickers: (m['stickers'] as List?)?.cast<String>() ?? const [],
        alertThreshold: (m['alertThreshold'] as num?)?.toDouble(),
        alertCurrency: m['alertCurrency'] as String?,
        alerted: m['alerted'] as bool? ?? false,
        alertBelow: m['alertBelow'] as bool? ?? false,
      );
      await HiveService.inventoryBox.put(item.id, item);
    }

    // 4) Restaurar ventas.
    final sals = (data['sales'] as List?) ?? const [];
    for (final raw in sals) {
      final m = raw as Map<String, dynamic>;
      final rec = SaleRecord(
        itemId: m['itemId'] as String,
        itemName: m['itemName'] as String,
        categoryIndex: m['categoryIndex'] as int? ?? 0,
        accountName: m['accountName'] as String,
        quantity: m['quantity'] as int? ?? 1,
        unitPriceEur: (m['unitPriceEur'] as num?)?.toDouble() ?? 0,
        unitPriceUsd: (m['unitPriceUsd'] as num?)?.toDouble() ?? 0,
        soldAt: DateTime.parse(m['soldAt'] as String),
      );
      await HiveService.salesBox.add(rec);
    }

    // 5) Restaurar marca de reset procesado.
    final lastReset = data['lastProcessedResetEpochMs'] as int?;
    if (lastReset != null) {
      HiveService.settings.lastProcessedResetEpochMs = lastReset;
      await HiveService.settings.save();
    }

    return (
      accounts: accs.length,
      items: invs.length,
      sales: sals.length,
    );
  }
}

class BackupCancelledException implements Exception {
  const BackupCancelledException();
  @override
  String toString() => 'Operación cancelada por el usuario.';
}
