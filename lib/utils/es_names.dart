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
  'CS:GO Weapon Case': 'Estuche de armas de CS:GO',
  'eSports 2013 Case': 'Estuche eSports 2013',
  'Operation Bravo Case': 'Estuche de la Operación Bravo',
  'CS:GO Weapon Case 2': 'Estuche de armas de CS:GO 2',
  'CS:GO Weapon Case 3': 'Estuche de armas de CS:GO 3',
  'Winter Offensive Weapon Case': 'Estuche de armas de la Ofensiva de Invierno',
  'eSports 2014 Summer Case': 'Estuche eSports Verano 2014',
  'Operation Breakout Weapon Case': 'Estuche de armas de la Operación Fuga',
  'Huntsman Weapon Case': 'Estuche de armas Cazador',
  'Operation Phoenix Weapon Case': 'Estuche de armas de la Operación Fénix',
  'Chroma Case': 'Estuche Cromo',
  'Chroma 2 Case': 'Estuche Cromo 2',
  'Falchion Case': 'Estuche Sable',
  'Shadow Case': 'Estuche Sombra',
  'Revolver Case': 'Estuche Revólver',
  'Operation Wildfire Case': 'Estuche de la Operación Fuego Salvaje',
  'Chroma 3 Case': 'Estuche Cromo 3',
  'Gamma Case': 'Estuche Gamma',
  'Gamma 2 Case': 'Estuche Gamma 2',
  'Glove Case': 'Estuche de guantes',
  'Spectrum Case': 'Estuche Espectro',
  'Operation Hydra Case': 'Estuche de la Operación Hidra',
  'Spectrum 2 Case': 'Estuche Espectro 2',
  'Clutch Case': 'Estuche Clutch',
  'Horizon Case': 'Estuche Horizonte',
  'Danger Zone Case': 'Estuche Zona de Peligro',
  'Prisma Case': 'Estuche Prisma',
  'CS20 Case': 'Estuche CS20',
  'Shattered Web Case': 'Estuche Red Rota',
  'Prisma 2 Case': 'Estuche Prisma 2',
  'Fracture Case': 'Estuche Fractura',
  'Operation Broken Fang Case': 'Estuche de la Operación Colmillo Roto',
  'Operation Riptide Case': 'Estuche de la Operación Contracorriente',
  'Snakebite Case': 'Estuche Mordedura de Serpiente',
  'Dreams & Nightmares Case': 'Estuche Sueños y Pesadillas',
  'Recoil Case': 'Estuche Retroceso',
  'Revolution Case': 'Estuche Revolución',
  'Kilowatt Case': 'Estuche Kilovatio',
  'Gallery Case': 'Estuche Galería',
  'Fever Case': 'Estuche Fiebre',
  'Operation Vanguard Weapon Case': 'Estuche de armas de la Operación Vanguardia',
  'Operation Bloodhound Weapon Case': 'Estuche de armas de la Operación Sabueso',
};

/// Nombre a mostrar en pantalla para un item: cajas traducidas al español,
/// el resto (skins, cuchillos, guantes, grafitis...) se queda tal cual,
/// igual que en el propio cliente de Steam en español.
String displayItemName(String itemName, ItemCategory category) {
  if (category != ItemCategory.caseBox) return itemName;
  return _caseNamesEs[itemName] ?? itemName;
}
