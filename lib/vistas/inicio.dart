import 'package:flutter/material.dart';
import 'package:kronos/vistas/registro.dart';
import 'package:kronos/vistas/agenda.dart'; 
import '../services/auth_service.dart';     

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
  // --- NUEVA VARIABLE PARA EL OJO ---
  bool _obscurePassword = true; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100, 
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                  
                  const SizedBox(height: 30),

                  Text(
                    'Iniciar sesión',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E2D3A),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // CAMPO CORREO
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

                  // CAMPO CONTRASEÑA CON EL OJO
                  _CustomLabelInput(
                    label: 'Contraseña',
                    controller: _passwordController,
                    isPassword: _obscurePassword, // Usa el estado dinámico
                    onChanged: (_) => _clearError(),
                    // --- BOTÓN DEL OJO AÑADIDO ---
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFF1E2D3A).withAlpha(150),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  // MENSAJE DE ERROR MODERNO
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _errorMessage != null
                        ? Container(
                            key: const ValueKey('error_msg'),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBF616A).withAlpha(30), 
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBF616A).withAlpha(60)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFBF616A), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFBF616A),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 35),

                  // BOTÓN INICIAR SESIÓN
                  SizedBox(
                    width: size.width * 0.5, 
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading 
                        ? const SizedBox(
                            height: 20, width: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          )
                        : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text(
                      'No tengo una cuenta',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Color(0xFF1E2D3A),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
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

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null; 
      });
      
      final error = await _authService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AgendaScreen()));
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
  final Widget? suffixIcon; // --- AÑADIDO ---

  const _CustomLabelInput({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.onChanged,
    this.suffixIcon, // --- AÑADIDO ---
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2D3A),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            // Soporte para versiones recientes y antiguas de Flutter
            fillColor: const Color(0xFFFFFFFF).withAlpha(128), 
            suffixIcon: suffixIcon, // --- ASIGNACIÓN AQUÍ ---
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, 
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}