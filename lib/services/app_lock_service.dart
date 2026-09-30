import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

import 'hive_service.dart';

/// Bloqueo de la app con PIN y/o huella/Face ID. El PIN nunca se guarda en
/// claro: solo su hash SHA-256 (con un salt fijo de la app, suficiente aquí
/// porque no protege una cuenta remota, solo evita que alguien abra la app
/// directamente desde el móvil desbloqueado de otra persona).
class AppLockService {
  static const _salt = 'cs2tracker_pin_salt_v1';
  final _localAuth = LocalAuthentication();

  String hashPin(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    return sha256.convert(bytes).toString();
  }

  bool checkPin(String pin) {
    final hash = HiveService.settings.pinHash;
    if (hash == null) return false;
    return hash == hashPin(pin);
  }

  /// True si el dispositivo tiene sensor biométrico configurado (huella,
  /// Face ID...) y se puede usar ahora mismo.
  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Lanza el diálogo nativo de huella/Face ID. Devuelve false también si
  /// el usuario cancela o el sensor falla (nunca lanza).
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Desbloquea CS2 Tracker',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
