import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// [MODIFICADO] evento_model.dart
enum TipoEvento {
  cotidiano,
  recordatorio,
  especial,
  muyEspecial,
  cumpleanos // <-- Nuevo tipo
}

extension TipoEventoExtension on TipoEvento {
  Color get color {
    switch (this) {
      case TipoEvento.cotidiano: return const Color(0xFF5E81AC);
      case TipoEvento.recordatorio: return Colors.orange.shade600;
      case TipoEvento.especial: return Colors.purple.shade400;
      case TipoEvento.muyEspecial: return Colors.amber.shade600;
      case TipoEvento.cumpleanos: return Colors.pink.shade300; // Rosa para cumpleaños
    }
  }

  IconData get icono {
    switch (this) {
      case TipoEvento.cotidiano: return Icons.work_outline_rounded;
      case TipoEvento.recordatorio: return Icons.notifications_active_rounded;
      case TipoEvento.especial: return Icons.people_alt_rounded;
      case TipoEvento.muyEspecial: return Icons.star_rounded;
      case TipoEvento.cumpleanos: return Icons.cake_rounded; // Icono de pastel
    }
  }

  String get etiqueta {
    switch (this) {
      case TipoEvento.cotidiano: return "Casual";
      case TipoEvento.recordatorio: return "Aviso";
      case TipoEvento.especial: return "Social";
      case TipoEvento.muyEspecial: return "Especial";
      case TipoEvento.cumpleanos: return "Cumple"; // Etiqueta corta
    }
  }
}

// 2. LA CLASE EVENTO
class Evento {
  final String id;
  final String titulo;
  final String descripcion; // 
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final TipoEvento tipo;
  final bool esTodoElDia;

  Evento({
    required this.id,
    required this.titulo,
    this.descripcion = '', //)
    required this.fechaInicio,
    required this.fechaFin,
    required this.tipo,
    required this.esTodoElDia,
  });

  factory Evento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parseo seguro de fechas
    DateTime inicio = (data['fechaInicio'] as Timestamp).toDate();
    DateTime fin = (data['fechaFin'] as Timestamp).toDate();

    // Recuperamos el dato crudo para ver si es int o String
    final rawTipo = data['tipo'];
    TipoEvento tipoFinal;

    if (rawTipo is int) {
      // Si en la BD es un número (0, 1, 2...), usamos el índice
      if (rawTipo >= 0 && rawTipo < TipoEvento.values.length) {
        tipoFinal = TipoEvento.values[rawTipo];
      } else {
        tipoFinal = TipoEvento.cotidiano;
      }
    } else if (rawTipo is String) {
      // Si en la BD es texto ("cotidiano", "especial", etc.)
      switch (rawTipo) {
        case 'cotidiano':
          tipoFinal = TipoEvento.cotidiano;
          break;
        case 'recordatorio':
          tipoFinal = TipoEvento.recordatorio;
          break;
        case 'especial':
          tipoFinal = TipoEvento.especial;
          break;
        case 'muyEspecial':
          tipoFinal = TipoEvento.muyEspecial;
          break;
        case 'cumpleanos': 
          tipoFinal = TipoEvento.cumpleanos;
          break;

        default:
          tipoFinal = TipoEvento.cotidiano;
        
      }
    } else {
      tipoFinal = TipoEvento.cotidiano;
    }

    return Evento(
      id: doc.id,
      titulo: data['titulo'] ?? 'Sin título',
      descripcion: data['descripcion'] ?? '', // ✅ AGREGADO
      fechaInicio: inicio,
      fechaFin: fin,
      tipo: tipoFinal,
      esTodoElDia: data['todoElDia'] ?? (tipoFinal == TipoEvento.muyEspecial),
    );
  }

  // Getter útil
  bool get todoElDia {
    return tipo == TipoEvento.muyEspecial;
  }

  // ✅ MÉTODO PARA CONVERTIR A MAP (útil para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'tipo': tipo.toString().split('.').last, // Guarda como string: "cotidiano", "recordatorio", etc.
      'todoElDia': esTodoElDia,
    };
  }
}