import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Recordatorio diario para jugar un ratito ("¡Owlito te espera!"). Lo activan los papás.
class Reminder {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _id = 1;

  /// Las pruebas lo reemplazan (no hay notificaciones de verdad).
  @visibleForTesting
  static Future<bool> Function(int? hour)? debugSchedule;

  static Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_owl')),
    );
    _ready = true;
  }

  /// Programa el aviso todos los días a la hora [hour] (0–23). Devuelve false si no hay permiso.
  static Future<bool> enable(int hour) async {
    if (debugSchedule != null) return debugSchedule!(hour);
    try {
      await _init();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Android 13 o más nuevo pregunta si la app puede mostrar notificaciones.
      if (await android?.requestNotificationsPermission() == false) return false;
      final now = DateTime.now();
      var at = DateTime(now.year, now.month, now.day, hour);
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      await _plugin.cancel(id: _id);
      await _plugin.zonedSchedule(
        id: _id,
        // Se repite cada día a la misma hora (guardada en UTC: en países con horario de
        // verano se corre una hora al cambiar, lo que para un recordatorio no importa).
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: '¡Owlito te espera!',
        body: 'Es hora de aprender jugando un ratito.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'recordatorio',
            'Recordatorio diario',
            channelDescription: 'Un aviso al día para jugar y aprender.',
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disable() async {
    if (debugSchedule != null) {
      await debugSchedule!(null);
      return;
    }
    try {
      await _init();
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
