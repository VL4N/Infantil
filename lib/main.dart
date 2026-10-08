import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/menu_screen.dart';
import 'services/ads.dart';
import 'services/app_state.dart';
import 'services/billing.dart';
import 'services/voice.dart';
import 'theme.dart';

Future<void> main() async {
  await startApp();
  // Tienda y anuncios cargan en segundo plano: nunca deben retrasar la primera pantalla.
  Billing.instance.init();
  Ads.init();
}

/// Lo necesario para mostrar la primera pantalla (separado de main() para probarlo).
Future<void> startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Si una pantalla falla, se muestra el error en vez de un recuadro vacío,
  // para poder mandar una captura y arreglarlo.
  ErrorWidget.builder = (details) => ErrorInfo(message: '${details.exception}');
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await AppState.instance.load().timeout(const Duration(seconds: 3));
  } catch (_) {
    // Si el progreso guardado no carga, se empieza de cero antes que no mostrar nada.
  }
  runApp(const AprendeJugandoApp());
  // La voz carga en segundo plano: si el motor de voz no responde, antes la app
  // se quedaba en negro esperándolo.
  Voice.init();
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

/// Pantalla que se muestra si algo falla al dibujar una pantalla.
class ErrorInfo extends StatelessWidget {
  const ErrorInfo({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: AppColors.bg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '😕 Algo falló. Haz una captura y envíala:\n\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.ink, decoration: TextDecoration.none),
            ),
          ),
        ),
      ),
    );
  }
}
