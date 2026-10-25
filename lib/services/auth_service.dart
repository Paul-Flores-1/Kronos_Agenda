import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import '../services/notification_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:huawei_account/huawei_account.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. REGISTRO (CON VERIFICACION) ---
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
        await user.sendEmailVerification(); 

        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'nombre': name,
          'correo': email,
          'fechaNacimiento': Timestamp.fromDate(birthDate),
          'fechaCreacion': FieldValue.serverTimestamp(),
          'authProvider': 'email',
        });

        await _createBirthdayEvent(user.uid, name, birthDate);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'La contrasena es muy debil.';
      if (e.code == 'email-already-in-use') return 'Ya existe una cuenta con este correo.';
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

  // --- 2. LOGIN (CON CANDADO DE VERIFICACION) ---
  Future<String?> loginUser({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = userCredential.user;

      // CANDADO DE SEGURIDAD 
      if (user != null && !user.emailVerified) {
        // Verificar si el usuario se registró con Huawei (no tiene verificación de email)
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final provider = doc.data()?['authProvider'];
        if (provider != 'huawei') {
          await _auth.signOut(); 
          return 'Acceso denegado.\nDebes verificar tu correo para poder entrar.';
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No existe usuario con ese correo.';
      if (e.code == 'wrong-password') return 'Contrasena incorrecta.';
      return "Error de credenciales.";
    } catch (e) {
      return e.toString();
    }
  }

  // --- INICIO DE SESION CON GOOGLE ---
  Future<String?> signInWithGoogle({DateTime? birthDate, String? name}) async {
    try {
      // 1. Inyectamos el ID para evitar el Error 10
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '726261566096-64ukgkofai69ub36oicnksvash6852bj.apps.googleusercontent.com', // ¡RECUERDA PONER TU ID TIPO 3 AQUÍ!
      );
      
      // --- LA SOLUCIÓN ESTÁ AQUÍ ---
      // Forzamos el cierre de cualquier sesión previa en caché para que 
      // Google siempre abra el modal preguntando qué cuenta deseas usar.
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return 'Inicio de sesión cancelado por el usuario.';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Inicia sesión o registra al usuario en Firebase Auth
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // 2. Verificamos si es la primera vez que entra (para crear su perfil en Firestore)
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!doc.exists) {
          // Si nos pasaron un nombre desde el formulario, lo usamos. Si no, usamos el de su cuenta de Google.
          String finalName = name ?? user.displayName ?? 'Usuario Google';
          
          // Si nos pasaron una fecha (desde el registro), la usamos. Si no, ponemos una por defecto (2000-01-01).
          DateTime finalBirthDate = birthDate ?? DateTime(2000, 1, 1);
          
          // Guardamos en la base de datos
          await _firestore.collection('users').doc(user.uid).set({
            'id': user.uid,
            'nombre': finalName,
            'correo': user.email,
            'fechaNacimiento': Timestamp.fromDate(finalBirthDate),
            'fechaCreacion': FieldValue.serverTimestamp(),
            'authProvider': 'google',
          });

          // Creamos el evento de cumpleaños con los datos correctos
          await _createBirthdayEvent(user.uid, finalName, finalBirthDate);
        }
      }
      return null; 
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error al conectar con Google: $e";
    }
  }

  // --- INICIO DE SESION CON HUAWEI ---
  Future<String?> signInWithHuawei({DateTime? birthDate, String? name}) async {
    try {
      AccountAuthParamsHelper authParamsHelper = AccountAuthParamsHelper();
      authParamsHelper.setProfile();
      authParamsHelper.setEmail();
      AccountAuthParams authParams = authParamsHelper.createParams();
      
      AccountAuthService authService = AccountAuthManager.getService(authParams);

      AuthAccount account = await authService.signIn();

      if (account.email == null || account.email!.isEmpty) {
        return 'No se pudo obtener el correo de la cuenta Huawei.';
      }

      final String generatedPassword = "HW_${account.unionId ?? account.openId}";
      late UserCredential userCredential;

      // 1. Intentar iniciar sesión (usuario Huawei que ya existía)
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: account.email!,
          password: generatedPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // 2. Usuario nuevo: intentar crear cuenta
          try {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: account.email!,
              password: generatedPassword,
            );
          } on FirebaseAuthException catch (createError) {
            // El email ya existe con otro método (registro manual o Google)
            if (createError.code == 'email-already-in-use') {
              return 'Este correo ya está registrado con otro método.\nInicia sesión con tu correo y contraseña, o con Google.';
            }
            return createError.message ?? 'Error al crear la cuenta.';
          }
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          // El email existe pero con otra contraseña (registro manual o Google)
          return 'Este correo ya está registrado con otro método.\nInicia sesión con tu correo y contraseña, o con Google.';
        } else {
          return e.message ?? 'Error de autenticación.';
        }
      }

      // 3. Guardar perfil solo si es usuario nuevo (no existe en Firestore)
      User? user = userCredential.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          String finalName = name ?? account.displayName ?? 'Usuario Huawei';
          DateTime finalBirthDate = birthDate ?? DateTime(2000, 1, 1);
          await _firestore.collection('users').doc(user.uid).set({
            'id': user.uid,
            'nombre': finalName,
            'correo': account.email,
            'fechaNacimiento': Timestamp.fromDate(finalBirthDate),
            'fechaCreacion': FieldValue.serverTimestamp(),
            'authProvider': 'huawei',
          });
          await _createBirthdayEvent(user.uid, finalName, finalBirthDate);
        }
      }
      return null; 
    } catch (e) {
      return "Error al conectar con Huawei: $e";
    }
  }

  // --- 3. LOGOUT ---
  Future<void> signOut() async {
    await GoogleSignIn().signOut(); // Limpia la cuenta de Google seleccionada
    await _auth.signOut();
  }

  // --- 4. CUMPLEANOS AUTOMATICO Y CICLICO ---
  Future<void> _createBirthdayEvent(String userId, String userName, DateTime birthDate) async {
    DateTime now = DateTime.now();
    DateTime nextBirthday = DateTime(now.year, birthDate.month, birthDate.day);
    
    if (nextBirthday.isBefore(DateTime(now.year, now.month, now.day))) {
      nextBirthday = DateTime(now.year + 1, birthDate.month, birthDate.day);
    }

    final docRef = _firestore.collection('users').doc(userId).collection('eventos');
    final existing = await docRef.where('titulo', isEqualTo: 'Cumpleanos de $userName').get();

    if (existing.docs.isEmpty) {
      await docRef.add({
        'idUsuario': userId,
        'titulo': 'Cumpleanos de $userName',
        'descripcion': 'Dia especial Celebracion de cumpleanos.',
        'fechaInicio': Timestamp.fromDate(nextBirthday),
        'fechaFin': Timestamp.fromDate(nextBirthday.add(const Duration(hours: 23, minutes: 59))),
        'tipo': 'cumpleanos', 
        'todoElDia': true,
        'eliminado': false,
      });
    } else {
      await docRef.doc(existing.docs.first.id).update({
        'fechaInicio': Timestamp.fromDate(nextBirthday),
        'fechaFin': Timestamp.fromDate(nextBirthday.add(const Duration(hours: 23, minutes: 59))),
        'tipo': 'cumpleanos',
      });
    }

    // --- NUEVO: PROGRAMAR LA ALARMA LOCAL A LAS 9:00 AM ---
    DateTime horaNotificacion = DateTime(nextBirthday.year, nextBirthday.month, nextBirthday.day, 9, 0);
    
    if (horaNotificacion.isAfter(DateTime.now())) {
      await NotificationService.programarNotificacion(
        id: nextBirthday.millisecondsSinceEpoch ~/ 1000, 
        titulo: 'Feliz Cumpleanos', 
        cuerpo: 'Hoy es el cumpleanos de $userName. A celebrar', 
        fecha: horaNotificacion
      );
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

  // --- 7. BORRADO LOGICO ---
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

  // --- 11. CAMBIAR CONTRASENA ---
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