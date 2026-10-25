import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditarDatosScreen extends StatefulWidget {
  const EditarDatosScreen({super.key});

  @override
  State<EditarDatosScreen> createState() => _EditarDatosScreenState();
}

class _EditarDatosScreenState extends State<EditarDatosScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  DateTime? _selectedDate;
  
  // Variables para rastrear si el usuario modificó algo
  String _originalName = "";
  DateTime? _originalDate;

  bool _isLoadingData = true;
  bool _isSaving = false;

  // Controladores de la animación elegante (Igual que anadir.dart)
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _emailController = TextEditingController();

    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut, reverseCurve: Curves.easeOut)
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart, reverseCurve: Curves.easeIn)
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad, reverseCurve: Curves.easeInBack)
    );

    _animationController.forward();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        _originalName = data['nombre'] ?? '';
        _nameController.text = _originalName;
        
        _emailController.text = data['correo'] ?? user.email ?? '';
        
        if (data['fechaNacimiento'] != null) {
          _originalDate = (data['fechaNacimiento'] as Timestamp).toDate();
          _selectedDate = _originalDate;
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN PARA CERRAR CON ANIMACIÓN ---
  void _closeScreen() {
    if (_animationController.status == AnimationStatus.reverse || 
        _animationController.status == AnimationStatus.dismissed) {
      return;
    }
    _animationController.reverse().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  bool _haCambiado() {
    return _nameController.text.trim() != _originalName || _selectedDate != _originalDate;
  }

  void _intentarGuardar() {
    if (!_haCambiado()) {
      // Si no modificó nada, simplemente cerramos la vista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se detectaron cambios."), duration: Duration(seconds: 2))
      );
      _closeScreen();
      return;
    }

    if (_formKey.currentState!.validate()) {
      _mostrarDialogoConfirmacion();
    }
  }

  void _mostrarDialogoConfirmacion() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.save_rounded, color: Color(0xFF5E81AC)), 
            SizedBox(width: 12), 
            Text("Confirmar cambios")
          ]
        ),
        content: const Text("¿Estás seguro de que deseas actualizar tus datos personales?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E81AC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _guardarDatosEnFirebase();
            },
            child: const Text("Sí, actualizar"),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarDatosEnFirebase() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Actualizamos en Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'nombre': _nameController.text.trim(),
          'fechaNacimiento': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        });

        // Opcional: Actualizar el displayName de Auth
        await user.updateDisplayName(_nameController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Datos actualizados correctamente"), backgroundColor: Color(0xFF5E81AC))
          );
          _closeScreen();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        _closeScreen();
        return false; 
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // CABECERA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _closeScreen,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(76),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(50), width: 1),
                        ),
                        child: Icon(Icons.close_rounded, size: 20, color: theme.textTheme.bodyLarge?.color),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Mis Datos',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.textTheme.titleLarge?.color, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
      
              // FORMULARIO CON ANIMACIÓN COMPUESTA
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: _isLoadingData 
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5E81AC)))
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Nombre Completo"),
                                    _buildTextField(
                                      controller: _nameController,
                                      hint: "Escribe tu nombre",
                                      icon: Icons.person_outline_rounded,
                                      validator: (val) => val == null || val.isEmpty ? "Obligatorio" : null,
                                    ),
                                    const SizedBox(height: 22),

                                    _buildLabel("Correo Electrónico (Solo Lectura)"),
                                    _buildTextField(
                                      controller: _emailController,
                                      hint: "correo@ejemplo.com",
                                      icon: Icons.email_outlined,
                                      readOnly: true, // El correo se edita desde otra lógica por seguridad
                                    ),
                                    const SizedBox(height: 22),

                                    _buildLabel("Fecha de nacimiento"),
                                    GestureDetector(
                                      onTap: _pickDate,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC), 
                                          borderRadius: BorderRadius.circular(14), 
                                          border: Border.all(color: const Color(0xFFEEF2F7), width: 1.5)
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.cake_outlined, size: 18, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 10),
                                            Text(
                                              _selectedDate != null ? DateFormat('d MMMM yyyy', 'es_ES').format(_selectedDate!) : "Seleccionar fecha", 
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E2D3A))
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),

                                    // BOTÓN GUARDAR
                                    SizedBox(
                                      width: double.infinity, height: 54,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF5E81AC), 
                                          foregroundColor: Colors.white, 
                                          elevation: 0, 
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                        ),
                                        onPressed: _isSaving ? null : _intentarGuardar,
                                        icon: _isSaving 
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                          : const Icon(Icons.save_rounded, size: 20),
                                        label: const Text("Guardar Cambios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.7)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator
  }) {
    return TextFormField(
      controller: controller, 
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        fontWeight: FontWeight.w600, 
        fontSize: 15, 
        color: readOnly ? Colors.grey : const Color(0xFF1E2D3A)
      ), 
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        hintText: hint, 
        hintStyle: const TextStyle(color: Color(0xFFA0ADB8), fontSize: 14, fontWeight: FontWeight.normal),
        filled: true, 
        fillColor: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEEF2F7), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEEF2F7), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF99C2FF), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      )
    );
  }
}