import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/accounts_provider.dart';
import '../../providers/services_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/app_lock_service.dart';
import '../../services/backup_service.dart';

const _settingsPinLength = 4;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifications = ref.read(notificationServiceProvider);
    final orchestrator = ref.read(orchestratorProvider);
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AJUSTES')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Moneda preferida',
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(value: 'EUR', label: Text('EUR (€)')),
                ButtonSegment<String>(value: 'USD', label: Text('USD (\$)')),
              ],
              selected: {settings.preferredCurrency},
              onSelectionChanged: (s) async {
                await ref.read(settingsProvider.notifier).setCurrency(s.first);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Moneda: ${s.first}')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Notificaciones',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activar notificaciones locales'),
                  subtitle: const Text(
                    'Aviso 24h antes del reset y alerta al iniciar el nuevo ciclo',
                  ),
                  value: settings.notificationsEnabled,
                  onChanged: (v) async {
                    if (v) {
                      final ok = await notifications.requestPermissions();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Permiso de notificaciones denegado por el sistema.'),
                          ),
                        );
                        return;
                      }
                      await ref.read(settingsProvider.notifier).setNotificationsEnabled(true);
                      await orchestrator.enableNotifications();
                    } else {
                      await ref.read(settingsProvider.notifier).setNotificationsEnabled(false);
                      await orchestrator.disableNotifications();
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.send_outlined),
                  title: const Text('Enviar notificación de prueba'),
                  subtitle: const Text('Comprueba que el canal funciona'),
                  onTap: () async {
                    final ok = await notifications.requestPermissions();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Permiso denegado.')),
                      );
                      return;
                    }
                    await notifications.showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notificación enviada.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Datos',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.people_alt_outlined),
                  title: const Text('Cuentas registradas'),
                  trailing: Text('${accounts.length}'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Exportar backup'),
                  subtitle: const Text(
                      'Guarda cuentas, inventario y ventas en un archivo JSON que puedes compartir.'),
                  onTap: () => _exportBackup(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('Importar backup'),
                  subtitle: const Text(
                      'Restaura un backup previo. SOBRESCRIBE los datos actuales.'),
                  onTap: () => _importBackup(context, ref),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Backup automático'),
                  subtitle: Text(
                    settings.autoBackupEnabled
                        ? 'Cada ${settings.autoBackupIntervalDays} días, en una carpeta del dispositivo. ${_lastBackupLabel(settings.lastAutoBackupEpochMs)}'
                        : 'Desactivado. Guarda un JSON periódicamente sin necesidad de exportar a mano.',
                  ),
                  value: settings.autoBackupEnabled,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setAutoBackupEnabled(v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: const Text('Forzar reset semanal manual'),
                  subtitle: const Text(
                      'Marca todas las cuentas como pendientes. NO actualiza estadísticas. Útil tras cambiar zona horaria.'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Forzar reset semanal?'),
                        content: const Text(
                          'Todas las cuentas pasarán a "Drop pendiente" y se reprogramarán las notificaciones. Esta acción NO modifica tus estadísticas históricas.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(accountsProvider.notifier).forceWeeklyReset();
                      await orchestrator.rescheduleReminders();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reset aplicado.')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SteamSection(initialApiKey: settings.steamApiKey),
          const SizedBox(height: 16),
          const _SecuritySection(),
          const SizedBox(height: 16),
          _Section(
            title: 'Acerca de',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CS2 Tracker',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  'App de gestión y seguimiento personal de CS2. No almacena credenciales de Steam en el servidor ni en el repositorio: tu API key y SteamID64, si los introduces, se guardan solo en este dispositivo. Los precios son consultados al Steam Community Market (appid 730) y cacheados durante 2 horas para evitar el rate-limit HTTP 429.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161A20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A313B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SteamSection extends ConsumerStatefulWidget {
  const _SteamSection({required this.initialApiKey});

  final String? initialApiKey;

  @override
  ConsumerState<_SteamSection> createState() => _SteamSectionState();
}

class _SteamSectionState extends ConsumerState<_SteamSection> {
  late final TextEditingController _keyCtrl;
  bool _obscureKey = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.initialApiKey ?? '');
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce tu Steam Web API key.')),
      );
      return;
    }
    setState(() => _saving = true);
    await ref.read(settingsProvider.notifier).setSteamApiKey(key);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key guardada en este dispositivo.')),
    );
  }

  Future<void> _clear() async {
    await ref.read(settingsProvider.notifier).clearSteamApiKey();
    _keyCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key de Steam eliminada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Estadísticas de Steam',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Introduce tu Steam Web API key (una sola, gratuita, revocable en steamcommunity.com/dev/apikey) para ver las estadísticas de CS2 de por vida de tus cuentas. Después, en la ficha de cada cuenta, añade su SteamID64 para consultar sus stats. Se guarda SOLO en este dispositivo, nunca se sube a internet ni al repositorio.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: 'Steam Web API key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _saving ? null : _clear,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar API key',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecuritySection extends ConsumerStatefulWidget {
  const _SecuritySection();

  @override
  ConsumerState<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends ConsumerState<_SecuritySection> {
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    AppLockService().canUseBiometrics().then((v) {
      if (mounted) setState(() => _biometricsAvailable = v);
    });
  }

  Future<void> _setUpPin() async {
    final pin = await _PinEntryDialog.show(context, title: 'Nuevo PIN');
    if (pin == null || !mounted) return;
    final confirm = await _PinEntryDialog.show(context, title: 'Repite el PIN');
    if (confirm == null || !mounted) return;
    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los PIN no coinciden.')),
      );
      return;
    }
    await ref.read(settingsProvider.notifier).setPin(pin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN configurado. Bloqueo activado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final hasPin = settings.pinHash != null;

    return _Section(
      title: 'Seguridad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pide PIN (y huella/Face ID, si tu móvil la soporta) para abrir la app.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bloqueo con PIN'),
            value: settings.appLockEnabled && hasPin,
            onChanged: (v) async {
              if (v) {
                await _setUpPin();
              } else {
                await ref.read(settingsProvider.notifier).clearPin();
              }
            },
          ),
          if (settings.appLockEnabled && hasPin) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.password),
              title: const Text('Cambiar PIN'),
              onTap: _setUpPin,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usar también huella / Face ID'),
              subtitle: Text(
                _biometricsAvailable
                    ? 'Como alternativa rápida al PIN.'
                    : 'Este dispositivo no tiene huella/Face ID configurada.',
              ),
              value: settings.biometricEnabled,
              onChanged: _biometricsAvailable
                  ? (v) => ref.read(settingsProvider.notifier).setBiometricEnabled(v)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _PinEntryDialog extends StatefulWidget {
  const _PinEntryDialog({required this.title});
  final String title;

  static Future<String?> show(BuildContext context, {required String title}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _PinEntryDialog(title: title),
    );
  }

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: _settingsPinLength,
        decoration: const InputDecoration(
          labelText: 'PIN de 4 dígitos',
          counterText: '',
        ),
        onSubmitted: (v) {
          if (v.length == _settingsPinLength) Navigator.of(context).pop(v);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _ctrl.text.length == _settingsPinLength
              ? () => Navigator.of(context).pop(_ctrl.text)
              : null,
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

String _lastBackupLabel(int epochMs) {
  if (epochMs <= 0) return 'Todavía no se ha hecho ninguno.';
  final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
  return 'Último: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}.';
}

Future<void> _exportBackup(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final service = BackupService();
    final path = await service.exportAndShare();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF22C55E),
        content: Text(
          'Backup creado: ${path.split('/').last}',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Error al exportar: $e')),
    );
  }
}

Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Text('Sobrescribir todos los datos'),
        ],
      ),
      content: const Text(
        'Vas a restaurar un backup. Esto BORRARÁ todas tus cuentas, items y ventas actuales. ¿Continuar?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('SOBRESCRIBIR'),
        ),
      ],
    ),
  );
  if (confirm != true) return;
  try {
    final service = BackupService();
    final res = await service.restoreFromPicker();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF22C55E),
        content: Text(
          'Backup restaurado: ${res.accounts} cuentas, ${res.items} items, ${res.sales} ventas.',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  } on BackupCancelledException {
    // usuario canceló, no hacer nada
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Error al importar: $e')),
    );
  }
}
