import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logic/lang.dart';
import 'screens/language_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/profile_screen.dart';
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

class AprendeJugandoApp extends StatefulWidget {
  const AprendeJugandoApp({super.key});

  @override
  State<AprendeJugandoApp> createState() => _AprendeJugandoAppState();
}

/// De día la app usa el estilo "Caramelo" y de noche "Noche estrellada": se revisa la hora
/// cada minuto y al volver a la app.
class _AprendeJugandoAppState extends State<AprendeJugandoApp> with WidgetsBindingObserver {
  Palette _palette = Palette.at(DateTime.now());
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => _checkTime());
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkTime();
  }

  void _checkTime() {
    final palette = Palette.at(DateTime.now());
    if (palette != _palette) setState(() => _palette = palette);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: tr('Aprende Jugando', 'Learn & Play'),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(_palette),
      home: !AppState.instance.langChosen
          ? const LanguageScreen()
          : AppState.instance.profiles.length > 1
              ? const ProfilePickerScreen()
              : const MenuScreen(),
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
        color: Palette.day.bg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${tr('😕 Algo falló. Haz una captura y envíala:', '😕 Something went wrong. Take a screenshot and send it:')}\n\n$message',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Palette.day.ink, decoration: TextDecoration.none),
            ),
          ),
        ),
      ),
    );
  }
}
