import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // IMPORTANTE AÑADIR ESTO
import '../../providers/eventos_provider.dart'; // IMPORTANTE AÑADIR ESTO
import 'package:kronos/vistas/calendario/agenda.dart';
import 'package:kronos/vistas/calendario/mes.dart';
import 'package:kronos/vistas/usuario/perfil.dart'; 
import 'package:kronos/vistas/legal/aviso_privacidad.dart'; 
import 'package:kronos/vistas/legal/terminos.dart';         
import '../../services/auth_service.dart';
import '../auth/inicio.dart'; 
import '../calendario/estadisticas.dart';
import '../legal/ayuda.dart';
import 'configuracion.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Route _rutaHaciaIzquierda(Widget vista) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => vista,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); 
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth >= 600;
    final isLargeTablet = screenWidth >= 900;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerMargin = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final borderRadius = isLargeTablet ? 45.0 : (isTablet ? 40.0 : 35.0);
    
    final titleFontSize = isLargeTablet ? 32.0 : (isTablet ? 28.0 : 24.0);
    final menuItemFontSize = isLargeTablet ? 18.0 : (isTablet ? 17.0 : 16.0);
    final contentPadding = isLargeTablet ? 32.0 : (isTablet ? 28.0 : 20.0);

    final headerTextColor = isDark ? Colors.white : const Color(0xFF1E2D3A);
    final backBtnBgColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [const Color(0xFF15202B), const Color(0xFF1E2D3A)] : [const Color(0xFFA5BBC3), const Color(0xFF8DA9B3)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(containerMargin, 20, containerMargin, 10),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: backBtnBgColor,
                            borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_new, color: headerTextColor, size: isTablet ? 22 : 20),
                            onPressed: () => Navigator.pushReplacement(context, _rutaHaciaIzquierda(const AgendaScreen())),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          "Menú",
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: headerTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isLargeTablet ? 800 : double.infinity),
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.fromLTRB(containerMargin, 10, containerMargin, containerMargin),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color, 
                            borderRadius: BorderRadius.circular(borderRadius),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10), spreadRadius: -5)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: contentPadding, bottom: contentPadding * 0.5),
                                    child: Column(
                                      children: [
                                        _buildMenuItem(context, Icons.person_rounded, "Mi Perfil", 0, isTablet: isTablet, isLargeTablet: isLargeTablet, fontSize: menuItemFontSize),
                                        _buildMenuItem(context, Icons.calendar_month_outlined, "Mes", 1, isTablet: isTablet, isLargeTablet: isLargeTablet, fontSize: menuItemFontSize),
                                        _buildMenuItem(context, Icons.book_outlined, "Agenda", 2, isTablet: isTablet, isLargeTablet: isLargeTablet, fontSize: menuItemFontSize),
                                        _buildMenuItem(context, Icons.bar_chart_rounded, "Estadísticas", 3, isTablet: isTablet, isLargeTablet: isLargeTablet, fontSize: menuItemFontSize),
                                        _buildMenuItem(context, Icons.settings_outlined, "Configuración", 4, isTablet: isTablet, isLargeTablet: isLargeTablet, fontSize: menuItemFontSize),
                                        _buildMenuItem(context, Icons.privacy_tip_outlined, "Aviso de Privacidad", 5, isTablet: isTablet, isLargeTablet: isLargeTablet, fontSize: menuItemFontSize),
                                        _buildMenuItem(context, Icons.gavel_rounded, "Términos y Condiciones", 6, isTablet: isTablet, isLargeTablet: isLargeTablet, fontSize: menuItemFontSize),
                                        _buildMenuItem(context, Icons.help_outline, "Ayuda", 7, isTablet: isTablet, isLargeTablet: isLargeTablet, fontSize: menuItemFontSize),
                                      ],
                                    ),
                                  ),

                                  Padding(
                                    padding: EdgeInsets.fromLTRB(contentPadding, 0, contentPadding, isTablet ? 40 : 35),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
                                        boxShadow: [BoxShadow(color: const Color(0xFFFF9E9E).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: isLargeTablet ? 64 : (isTablet ? 60 : 56),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFF9E9E),
                                            foregroundColor: const Color(0xFF1E2D3A),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTablet ? 22 : 20)),
                                          ),
                                          onPressed: () async {
                                            // 1. Desconecta a Firestore de forma segura ANTES de cerrar sesión
                                            context.read<EventosProvider>().cerrarSesion();

                                            // 2. Cierra la sesión en Firebase Auth
                                            await _authService.signOut();

                                            // 3. Envía al usuario al Login limpiando la pila
                                            if (context.mounted) {
                                              Navigator.pushAndRemoveUntil(
                                                context, 
                                                MaterialPageRoute(builder: (context) => const LoginScreen()), 
                                                (route) => false
                                              );
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.logout, size: isTablet ? 22 : 20),
                                              SizedBox(width: isTablet ? 12 : 10),
                                              Text("Cerrar sesión", style: TextStyle(fontSize: menuItemFontSize, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String text, int index, {required bool isTablet, required bool isLargeTablet, required double fontSize}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final horizontalMargin = isLargeTablet ? 16.0 : (isTablet ? 14.0 : 12.0);
    final verticalMargin = isTablet ? 8.0 : 6.0;
    final itemBorderRadius = isLargeTablet ? 18.0 : (isTablet ? 17.0 : 16.0);
    final iconContainerSize = isLargeTablet ? 48.0 : (isTablet ? 44.0 : 40.0);
    final iconSize = isLargeTablet ? 26.0 : (isTablet ? 25.0 : 24.0);
    final horizontalPadding = isLargeTablet ? 24.0 : (isTablet ? 22.0 : 20.0);
    final verticalPadding = isLargeTablet ? 18.0 : (isTablet ? 17.0 : 16.0);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: verticalMargin),
        decoration: BoxDecoration(
          color: theme.cardTheme.color, 
          borderRadius: BorderRadius.circular(itemBorderRadius),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(itemBorderRadius),
            onTap: () {
              if (text == "Mi Perfil") {
                Navigator.pushReplacement(context, _rutaHaciaIzquierda(const PerfilScreen()));
              } else if (text == "Agenda") {
                Navigator.pushAndRemoveUntil(context, _rutaHaciaIzquierda(const AgendaScreen()), (route) => false);
              } else if (text == "Mes") {
                Navigator.pushReplacement(context, _rutaHaciaIzquierda(const MesScreen()));
              } else if (text == "Estadísticas") {
                Navigator.pushReplacement(context, _rutaHaciaIzquierda(const EstadisticasScreen()));
              } else if (text == "Aviso de Privacidad") {
                Navigator.pushReplacement(context, _rutaHaciaIzquierda(const AvisoPrivacidadScreen()));
              } else if (text == "Términos y Condiciones") {
                Navigator.pushReplacement(context, _rutaHaciaIzquierda(const TerminosScreen()));
              } else if (text == "Ayuda") {
                Navigator.pushReplacement(context, _rutaHaciaIzquierda(const AyudaScreen()));
              } else if (text == "Configuración") {
                Navigator.pushReplacement(context, _rutaHaciaIzquierda(const ConfiguracionScreen()));
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              child: Row(
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    padding: EdgeInsets.all(isTablet ? 11 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E81AC).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(isTablet ? 13 : 12),
                    ),
                    child: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF1E2D3A), size: iconSize),
                  ),
                  SizedBox(width: isTablet ? 18 : 16),
                  Expanded(
                    child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color, letterSpacing: 0.2)),
                  ),
                  Icon(Icons.arrow_forward_ios, size: isTablet ? 18 : 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}