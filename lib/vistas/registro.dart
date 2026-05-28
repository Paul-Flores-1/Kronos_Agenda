import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kronos/vistas/inicio.dart'; 
import '../services/auth_service.dart'; 
import 'agenda.dart';

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
  final _confirmPasswordController = TextEditingController(); // <-- Nueva: Confirmación
  final _dobController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false; 

  // Estados para la visibilidad de las contraseñas
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E2D3A),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Campo Nombre
                  _CustomLabelInput(
                    label: 'Nombre completo', 
                    controller: _nameController, 
                    maxLength: 30, 
                    validator: (value) => (value == null || value.isEmpty) ? 'El nombre es obligatorio' : null,
                  ),
                  const SizedBox(height: 15),

                  // Campo Correo
                  _CustomLabelInput(
                    label: 'Correo electrónico', 
                    controller: _emailController, 
                    keyboardType: TextInputType.emailAddress, 
                    maxLength: 30,
                    validator: (value) => (value == null || !value.contains('@')) ? 'Correo inválido' : null,
                  ),
                  const SizedBox(height: 15),

                  // Campo Contraseña con Ojito
                  _CustomLabelInput(
                    label: 'Contraseña', 
                    controller: _passwordController, 
                    isPassword: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFF1E2D3A),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 15),

                  // Campo Confirmar Contraseña con Ojito
                  _CustomLabelInput(
                    label: 'Confirmar Contraseña', 
                    controller: _confirmPasswordController, 
                    isPassword: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFF1E2D3A),
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

                  // Campo Fecha de Nacimiento
                  _CustomLabelInput(
                    label: 'Fecha de nacimiento', 
                    controller: _dobController, 
                    readOnly: true, 
                    onTap: _pickDate,
                    suffixIcon: const Icon(Icons.calendar_today, size: 20, color: Color(0xFF1E2D3A)),
                    validator: (value) => (value == null || value.isEmpty) ? 'Fecha obligatoria' : null,
                  ),
                  const SizedBox(height: 40),

                  // Botón Registrarse
                  SizedBox(
                    width: size.width * 0.5,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Registrarse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link Volver al Login
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                    child: const Text(
                      'Ya estoy registrado', 
                      style: TextStyle(decoration: TextDecoration.underline, color: Color(0xFF1E2D3A), fontWeight: FontWeight.w500)
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread_rounded, color: Color(0xFF5E81AC)),
            SizedBox(width: 10),
            Expanded(child: Text("Verificación Requerida", style: TextStyle(fontSize: 18))),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Hemos enviado un enlace a tu correo. NO podrás usar la app hasta que lo verifiques.",
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2D3A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              await user?.reload(); 
              
              if (user != null && user.emailVerified) {
                if (!mounted) return;
                Navigator.pop(ctx); 
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AgendaScreen()),
                  (route) => false,
                );
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Aún no has verificado tu correo."))
                );
              }
            },
            child: const Text("Ya lo verifiqué"),
          ),
        ],
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

  const _CustomLabelInput({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLength, 
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2D3A))
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          validator: validator,
          readOnly: readOnly, 
          onTap: onTap,      
          maxLength: maxLength, 
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withAlpha(128), // Sustituye withValues por withAlpha para compatibilidad
            suffixIcon: suffixIcon, 
            counterText: "", 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}