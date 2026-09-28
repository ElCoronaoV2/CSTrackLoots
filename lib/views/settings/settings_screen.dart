import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/accounts_provider.dart';
import '../../providers/services_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';

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
                  'App de gestión y seguimiento personal de CS2. No almacena credenciales de Steam; sólo alias. Los precios son consultados al Steam Community Market (appid 730) y cacheados durante 2 horas para evitar el rate-limit HTTP 429.',
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
