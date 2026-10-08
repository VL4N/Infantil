import 'dart:async';

import 'package:aprende_jugando/main.dart' as app;
import 'package:aprende_jugando/services/voice.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la app se muestra aunque el motor de voz del teléfono no responda', (tester) async {
    // Teléfono cuyo motor de voz nunca termina de arrancar: ninguna llamada responde.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) => Completer<Object?>().future,
    );
    SharedPreferences.setMockInitialValues({});

    await tester.runAsync(() async {
      // Antes, main() esperaba a la voz y nunca llegaba a mostrar la app (pantalla negra).
      await app.main().timeout(const Duration(seconds: 5));
    });
    await tester.pump();

    expect(find.text('¿Qué quieres aprender hoy?'), findsOneWidget);

    // Sin voz lista, hablar no bloquea el juego.
    await tester.runAsync(() => Voice.say('hola', 'es').timeout(const Duration(seconds: 1)));
  });
}
