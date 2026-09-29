import 'package:flutter/services.dart';

/// Puente con los accesos directos estáticos del icono de la app en
/// Android (long-press en el launcher). Ver MainActivity.kt +
/// android/app/src/main/res/xml/shortcuts.xml.
class ShortcutsService {
  static const MethodChannel _channel = MethodChannel('cs2tracker/shortcuts');

  /// Devuelve el id del shortcut con el que se abrió la app en frío
  /// ("inventory", "register_drop"), o null si se abrió normalmente.
  static Future<String?> getInitialShortcut() async {
    try {
      return await _channel.invokeMethod<String>('getInitialShortcut');
    } catch (_) {
      return null;
    }
  }

  /// Escucha shortcuts pulsados mientras la app ya está abierta en primer
  /// plano (la Activity es singleTop, así que llega por onNewIntent).
  static void listen(void Function(String shortcut) onShortcut) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShortcut' && call.arguments is String) {
        onShortcut(call.arguments as String);
      }
    });
  }
}
