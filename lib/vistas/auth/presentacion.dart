import 'package:flutter/material.dart';
import 'registro.dart';
import '../../config/app_theme.dart';

class Presentacionvista extends StatefulWidget {
  const Presentacionvista({super.key});

  @override
  State<Presentacionvista> createState() => _PresentacionvistaState();
}

class _PresentacionvistaState extends State<Presentacionvista> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _buttonOpacity;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animación del Logo (Aparece primero)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut))
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuart))
    );

    // Animación del Texto (Aparece un poco después)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.easeOut))
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuart))
    );

    // Animación del Botón (Aparece al final)
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut))
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOutQuart))
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- ANIMACIÓN ELEGANTE (ZOOM + FADE) PARA PASAR AL REGISTRO ---
  Route _rutaElegante(Widget vista) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (context, animation, secondaryAnimation) => vista,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut)
        );
        var scale = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
        );
        return FadeTransition(
          opacity: fade, 
          child: ScaleTransition(scale: scale, child: child)
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Theme(
      data: KronosTheme.lightTheme,
      child: Scaffold(
        backgroundColor: KronosTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: SizedBox(
              width: double.infinity, 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // IMAGEN (LOGO)
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Image.asset(
                          'assets/images/logo.png', 
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 56),

                  // TEXTO DE DESCRIPCIÓN
                  FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Text(
                        'Es tu asistente personal. \nPlanifica y cumple tus metas de forma natural y fluida.',
                        textAlign: TextAlign.center,
                        style: KronosTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          height: 1.5,
                          color: const Color(0xFF1E2D3A),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // BOTÓN "EMPEZAR"
                  FadeTransition(
                    opacity: _buttonOpacity,
                    child: SlideTransition(
                      position: _buttonSlide,
                      child: SizedBox(
                        width: size.width * 0.6,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              _rutaElegante(const RegisterScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Empezar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
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
}