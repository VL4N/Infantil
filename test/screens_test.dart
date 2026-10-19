import 'package:aprende_jugando/main.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:aprende_jugando/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantallas en las que se prueba la app (tamaño en puntos, como las ve Flutter).
const screens = {
  'teléfono pequeño': Size(320, 568),
  'teléfono normal': Size(360, 780),
  'teléfono grande': Size(430, 932),
  'tablet': Size(800, 1280),
};

/// Tamaños de letra del sistema: normal y "letra grande" de accesibilidad.
const textScales = [1.0, 1.3];

void main() {
  // De día ("Caramelo") y de noche ("Noche estrellada") las pantallas cambian.
  for (final night in [false, true]) {
    for (final MapEntry(key: name, value: size) in screens.entries) {
      for (final scale in textScales) {
        testWidgets('nada se corta ni se sale: $name, letra x$scale, ${night ? 'noche' : 'día'}', (tester) async {
          Palette.debugNight = night;
          addTearDown(() => Palette.debugNight = null);
          tester.view.physicalSize = size * 3;
          tester.view.devicePixelRatio = 3;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('flutter_tts'),
            (_) async => 1,
          );
          SharedPreferences.setMockInitialValues({'premium': true});
          await AppState.instance.load();
          await tester.pumpWidget(const AprendeJugandoApp());
          await tester.pumpAndSettle();

          Future<void> open(String text) async {
            // Como un usuario: hace scroll hasta ver el botón y lo toca.
            final target = find.textContaining(text);
            for (var i = 0; i < 20 && target.evaluate().isEmpty; i++) {
              await tester.drag(find.byType(ListView).last, const Offset(0, -200));
              await tester.pumpAndSettle();
            }
            await tester.ensureVisible(target.first);
            await tester.pumpAndSettle();
            await tester.tap(target.first);
            await tester.pumpAndSettle();
          }

          Future<void> back() async {
            await tester.pageBack();
            await tester.pumpAndSettle();
          }

          // Sumas: niveles y una partida de cada nivel.
          await open('Sumar');
          for (final level in ['Hasta 5', 'Hasta 10', 'Hasta 20']) {
            await open(level);
            await back();
          }
          await back();

          // Inglés: cada tema.
          await open('Inglés');
          for (final topic in ['Animales', 'Colores', 'Saludos', 'Familia']) {
            await open(topic);
            await back();
          }
          await back();

          // Juego de parejas.
          await open('Parejas');
          await back();
        });
      }
    }
  }
}
