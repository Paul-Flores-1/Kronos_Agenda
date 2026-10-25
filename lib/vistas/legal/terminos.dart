import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../usuario/menu.dart';

class TerminosScreen extends StatefulWidget {
  const TerminosScreen({super.key});

  @override
  State<TerminosScreen> createState() => _TerminosScreenState();
}

class _TerminosScreenState extends State<TerminosScreen> with SingleTickerProviderStateMixin {
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
                        'Términos y Condiciones',
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
                            "Al descargar o utilizar Agenda Kronos, aceptas automáticamente estos términos y condiciones establecidos por PF Studios. Léelos detenidamente antes de usar la aplicación.\n\n"
                            "1. Uso de la Aplicación\n"
                            "Kronos es una herramienta diseñada para la gestión personal de tu tiempo y eventos. El usuario es responsable de la exactitud de los datos ingresados y del uso que le dé a las notificaciones y recordatorios.\n\n"
                            "2. Disponibilidad del Servicio\n"
                            "Nos esforzamos por mantener la aplicación funcional y sincronizada en todo momento. Sin embargo, PF Studios no se hace responsable por pérdidas de datos, retrasos en notificaciones o fallas derivadas de tu conexión a internet o de caídas temporales en los servidores de autenticación (Google o Huawei).\n\n"
                            "3. Propiedad Intelectual\n"
                            "Todo el código, diseño gráfico, logotipos, animaciones y marca de Agenda Kronos son propiedad intelectual exclusiva de PF Studios. Queda estrictamente prohibida su copia, modificación o distribución sin nuestra autorización explícita.\n\n"
                            "4. Modificaciones a la Aplicación y Términos\n"
                            "Nos reservamos el derecho de modificar la aplicación, implementar nuevas funciones en fase Beta, o actualizar estos términos en cualquier momento para mejorar el servicio. Se notificará a los usuarios sobre cambios sustanciales.\n\n"
                            "5. Contacto\n"
                            "Para reportes de errores o soporte sobre estos términos, escríbenos a: pf.studios.dev@gmail.com",
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