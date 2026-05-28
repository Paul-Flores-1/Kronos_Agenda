import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kronos/vistas/agenda.dart';
import 'package:kronos/vistas/presentacion.dart';   
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [IMPORTANTE] Importamos el archivo de temas que creamos
import 'config/app_theme.dart'; 

// VARIABLE GLOBAL PARA EL TEMA
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await Firebase.initializeApp();
  await NotificationService.init();

  // Cargar preferencia guardada
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('modoOscuro') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  
  runApp(const KronosApp());
}

class KronosApp extends StatelessWidget {
  const KronosApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de tema
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'KRONOS Agenda',
          
          // [CAMBIO] Usamos los temas definidos en app_theme.dart
          theme: KronosTheme.lightTheme,      
          darkTheme: KronosTheme.darkTheme,   
          
          themeMode: currentMode, // Modo dinámico

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'),
          ],
          locale: const Locale('es', 'ES'), 

          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => user != null 
            ? const AgendaScreen() 
            : const Presentacionvista(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [SOLUCIÓN] Forzamos el color AQUÍ. 
      // Al poner un color explícito, ignora el tema oscuro (Theme.of(context).scaffoldBackgroundColor).
      backgroundColor: const Color(0xFFA5BBC3), 
      
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.4,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}