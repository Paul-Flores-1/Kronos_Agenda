import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'menu.dart'; 

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Variables de tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainTextColor = theme.textTheme.titleLarge?.color;
    final bodyTextColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      body: Column(
        children: [
          // 1. CABECERA
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Menú Adaptado
                  Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.menu_rounded, size: 28, color: mainTextColor),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MenuScreen()),
                        );
                      },
                    ),
                  ),
                  Text(
                    "Ayuda y Soporte",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: mainTextColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 48), 
                ],
              ),
            ),
          ),

          // 2. CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                // [CAMBIO] Color de tarjeta dinámico
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // AVISO BETA (Adaptado)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          // [CAMBIO] Fondo ámbar sutil en modo oscuro
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
                                      // Texto legible en ambos modos
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
                          color: mainTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildFAQItem(
                        context,
                        "¿Cómo elimino un evento?",
                        "En la vista de Agenda, desliza la tarjeta del evento hacia un lado.",
                      ),
                      _buildFAQItem(
                        context,
                        "¿Qué significan los iconos?",
                        "⭐ Estrella: Muy Especial\n👥 Personas: Especial\n🔔 Campana: Recordatorio\n💼 Maletín: Cotidiano",
                      ),
                      _buildFAQItem(
                        context,
                        "¿Como se calculan mis estadísticas de tiempo?",
                        "-Día (Hoy): Calcula el tiempo total ocupado desde las 00:00 hasta las 23:59 del día actual.\n-Semana: Suma la duración de todos los eventos desde el Lunes (inicio de semana) hasta el Domingo actual.\n- Mes: Muestra el acumulado de horas desde el día 1 hasta el último día del mes en curso.",
                      ),

                      const SizedBox(height: 30),
                      // Divisor adaptado
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
                                color: mainTextColor,
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
                            const SizedBox(height: 16),
                            
                            // BOTÓN DE CORREO
                            ElevatedButton.icon(
                              onPressed: () => _enviarCorreoSoporte(context), 
                              icon: const Icon(Icons.mail_outline_rounded, size: 18),
                              label: const Text("Enviar Reporte de Error"),
                              style: ElevatedButton.styleFrom(
                                // El color de fondo del botón se define en el theme, pero podemos forzar contraste
                                backgroundColor: isDark ? const Color(0xFF5E81AC) : const Color(0xFF1E2D3A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE CORREO ---
  Future<void> _enviarCorreoSoporte(BuildContext context) async {
    const String emailDestino = "alanpaul380@gmail.com"; 
    
    const String subject = "Reporte de Error - Kronos Beta";
    const String body = "Hola equipo Kronos,\n\nEncontré el siguiente error:\n\n[Describe aquí lo que pasó]\n\n";

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
        // [CAMBIO] Fondo de FAQ adaptado
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200
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
              color: theme.textTheme.bodyLarge?.color // Color dinámico
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