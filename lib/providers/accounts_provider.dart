import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/cs_account.dart';
import '../services/hive_service.dart';
import 'services_providers.dart';

const _uuid = Uuid();

/// Notifier que mantiene la lista de cuentas y emite cambios al UI.
class AccountsNotifier extends StateNotifier<List<CsAccount>> {
  AccountsNotifier(this.ref) : super(<CsAccount>[]) {
    _load();
    // Re-emitimos ante cualquier cambio externo (ej. auto-reset al arrancar).
    HiveService.accountsBox.listenable().addListener(_load);
  }

  final Ref ref;

  void _load() {
    final all = HiveService.accountsBox.values.toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    state = all;
  }

  @override
  void dispose() {
    HiveService.accountsBox.listenable().removeListener(_load);
    super.dispose();
  }

  Future<CsAccount> addAccount(String alias) async {
    final account = CsAccount(
      id: _uuid.v4(),
      alias: alias.trim(),
      sortIndex: state.length,
    );
    await HiveService.accountsBox.put(account.id, account);
    _load();
    await ref.read(orchestratorProvider).rescheduleReminders();
    return account;
  }

  Future<void> deleteAccount(String id) async {
    await HiveService.accountsBox.delete(id);
    _load();
    await ref.read(orchestratorProvider).rescheduleReminders();
  }

  Future<void> updateAccount(CsAccount updated) async {
    await HiveService.accountsBox.put(updated.id, updated);
    _load();
  }

  Future<void> markDropObtained(String accountId, DateTime when) async {
    final acc = HiveService.accountsBox.get(accountId);
    if (acc == null) return;
    acc.dropObtainedThisWeek = true;
    acc.lastDropDate = when;
    await acc.save();
    _load();
    await ref.read(orchestratorProvider).rescheduleReminders();
  }

  Future<void> markDropPending(String accountId) async {
    final acc = HiveService.accountsBox.get(accountId);
    if (acc == null) return;
    acc.dropObtainedThisWeek = false;
    acc.dropMissedThisWeek = false;
    acc.lastDropDate = null;
    await acc.save();
    _load();
    await ref.read(orchestratorProvider).rescheduleReminders();
  }

  Future<void> markDropMissed(String accountId) async {
    final acc = HiveService.accountsBox.get(accountId);
    if (acc == null) return;
    acc.dropObtainedThisWeek = false;
    acc.dropMissedThisWeek = true;
    await acc.save();
    _load();
    await ref.read(orchestratorProvider).rescheduleReminders();
  }

  /// Reset manual desde Ajustes: NO actualiza estadísticas (es solo para
  /// arreglar zona horaria). Solo limpia los flags de la semana en curso.
  Future<void> forceWeeklyReset() async {
    for (final acc in HiveService.accountsBox.values) {
      acc.dropObtainedThisWeek = false;
      acc.dropMissedThisWeek = false;
      try {
        await acc.save();
      } catch (_) {}
    }
    _load();
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<CsAccount>>((ref) => AccountsNotifier(ref));

/// Cuenta individual por id.
final accountByIdProvider = Provider.family<CsAccount?, String>((ref, id) {
  final list = ref.watch(accountsProvider);
  for (final a in list) {
    if (a.id == id) return a;
  }
  return null;
});
