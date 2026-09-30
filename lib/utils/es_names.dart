import '../models/inventory_item.dart';

/// Traducción de nombres de cajas al español, igual que las muestra el
/// propio cliente de Steam en español. Los nombres de skins/armas NO se
/// traducen (Steam tampoco los traduce, incluso con el idioma en español).
///
/// Importante: esto es SOLO para mostrar en pantalla. El nombre real
/// guardado en [InventoryItem.itemName] se queda en inglés siempre, porque
/// es el market_hash_name exacto que usan Steam Market y Skinport para
/// consultar precios — traducirlo rompería esas búsquedas.
const Map<String, String> _caseNamesEs = <String, String>{
  'CS:GO Weapon Case': 'Caja de armas de CS:GO',
  'eSports 2013 Case': 'Maletín eSports 2013',
  'Operation Bravo Case': 'Caja de la Operación Bravo',
  'CS:GO Weapon Case 2': 'Caja de armas de CS:GO 2',
  'eSports 2013 Winter Case': 'Maletín eSports de invierno 2013',
  'Winter Offensive Weapon Case': 'Caja de armas de la Ofensiva Invernal',
  'CS:GO Weapon Case 3': 'Caja de armas de CS:GO 3',
  'Operation Phoenix Weapon Case': 'Caja de armas de la Operación Phoenix',
  'Huntsman Weapon Case': 'Caja de armas del Cazador',
  'Operation Breakout Weapon Case': 'Caja de armas de la Operación Breakout',
  'eSports 2014 Summer Case': 'Maletín eSports de verano 2014',
  'Operation Vanguard Weapon Case': 'Caja de armas de la Operación Vanguard',
  'Chroma Case': 'Caja Croma',
  'Chroma 2 Case': 'Caja Croma 2',
  'Falchion Case': 'Caja Alfanje',
  'Shadow Case': 'Caja Sombría',
  'Revolver Case': 'Caja Revólver',
  'Operation Wildfire Case': 'Caja de armas de la Operación Wildfire',
  'Chroma 3 Case': 'Caja Croma 3',
  'Community Graffiti Box 1': 'Caja de grafitis de la comunidad 1',
  'Gamma Case': 'Caja Gamma',
  'Gamma 2 Case': 'Caja Gamma 2',
  'CS:GO Graffiti Box': 'Caja de grafitis de CS:GO',
  'Perfect World Graffiti Box': 'Caja de grafitis de Perfect World',
  'StatTrak™ Radicals Box': 'Caja Radicals de StatTrak™',
  'Glove Case': 'Caja de Guantes',
  'Spectrum Case': 'Caja Espectro',
  'Operation Hydra Case': 'Caja de la Operación Hydra',
  'Spectrum 2 Case': 'Caja Espectro 2',
  'Clutch Case': 'Caja Clutch',
  'Horizon Case': 'Caja Horizonte',
  'Danger Zone Case': 'Caja Danger Zone',
  'Prisma Case': 'Caja Prisma',
  'Shattered Web Case': 'Caja de Shattered Web',
  'CS20 Case': 'Caja CS20',
  'Prisma 2 Case': 'Caja Prisma 2',
  'Masterminds Music Kit Box': 'Caja de kits de música Masterminds',
  'StatTrak™ Masterminds Music Kit Box':
      'Caja de kits de música Masterminds de StatTrak™',
  'Fracture Case': 'Caja Fractura',
  'Operation Broken Fang Case': 'Caja de la Operación Broken Fang',
  'Snakebite Case': 'Caja Picadura',
  'Tacticians Music Kit Box': 'Caja de kits de música Tacticians',
  'StatTrak™ Tacticians Music Kit Box':
      'Caja de kits de música Tacticians de StatTrak™',
  'Operation Riptide Case': 'Caja de la Operación Riptide',
  'Dreams & Nightmares Case': 'Caja Sueños y Pesadillas',
  'Recoil Case': 'Caja Retroceso',
  'Initiators Music Kit Box': 'Caja de kits de música Initiators',
  'StatTrak™ Initiators Music Kit Box':
      'Caja de kits de música Initiators de StatTrak™',
  'Revolution Case': 'Caja Revolución',
  'Kilowatt Case': 'Caja Kilovatio',
  'NIGHTMODE Music Kit Box': 'Caja de kits de música NIGHTMODE',
  'StatTrak™ NIGHTMODE Music Kit Box':
      'Caja de kits de música NIGHTMODE de StatTrak™',
  'Masterminds 2 Music Kit Box': 'Caja de kits de música Masterminds 2',
  'StatTrak™ Masterminds 2 Music Kit Box':
      'Caja de kits de música Masterminds 2 de StatTrak™',
  'Gallery Case': 'Caja Galería',
  'Fever Case': 'Caja Fiebre',
  'Deluge Music Kit Box': 'Caja de kits de música Deluge',
  'StatTrak™ Deluge Music Kit Box':
      'Caja de kits de música Deluge de StatTrak™',
};

/// Nombre a mostrar en pantalla para un item: cajas traducidas al español,
/// el resto (skins, cuchillos, guantes, grafitis...) se queda tal cual,
/// igual que en el propio cliente de Steam en español.
String displayItemName(String itemName, ItemCategory category) {
  if (category != ItemCategory.caseBox) return itemName;
  return _caseNamesEs[itemName] ?? itemName;
}

/// True si `query` coincide con el nombre real (inglés, el que se guarda y
/// se usa para consultar precios) O con su nombre traducido al español (el
/// que se muestra en pantalla). Así el autocompletado encuentra "Caja
/// Kilovatio" tanto si escribes "Kilowatt" como si escribes "Kilovatio" o
/// "Caja".
bool itemMatchesQuery(String itemName, ItemCategory category, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return false;
  if (itemName.toLowerCase().contains(q)) return true;
  return displayItemName(itemName, category).toLowerCase().contains(q);
}
