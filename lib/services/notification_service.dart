import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'weekly_reset_service.dart';

/// IDs de notificación reservados. Si añades más, recuerda no chocar.
class NotifIds {
  static const int resetMoment = 1000;
  static const int reminder24h = 1001;
  static const int test = 9999;
}

/// Wrapper de `flutter_local_notifications` con foco en notificaciones del reset.
class NotificationService {
  NotificationService(this._resetService);

  final WeeklyResetService _resetService;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'cs2_drops',
    'CS2 Drops',
    description: 'Recordatorios del drop semanal y nuevo ciclo de CS2',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit, macOS: iosInit),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    _initialized = true;
  }

  /// Pide permisos (Android 13+ y iOS). Llamar tras la primera interacción del usuario.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final granted = await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          true;
      return granted;
    } else if (Platform.isIOS) {
      final granted = await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
      return granted;
    }
    return true;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Programa las notificaciones del próximo reset:
  /// 1. Aviso 24h antes si hay cuentas con drop pendiente.
  /// 2. Aviso en el momento exacto del reset.
  Future<void> scheduleResetNotifications({required bool anyPendingDrops}) async {
    await init();
    await cancelAll();

    final nextReset = _resetService.nextReset();
    final now = tz.TZDateTime.now(nextReset.location);

    // 1) Aviso en el momento exacto del reset.
    if (nextReset.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          NotifIds.resetMoment,
          'Nuevo ciclo semanal de drops',
          'El reset de CS2 acaba de ocurrir. Todas las cuentas vuelven a estar pendientes.',
          nextReset,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'cs2_drops', 'CS2 Drops',
              channelDescription: 'Recordatorios del drop semanal y nuevo ciclo de CS2',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('schedule reset-moment failed: $e');
      }
    }

    // 2) Aviso 24h antes, SOLO si hay drops pendientes.
    if (anyPendingDrops) {
      final reminder = nextReset.subtract(const Duration(hours: 24));
      if (reminder.isAfter(now)) {
        try {
          await _plugin.zonedSchedule(
            NotifIds.reminder24h,
            'Drop semanal pendiente',
            'Quedan 24h para el reset. Aún tienes cuentas sin reclamar el drop.',
            reminder,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'cs2_drops', 'CS2 Drops',
                channelDescription: 'Recordatorios del drop semanal y nuevo ciclo de CS2',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
              macOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (e) {
          debugPrint('schedule 24h reminder failed: $e');
        }
      }
    }
  }

  /// Notificación inmediata (test de diagnóstico desde Settings).
  Future<void> showTestNotification() async {
    await init();
    await _plugin.show(
      NotifIds.test,
      'CS2 Tracker',
      'Las notificaciones funcionan correctamente.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cs2_drops', 'CS2 Drops',
          channelDescription: 'Recordatorios del drop semanal y nuevo ciclo de CS2',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }
}
