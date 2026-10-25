import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../auth/inicio.dart';
import 'menu.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {

  // --- ANIMACIÓN HACIA LA DERECHA (PARA VOLVER AL MENÚ) ---
  Route _rutaHaciaDerecha(Widget vista) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => vista,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0); // Entra desde la izquierda
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainTextColor = theme.textTheme.titleLarge?.color;
    final cardColor = theme.cardTheme.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF15202B), const Color(0xFF1E2D3A)] 
                : [const Color(0xFFA5BBC3), const Color(0xFF8DA9B3)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. CABECERA (AFUERA DEL PANEL)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF1E2D3A), size: 20),
                        // Botón con animación hacia la derecha
                        onPressed: () => Navigator.pushReplacement(context, _rutaHaciaDerecha(const MenuScreen())),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Mi Perfil',
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : const Color(0xFF1E2D3A), 
                        letterSpacing: -0.5
                      ),
                    ),
                  ],
                ),
              ),

              // 2. PANEL DE DATOS (TARJETA CENTRAL)
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15), 
                        blurRadius: 20, 
                        offset: const Offset(0, 10),
                        spreadRadius: -5
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: user == null
                        ? Center(child: Text("No hay sesión activa", style: TextStyle(color: mainTextColor)))
                        : StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF5E81AC)));
                              }

                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return Center(child: Text("Error al cargar los datos del perfil.", style: TextStyle(color: mainTextColor)));
                              }

                              final userData = snapshot.data!.data() as Map<String, dynamic>;
                              final nombre = userData['nombre'] ?? 'Usuario';
                              final correo = userData['correo'] ?? user.email ?? 'Sin correo';
                              
                              // Formateo seguro de fecha
                              String fechaNacimientoStr = 'No registrada';
                              if (userData['fechaNacimiento'] != null) {
                                DateTime fechaNac = (userData['fechaNacimiento'] as Timestamp).toDate();
                                List<String> meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
                                fechaNacimientoStr = '${fechaNac.day} de ${meses[fechaNac.month - 1]} de ${fechaNac.year}';
                              }

                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 10),
                                    
                                    // AVATAR
                                    Container(
                                      width: 100, height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft, end: Alignment.bottomRight, 
                                          colors: [Color(0xFF5E81AC), Color(0xFF7A8BA0)]
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF5E81AC).withValues(alpha: 0.4), 
                                            blurRadius: 15, 
                                            offset: const Offset(0, 5)
                                          )
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'K',
                                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // TEXTOS DE NOMBRE Y CORREO
                                    Text(
                                      nombre, 
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: mainTextColor, letterSpacing: -0.5)
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      correo, 
                                      style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)
                                    ),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // TARJETA DE INFORMACIÓN INTERNA
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F7)),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildInfoRow(context, Icons.cake_rounded, "Fecha de nacimiento", fechaNacimientoStr),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                                            child: Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200, height: 1),
                                          ),
                                          _buildInfoRow(context, Icons.calendar_today_rounded, "Miembro desde", 
                                            userData['fechaCreacion'] != null 
                                              ? DateFormat('dd / MM / yyyy').format((userData['fechaCreacion'] as Timestamp).toDate()) 
                                              : 'Reciente',
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 60),

                                    // BOTÓN CERRAR SESIÓN
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFBF616A),
                                          side: BorderSide(color: const Color(0xFFBF616A).withValues(alpha: 0.5), width: 1.5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          backgroundColor: const Color(0xFFBF616A).withValues(alpha: 0.05),
                                        ),
                                        icon: const Icon(Icons.logout_rounded),
                                        label: const Text("Cerrar Sesión", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          await AuthService().signOut();
                                          if (!context.mounted) return;
                                          Navigator.pushAndRemoveUntil(
                                            context, 
                                            MaterialPageRoute(builder: (context) => const LoginScreen()), 
                                            (route) => false
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET AUXILIAR PARA LAS FILAS DE INFORMACIÓN
  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.titleLarge?.color;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF5E81AC).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: const Color(0xFF5E81AC), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontWeight: FontWeight.w600)
              ),
              const SizedBox(height: 4),
              Text(
                value, 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)
              ),
            ],
          ),
        ),
      ],
    );
  }
}