import 'package:flutter/material.dart';

class KronosTheme {
  // Paleta de Colores
  static const Color backgroundLight = Color(0xFFA5BBC3);
  static const Color backgroundDark = Color(0xFF15202B);
  static const Color textLight = Color(0xFF1E2D3A);
  static const Color textDark = Color(0xFFE1E8ED);
  static const Color primaryButton = Color(0xFF9CC3FF);
  static const Color cardColorLight = Colors.white;
  static const Color cardColorDark = Color(0xFF1E2D3A);

  // --- MODO CLARO ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Poppins',
      
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textLight),
        bodyMedium: TextStyle(color: textLight),
        titleLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryButton,
          foregroundColor: textLight,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColorLight,
        elevation: 3,
        shadowColor: textLight.withValues(alpha: 0.1),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        hintStyle: TextStyle(color: textLight.withValues(alpha: 0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  // --- MODO OSCURO ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'Poppins',

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textDark),
        titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E81AC),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColorDark,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      iconTheme: const IconThemeData(color: textDark),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF273a4a),
        hintStyle: TextStyle(color: textDark.withValues(alpha: 0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      
      // SOLUCIÓN AL ERROR ROJO: 
      // Si tu versión de Flutter pide DialogThemeData, usamos esto.
      // Si te da error de nuevo, cámbialo por "DialogTheme" (sin Data).
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E2D3A),
        titleTextStyle: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: textDark, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      
      datePickerTheme: DatePickerThemeData(
        backgroundColor: const Color(0xFF1E2D3A),
        headerBackgroundColor: const Color(0xFF5E81AC),
        headerForegroundColor: Colors.white,
        dayStyle: const TextStyle(color: textDark),
        yearStyle: const TextStyle(color: textDark),
        dayForegroundColor: WidgetStateProperty.all(textDark),
      ),
    );
  }
}