import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart' as native_cal;
import 'package:firebase_auth/firebase_auth.dart'; // IMPORTANTE: Agregado para detectar la sesión
import '../models/evento_model.dart';
import '../services/auth_service.dart';

class EventosProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final native_cal.DeviceCalendarPlugin _deviceCalendarPlugin = native_cal.DeviceCalendarPlugin();

  List<Evento> _eventos = [];
  bool _isLoading = true;
  
  StreamSubscription? _eventosSubscription; 
  StreamSubscription? _authSubscription; // Para escuchar si el usuario inicia o cierra sesión

  List<Evento> get eventos => _eventos;
  bool get isLoading => _isLoading;

  EventosProvider() {
    // Escucha en tiempo real si hay un usuario logueado o no
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // Si hay usuario, inicia la descarga de sus eventos
        _initStream();
      } else {
        // Si no hay usuario, limpia la lista y prepara la vista de carga
        cerrarSesion();
      }
    });
  }

  void _initStream() {
    // Cancelamos cualquier escucha previa por seguridad
    _eventosSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _eventosSubscription = _authService.getEvents().listen((eventosFirebase) {
      _eventos = eventosFirebase;
      _isLoading = false; // Detiene la animación de carga al recibir datos
      notifyListeners(); 
    });
  }

  void cerrarSesion() {
    _eventosSubscription?.cancel();
    _eventosSubscription = null;
    _eventos.clear();
    _isLoading = true; 
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _eventosSubscription?.cancel();
    super.dispose();
  }

  Future<void> importarFestivosNativos(BuildContext context) async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !(permissionsGranted.data ?? false)) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !(permissionsGranted.data ?? false)) {
          throw Exception("Permisos de calendario denegados.");
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null || calendarsResult.data!.isEmpty) {
        throw Exception("No hay ningún calendario configurado en este dispositivo.");
      }

      final calendarios = calendarsResult.data!;
      final palabrasClave = ['holiday', 'festivo', 'feriado', 'fiesta', 'nacional', 'mexico', 'méxico'];
      
      final calendariosFestivos = calendarios.where((cal) {
        final nombre = cal.name?.toLowerCase() ?? '';
        final cuenta = cal.accountName?.toLowerCase() ?? '';
        return palabrasClave.any((kw) => nombre.contains(kw) || cuenta.contains(kw));
      }).toList();

      final now = DateTime.now();
      int importados = 0;

      if (calendariosFestivos.isEmpty) {
        importados = await _importarFestivosManuales(now);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Calendario nativo no hallado. Se importaron $importados festivos oficiales predeterminados."),
              backgroundColor: const Color.fromARGB(255, 43, 255, 0),
            )
          );
        }
        return; 
      }

      for (var calendario in calendariosFestivos) {
        final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calendario.id,
          native_cal.RetrieveEventsParams(startDate: DateTime(now.year, 1, 1), endDate: DateTime(now.year, 12, 31)),
        );

        if (eventsResult.isSuccess && eventsResult.data != null) {
          for (var nativeEvent in eventsResult.data!) {
            final yaExiste = _eventos.any((e) => e.titulo == nativeEvent.title);
            if (!yaExiste && nativeEvent.start != null) {
              await _authService.createEvent(
                title: nativeEvent.title ?? "Festivo",
                description: "Importado automáticamente",
                startDate: nativeEvent.start!.toUtc(),
                endDate: nativeEvent.end?.toUtc() ?? nativeEvent.start!.toUtc(),
                isAllDay: nativeEvent.allDay ?? true,
                type: 'festivo',
              );
              importados++;
            }
          }
        }
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$importados festivos importados."),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$e".replaceAll("Exception: ", "")), 
            backgroundColor: Colors.red
          )
        );
      }
    }
  }

  Future<int> _importarFestivosManuales(DateTime now) async {
    int importados = 0;
    final int anio = now.year;

    final List<Map<String, dynamic>> festivosBase = [
      {'titulo': 'Año Nuevo', 'fecha': DateTime(anio, 1, 1)},
      {'titulo': 'Día de los Reyes Magos', 'fecha': DateTime(anio, 1, 6)},
      {'titulo': 'Día de la Candelaria', 'fecha': DateTime(anio, 2, 2)},
      {'titulo': 'Día de San Valentín', 'fecha': DateTime(anio, 2, 14)},
      {'titulo': 'Día de la Bandera', 'fecha': DateTime(anio, 2, 24)},
      {'titulo': 'Día Internacional de la Mujer', 'fecha': DateTime(anio, 3, 8)},
      {'titulo': 'Día del Niño', 'fecha': DateTime(anio, 4, 30)},
      {'titulo': 'Día del Trabajo', 'fecha': DateTime(anio, 5, 1)},
      {'titulo': 'Batalla de Puebla', 'fecha': DateTime(anio, 5, 5)},
      {'titulo': 'Día de la Madre', 'fecha': DateTime(anio, 5, 10)},
      {'titulo': 'Día del Maestro', 'fecha': DateTime(anio, 5, 15)},
      {'titulo': 'Día del Estudiante', 'fecha': DateTime(anio, 5, 23)},
      {'titulo': 'Día del Abuelo', 'fecha': DateTime(anio, 8, 28)},
      {'titulo': 'Grito de Independencia', 'fecha': DateTime(anio, 9, 15)},
      {'titulo': 'Día de la Independencia', 'fecha': DateTime(anio, 9, 16)},
      {'titulo': 'Día del Médico', 'fecha': DateTime(anio, 10, 23)},
      {'titulo': 'Halloween', 'fecha': DateTime(anio, 10, 31)},
      {'titulo': 'Día de Todos los Santos', 'fecha': DateTime(anio, 11, 1)},
      {'titulo': 'Día de Muertos', 'fecha': DateTime(anio, 11, 2)},
      {'titulo': 'Día Internacional del Hombre', 'fecha': DateTime(anio, 11, 19)},
      {'titulo': 'Día de la Virgen de Guadalupe', 'fecha': DateTime(anio, 12, 12)},
      {'titulo': 'Nochebuena', 'fecha': DateTime(anio, 12, 24)},
      {'titulo': 'Navidad', 'fecha': DateTime(anio, 12, 25)},
      {'titulo': 'Día de los Santos Inocentes', 'fecha': DateTime(anio, 12, 28)},
      {'titulo': 'Fin de Año', 'fecha': DateTime(anio, 12, 31)},
    ];

    final DateTime domingoResurreccion = _calcularDomingoDePascua(anio);

    festivosBase.addAll([
      {
        'titulo': 'Día de la Constitución (Puente)', 
        'fecha': _obtenerDiaVariable(anio, 2, DateTime.monday, 1) 
      },
      {
        'titulo': 'Natalicio de Benito Juárez (Puente)', 
        'fecha': _obtenerDiaVariable(anio, 3, DateTime.monday, 3) 
      },
      {
        'titulo': 'Jueves Santo', 
        'fecha': domingoResurreccion.subtract(const Duration(days: 3))
      },
      {
        'titulo': 'Viernes Santo', 
        'fecha': domingoResurreccion.subtract(const Duration(days: 2))
      },
      {
        'titulo': 'Domingo de Resurrección', 
        'fecha': domingoResurreccion
      },
      {
        'titulo': 'Día del Padre', 
        'fecha': _obtenerDiaVariable(anio, 6, DateTime.sunday, 3) 
      },
      {
        'titulo': 'Día de la Revolución Mexicana (Puente)', 
        'fecha': _obtenerDiaVariable(anio, 11, DateTime.monday, 3) 
      },
    ]);

    for (var festivo in festivosBase) {
      final String titulo = festivo['titulo'];
      final DateTime fecha = festivo['fecha'];

      final yaExiste = _eventos.any((e) => e.titulo == titulo && e.fechaInicio.year == anio);
      
      if (!yaExiste) {
        await _authService.createEvent(
          title: titulo,
          description: "Generado automáticamente por sistema",
          startDate: fecha.toUtc(),
          endDate: fecha.toUtc(),
          isAllDay: true,
          type: 'festivo',
        );
        importados++;
      }
    }
    return importados;
  }

  DateTime _obtenerDiaVariable(int anio, int mes, int diaSemanaBuscado, int n) {
    DateTime primerDiaDelMes = DateTime(anio, mes, 1);
    int diferencia = (diaSemanaBuscado - primerDiaDelMes.weekday) % 7;
    if (diferencia < 0) diferencia += 7; 
    int diasASumar = diferencia + (7 * (n - 1));
    return primerDiaDelMes.add(Duration(days: diasASumar));
  }

  DateTime _calcularDomingoDePascua(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final month = (a + 11 * h + 22 * l) ~/ 451;
    final mesFinal = (h + l - 7 * month + 114) ~/ 31;
    final diaFinal = ((h + l - 7 * month + 114) % 31) + 1;
    
    return DateTime(year, mesFinal, diaFinal);
  }
}