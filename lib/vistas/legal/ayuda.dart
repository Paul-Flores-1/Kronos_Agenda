import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../usuario/menu.dart'; 

class AyudaScreen extends StatefulWidget {
  const AyudaScreen({super.key});

  @override
  State<AyudaScreen> createState() => _AyudaScreenState();
}

class _AyudaScreenState extends State<AyudaScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Animación elegante de entrada
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Color de texto para la cabecera
    final headerTextColor = isDark ? Colors.white : const Color(0xFF1E2D3A);
    final cardColor = theme.cardTheme.color;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Fondo degradado para mantener la consistencia premium
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF15202B), const Color(0xFF1E2D3A)] 
                : [const Color(0xFFA5BBC3), const Color(0xFF8DA9B3)],
          ),
        ),
        child: Column(
          children: [
            // 1. CABECERA
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón Atrás/Menú con animación
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: headerTextColor),
                        onPressed: () => Navigator.pushReplacement(context, _rutaHaciaDerecha(const MenuScreen())),
                      ),
                    ),
                    Text(
                      "Ayuda y Soporte",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: headerTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 48), // Espaciador para centrar el título
                  ],
                ),
              ),
            ),

            // 2. CONTENIDO PRINCIPAL CON ANIMACIÓN
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            // AVISO BETA
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.amber.withValues(alpha: 0.15) 
                                    : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark 
                                      ? Colors.amber.withValues(alpha: 0.3) 
                                      : Colors.amber.shade200
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.construction_rounded, color: Colors.amber.shade800, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Aplicación en Fase Beta",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.amber.shade400 : Colors.amber.shade900,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Kronos está en desarrollo activo. Es posible que encuentres pequeños errores. ¡Gracias por reportarlos!",
                                          style: TextStyle(
                                            color: isDark 
                                                ? Colors.amber.shade200 
                                                : Colors.amber.shade900.withValues(alpha: 0.8),
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            Text(
                              "Preguntas Frecuentes",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildFAQItem(
                              context,
                              "¿Cómo elimino un evento?",
                              "En la vista de Agenda, desliza la tarjeta del evento hacia un lado.",
                            ),
                            _buildFAQItem(
                              context,
                              "¿Qué significan los iconos?",
                              "Estrella: Muy Especial\nPersonas: Especial\nCampana: Recordatorio\nMaletín: Cotidiano",
                            ),
                            _buildFAQItem(
                              context,
                              "¿Como se calculan mis estadísticas de tiempo?",
                              "- Día (Hoy): Calcula el tiempo total ocupado desde las 00:00 hasta las 23:59 del día actual.\n- Semana: Suma la duración de todos los eventos desde el Lunes (inicio de semana) hasta el Domingo actual.\n- Mes: Muestra el acumulado de horas desde el día 1 hasta el último día del mes en curso.",
                            ),

                            const SizedBox(height: 30),
                            Divider(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFEEEEEE)
                            ),
                            const SizedBox(height: 30),

                            // SECCIÓN DE CONTACTO
                            Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.bug_report_rounded, size: 40, color: Color(0xFF5E81AC)),
                                  const SizedBox(height: 12),
                                  Text(
                                    "¿Encontraste un error?",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.textTheme.titleLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Ayúdanos enviando un reporte directo.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // BOTÓN DE CORREO
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _enviarCorreoSoporte(context), 
                                      icon: const Icon(Icons.mail_outline_rounded, size: 18),
                                      label: const Text("Enviar Reporte de Error", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? const Color(0xFF5E81AC) : const Color(0xFF1E2D3A),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                          ],
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
    );
  }

  // --- LÓGICA DE CORREO ---
  Future<void> _enviarCorreoSoporte(BuildContext context) async {
    // CORREO ACTUALIZADO A PF STUDIOS
    const String emailDestino = "pf.studios.dev@gmail.com"; 
    
    const String subject = "Reporte de Error - Kronos Beta";
    const String body = "Hola equipo PF Studios,\n\nEncontré el siguiente error en Kronos:\n\n[Describe aquí lo que pasó]\n\n";

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailDestino,
      query: _encodeQueryParameters({
        'subject': subject,
        'body': body,
      }),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'No se pudo abrir la app de correo';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("No se encontró una app de correo configurada."),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.03) 
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F7)
        ),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF5E81AC),
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 15, 
              color: theme.textTheme.bodyLarge?.color
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer, 
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, 
                fontSize: 14, 
                height: 1.5
              )
            ),
          ],
        ),
      ),
    );
  }
}