import 'package:hive/hive.dart';

part 'sale_record.g.dart';

/// Registro de una venta parcial o total de un item del inventario.
/// Cada vez que el usuario marca unidades como vendidas se crea uno.
@HiveType(typeId: 7)
class SaleRecord extends HiveObject {
  /// Id del item original (InventoryItem). Tras borrar el item, este registro
  /// sigue conservándose como histórico.
  @HiveField(0)
  final String itemId;

  /// Snapshot del nombre en el momento de la venta (inmutable).
  @HiveField(1)
  final String itemName;

  /// Categoría congelada al vender (para icono estable).
  @HiveField(2)
  final int categoryIndex;

  /// Nombre de la cuenta snapshot.
  @HiveField(3)
  final String accountName;

  /// Cuántas unidades se vendieron en este registro.
  @HiveField(4)
  final int quantity;

  /// Precio unitario en EUR en el momento de la venta.
  @HiveField(5)
  final double unitPriceEur;

  /// Precio unitario en USD en el momento de la venta.
  @HiveField(6)
  final double unitPriceUsd;

  /// Cuándo se registró la venta.
  @HiveField(7)
  final DateTime soldAt;

  SaleRecord({
    required this.itemId,
    required this.itemName,
    required this.categoryIndex,
    required this.accountName,
    required this.quantity,
    required this.unitPriceEur,
    required this.unitPriceUsd,
    required this.soldAt,
  });

  double get totalEur => unitPriceEur * quantity;
  double get totalUsd => unitPriceUsd * quantity;
}
