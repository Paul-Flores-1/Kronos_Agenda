import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../../main.dart'; // IMPORTANTE: Conecta con el themeNotifier
import 'menu.dart';
import 'inicio.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final AuthService _authService = AuthService();
  
  // Variables de estado
  bool _notificacionesActivas = true;
  bool _modoOscuro = false;
  bool _inicioLunes = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // --- CARGAR PREFERENCIAS ---
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificacionesActivas = prefs.getBool('notificaciones') ?? true;
      _modoOscuro = prefs.getBool('modoOscuro') ?? false;
      _inicioLunes = prefs.getBool('inicioLunes') ?? true;
    });
  }

  // --- GUARDAR PREFERENCIAS ---
  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    // Usamos los colores del tema actual para que se adapte al modo oscuro
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    final textColor = theme.textTheme.bodyLarge?.color;
    final titleColor = theme.textTheme.titleLarge?.color;

    return Scaffold(
      // El fondo ya es automático gracias al tema en main.dart
      body: Column(
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
                      color: cardColor?.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.menu_rounded, size: 28, color: textColor),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MenuScreen()),
                        );
                      },
                    ),
                  ),
                  Text(
                    "Configuración",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 48), // Espacio para equilibrar
                ],
              ),
            ),
          ),

          // CONTENIDO
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: cardColor,
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
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    
                    // --- CUENTA ---
                    _buildSectionTitle("Cuenta"),
                    _buildListTile(
                      icon: Icons.person_outline_rounded,
                      title: "Editar Nombre",
                      onTap: _mostrarDialogoEditarNombre,
                    ),
                    _buildListTile(
                      icon: Icons.lock_outline_rounded,
                      title: "Cambiar Contraseña",
                      onTap: _enviarCorreoRestablecimiento,
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // --- GENERAL ---
                    _buildSectionTitle("General"),
                    
                    _buildSwitchTile(
                      icon: Icons.notifications_none_rounded,
                      title: "Notificaciones",
                      value: _notificacionesActivas,
                      onChanged: (val) {
                        setState(() => _notificacionesActivas = val);
                        _savePreference('notificaciones', val);
                      },
                    ),

                    _buildSwitchTile(
                      icon: Icons.calendar_today_rounded,
                      title: "Empezar semana en Lunes",
                      value: _inicioLunes,
                      onChanged: (val) {
                        setState(() => _inicioLunes = val);
                        _savePreference('inicioLunes', val);
                      },
                    ),

                    // SWITCH DE MODO OSCURO (CONECTADO AL MAIN)
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: "Modo Oscuro",
                      value: _modoOscuro,
                      onChanged: (val) {
                        setState(() => _modoOscuro = val);
                        _savePreference('modoOscuro', val);
                        
                        // ¡AQUÍ ESTÁ LA MAGIA!
                        themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // --- ACCIONES ---
                    _buildSectionTitle("Acciones"),
                    
                    // CERRAR SESIÓN
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 22),
                      ),
                      title: Text(
                        "Cerrar Sesión",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                      onTap: () async {
                        await _authService.signOut();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),

                    // ELIMINAR CUENTA
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700, size: 22),
                      ),
                      title: Text(
                        "Eliminar Cuenta",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
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
    );
  }

  // --- LÓGICA DE FUNCIONES ---

  void _mostrarDialogoEditarNombre() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Nombre"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nuevo nombre"),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _authService.updateUserName(controller.text.trim());
                if (!mounted) return;
                Navigator.pop(ctx);
                _mostrarAlerta("Nombre actualizado con éxito");
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _enviarCorreoRestablecimiento() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await _authService.sendPasswordResetEmail(user.email!);
      if (!mounted) return;
      _mostrarAlerta("Correo enviado a ${user.email}");
    }
  }

  void _confirmarEliminarCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar cuenta?"),
        content: const Text("Perderás todos tus eventos. Si hace mucho que no inicias sesión, deberás salir y entrar de nuevo."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); 
              setState(() => _isLoading = true); 
              
              try {
                await _authService.deleteAccount();
                if (!mounted) return;
                
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _isLoading = false);
                _mostrarAlerta("Error: Cierra sesión e ingresa de nuevo para eliminar.");
              }
            },
            child: Text("Sí, Eliminar", style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // Usamos el color de fondo del scaffold para el icono, con transparencia
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.textTheme.bodyLarge?.color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.textTheme.bodyLarge?.color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Switch(
        value: value,
        activeColor: const Color(0xFF5E81AC),
        onChanged: onChanged,
      ),
    );
  }

  void _mostrarAlerta(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}