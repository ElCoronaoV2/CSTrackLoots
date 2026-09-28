import 'dart:async';

import 'package:timezone/timezone.dart' as tz;

/// Servicio que calcula el próximo reset semanal de drops de CS2.
///
/// Valve publica el reset semanal a las **18:00 PST/PDT del martes**, que
/// corresponde al **miércoles 01:00 UTC (o 02:00 UTC cuando hay DST en EE.UU.)**.
/// Usamos la zona `America/Los_Angeles` del paquete `timezone` para que el
/// cálculo sea siempre correcto independientemente del horario de verano.
class WeeklyResetService {
  /// Stream de duración hasta el próximo reset, emitido cada segundo.
  StreamController<Duration>? _controller;
  Timer? _timer;

  static const String _laLocation = 'America/Los_Angeles';

  /// Devuelve el próximo `tz.TZDateTime` en el que ocurre el reset (martes 18:00 en LA).
  /// Si ya pasó el reset de esta semana, devuelve el de la semana siguiente.
  tz.TZDateTime nextReset() {
    final loc = tz.getLocation(_laLocation);
    final now = tz.TZDateTime.now(loc);

    // Martes 18:00 en Los Angeles de esta semana.
    var reset = tz.TZDateTime(loc, now.year, now.month, now.day, 18, 0);
    while (reset.weekday != DateTime.tuesday) {
      reset = reset.add(const Duration(days: 1));
    }

    if (!reset.isAfter(now)) {
      reset = reset.add(const Duration(days: 7));
    }
    return reset;
  }

  /// Devuelve el reset anterior (el que ya ocurrió). Útil para auditoría.
  tz.TZDateTime lastReset() {
    final next = nextReset();
    return next.subtract(const Duration(days: 7));
  }

  /// Stream que emite la duración restante hasta el próximo reset cada segundo.
  Stream<Duration> countdownStream() {
    _controller ??= StreamController<Duration>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
    return _controller!.stream;
  }

  void _start() {
    _emit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _emit() {
    if (_controller == null || _controller!.isClosed) return;
    final remaining = nextReset().difference(tz.TZDateTime.now(tz.getLocation(_laLocation)));
    _controller!.add(remaining.isNegative ? Duration.zero : remaining);
  }

  void dispose() {
    _stop();
    _controller?.close();
    _controller = null;
  }
}
