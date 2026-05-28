import 'package:flutter/material.dart';
import 'registro.dart';
//import 'package:kronos/screens/login_screen.dart'; // Asegúrate de que esta ruta sea correcta según tu estructura


class Presentacionvista extends StatelessWidget {
  const Presentacionvista({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tema para usar los estilos de texto
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: SizedBox(
            // CORRECCIÓN CLAVE: Esto obliga a la columna a ocupar todo el ancho
            width: double.infinity, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centrado Vertical
              crossAxisAlignment: CrossAxisAlignment.center, // Centrado Horizontal de los hijos
              children: [
                // 1. Imagen (Logo)
                FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Image.asset(
                    'assets/images/logo.png', 
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 40),


                const SizedBox(height: 16),

                // 3. Texto de descripción
                Text(
                  'Es tu asistente personal. \nPlanifica y cumple tus metas de forma natural y fluida.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 60),

                // 4. Botón "Empezar"
                SizedBox(
                  width: size.width * 0.6,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const RegisterScreen()),
  );
                    },
                    child: const Text(
                      'Empezar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}