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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await AppState.instance.load();
  await Voice.init();
  runApp(const AprendeJugandoApp());
  // Tienda y anuncios cargan en segundo plano para no retrasar el arranque.
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
