import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. REGISTRO (CON VERIFICACIÓN) ---
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required DateTime birthDate,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(name);
        await user.sendEmailVerification(); // Envía el correo

        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'nombre': name,
          'correo': email,
          'fechaNacimiento': Timestamp.fromDate(birthDate),
          'fechaCreacion': FieldValue.serverTimestamp(),
        });

        await _createBirthdayEvent(user.uid, name, birthDate);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'La contraseña es muy débil.';
      if (e.code == 'email-already-in-use') return 'Ya existe una cuenta con este correo.';
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

  // --- 2. LOGIN (CON CANDADO DE VERIFICACIÓN) ---
  Future<String?> loginUser({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = userCredential.user;

      //  CANDADO DE SEGURIDAD 
      if (user != null && !user.emailVerified) {
        await _auth.signOut(); // Los sacamos inmediatamente
        return 'Acceso denegado.\nDebes verificar tu correo para poder entrar.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No existe usuario con ese correo.';
      if (e.code == 'wrong-password') return 'Contraseña incorrecta.';
      return "Error de credenciales.";
    } catch (e) {
      return e.toString();
    }
  }

  // --- 3. LOGOUT ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- 4. CUMPLEAÑOS AUTOMÁTICO Y CÍCLICO ---
  Future<void> _createBirthdayEvent(String userId, String userName, DateTime birthDate) async {
    DateTime now = DateTime.now();
    // Calculamos el cumpleaños para este año
    DateTime nextBirthday = DateTime(now.year, birthDate.month, birthDate.day);
    
    // Si ya pasó este año, lo programamos para el próximo
    if (nextBirthday.isBefore(DateTime(now.year, now.month, now.day))) {
      nextBirthday = DateTime(now.year + 1, birthDate.month, birthDate.day);
    }

    // Buscamos si ya existe para no duplicar, si no, lo creamos
    final docRef = _firestore.collection('users').doc(userId).collection('eventos');
    final existing = await docRef.where('titulo', isEqualTo: 'Cumpleaños de $userName').get();

    if (existing.docs.isEmpty) {
      await docRef.add({
        'idUsuario': userId,
        'titulo': 'Cumpleaños de $userName',
        'descripcion': '¡Día especial! Celebración de cumpleaños.',
        'fechaInicio': Timestamp.fromDate(nextBirthday),
        'fechaFin': Timestamp.fromDate(nextBirthday.add(const Duration(hours: 23, minutes: 59))),
        'tipo': 'cumpleanos', // <--- CORREGIDO: Ahora usa el tipo correcto para el pastel
        'todoElDia': true,
        'eliminado': false,
      });
    } else {
      // Si ya existe, actualizamos la fecha y aseguramos el tipo correcto
      await docRef.doc(existing.docs.first.id).update({
        'fechaInicio': Timestamp.fromDate(nextBirthday),
        'fechaFin': Timestamp.fromDate(nextBirthday.add(const Duration(hours: 23, minutes: 59))),
        'tipo': 'cumpleanos', // Aseguramos que se actualice el tipo si era antiguo
      });
    }
  }

  // --- 5. OBTENER EVENTOS (SOLO FUTUROS) ---
  Stream<List<Evento>> getEvents() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore.collection('users').doc(uid).collection('eventos')
        .where('eliminado', isEqualTo: false).snapshots().map((snapshot) {
          final todosLosEventos = snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
          final now = DateTime.now();
          return todosLosEventos.where((evento) {
            if (evento.todoElDia) {
              final finDelDia = DateTime(evento.fechaFin.year, evento.fechaFin.month, evento.fechaFin.day, 23, 59, 59);
              return finDelDia.isAfter(now);
            }
            return evento.fechaFin.isAfter(now);
          }).toList();
        });
  }
  
  // --- 6. OBTENER HISTORIAL (SOLO PASADOS) ---
  Stream<List<Evento>> getHistorial() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore.collection('users').doc(uid).collection('eventos')
        .where('eliminado', isEqualTo: false).snapshots().map((snapshot) {
          final todosLosEventos = snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
          final now = DateTime.now();
          return todosLosEventos.where((evento) => evento.fechaFin.isBefore(now)).toList();
        });
  }

  // --- 7. BORRADO LÓGICO ---
  Future<void> deleteEvent(String eventId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('eventos').doc(eventId).update({'eliminado': true});
  }

  // --- 8. CREAR EVENTO MANUAL ---
  Future<void> createEvent({required String title, required String description, required DateTime startDate, required DateTime endDate, required bool isAllDay, required String type}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('eventos').add({
      'idUsuario': uid, 'titulo': title, 'descripcion': description, 'fechaInicio': Timestamp.fromDate(startDate), 'fechaFin': Timestamp.fromDate(endDate), 'tipo': type, 'todoElDia': isAllDay, 'eliminado': false,
    });
  }

  // --- 9. ACTUALIZAR EVENTO ---
  Future<void> updateEvent({required String eventId, required String title, required String description, required DateTime startDate, required DateTime endDate, required bool isAllDay, required String type}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('eventos').doc(eventId).update({
      'titulo': title, 'descripcion': description, 'fechaInicio': Timestamp.fromDate(startDate), 'fechaFin': Timestamp.fromDate(endDate), 'tipo': type, 'todoElDia': isAllDay,
    });
  }

  // --- 10. ACTUALIZAR NOMBRE ---
  Future<void> updateUserName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(newName);
    await _firestore.collection('users').doc(user.uid).update({'nombre': newName});
  }

  // --- 11. CAMBIAR CONTRASEÑA ---
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- 12. ELIMINAR CUENTA ---
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }
}