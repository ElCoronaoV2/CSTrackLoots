import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/accounts_provider.dart';
import '../../providers/services_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../services/steam_stats_service.dart';

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
          _SteamSection(
            initialApiKey: settings.steamApiKey,
            initialSteamId: settings.steamId64,
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
  const _SteamSection({required this.initialApiKey, required this.initialSteamId});

  final String? initialApiKey;
  final String? initialSteamId;

  @override
  ConsumerState<_SteamSection> createState() => _SteamSectionState();
}

class _SteamSectionState extends ConsumerState<_SteamSection> {
  late final TextEditingController _keyCtrl;
  late final TextEditingController _idCtrl;
  bool _obscureKey = true;
  bool _loading = false;
  Cs2LifetimeStats? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.initialApiKey ?? '');
    _idCtrl = TextEditingController(text: widget.initialSteamId ?? '');
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _keyCtrl.text.trim();
    final id = _idCtrl.text.trim();
    if (key.isEmpty || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce la API key y el SteamID64.')),
      );
      return;
    }
    await ref
        .read(settingsProvider.notifier)
        .setSteamCredentials(apiKey: key, steamId64: id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales guardadas en este dispositivo.')),
      );
    }
    await _test();
  }

  Future<void> _test() async {
    final key = _keyCtrl.text.trim();
    final id = _idCtrl.text.trim();
    if (key.isEmpty || id.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final service = ref.read(steamStatsServiceProvider);
    final stats = await service.fetchLifetimeStats(apiKey: key, steamId64: id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _stats = stats;
      _error = stats == null
          ? 'No se pudieron obtener estadísticas. Revisa la key, el SteamID64 y que el perfil y las stats de CS2 sean públicos.'
          : null;
    });
  }

  Future<void> _clear() async {
    await ref.read(settingsProvider.notifier).clearSteamCredentials();
    _keyCtrl.clear();
    _idCtrl.clear();
    setState(() {
      _stats = null;
      _error = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales de Steam eliminadas.')),
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
            'Introduce tu Steam Web API key y tu SteamID64 para ver tus estadísticas de CS2 de por vida (kills, victorias, ratio K/D, horas jugadas...). Valve no expone el rango competitivo por esta vía, solo contadores históricos. Se guardan SOLO en este dispositivo, nunca se suben a internet ni al repositorio.',
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
          const SizedBox(height: 8),
          TextField(
            controller: _idCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'SteamID64',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar y comprobar'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loading ? null : _clear,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar credenciales',
              ),
            ],
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ],
          if (_stats != null) ...[
            const SizedBox(height: 16),
            _StatsGrid(stats: _stats!),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final Cs2LifetimeStats stats;

  @override
  Widget build(BuildContext context) {
    final hours = stats.timePlayed.inMinutes / 60;
    final items = <(String, String)>[
      ('Kills', '${stats.kills}'),
      ('Muertes', '${stats.deaths}'),
      ('Ratio K/D', stats.kdRatio.toStringAsFixed(2)),
      ('Victorias', '${stats.wins}'),
      ('Partidas', '${stats.matchesPlayed}'),
      ('% victorias', '${stats.winRatePercent.toStringAsFixed(1)}%'),
      ('MVPs', '${stats.mvps}'),
      ('% headshot', '${stats.headshotPercent.toStringAsFixed(1)}%'),
      ('Precisión', '${stats.accuracyPercent.toStringAsFixed(1)}%'),
      ('Horas jugadas', hours.toStringAsFixed(0)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: items.map((e) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1318),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A313B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.$2,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              Text(e.$1,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
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
