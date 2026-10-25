import 'package:flutter/material.dart';
import 'package:kronos/vistas/auth/registro.dart';
import 'package:kronos/vistas/calendario/agenda.dart'; 
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';
import '../../main.dart';     

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService(); 

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage; 
  bool _obscurePassword = true; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Route _rutaHaciaRegistro(Widget vista) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => vista,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); 
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 100, child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)),
                    const SizedBox(height: 30),
                    Text('Iniciar sesión', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 40),

                    _CustomLabelInput(
                      label: 'Correo',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _clearError(),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa tu usuario';
                        if (!value.contains('@')) return 'Correo no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _CustomLabelInput(
                      label: 'Contraseña',
                      controller: _passwordController,
                      isPassword: _obscurePassword, 
                      onChanged: (_) => _clearError(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: textColor.withAlpha(150), size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _errorMessage != null
                          ? Container(
                              key: const ValueKey('error_msg'),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(color: const Color(0xFFBF616A).withAlpha(30), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBF616A).withAlpha(60))),
                              child: Row(children: [const Icon(Icons.error_outline_rounded, color: Color(0xFFBF616A), size: 20), const SizedBox(width: 12), Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFBF616A), fontWeight: FontWeight.w500, fontSize: 13)))]),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: size.width * 0.5, 
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.withAlpha(80), thickness: 1.5)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("O continuar con", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500))),
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

                          final error = await _authService.signInWithGoogle();
                          
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
                          final error = await _authService.signInWithHuawei();
                          
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
                      onTap: () => Navigator.pushReplacement(context, _rutaHaciaRegistro(const RegisterScreen())),
                      child: Text('No tengo una cuenta', style: TextStyle(decoration: TextDecoration.underline, decorationColor: textColor, color: textColor, fontWeight: FontWeight.w500, fontSize: 14)),
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
        style: ElevatedButton.styleFrom(backgroundColor: backgroundColor, foregroundColor: textColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: borderColor, width: 1.5))),
        onPressed: onTap,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [iconWidget, const SizedBox(width: 12), Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor))]),
      ),
    );
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _errorMessage = null; });
      final error = await _authService.loginUser(email: _emailController.text.trim(), password: _passwordController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (error == null) {
        Navigator.pushReplacement(context, _rutaEntradaApp(const AgendaScreen()));
      } else {
        setState(() => _errorMessage = error);
      }
    }
  }
}

class _CustomLabelInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final Function(String)? onChanged; 
  final Widget? suffixIcon; 

  const _CustomLabelInput({required this.label, required this.controller, this.keyboardType = TextInputType.text, this.isPassword = false, this.validator, this.onChanged, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFF1E2D3A);
    final fillColor = const Color(0xFFFFFFFF).withAlpha(128);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 4.0, bottom: 8.0), child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor))),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(filled: true, fillColor: fillColor, suffixIcon: suffixIcon, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        ),
      ],
    );
  }
}