import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../services/app_lock_service.dart';
import '../../theme/app_theme.dart';

const _pinLength = 4;

/// Pantalla de bloqueo mostrada antes que nada cuando el usuario activó
/// PIN/huella en Ajustes. Solo permite pasar con el PIN correcto o, si está
/// activada, con huella/Face ID.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final _lock = AppLockService();
  String _entered = '';
  String? _error;
  bool _checkingBiometrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricsIfEnabled());
  }

  Future<void> _tryBiometricsIfEnabled() async {
    final settings = ref.read(settingsProvider);
    if (!settings.biometricEnabled) return;
    setState(() => _checkingBiometrics = true);
    final ok = await _lock.authenticateWithBiometrics();
    if (!mounted) return;
    setState(() => _checkingBiometrics = false);
    if (ok) widget.onUnlocked();
  }

  void _onDigit(String d) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length == _pinLength) {
      final ok = _lock.checkPin(_entered);
      if (ok) {
        widget.onUnlocked();
      } else {
        setState(() {
          _error = 'PIN incorrecto';
          _entered = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppTheme.csOrange),
              const SizedBox(height: 16),
              const Text(
                'CS2 TRACKER BLOQUEADO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _entered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppTheme.csOrange : Colors.transparent,
                      border: Border.all(color: AppTheme.csOrange, width: 2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 20,
                child: Text(
                  _error ?? '',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              _Keypad(onDigit: _onDigit, onBackspace: _onBackspace),
              if (settings.biometricEnabled) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _checkingBiometrics ? null : _tryBiometricsIfEnabled,
                  icon: const Icon(Icons.fingerprint, color: AppTheme.csOrange),
                  label: const Text('Usar huella / Face ID',
                      style: TextStyle(color: AppTheme.csOrange)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) {
      return SizedBox(
        width: 72,
        height: 60,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? (label.isEmpty ? null : () => onDigit(label)),
          child: Center(
            child: child ??
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            key('', onTap: null),
            key('0'),
            key('', onTap: onBackspace, child: const Icon(Icons.backspace_outlined, color: Colors.white54, size: 20)),
          ],
        ),
      ],
    );
  }
}
