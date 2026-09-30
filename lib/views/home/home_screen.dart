import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/accounts_provider.dart';
import '../../providers/services_providers.dart';
import '../../services/backup_service.dart';
import '../../services/shortcuts_service.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account_card.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/countdown_header.dart';
import '../../widgets/cut_corner_card.dart';
import '../../widgets/section_label.dart';
import '../../widgets/update_dialog.dart';
import '../account/account_detail_screen.dart';
import '../compare/skin_compare_screen.dart';
import '../drop/register_drop_dialog.dart';
import '../inventory/inventory_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../watchlist/watchlist_screen.dart';

/// Opciones del menú "más opciones" del AppBar principal.
enum _HomeMenuAction { stats, compare, settings }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ShortcutsService.listen((s) {
      if (mounted) _handleShortcut(s);
    });
    // Verificar reset al abrir la app.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(orchestratorProvider).runStartupCheck();
      if (!mounted) return;
      // Si el orquestador marcó un reset, pedir también refresh del estado.
      ref.read(accountsProvider.notifier);

      try {
        await StatsService.recordDailySnapshotIfNeeded();
      } catch (_) {}

      try {
        await StatsService.recordDailyRankSnapshotsIfNeeded();
      } catch (_) {}

      try {
        await StatsService.recordDailyItemPriceSnapshotsIfNeeded();
      } catch (_) {}

      try {
        await BackupService().autoBackupIfNeeded();
      } catch (_) {}

      final update = await ref.read(updateServiceProvider).checkForUpdate();
      if (update != null && mounted) {
        showUpdateDialog(context, update);
      }

      final shortcut = await ShortcutsService.getInitialShortcut();
      if (shortcut != null && mounted) _handleShortcut(shortcut);
    });
  }

  /// Navega a la pantalla correspondiente al acceso directo del icono. Para
  /// "Registrar drop": si hay exactamente una cuenta con drop pendiente, la
  /// abre directamente; si hay varias (o ninguna) se queda en la pantalla
  /// principal, donde ya se ven todas.
  void _handleShortcut(String shortcut) {
    switch (shortcut) {
      case 'inventory':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        );
        break;
      case 'register_drop':
        final pending = ref
            .read(accountsProvider)
            .where((a) => !a.dropObtainedThisWeek && !a.dropMissedThisWeek)
            .toList();
        if (pending.length == 1) {
          RegisterDropDialog.show(context, account: pending.first);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final countdownAsync = ref.watch(countdownStreamProvider);
    final pending = accounts
        .where((a) => !a.dropObtainedThisWeek && !a.dropMissedThisWeek)
        .length;
    final missed = accounts.where((a) => a.dropMissedThisWeek).length;
    final completed = accounts.where((a) => a.dropObtainedThisWeek).length;
    final nextResetDate = ref.read(weeklyResetServiceProvider).nextReset().toLocal();

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/cs2_logo.jpg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CS2',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'TRACKER',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.csOrange,
                fontSize: 22,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, size: 22),
            tooltip: 'Inventario General',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 22),
            tooltip: 'Lista de seguimiento',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WatchlistScreen()),
              );
            },
          ),
          PopupMenuButton<_HomeMenuAction>(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert, size: 22),
            onSelected: (action) {
              switch (action) {
                case _HomeMenuAction.stats:
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  );
                  break;
                case _HomeMenuAction.compare:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SkinCompareScreen()),
                  );
                  break;
                case _HomeMenuAction.settings:
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _HomeMenuAction.stats,
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Estadísticas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.compare,
                child: ListTile(
                  leading: Icon(Icons.price_check),
                  title: Text('Comparador de precios'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.settings,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Ajustes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: BackgroundPattern(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(orchestratorProvider).runStartupCheck();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              countdownAsync.when(
                data: (d) => CountdownHeader(
                  countdown: d,
                  total: accounts.length,
                  pending: pending,
                  missed: missed,
                  completed: completed,
                  nextResetDate: nextResetDate,
                ),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 22),
              SectionLabel(
                'Mis cuentas',
                trailing: Text(
                  '${accounts.length} jugadores',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (accounts.isEmpty)
                _EmptyState(
                  onAdd: () => _showAddAccountDialog(context),
                )
              else
                ...accounts.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AccountCard(
                      account: a,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AccountDetailScreen(accountId: a.id),
                          ),
                        );
                      },
                      onRegisterDrop: () => _openRegisterDrop(context, a.id),
                      onDelete: () => _confirmDelete(context, a.id, a.alias),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: accounts.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppTheme.csOrange,
              foregroundColor: Colors.black,
              onPressed: () => _showAddAccountDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('AÑADIR CUENTA',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
    );
  }

  Future<void> _showAddAccountDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nueva cuenta'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Alias o nombre de la cuenta',
              prefixIcon: Icon(Icons.person_add_alt_1_outlined),
            ),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (result != null && result.trim().isNotEmpty) {
      await ref.read(accountsProvider.notifier).addAccount(result.trim());
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id, String alias) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar "$alias"?'),
        content: const Text(
          'La cuenta se eliminará. Los items ya registrados en el inventario NO se borrarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(accountsProvider.notifier).deleteAccount(id);
    }
  }

  Future<void> _openRegisterDrop(BuildContext context, String accountId) async {
    final list = ref.read(accountsProvider);
    final acc = list.firstWhere((a) => a.id == accountId);
    if (!mounted) return;
    await RegisterDropDialog.show(context, account: acc);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return CutCornerCard(
      color: AppTheme.bgCard,
      borderColor: AppTheme.csOrange.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.gamepad_outlined, size: 56, color: AppTheme.csOrange),
          const SizedBox(height: 12),
          const Text(
            'Aún no tienes cuentas registradas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Añade tus cuentas de CS2 (sólo alias, sin credenciales) para empezar a gestionar drops y rangos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('AÑADIR PRIMERA CUENTA'),
          ),
        ],
      ),
    );
  }
}
