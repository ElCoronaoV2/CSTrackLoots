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

  /// Nombre del desgaste en español, tal cual lo muestra el propio cliente
  /// de Steam en español. Es solo para mostrar en pantalla: [label] (inglés)
  /// sigue siendo el que se usa para consultar precios en Steam Market /
  /// Skinport, porque el market_hash_name real siempre está en inglés.
  String get labelEs {
    switch (this) {
      case SkinWear.factoryNew:
        return 'De fábrica';
      case SkinWear.minimalWear:
        return 'Ligeramente usada';
      case SkinWear.fieldTested:
        return 'Curtida por el combate';
      case SkinWear.wellWorn:
        return 'Bastante usada';
      case SkinWear.battleScarred:
        return 'Veterana de mil batallas';
    }
  }
}

/// Item individual en el Inventario General.
/// Se desnormaliza el nombre de la cuenta para no tener que hacer joins al listar.
@HiveType(typeId: 4)
class InventoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  /// Mutables (no `final`) para poder transferir el item a otra cuenta sin
  /// tener que borrar y recrear la fila (ver [InventoryNotifier.transferItem]).
  @HiveField(1)
  String accountId;

  @HiveField(2)
  String accountName;

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

  /// Umbral de precio para la alerta (en la moneda [alertCurrency]).
  /// Null = sin alerta configurada para este item.
  @HiveField(15)
  double? alertThreshold;

  /// Moneda del umbral ('EUR' o 'USD'). Solo relevante si [alertThreshold]
  /// no es null.
  @HiveField(16)
  String? alertCurrency;

  /// True si ya se notificó para el umbral actual (evita repetir la
  /// notificación en cada refresco de precio). Se resetea a false si el
  /// precio vuelve a cruzar el umbral en sentido contrario, permitiendo
  /// re-alertar más tarde.
  @HiveField(17)
  bool alerted;

  /// True = avisar cuando el precio BAJE de [alertThreshold] (para comprar
  /// barato o vender antes de que siga cayendo). False (por defecto) =
  /// avisar cuando SUBA, el comportamiento original.
  @HiveField(18)
  bool alertBelow;

  /// Lo que realmente pagaste por el item (0.0 si fue un drop gratis o no
  /// lo recuerdas). Sirve para calcular el beneficio/ROI real, no solo el
  /// valor de mercado actual.
  @HiveField(19)
  double costEur;

  @HiveField(20)
  double costUsd;

  /// Marcado como favorito para que aparezca destacado/primero en la lista.
  @HiveField(21)
  bool isFavorite;

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
    this.alertThreshold,
    this.alertCurrency,
    this.alerted = false,
    this.alertBelow = false,
    this.costEur = 0.0,
    this.costUsd = 0.0,
    this.isFavorite = false,
  })  : assert(quantity >= 0, 'quantity no puede ser negativa'),
        assert(floatValue == null || (floatValue >= 0.0 && floatValue <= 1.0),
            'floatValue debe estar entre 0.0 y 1.0'),
        stickers = stickers ?? <String>[],
        obtainedAt = obtainedAt ?? DateTime.now();

  /// Precio EUR multiplicado por la cantidad disponible (lo que se vende).
  double get totalEur => priceEur * quantity;
  double get totalUsd => priceUsd * quantity;

  /// Coste total pagado por toda la cantidad (0 si fue drop gratis).
  double get totalCostEur => costEur * quantity;
  double get totalCostUsd => costUsd * quantity;

  /// Beneficio no realizado: valor de mercado actual menos lo que pagaste,
  /// para toda la cantidad. Puede ser negativo si el precio bajó.
  double get unrealizedProfitEur => totalEur - totalCostEur;
  double get unrealizedProfitUsd => totalUsd - totalCostUsd;

  /// Cantidad aún sin vender.
  int get availableQuantity => sold ? 0 : quantity;

  bool get supportsWearDetails => category.supportsWearDetails;
}
