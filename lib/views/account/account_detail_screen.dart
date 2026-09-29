import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/cs_account.dart';
import '../../models/cs_rank_enums.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/services_providers.dart';
import '../../providers/settings_provider.dart';
import '../../services/hive_service.dart';
import '../../services/steam_stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rank_widgets.dart';
import '../../widgets/steam_stats_grid.dart';
import '../drop/register_drop_dialog.dart';
import '../settings/settings_screen.dart';

class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final String accountId;

  @override
  ConsumerState<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  late TextEditingController _premierCtrl;
  late TextEditingController _steamIdCtrl;
  bool _steamLoading = false;
  Cs2LifetimeStats? _steamStats;
  String? _steamError;

  @override
  void initState() {
    super.initState();
    final acc = ref.read(accountByIdProvider(widget.accountId));
    _premierCtrl = TextEditingController(text: (acc?.premierRating ?? 0).toString());
    _steamIdCtrl = TextEditingController(text: acc?.steamId64 ?? '');
  }

  @override
  void dispose() {
    _premierCtrl.dispose();
    _steamIdCtrl.dispose();
    super.dispose();
  }

  CsAccount? _getAccount() => ref.read(accountByIdProvider(widget.accountId));

  Future<void> _save() async {
    final acc = _getAccount();
    if (acc == null) return;
    final rating = int.tryParse(_premierCtrl.text.trim()) ?? 0;
    acc.premierRating = rating.clamp(0, 50000);
    await ref.read(accountsProvider.notifier).updateAccount(acc);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados.')),
      );
    }
  }

  Future<void> _saveSteamIdAndFetch() async {
    final acc = _getAccount();
    if (acc == null) return;
    final apiKey = ref.read(settingsProvider).steamApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Antes configura tu Steam Web API key en Ajustes.'),
          action: SnackBarAction(
            label: 'Ir a Ajustes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ),
      );
      return;
    }
    final steamId = _steamIdCtrl.text.trim();
    if (steamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce el SteamID64 de esta cuenta.')),
      );
      return;
    }
    acc.steamId64 = steamId;
    await ref.read(accountsProvider.notifier).updateAccount(acc);
    setState(() {
      _steamLoading = true;
      _steamError = null;
    });
    final service = ref.read(steamStatsServiceProvider);
    final stats =
        await service.fetchLifetimeStats(apiKey: apiKey, steamId64: steamId);
    if (!mounted) return;
    setState(() {
      _steamLoading = false;
      _steamStats = stats;
      _steamError = stats == null
          ? 'No se pudieron obtener estadísticas. Revisa el SteamID64 y que el perfil y las stats de CS2 de esta cuenta sean públicos.'
          : null;
    });
  }

  Future<void> _clearSteamId() async {
    final acc = _getAccount();
    if (acc == null) return;
    acc.steamId64 = null;
    await ref.read(accountsProvider.notifier).updateAccount(acc);
    _steamIdCtrl.clear();
    setState(() {
      _steamStats = null;
      _steamError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountByIdProvider(widget.accountId));
    if (account == null) {
      return const Scaffold(
        body: Center(child: Text('Cuenta no encontrada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(account.alias.toUpperCase()),
        actions: [
          IconButton(
            tooltip: account.dropObtainedThisWeek
                ? 'Marcar drop pendiente'
                : 'Marcar drop conseguido',
            icon: Icon(
              account.dropObtainedThisWeek
                  ? Icons.flag
                  : Icons.check_circle_outline,
              color: account.dropObtainedThisWeek ? const Color(0xFFF59E0B) : null,
            ),
            onPressed: () async {
              if (account.dropObtainedThisWeek) {
                await ref
                    .read(accountsProvider.notifier)
                    .markDropPending(account.id);
              } else {
                await RegisterDropDialog.show(context, account: account);
              }
            },
          ),
          if (account.dropMissedThisWeek)
            IconButton(
              tooltip: 'Quitar drop perdido',
              icon: const Icon(Icons.cancel, color: Color(0xFFEF4444)),
              onPressed: () async {
                await ref
                    .read(accountsProvider.notifier)
                    .markDropPending(account.id);
              },
            ),
          IconButton(
            tooltip: 'Marcar drop como perdido',
            icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref
                  .read(accountsProvider.notifier)
                  .markDropMissed(account.id);
              if (!context.mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Marcado como drop perdido.')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(icon: Icons.workspace_premium, title: 'Premier Rating'),
          _PremierCard(
            controller: _premierCtrl,
            account: account,
            onSaved: _save,
          ),
          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.show_chart, title: 'Progreso de rango'),
          const SizedBox(height: 8),
          _RankHistoryCard(accountId: account.id),
          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.public, title: 'Competitivo por mapa'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: CsMap.values.map((m) {
                  final stored = account.mapRanks[m.name];
                  final rank = stored == null
                      ? null
                      : CompetitiveRank.values.firstWhere(
                          (r) => r.name == stored,
                          orElse: () => CompetitiveRank.silver1,
                        );
                  return MapRankRow(
                    map: m,
                    rank: rank,
                    onChanged: (newRank) async {
                      if (newRank == null) {
                        account.mapRanks.remove(m.name);
                      } else {
                        account.mapRanks[m.name] = newRank.name;
                      }
                      await ref.read(accountsProvider.notifier).updateAccount(account);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.people_outline, title: 'Wingman (Compañero)'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CompetitiveRankDropdown(
                value: account.wingmanRank == null
                    ? null
                    : CompetitiveRank.values.firstWhere(
                        (r) => r.name == account.wingmanRank,
                        orElse: () => CompetitiveRank.silver1,
                      ),
                onChanged: (newRank) async {
                  account.wingmanRank = newRank?.name;
                  await ref.read(accountsProvider.notifier).updateAccount(account);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.insights, title: 'Estadísticas'),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161A20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderStrong),
            ),
            child: _AccountStatsGrid(account: account),
          ),
          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.videogame_asset_outlined, title: 'Estadísticas de Steam (CS2)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161A20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Introduce el SteamID64 de esta cuenta para ver sus kills, muertes, ratio K/D, victorias y horas jugadas de por vida. Necesitas tener tu API key configurada en Ajustes primero.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _steamIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'SteamID64 de esta cuenta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _steamLoading ? null : _saveSteamIdAndFetch,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Guardar y consultar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _steamLoading ? null : _clearSteamId,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Quitar SteamID64',
                    ),
                  ],
                ),
                if (_steamLoading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_steamError != null) ...[
                  const SizedBox(height: 12),
                  Text(_steamError!,
                      style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                ],
                if (_steamStats != null) ...[
                  const SizedBox(height: 16),
                  SteamStatsGrid(stats: _steamStats!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.flag, title: 'Estado semanal'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        account.dropObtainedThisWeek
                            ? Icons.check_circle
                            : (account.dropMissedThisWeek ? Icons.cancel : Icons.flag),
                        color: account.dropObtainedThisWeek
                            ? const Color(0xFF22C55E)
                            : (account.dropMissedThisWeek
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.dropObtainedThisWeek
                                  ? 'Drop conseguido esta semana'
                                  : (account.dropMissedThisWeek
                                      ? 'Drop perdido esta semana'
                                      : 'Drop pendiente'),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if (account.lastDropDate != null)
                              Text(
                                'Último drop: ${account.lastDropDate!.toLocal().toString().split(".").first}',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Conseguido'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () =>
                              RegisterDropDialog.show(context, account: account),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel, size: 18, color: Color(0xFFEF4444)),
                          label: const Text('Perdido',
                              style: TextStyle(color: Color(0xFFEF4444))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ref
                                .read(accountsProvider.notifier)
                                .markDropMissed(account.id);
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Marcado como drop perdido.')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremierCard extends StatelessWidget {
  const _PremierCard({
    required this.controller,
    required this.account,
    required this.onSaved,
  });

  final TextEditingController controller;
  final CsAccount account;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            RankBadge(rating: account.premierRating),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremierTierChip(rating: account.premierRating),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rating',
                      hintText: '0 - 50000',
                      prefixIcon: Icon(Icons.star, color: Color(0xFFF59E0B)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: onSaved,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountStatsGrid extends StatelessWidget {
  const _AccountStatsGrid({required this.account});
  final CsAccount account;

  @override
  Widget build(BuildContext context) {
    final success = account.successRate;
    final successStr =
        success < 0 ? '—' : '${success.toStringAsFixed(0)}%';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                icon: Icons.check_circle_outline,
                color: const Color(0xFF22C55E),
                label: 'Obtenidos',
                value: '${account.totalObtained}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                icon: Icons.cancel_outlined,
                color: const Color(0xFFEF4444),
                label: 'Perdidos',
                value: '${account.totalMissed}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                icon: Icons.local_fire_department_outlined,
                color: const Color(0xFFF59E0B),
                label: 'Racha actual',
                value: '${account.currentStreak}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                icon: Icons.emoji_events_outlined,
                color: const Color(0xFF22D3EE),
                label: 'Mejor racha',
                value: '${account.bestStreak}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111418),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderStrong),
          ),
          child: Row(
            children: [
              const Icon(Icons.percent,
                  size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Text(
                'Tasa de éxito',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                successStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        if (account.totalWeeks > 0) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Basado en ${account.totalWeeks} semanas registradas.',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111418),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderStrong),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de la evolución del Premier Rating de la cuenta a lo largo del
/// tiempo, a partir de los snapshots diarios guardados al abrir la app.
class _RankHistoryCard extends StatelessWidget {
  const _RankHistoryCard({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final snapshots = HiveService.rankSnapshotsBox.values
        .where((s) => s.accountId == accountId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (snapshots.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161A20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderStrong),
        ),
        child: const Column(
          children: [
            Icon(Icons.show_chart, size: 32, color: Colors.white24),
            SizedBox(height: 8),
            Text(
              'Todavía no hay suficientes días registrados. Cada vez que abras la app se guarda el rating de hoy — vuelve en un par de días para ver la evolución.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < snapshots.length; i++)
        FlSpot(i.toDouble(), snapshots[i].premierRating.toDouble()),
    ];
    final maxY =
        spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.csOrange.withValues(alpha: 0.3)),
      ),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY <= 0 ? 1 : maxY * 1.15,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: AppTheme.borderStrong, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval:
                      (snapshots.length / 4).clamp(1, 999).roundToDouble(),
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= snapshots.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('dd/MM').format(snapshots[i].date),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppTheme.csOrange,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.csOrange.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
