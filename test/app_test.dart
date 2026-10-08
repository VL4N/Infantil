import 'package:aprende_jugando/config.dart';
import 'package:aprende_jugando/main.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> startApp(WidgetTester tester, {bool premium = false}) async {
  SharedPreferences.setMockInitialValues({'premium': premium});
  await AppState.instance.load();
  await tester.pumpWidget(const AprendeJugandoApp());
}

Future<void> answerGate(WidgetTester tester, {required bool correctly}) async {
  final q = tester.widget<Text>(find.textContaining('¿Cuánto es')).data!;
  final n = RegExp(r'\d+').allMatches(q).map((m) => int.parse(m[0]!)).toList();
  await tester.enterText(find.byKey(const Key('gate-input')), '${correctly ? n[0] * n[1] : 1}');
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el nivel de pago pide la pregunta para adultos', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('➕  Sumar'));
    await tester.pumpAndSettle();
    expect(find.text('🦅 Hasta 20 🔒'), findsOneWidget);
    expect(find.text('🐣 Hasta 5'), findsOneWidget);

    await tester.tap(find.text('🦅 Hasta 20 🔒'));
    await tester.pumpAndSettle();
    await answerGate(tester, correctly: false);
    expect(find.text('Aprende Jugando Premium'), findsNothing);

    await tester.tap(find.text('🦅 Hasta 20 🔒'));
    await tester.pumpAndSettle();
    await answerGate(tester, correctly: true);
    expect(find.text('Aprende Jugando Premium'), findsOneWidget);
    expect(find.text('Desbloquear por ${Config.fallbackPrice}'), findsOneWidget);
  });

  testWidgets('con Premium no hay candados', (tester) async {
    await startApp(tester, premium: true);
    await tester.tap(find.text('🇬🇧  Inglés'));
    await tester.pumpAndSettle();
    expect(find.textContaining('🔒'), findsNothing);
  });

  testWidgets('una partida completa de sumas termina con estrellas', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('➕  Sumar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🐣 Hasta 5'));
    await tester.pumpAndSettle();

    for (var i = 0; i < Config.roundsPerGame; i++) {
      final prompt = tester.widget<Text>(find.textContaining('= ?')).data!;
      final n = RegExp(r'\d+').allMatches(prompt).map((m) => int.parse(m[0]!)).toList();
      await tester.tap(find.widgetWithText(InkWell, '${n[0] + n[1]}'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('10 de 10 a la primera'), findsOneWidget);
    expect(AppState.instance.stars, 10);
  });
}
