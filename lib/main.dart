import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'providers/services_providers.dart';
import 'services/hive_service.dart';
import 'theme/app_theme.dart';
import 'views/home/home_screen.dart';
import 'views/lock/app_lock_screen.dart';

/// Wrapper top-level para que flutter_local_notifications pueda invocarlo
/// desde el isolate de background al tocar una notificación (entry-point).
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  // No-op por ahora: podríamos navegar a la pantalla correspondiente.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await initializeDateFormatting();
  Intl.defaultLocale = 'es';
  await HiveService.init();
  runApp(const ProviderScope(child: Cs2TrackerApp()));
}

class Cs2TrackerApp extends ConsumerStatefulWidget {
  const Cs2TrackerApp({super.key});

  @override
  ConsumerState<Cs2TrackerApp> createState() => _Cs2TrackerAppState();
}

class _Cs2TrackerAppState extends ConsumerState<Cs2TrackerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final notifications = ref.read(notificationServiceProvider);
        await notifications.init();
        // Android 13+ (y iOS) requieren pedir el permiso explícitamente;
        // sin esto, las notificaciones quedan activadas en Ajustes (por
        // defecto) pero nunca llegan a mostrarse. El sistema no vuelve a
        // preguntar si ya se concedió o se denegó antes, así que es seguro
        // llamarlo en cada arranque.
        if (HiveService.settings.notificationsEnabled) {
          await notifications.requestPermissions();
        }
      } catch (_) {}
      try {
        await ref.read(orchestratorProvider).runStartupCheck();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CS2 Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const _AppLockGate(),
    );
  }
}

/// Muestra la pantalla de bloqueo (PIN/huella) antes de nada si el usuario
/// la activó en Ajustes; si no, va directo al inicio. Una vez desbloqueada
/// en esta sesión, no vuelve a pedirla hasta reabrir la app.
class _AppLockGate extends ConsumerStatefulWidget {
  const _AppLockGate();

  @override
  ConsumerState<_AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<_AppLockGate> {
  late bool _unlocked = !HiveService.settings.appLockEnabled;

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return const HomeScreen();
    return AppLockScreen(onUnlocked: () => setState(() => _unlocked = true));
  }
}
