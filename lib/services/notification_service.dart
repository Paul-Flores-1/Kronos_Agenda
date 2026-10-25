import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Obtiene la zona horaria dinámica en lugar de forzar Mazatlán
    // Quitamos la palabra "String" para que Dart infiera el tipo de objeto
final zonaHorariaDispositivo = await FlutterTimezone.getLocalTimezone();

// Convertimos el objeto a texto agregando .toString()
tz.setLocalLocation(tz.getLocation(zonaHorariaDispositivo.toString()));

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
      debugPrint('NotificationService inicializado. Zona: $zonaHorariaDispositivo');
    }

    await solicitarPermisos();
  }

  static Future<bool> solicitarPermisos() async {
    // 1. Permiso básico de notificaciones
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // 2. Permiso para agendar eventos exactos (Vital para Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // 3. Excepción de optimización de batería (Vital para Samsung/Huawei)
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    return await Permission.notification.isGranted;
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
        debugPrint('Fecha en el pasado. Ignorando evento ID: $id');
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
        debugPrint('Notificación programada exitosamente para: $tzFecha');
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
  }

  static Future<void> cancelarNotificacion(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelarTodas() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> verNotificacionesPendientes() async {
    final pendientes = await _notificationsPlugin.pendingNotificationRequests();
    if (kDebugMode) {
      debugPrint('Notificaciones pendientes: ${pendientes.length}');
    }
  }
}