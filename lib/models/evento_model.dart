import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TipoEvento {
  cotidiano,
  recordatorio,
  especial,
  muyEspecial,
  cumpleanos,
  festivo
}

extension TipoEventoExtension on TipoEvento {
  Color get color {
    switch (this) {
      case TipoEvento.cotidiano: return const Color(0xFF5E81AC);
      case TipoEvento.recordatorio: return Colors.orange.shade600;
      case TipoEvento.especial: return Colors.purple.shade400;
      case TipoEvento.muyEspecial: return Colors.amber.shade600;
      case TipoEvento.cumpleanos: return Colors.pink.shade300;
      case TipoEvento.festivo: return const Color.fromARGB(255, 121, 121, 121);
    }
  }

  IconData get icono {
    switch (this) {
      case TipoEvento.cotidiano: return Icons.work_outline_rounded;
      case TipoEvento.recordatorio: return Icons.notifications_active_rounded;
      case TipoEvento.especial: return Icons.people_alt_rounded;
      case TipoEvento.muyEspecial: return Icons.star_rounded;
      case TipoEvento.cumpleanos: return Icons.cake_rounded;
      case TipoEvento.festivo: return Icons.calendar_today_rounded;
    }
  }

  String get etiqueta {
    switch (this) {
      case TipoEvento.cotidiano: return "Casual";
      case TipoEvento.recordatorio: return "Aviso";
      case TipoEvento.especial: return "Social";
      case TipoEvento.muyEspecial: return "Especial";
      case TipoEvento.cumpleanos: return "Cumple"; 
      case TipoEvento.festivo: return "Calendario";
    }
  }
}

class Evento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final TipoEvento tipo;
  final bool esTodoElDia;

  Evento({
    required this.id,
    required this.titulo,
    this.descripcion = '',
    required this.fechaInicio,
    required this.fechaFin,
    required this.tipo,
    required this.esTodoElDia,
  });

  factory Evento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime inicio = (data['fechaInicio'] as Timestamp).toDate();
    DateTime fin = (data['fechaFin'] as Timestamp).toDate();

    final rawTipo = data['tipo'];
    TipoEvento tipoFinal;

    if (rawTipo is int) {
      if (rawTipo >= 0 && rawTipo < TipoEvento.values.length) {
        tipoFinal = TipoEvento.values[rawTipo];
      } else {
        tipoFinal = TipoEvento.cotidiano;
      }
    } else if (rawTipo is String) {
      switch (rawTipo) {
        case 'cotidiano': tipoFinal = TipoEvento.cotidiano; break;
        case 'recordatorio': tipoFinal = TipoEvento.recordatorio; break;
        case 'especial': tipoFinal = TipoEvento.especial; break;
        case 'muyEspecial': tipoFinal = TipoEvento.muyEspecial; break;
        case 'cumpleanos': tipoFinal = TipoEvento.cumpleanos; break;
        case 'festivo': tipoFinal = TipoEvento.festivo; break;
        default: tipoFinal = TipoEvento.cotidiano;
      }
    } else {
      tipoFinal = TipoEvento.cotidiano;
    }

    return Evento(
      id: doc.id,
      titulo: data['titulo'] ?? 'Sin título',
      descripcion: data['descripcion'] ?? '',
      fechaInicio: inicio,
      fechaFin: fin,
      tipo: tipoFinal,
      esTodoElDia: data['todoElDia'] ?? (tipoFinal == TipoEvento.muyEspecial || tipoFinal == TipoEvento.cumpleanos || tipoFinal == TipoEvento.festivo),
    );
  }

  // Getter corregido para que respete el valor real de la base de datos
  bool get todoElDia => esTodoElDia;

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'tipo': tipo.toString().split('.').last,
      'todoElDia': esTodoElDia,
    };
  }
}