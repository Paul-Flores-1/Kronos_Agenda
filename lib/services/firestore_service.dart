import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/evento_model.dart';
import 'package:flutter/material.dart'; 

class FirestoreService {
  // Obtenemos el usuario actual
  User? get user => FirebaseAuth.instance.currentUser;

  // Referencia a la colección de eventos del usuario
  CollectionReference get _eventosRef {
    if (user == null) throw Exception("Usuario no logueado");
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('eventos');
  }

  // --- CREAR EVENTO ---
  Future<void> agregarEvento({
    required String titulo,
    required DateTime fecha,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
    required TipoEvento tipo,
  }) async {
    
    // Convertimos TimeOfDay a DateTime para guardarlo en Firebase
    final fechaInicio = DateTime(fecha.year, fecha.month, fecha.day, horaInicio.hour, horaInicio.minute);
    final fechaFin = DateTime(fecha.year, fecha.month, fecha.day, horaFin.hour, horaFin.minute);

    await _eventosRef.add({
      'titulo': titulo,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'tipo': tipo.index, // Guardamos 0, 1, 2 o 3 (es más fácil que guardar texto)
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  // --- LEER EVENTOS (Stream para tiempo real) ---
  Stream<QuerySnapshot> obtenerEventosDelDia(DateTime fecha) {
    // Filtramos desde las 00:00 hasta las 23:59 de ese día
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    return _eventosRef
        .where('fechaInicio', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fechaInicio', isLessThanOrEqualTo: Timestamp.fromDate(finDia))
        .orderBy('fechaInicio') // Ordenar por hora
        .snapshots();
  }
}