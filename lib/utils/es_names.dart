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
  'eSports 2013 Case': 'Caja eSports 2013',
  'Operation Bravo Case': 'Caja de la Operación Bravo',
  'CS:GO Weapon Case 2': 'Caja de armas de CS:GO 2',
  'CS:GO Weapon Case 3': 'Caja de armas de CS:GO 3',
  'Winter Offensive Weapon Case': 'Caja de armas de la Ofensiva de Invierno',
  'eSports 2014 Summer Case': 'Caja eSports Verano 2014',
  'Operation Breakout Weapon Case': 'Caja de armas de la Operación Fuga',
  'Huntsman Weapon Case': 'Caja de armas Cazador',
  'Operation Phoenix Weapon Case': 'Caja de armas de la Operación Fénix',
  'Chroma Case': 'Caja Cromo',
  'Chroma 2 Case': 'Caja Cromo 2',
  'Falchion Case': 'Caja Sable',
  'Shadow Case': 'Caja Sombra',
  'Revolver Case': 'Caja Revólver',
  'Operation Wildfire Case': 'Caja de la Operación Fuego Salvaje',
  'Chroma 3 Case': 'Caja Cromo 3',
  'Gamma Case': 'Caja Gamma',
  'Gamma 2 Case': 'Caja Gamma 2',
  'Glove Case': 'Caja de guantes',
  'Spectrum Case': 'Caja Espectro',
  'Operation Hydra Case': 'Caja de la Operación Hidra',
  'Spectrum 2 Case': 'Caja Espectro 2',
  'Clutch Case': 'Caja Clutch',
  'Horizon Case': 'Caja Horizonte',
  'Danger Zone Case': 'Caja Zona de Peligro',
  'Prisma Case': 'Caja Prisma',
  'CS20 Case': 'Caja CS20',
  'Shattered Web Case': 'Caja Red Rota',
  'Prisma 2 Case': 'Caja Prisma 2',
  'Fracture Case': 'Caja Fractura',
  'Operation Broken Fang Case': 'Caja de la Operación Colmillo Roto',
  'Operation Riptide Case': 'Caja de la Operación Contracorriente',
  'Snakebite Case': 'Caja Mordedura de Serpiente',
  'Dreams & Nightmares Case': 'Caja Sueños y Pesadillas',
  'Recoil Case': 'Caja Retroceso',
  'Revolution Case': 'Caja Revolución',
  'Kilowatt Case': 'Caja Kilovatio',
  'Gallery Case': 'Caja Galería',
  'Fever Case': 'Caja Fiebre',
  'Operation Vanguard Weapon Case': 'Caja de armas de la Operación Vanguardia',
  'Operation Bloodhound Weapon Case': 'Caja de armas de la Operación Sabueso',
};

/// Nombre a mostrar en pantalla para un item: cajas traducidas al español,
/// el resto (skins, cuchillos, guantes, grafitis...) se queda tal cual,
/// igual que en el propio cliente de Steam en español.
String displayItemName(String itemName, ItemCategory category) {
  if (category != ItemCategory.caseBox) return itemName;
  return _caseNamesEs[itemName] ?? itemName;
}
