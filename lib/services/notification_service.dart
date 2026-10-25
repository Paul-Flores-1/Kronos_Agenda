import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mazatlan'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          debugPrint('Notificación recibida: ${response.payload}');
        }
      },
    );

    _initialized = true;
    if (kDebugMode) {
      debugPrint('NotificationService inicializado');
    }

    await solicitarPermisos();
  }

  static Future<bool> solicitarPermisos() async {
    if (await Permission.notification.isDenied) {
      if (kDebugMode) {
        debugPrint('Solicitando permisos de notificación...');
      }
      final status = await Permission.notification.request();
      
      if (status.isGranted) {
        if (kDebugMode) {
          debugPrint('Permisos de notificación concedidos');
        }
        return true;
      } else if (status.isPermanentlyDenied) {
        if (kDebugMode) {
          debugPrint('Permisos permanentemente denegados.');
        }
        await openAppSettings();
        return false;
      } else {
        if (kDebugMode) {
          debugPrint('Permisos de notificación denegados');
        }
        return false;
      }
    }
    
    if (kDebugMode) {
      debugPrint('Permisos ya concedidos');
    }
    return true;
  }

  static Future<void> programarNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fecha,
  }) async {
    final ahora = DateTime.now();
    
    if (fecha.isBefore(ahora)) {
      if (kDebugMode) {
        debugPrint('Fecha en el pasado: $fecha (ahora: $ahora)');
        debugPrint('Diferencia: ${ahora.difference(fecha).inMinutes} minutos');
      }
      return;
    }

    final tienePermisos = await solicitarPermisos();
    if (!tienePermisos) {
      if (kDebugMode) {
        debugPrint('No hay permisos para notificaciones');
      }
      return;
    }

    try {
      final tzFecha = tz.TZDateTime.from(fecha, tz.local);
      
      if (kDebugMode) {
        debugPrint('Programando notificación:');
        debugPrint('  ID: $id');
        debugPrint('  Título: $titulo');
        debugPrint('  Fecha local: $fecha');
        debugPrint('  Fecha TZ: $tzFecha');
        debugPrint('  En ${fecha.difference(ahora).inMinutes} minutos');
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        titulo,
        cuerpo,
        tzFecha,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'kronos_channel',
            'Recordatorios Kronos',
            channelDescription: 'Notificaciones de eventos y recordatorios',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      if (kDebugMode) {
        debugPrint('Notificación programada exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al programar notificación: $e');
      }
    }
  }

  static Future<void> mostrarNotificacionInmediata({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'kronos_channel',
      'Recordatorios Kronos',
      channelDescription: 'Notificaciones de eventos y recordatorios',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, titulo, cuerpo, details);
    if (kDebugMode) {
      debugPrint('Notificación inmediata mostrada');
    }
  }

  static Future<void> cancelarNotificacion(int id) async {
    await _notificationsPlugin.cancel(id);
    if (kDebugMode) {
      debugPrint('Notificación $id cancelada');
    }
  }

  static Future<void> cancelarTodas() async {
    await _notificationsPlugin.cancelAll();
    if (kDebugMode) {
      debugPrint('Todas las notificaciones canceladas');
    }
  }

  static Future<void> verNotificacionesPendientes() async {
    final pendientes = await _notificationsPlugin.pendingNotificationRequests();
    if (kDebugMode) {
      debugPrint('Notificaciones pendientes: ${pendientes.length}');
      for (var notif in pendientes) {
        debugPrint('   - ID ${notif.id}: ${notif.title}');
      }
    }
  }
}