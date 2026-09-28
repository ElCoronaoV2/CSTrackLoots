import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/drop_cycle_orchestrator.dart';
import '../services/notification_service.dart';
import '../services/steam_market_service.dart';
import '../services/weekly_reset_service.dart';

/// Servicios singleton (no se reconstruyen durante la vida de la app).
final weeklyResetServiceProvider = Provider<WeeklyResetService>((ref) {
  final svc = WeeklyResetService();
  ref.onDispose(svc.dispose);
  return svc;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(weeklyResetServiceProvider));
});

final orchestratorProvider = Provider<DropCycleOrchestrator>((ref) {
  return DropCycleOrchestrator(
    ref.read(weeklyResetServiceProvider),
    ref.read(notificationServiceProvider),
  );
});

final steamMarketServiceProvider = Provider<SteamMarketService>((ref) {
  return SteamMarketService();
});

/// Stream que emite la duración restante hasta el próximo reset cada segundo.
final countdownStreamProvider = StreamProvider<Duration>((ref) {
  return ref.read(weeklyResetServiceProvider).countdownStream();
});
