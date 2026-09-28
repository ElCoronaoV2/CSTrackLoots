import 'package:hive/hive.dart';

part 'inventory_item.g.dart';

/// Categoría del item. Sirve para mostrar icono genérico y filtrar.
@HiveType(typeId: 3)
enum ItemCategory {
  @HiveField(0)
  caseBox,
  @HiveField(1)
  skin,
  @HiveField(2)
  graffiti,
  @HiveField(3)
  knife,
  @HiveField(4)
  glove,
  @HiveField(5)
  other,
}

extension ItemCategoryX on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.caseBox:
        return 'Caja';
      case ItemCategory.skin:
        return 'Skin';
      case ItemCategory.graffiti:
        return 'Grafiti';
      case ItemCategory.knife:
        return 'Cuchillo';
      case ItemCategory.glove:
        return 'Guante';
      case ItemCategory.other:
        return 'Otro';
    }
  }

  /// Solo armas, cuchillos y guantes tienen float/wear/StatTrak/stickers.
  bool get supportsWearDetails =>
      this == ItemCategory.skin ||
      this == ItemCategory.knife ||
      this == ItemCategory.glove;
}

/// Desgaste (wear) de una skin. Los rangos de float exactos varían por skin
/// (cada una define su propio float mínimo/máximo), así que esto es una
/// elección manual del usuario y no se deriva automáticamente del float.
@HiveType(typeId: 8)
enum SkinWear {
  @HiveField(0)
  factoryNew,
  @HiveField(1)
  minimalWear,
  @HiveField(2)
  fieldTested,
  @HiveField(3)
  wellWorn,
  @HiveField(4)
  battleScarred,
}

extension SkinWearX on SkinWear {
  String get label {
    switch (this) {
      case SkinWear.factoryNew:
        return 'Factory New';
      case SkinWear.minimalWear:
        return 'Minimal Wear';
      case SkinWear.fieldTested:
        return 'Field-Tested';
      case SkinWear.wellWorn:
        return 'Well-Worn';
      case SkinWear.battleScarred:
        return 'Battle-Scarred';
    }
  }

  String get shortLabel {
    switch (this) {
      case SkinWear.factoryNew:
        return 'FN';
      case SkinWear.minimalWear:
        return 'MW';
      case SkinWear.fieldTested:
        return 'FT';
      case SkinWear.wellWorn:
        return 'WW';
      case SkinWear.battleScarred:
        return 'BS';
    }
  }
}

/// Item individual en el Inventario General.
/// Se desnormaliza el nombre de la cuenta para no tener que hacer joins al listar.
@HiveType(typeId: 4)
class InventoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String accountId;

  @HiveField(2)
  final String accountName;

  @HiveField(3)
  String itemName;

  @HiveField(4)
  ItemCategory category;

  @HiveField(5)
  double priceEur;

  @HiveField(6)
  double priceUsd;

  @HiveField(7)
  DateTime obtainedAt;

  @HiveField(8)
  bool sold;

  @HiveField(9)
  DateTime? soldAt;

  /// Cantidad de unidades de este mismo item (p.ej. 5 Kilowatt Case = 1 fila
  /// con quantity=5). Por defecto 1 para items únicos.
  @HiveField(10)
  int quantity;

  /// Float (desgaste numérico 0.0-1.0) de la skin, si se conoce.
  @HiveField(11)
  double? floatValue;

  /// Tier de desgaste (Factory New..Battle-Scarred), elegido manualmente.
  @HiveField(12)
  SkinWear? wear;

  /// True si es la versión StatTrak™ del item.
  @HiveField(13)
  bool statTrak;

  /// Nombres de los stickers aplicados (hasta 4 en un arma). Texto libre.
  @HiveField(14)
  List<String> stickers;

  InventoryItem({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.itemName,
    required this.category,
    this.priceEur = 0.0,
    this.priceUsd = 0.0,
    DateTime? obtainedAt,
    this.sold = false,
    this.soldAt,
    this.quantity = 1,
    this.floatValue,
    this.wear,
    this.statTrak = false,
    List<String>? stickers,
  })  : assert(quantity >= 0, 'quantity no puede ser negativa'),
        assert(floatValue == null || (floatValue >= 0.0 && floatValue <= 1.0),
            'floatValue debe estar entre 0.0 y 1.0'),
        stickers = stickers ?? <String>[],
        obtainedAt = obtainedAt ?? DateTime.now();

  /// Precio EUR multiplicado por la cantidad disponible (lo que se vende).
  double get totalEur => priceEur * quantity;
  double get totalUsd => priceUsd * quantity;

  /// Cantidad aún sin vender.
  int get availableQuantity => sold ? 0 : quantity;

  bool get supportsWearDetails => category.supportsWearDetails;
}
