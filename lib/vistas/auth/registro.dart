import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // NECESARIO PARA EL TEXTO CLICKEABLE
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kronos/vistas/auth/inicio.dart'; 
import '../../services/auth_service.dart'; 
import '../calendario/agenda.dart';
import '../legal/terminos.dart';           // IMPORTAMOS LOS TÉRMINOS
import '../legal/aviso_privacidad.dart';   // IMPORTAMOS LA PRIVACIDAD
import '../../config/app_theme.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _Registrovista();
}

class _Registrovista extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService(); 

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); 
  final _dobController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false; 

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controladores táctiles para los enlaces de texto
  late TapGestureRecognizer _terminosRecognizer;
  late TapGestureRecognizer _privacidadRecognizer;

  @override
  void initState() {
    super.initState();
    
    // Configuramos la navegación de los enlaces de texto
    _terminosRecognizer = TapGestureRecognizer()..onTap = () {
      Navigator.push(context, _rutaHaciaInformacion(const TerminosScreen()));
    };
    
    _privacidadRecognizer = TapGestureRecognizer()..onTap = () {
      Navigator.push(context, _rutaHaciaInformacion(const AvisoPrivacidadScreen()));
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _terminosRecognizer.dispose();
    _privacidadRecognizer.dispose();
    super.dispose();
  }

  // --- ANIMACIÓN PARA IR A TÉRMINOS Y PRIVACIDAD ---
  Route _rutaHaciaInformacion(Widget vista) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => vista,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Entra desde la derecha
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // --- ANIMACIÓN PARA VOLVER AL LOGIN ---
  Route _rutaHaciaLogin(Widget vista) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => vista,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0); 
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // --- ANIMACIÓN PARA ENTRAR A LA AGENDA ---
  Route _rutaEntradaApp(Widget vista) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => vista,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          )
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textColor = const Color(0xFF1E2D3A);

    return Theme(
      data: KronosTheme.lightTheme,
      child: Scaffold(
        backgroundColor: KronosTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 90,
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Registrarse',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 30),
                    
                    _CustomLabelInput(
                      label: 'Nombre completo', 
                      controller: _nameController, 
                      maxLength: 30, 
                      validator: (value) => (value == null || value.isEmpty) ? 'El nombre es obligatorio' : null,
                    ),
                    const SizedBox(height: 15),

                    _CustomLabelInput(
                      label: 'Correo electrónico', 
                      controller: _emailController, 
                      keyboardType: TextInputType.emailAddress, 
                      maxLength: 30,
                      validator: (value) => (value == null || !value.contains('@')) ? 'Correo inválido' : null,
                    ),
                    const SizedBox(height: 15),

                    _CustomLabelInput(
                      label: 'Contraseña', 
                      controller: _passwordController, 
                      isPassword: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: textColor.withAlpha(150),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 15),

                    _CustomLabelInput(
                      label: 'Confirmar Contraseña', 
                      controller: _confirmPasswordController, 
                      isPassword: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: textColor.withAlpha(150),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Confirma tu contraseña';
                        if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    _CustomLabelInput(
                      label: 'Fecha de nacimiento', 
                      controller: _dobController, 
                      readOnly: true, 
                      onTap: _pickDate,
                      suffixIcon: Icon(Icons.calendar_today, size: 20, color: textColor.withAlpha(150)),
                      validator: (value) => (value == null || value.isEmpty) ? 'Fecha obligatoria' : null,
                    ),
                    const SizedBox(height: 30),

                    // TEXTO DE TÉRMINOS Y CONDICIONES
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
                          children: [
                            const TextSpan(text: 'Al registrarte, aceptas nuestros '),
                            TextSpan(
                              text: 'Términos y Condiciones',
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              recognizer: _terminosRecognizer,
                            ),
                            const TextSpan(text: ' y el '),
                            TextSpan(
                              text: 'Aviso de Privacidad',
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              recognizer: _privacidadRecognizer,
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: size.width * 0.5,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Registrarse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.withAlpha(80), thickness: 1.5)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("O registrarse con", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.withAlpha(80), thickness: 1.5)),
                      ],
                    ),
                    
                    const SizedBox(height: 25),

                    if (tieneGMS)
                      _buildSocialButton(
                        text: "Google",
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        borderColor: Colors.grey.shade300,
                        iconWidget: Image.asset('assets/images/google.png', height: 24, fit: BoxFit.contain), 
                        onTap: () async {
                          setState(() => _isLoading = true);
                          final error = await _authService.signInWithGoogle(
                            birthDate: _selectedDate,
                            name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
                          );
                          
                          if (!mounted) return;
                          setState(() => _isLoading = false);
                          
                          if (error == null) {
                            Navigator.pushReplacement(context, _rutaEntradaApp(const AgendaScreen()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
                          }
                        },
                      )
                    else
                      _buildSocialButton(
                        text: "Huawei ID",
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        borderColor: Colors.grey.shade300,
                        iconWidget: Image.asset('assets/images/huawei.png', height: 24, fit: BoxFit.contain), 
                        onTap: () async {
                          setState(() => _isLoading = true);
                          final error = await _authService.signInWithHuawei(
                            birthDate: _selectedDate,
                            name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
                          );
                          
                          if (!mounted) return;
                          setState(() => _isLoading = false);
                          
                          if (error == null) {
                            Navigator.pushReplacement(context, _rutaEntradaApp(const AgendaScreen()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
                          }
                        },
                      ),

                    const SizedBox(height: 35),

                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, _rutaHaciaLogin(const LoginScreen())),
                      child: Text(
                        'Ya estoy registrado', 
                        style: TextStyle(decoration: TextDecoration.underline, decorationColor: textColor, color: textColor, fontWeight: FontWeight.w500)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required String text, required Color backgroundColor, required Color textColor, required Color borderColor, required Widget iconWidget, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: borderColor, width: 1.5)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(data: KronosTheme.lightTheme, child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor selecciona tu fecha de nacimiento')));
        return;
      }
      setState(() => _isLoading = true);
      final error = await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        birthDate: _selectedDate!,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (error == null) {
        _mostrarDialogoVerificacion();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _mostrarDialogoVerificacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(
        data: KronosTheme.lightTheme,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.mark_email_unread_rounded, color: Color(0xFF5E81AC)), SizedBox(width: 10), Expanded(child: Text("Verificación Requerida", style: TextStyle(fontSize: 18, color: Color(0xFF1E2D3A))))]),
          content: const Column(mainAxisSize: MainAxisSize.min, children: [Text("Hemos enviado un enlace a tu correo. NO podrás usar la app hasta que lo verifiques.", style: TextStyle(fontSize: 15, color: Color(0xFF1E2D3A)))]),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut(); 
                if (!mounted) return;
                Navigator.pop(ctx); 
              },
              child: const Text("Corregir Correo", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2D3A), foregroundColor: Colors.white),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                await user?.reload(); 
                if (user != null && user.emailVerified) {
                  if (!mounted) return;
                  Navigator.pop(ctx); 
                  Navigator.pushAndRemoveUntil(context, _rutaEntradaApp(const AgendaScreen()), (route) => false);
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aún no has verificado tu correo.")));
                }
              },
              child: const Text("Ya lo verifiqué"),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomLabelInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final bool readOnly;       
  final VoidCallback? onTap; 
  final Widget? suffixIcon;  
  final int? maxLength; 

  const _CustomLabelInput({required this.label, required this.controller, this.keyboardType = TextInputType.text, this.isPassword = false, this.validator, this.readOnly = false, this.onTap, this.suffixIcon, this.maxLength});

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFF1E2D3A);
    final fillColor = Colors.white.withAlpha(128);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          validator: validator,
          readOnly: readOnly, 
          onTap: onTap,      
          maxLength: maxLength, 
          style: TextStyle(color: textColor),
          decoration: InputDecoration(filled: true, fillColor: fillColor, suffixIcon: suffixIcon, counterText: "", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        ),
      ],
    );
  }
}