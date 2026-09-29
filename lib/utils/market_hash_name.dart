import '../models/inventory_item.dart';

/// Construye el market_hash_name exacto que usan Steam Market y Skinport
/// a partir del nombre base, el prefijo StatTrak™ y el sufijo de desgaste.
String buildMarketHashName({
  required String baseName,
  bool statTrak = false,
  SkinWear? wear,
}) {
  final prefix = statTrak ? 'StatTrak™ ' : '';
  final suffix = wear != null ? ' (${wear.label})' : '';
  return '$prefix$baseName$suffix';
}

/// Desgaste aproximado según los rangos de float "estándar" de Valve. Cada
/// skin puede definir su propio rango (algunas ni siquiera llegan a Factory
/// New o Battle-Scarred), así que esto es solo una referencia orientativa,
/// no el desgaste real de esa skin en concreto.
SkinWear approximateWearFromFloat(double float) {
  if (float < 0.07) return SkinWear.factoryNew;
  if (float < 0.15) return SkinWear.minimalWear;
  if (float < 0.38) return SkinWear.fieldTested;
  if (float < 0.45) return SkinWear.wellWorn;
  return SkinWear.battleScarred;
}
