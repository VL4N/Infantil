import 'dart:async';

import 'package:aprende_jugando/logic/lang.dart';
import 'package:aprende_jugando/main.dart' as app;
import 'package:aprende_jugando/services/voice.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la app se muestra aunque el motor de voz del teléfono no responda', (tester) async {
    // startApp() cambia la pantalla de error; se restaura al terminar la prueba.
    final originalErrorBuilder = ErrorWidget.builder;
    // Teléfono cuyo motor de voz nunca termina de arrancar: ninguna llamada responde.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) => Completer<Object?>().future,
    );
    SharedPreferences.setMockInitialValues({'lang': 'es'});

    await tester.runAsync(() async {
      // Antes, el arranque esperaba a la voz y nunca llegaba a mostrar la app (pantalla negra).
      await app.startApp().timeout(const Duration(seconds: 5));
    });
    await tester.pump();

    expect(find.text('Aprende Jugando'), findsOneWidget);

    // Sin voz lista, hablar no bloquea el juego.
    await tester.runAsync(() => Voice.say('hola', 'es').timeout(const Duration(seconds: 1)));
    ErrorWidget.builder = originalErrorBuilder;
  });

  testWidgets('si una pantalla falla, se ve el mensaje del error', (tester) async {
    Lang.current = AppLang.es;
    await tester.pumpWidget(const app.ErrorInfo(message: 'prueba de error'));
    expect(find.textContaining('prueba de error'), findsOneWidget);
    expect(find.textContaining('Haz una captura'), findsOneWidget);
  });
}
