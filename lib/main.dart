import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; 
import 'package:kronos/vistas/calendario/agenda.dart';
import 'package:kronos/vistas/auth/presentacion.dart';   
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_api_availability/google_api_availability.dart'; 
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'config/app_theme.dart'; 
import 'providers/eventos_provider.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

bool tieneGMS = false; 

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('es_MX', null);

  try {
    GooglePlayServicesAvailability status = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
    tieneGMS = (status == GooglePlayServicesAvailability.success);
    debugPrint("Detección de entorno: GMS -> $tieneGMS");
  } catch (e) {
    tieneGMS = false;
  }

  await Firebase.initializeApp();
  await NotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('modoOscuro') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  
  User? initialUser = FirebaseAuth.instance.currentUser;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventosProvider()),
      ],
      child: KronosApp(initialUser: initialUser),
    ),
  );

  FlutterNativeSplash.remove();
}

class KronosApp extends StatelessWidget {
  final User? initialUser;
  const KronosApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'KRONOS Agenda',
          theme: KronosTheme.lightTheme,      
          darkTheme: KronosTheme.darkTheme,   
          themeMode: currentMode, 

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'MX'), 
            Locale('es', 'ES'),
          ],
          locale: const Locale('es', 'MX'), 

          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
              child: child!,
            );
          },

          home: initialUser != null ? const AgendaScreen() : const Presentacionvista(),
        );
      },
    );
  }
}