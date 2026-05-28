import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kronos/vistas/agenda.dart';
import 'package:kronos/vistas/mes.dart';
import '../services/auth_service.dart';
import 'inicio.dart'; 
import 'estadisticas.dart';
import 'ayuda.dart';
import 'configuracion.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String? userName = "Usuario";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          userName = doc.data()?['nombre'] ?? "Usuario";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ========== RESPONSIVE: Obtener tamaño de pantalla ==========
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Determinar tipo de dispositivo
    final isTablet = screenWidth >= 600;
    final isLargeTablet = screenWidth >= 900;
    
    // Obtenemos el tema y verificamos si es modo oscuro
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ========== RESPONSIVE: Calcular dimensiones adaptativas ==========
    // Márgenes adaptativos según el tamaño de pantalla
    final containerMargin = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    
    // Radio de bordes adaptativo
    final borderRadius = isLargeTablet ? 45.0 : (isTablet ? 40.0 : 35.0);
    
    // Tamaño del avatar adaptativo
    final avatarSize = isLargeTablet ? 100.0 : (isTablet ? 90.0 : 80.0);
    
    // Tamaños de fuente adaptativos
    final userNameFontSize = isLargeTablet ? 28.0 : (isTablet ? 24.0 : 20.0);
    final greetingFontSize = isLargeTablet ? 16.0 : (isTablet ? 15.0 : 14.0);
    final menuItemFontSize = isLargeTablet ? 18.0 : (isTablet ? 17.0 : 16.0);
    
    // Padding adaptativos
    final headerPadding = isLargeTablet 
        ? const EdgeInsets.fromLTRB(32, 20, 32, 28)
        : (isTablet 
            ? const EdgeInsets.fromLTRB(28, 18, 28, 24)
            : const EdgeInsets.fromLTRB(20, 15, 20, 20));
    
    final contentPadding = isLargeTablet ? 32.0 : (isTablet ? 28.0 : 20.0);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [
                  const Color(0xFF15202B), // Fondo oscuro base
                  const Color(0xFF1E2D3A), // Un poco más claro
                ]
              : [
                  const Color(0xFFA5BBC3), // Tu azul original
                  const Color(0xFF8DA9B3),
                ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              // ========== RESPONSIVE: Container con ancho máximo para tablets grandes ==========
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // En tablets grandes, limitamos el ancho para mejor legibilidad
                    maxWidth: isLargeTablet ? 800 : double.infinity,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    margin: EdgeInsets.all(containerMargin),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color, 
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: -5,
                        )
                      ],
                    ),
                    
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // SECCIÓN DE CABECERA CON PERFIL
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isDark 
                                  ? [
                                      theme.cardTheme.color!.withValues(alpha: 0.8),
                                      theme.cardTheme.color!,
                                    ]
                                  : [
                                      const Color(0xFFF8F9FA),
                                      Colors.white,
                                    ],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(borderRadius),
                                topRight: Radius.circular(borderRadius),
                              ),
                            ),
                            child: Padding(
                              padding: headerPadding,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Botón Atrás con tamaño adaptativo
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark 
                                              ? Colors.white.withValues(alpha: 0.05) 
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            isTablet ? 14 : 12
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.arrow_back_ios_new, 
                                            color: isDark ? Colors.white70 : const Color(0xFF5E6A81), 
                                            size: isTablet ? 22 : 20,
                                          ),
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => const AgendaScreen()),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: isTablet ? 20 : 16),
                                  
                                  // Avatar con tamaño adaptativo
                                  Container(
                                    width: avatarSize,
                                    height: avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF5E6A81),
                                          Color(0xFF7A8BA0),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF5E6A81).withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: avatarSize * 0.5, // 50% del tamaño del avatar
                                      color: Colors.white,
                                    ),
                                  ),
                                  
                                  SizedBox(height: isTablet ? 18 : 16),
                                  
                                  // Nombre del usuario con fuente adaptativa
                                  Text(
                                    userName ?? "Usuario",
                                    style: TextStyle(
                                      fontSize: userNameFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  
                                  SizedBox(height: isTablet ? 8 : 6),
                                  
                                  // Saludo con fuente adaptativa
                                  Text(
                                    "¡Bienvenido a Kronos!",
                                    style: TextStyle(
                                      fontSize: greetingFontSize,
                                      color: isDark 
                                          ? Colors.white60
                                          : Colors.grey[600],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  
                                  SizedBox(height: isTablet ? 6 : 4),
                                  
                                  // Email con fuente adaptativa
                                  Text(
                                    FirebaseAuth.instance.currentUser?.email ?? "",
                                    style: TextStyle(
                                      fontSize: greetingFontSize - 1,
                                      color: isDark 
                                          ? Colors.white38
                                          : Colors.grey[500],
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // LISTA DE OPCIONES DEL MENÚ
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: contentPadding * 0.75,
                            ),
                            child: Column(
                              children: [
                                _buildMenuItem(
                                  context, 
                                  Icons.calendar_month_outlined, 
                                  "Mes", 
                                  0,
                                  isTablet: isTablet,
                                  isLargeTablet: isLargeTablet,
                                  fontSize: menuItemFontSize,
                                ),
                                _buildMenuItem(
                                  context, 
                                  Icons.book_outlined, 
                                  "Agenda", 
                                  1,
                                  isTablet: isTablet,
                                  isLargeTablet: isLargeTablet,
                                  fontSize: menuItemFontSize,
                                ),
                                _buildMenuItem(
                                  context, 
                                  Icons.bar_chart_rounded, 
                                  "Estadísticas", 
                                  2,
                                  isTablet: isTablet,
                                  isLargeTablet: isLargeTablet,
                                  fontSize: menuItemFontSize,
                                ),
                                _buildMenuItem(
                                  context, 
                                  Icons.help_outline, 
                                  "Ayuda", 
                                  3,
                                  isTablet: isTablet,
                                  isLargeTablet: isLargeTablet,
                                  fontSize: menuItemFontSize,
                                ),
                                _buildMenuItem(
                                  context, 
                                  Icons.settings_outlined, 
                                  "Configuración", 
                                  4,
                                  isTablet: isTablet,
                                  isLargeTablet: isLargeTablet,
                                  fontSize: menuItemFontSize,
                                ),
                              ],
                            ),
                          ),

                          // BOTÓN DE CERRAR SESIÓN
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              contentPadding, 
                              isTablet ? 18 : 15, 
                              contentPadding, 
                              isTablet ? 40 : 35
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 22 : 20
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9E9E).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: isLargeTablet ? 64 : (isTablet ? 60 : 56),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9E9E),
                                    foregroundColor: const Color(0xFF1E2D3A),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        isTablet ? 22 : 20
                                      ),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await _authService.signOut();
                                    if (context.mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.logout, 
                                        size: isTablet ? 22 : 20,
                                      ),
                                      SizedBox(width: isTablet ? 12 : 10),
                                      Text(
                                        "Cerrar sesión",
                                        style: TextStyle(
                                          fontSize: menuItemFontSize,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
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
        ),
      ),
    );
  }

  // ========== MÉTODO AUXILIAR MODIFICADO CON PARÁMETROS RESPONSIVE ==========
  Widget _buildMenuItem(
    BuildContext context, 
    IconData icon, 
    String text, 
    int index, {
    required bool isTablet,
    required bool isLargeTablet,
    required double fontSize,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dimensiones adaptativas para los items del menú
    final horizontalMargin = isLargeTablet ? 16.0 : (isTablet ? 14.0 : 12.0);
    final verticalMargin = isTablet ? 8.0 : 6.0;
    final itemBorderRadius = isLargeTablet ? 18.0 : (isTablet ? 17.0 : 16.0);
    final iconContainerSize = isLargeTablet ? 48.0 : (isTablet ? 44.0 : 40.0);
    final iconSize = isLargeTablet ? 26.0 : (isTablet ? 25.0 : 24.0);
    final horizontalPadding = isLargeTablet ? 24.0 : (isTablet ? 22.0 : 20.0);
    final verticalPadding = isLargeTablet ? 18.0 : (isTablet ? 17.0 : 16.0);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontalMargin, 
          vertical: verticalMargin,
        ),
        decoration: BoxDecoration(
          color: theme.cardTheme.color, 
          borderRadius: BorderRadius.circular(itemBorderRadius),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(itemBorderRadius),
            onTap: () {
              if (text == "Agenda") {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AgendaScreen()),
                  (route) => false,
                );
              } 
              else if (text == "Mes") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MesScreen()),
                );
              } 
              else if (text == "Estadísticas") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const EstadisticasScreen()),
                );
              }
              else if (text == "Ayuda") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AyudaScreen()),
                );
              }
              else if (text == "Configuración") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfiguracionScreen()),
                );
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, 
                vertical: verticalPadding,
              ),
              child: Row(
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    padding: EdgeInsets.all(isTablet ? 11 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E81AC).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(
                        isTablet ? 13 : 12
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isDark ? Colors.white70 : const Color(0xFF1E2D3A),
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: isTablet ? 18 : 16),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: isTablet ? 18 : 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}