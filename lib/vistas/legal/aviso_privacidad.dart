import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../usuario/menu.dart';

class AvisoPrivacidadScreen extends StatefulWidget {
  const AvisoPrivacidadScreen({super.key});

  @override
  State<AvisoPrivacidadScreen> createState() => _AvisoPrivacidadScreenState();
}

class _AvisoPrivacidadScreenState extends State<AvisoPrivacidadScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600)
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart)
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- ANIMACIÓN HACIA LA DERECHA (PARA VOLVER AL MENÚ) ---
  Route _rutaHaciaDerecha(Widget vista) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => vista,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0); 
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final headerTextColor = isDark ? Colors.white : const Color(0xFF1E2D3A);
    final cardColor = theme.cardTheme.color;
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
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
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: headerTextColor, size: 20),
                        // --- SEGURO DE NAVEGACIÓN INTELIGENTE ---
                        onPressed: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            Navigator.pushReplacement(context, _rutaHaciaDerecha(const MenuScreen()));
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Aviso de Privacidad',
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: headerTextColor, 
                          letterSpacing: -0.5
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
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
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(28.0), 
                          child: Text(
                            "Agenda Kronos, operada por PF Studios, respeta tu privacidad y se compromete a proteger tu información.\n\n"
                            "1. Información que recopilamos\n"
                            "Para brindarte una experiencia personalizada, recopilamos tu nombre completo, correo electrónico y fecha de nacimiento al momento de tu registro.\n\n"
                            "2. Uso de la información\n"
                            "Utilizamos tus datos personales exclusivamente para gestionar tu cuenta, sincronizar tus eventos de manera segura en la nube (a través de Firebase) y automatizar funciones de la aplicación, como la creación de tu evento anual de cumpleaños.\n\n"
                            "3. Servicios de Terceros\n"
                            "Kronos utiliza servicios de terceros para su funcionamiento y autenticación, tales como Google Play Services, Firebase de Google LLC y Huawei Mobile Services.\n\n"
                            "4. Protección y Seguridad\n"
                            "Tus contraseñas y datos están protegidos y encriptados. PF Studios no comparte, vende, ni alquila tu información personal a terceros para fines comerciales.\n\n"
                            "5. Retención y Eliminación de Datos\n"
                            "Tienes el derecho de solicitar la eliminación total de tu cuenta y de todos los datos asociados en cualquier momento directamente desde la sección de Configuración de la aplicación. Al hacerlo, toda tu información se borrará permanentemente de nuestros servidores.\n\n"
                            "6. Contacto\n"
                            "Si tienes preguntas o necesitas soporte sobre este aviso, contáctanos en: pf.studios.dev@gmail.com",
                            style: TextStyle(fontSize: 15, height: 1.6, color: textColor),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ),
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
}