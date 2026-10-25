import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; 
import '../../providers/eventos_provider.dart'; 
import '../../services/auth_service.dart';
import '../../../main.dart'; 
import 'menu.dart';
import '../auth/inicio.dart';
import 'editar_datos.dart'; // NUEVA IMPORTACIÓN

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final AuthService _authService = AuthService();
  
  bool _notificacionesActivas = true;
  bool _modoOscuro = false;
  bool _inicioLunes = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificacionesActivas = prefs.getBool('notificaciones') ?? true;
      _modoOscuro = prefs.getBool('modoOscuro') ?? false;
      _inicioLunes = prefs.getBool('inicioLunes') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
    final cardColor = theme.cardTheme.color;
    final textColor = theme.textTheme.bodyLarge?.color;
    final titleColor = theme.textTheme.titleLarge?.color;
    final headerTextColor = isDark ? Colors.white : const Color(0xFF1E2D3A);

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
        child: Column(
          children: [
            // CABECERA
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.3), 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: headerTextColor), 
                        onPressed: () => Navigator.pushReplacement(context, _rutaHaciaDerecha(const MenuScreen()))
                      ),
                    ),
                    Text(
                      "Configuración", 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: headerTextColor, letterSpacing: -0.5)
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // CONTENIDO
            Expanded(
              child: Container(
                width: double.infinity, margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      
                      // --- CUENTA ---
                      _buildSectionTitle("Cuenta"),
                      // AQUI LLAMAMOS A LA NUEVA VISTA
                      _buildListTile(
                        icon: Icons.person_outline_rounded, 
                        title: "Editar mis datos", 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditarDatosScreen()))
                      ),
                      _buildListTile(
                        icon: Icons.lock_outline_rounded, 
                        title: "Cambiar Contraseña", 
                        onTap: _enviarCorreoRestablecimiento
                      ),

                      const SizedBox(height: 20), const Divider(), const SizedBox(height: 20),

                      // --- GENERAL ---
                      _buildSectionTitle("General"),
                      _buildSwitchTile(icon: Icons.notifications_none_rounded, title: "Notificaciones", value: _notificacionesActivas, onChanged: (val) { setState(() => _notificacionesActivas = val); _savePreference('notificaciones', val); }),
                      _buildSwitchTile(icon: Icons.calendar_today_rounded, title: "Empezar semana en Lunes", value: _inicioLunes, onChanged: (val) { setState(() => _inicioLunes = val); _savePreference('inicioLunes', val); }),
                      _buildSwitchTile(icon: Icons.dark_mode_outlined, title: "Modo Oscuro", value: _modoOscuro, onChanged: (val) { setState(() => _modoOscuro = val); _savePreference('modoOscuro', val); themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light; }),
                      
                      _buildListTile(
                        icon: Icons.event_available_rounded, 
                        title: "Importar Festivos Nativos", 
                        onTap: () async {
                          setState(() => _isLoading = true);
                          await context.read<EventosProvider>().importarFestivosNativos(context);
                          setState(() => _isLoading = false);
                        }
                      ),

                      const SizedBox(height: 20), const Divider(), const SizedBox(height: 20),

                      // --- ACCIONES ---
                      _buildSectionTitle("Acciones"),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 22)),
                        title: Text("Cerrar Sesión", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
                        onTap: () async { await _authService.signOut(); if (!mounted) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700, size: 22)),
                        title: Text("Eliminar Cuenta", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                        subtitle: const Text("Esta acción no se puede deshacer"),
                        onTap: () => _confirmarEliminarCuenta(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enviarCorreoRestablecimiento() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) { await _authService.sendPasswordResetEmail(user.email!); if (!mounted) return; _mostrarAlerta("Correo enviado a ${user.email}"); }
  }

  void _confirmarEliminarCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar cuenta?"),
        content: const Text("Perderás todos tus eventos. Si hace mucho que no inicias sesión, deberás salir y entrar de nuevo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); setState(() => _isLoading = true); 
              try { await _authService.deleteAccount(); if (!mounted) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); } 
              catch (e) { if (!mounted) return; setState(() => _isLoading = false); _mostrarAlerta("Error: Cierra sesión e ingresa de nuevo para eliminar."); }
            },
            child: Text("Sí, Eliminar", style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) { return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.2))); }

  Widget _buildListTile({required IconData icon, required String title, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: theme.textTheme.bodyLarge?.color, size: 22)),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: theme.textTheme.bodyLarge?.color, size: 22)),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
      trailing: Switch(value: value, activeColor: const Color(0xFF5E81AC), onChanged: onChanged),
    );
  }

  void _mostrarAlerta(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }
}