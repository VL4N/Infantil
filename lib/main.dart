import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/menu_screen.dart';
import 'services/ads.dart';
import 'services/app_state.dart';
import 'services/billing.dart';
import 'services/voice.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await AppState.instance.load().timeout(const Duration(seconds: 3));
  } catch (_) {
    // Si el progreso guardado no carga, se empieza de cero antes que no mostrar nada.
  }
  runApp(const AprendeJugandoApp());
  // Voz, tienda y anuncios cargan en segundo plano: nunca deben retrasar la
  // primera pantalla (si el motor de voz no responde, la app se quedaba en negro).
  Voice.init();
  Billing.instance.init();
  Ads.init();
}

class AprendeJugandoApp extends StatelessWidget {
  const AprendeJugandoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aprende Jugando',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MenuScreen(),
    );
  }
}
