import 'package:aprende_jugando/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Se ejecuta en emuladores Android de varias versiones (ver
/// .github/workflows/emuladores.yml): abre la app de verdad y juega un poco.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitFor(WidgetTester tester, Finder finder, {int seconds = 20}) async {
    for (var i = 0; i < seconds * 4 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(finder, findsWidgets, reason: 'no apareció a tiempo (¿pantalla negra?)');
  }

  testWidgets('la app abre, muestra el menú y se puede jugar', (tester) async {
    // main() cambia la pantalla de error; se restaura al final de la prueba.
    final originalErrorBuilder = ErrorWidget.builder;
    await app.main();
    await waitFor(tester, find.text('Aprende Jugando'));

    // Sumas.
    await tester.tap(find.textContaining('Sumar'));
    await waitFor(tester, find.textContaining('Hasta 5'));
    await tester.tap(find.textContaining('Hasta 5'));
    await waitFor(tester, find.byType(LinearProgressIndicator));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await waitFor(tester, find.text('Aprende Jugando'));

    // Inglés.
    await tester.tap(find.textContaining('Inglés').first);
    await waitFor(tester, find.textContaining('Animales'));
    await tester.tap(find.textContaining('Animales'));
    await waitFor(tester, find.byType(LinearProgressIndicator));

    ErrorWidget.builder = originalErrorBuilder;
  });
}
