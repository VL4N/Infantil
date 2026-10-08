import 'package:aprende_jugando/config.dart';
import 'package:aprende_jugando/logic/questions.dart';
import 'package:aprende_jugando/main.dart';
import 'package:aprende_jugando/screens/game_screen.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:aprende_jugando/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voz simulada: responde al instante, como si ya hubiera terminado de hablar.
final spoken = <String>[];

Future<void> startApp(WidgetTester tester, {bool premium = false}) async {
  spoken.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
    if (call.method == 'speak') spoken.add('${call.arguments is Map ? call.arguments['text'] : call.arguments}');
    return 1;
  });
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

Future<void> waitFor(WidgetTester tester, {int seconds = 3}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Respuesta correcta de la pregunta de suma en pantalla, para cualquier formato.
int mathAnswer(WidgetTester tester) {
  final prompt = tester.widget<Text>(find.byKey(const Key('prompt'))).data!;
  final n = RegExp(r'\d+').allMatches(prompt).map((m) => int.parse(m[0]!)).toList();
  if (prompt.contains('+ ?')) return n[1] - n[0];
  if (n.length == 2) return n[0] + n[1];
  // "¿Cuántos hay?": se cuentan los dibujos.
  return find.byKey(const Key('counted-object')).evaluate().length;
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
    expect(find.textContaining('Respuesta incorrecta'), findsOneWidget);

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
      await tester.tap(find.widgetWithText(InkWell, '${mathAnswer(tester)}'));
      await waitFor(tester);
    }
    expect(find.textContaining('10 de 10 a la primera'), findsOneWidget);
    expect(find.text('★★★'), findsOneWidget);
    expect(AppState.instance.stars, 10);

    // El mejor resultado queda guardado y se ve en el botón del nivel.
    await tester.tap(find.text('🏠 Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('➕  Sumar'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.widgetWithText(BigButton, '🐣 Hasta 5'), matching: find.text('★★★')), findsOneWidget);
    expect(find.descendant(of: find.widgetWithText(BigButton, '🐥 Hasta 10'), matching: find.text('☆☆☆')), findsOneWidget);
    await AppState.instance.load();
    expect(AppState.instance.bestFor('suma-5'), 3);
  });

  testWidgets('en "2 + ? = 5" el segundo grupo aparece al contar', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Sumar', progressKey: 'suma-10', makeQuestion: (r) => missingQuestion(r, 10)),
    ));
    await tester.pumpAndSettle();
    final answer = mathAnswer(tester);
    final prompt = tester.widget<Text>(find.byKey(const Key('prompt'))).data!;
    final a = int.parse(prompt.split(' ').first);
    expect(find.text('?'), findsOneWidget, reason: 'lo que falta está escondido');
    if (a + answer <= 10) expect(find.byKey(const Key('counted-object')), findsNWidgets(a));

    final wrong = find.descendant(
      of: find.byWidgetPredicate((w) => w is BigButton && w.label != '$answer' && w.key.toString().contains('option')),
      matching: find.byType(InkWell),
    ).first;
    await tester.tap(wrong);
    await waitFor(tester, seconds: 20);
    expect(spoken.last, contains('¡Toca el $answer!'));
    if (a + answer <= 10) expect(find.byKey(const Key('counted-object')), findsNWidgets(a + answer));
  });

  test('las estrellas de una partida dependen de los aciertos a la primera', () {
    expect([for (final c in [0, 1, 4, 5, 7, 8, 10]) AppState.starsFor(c)], [0, 1, 1, 2, 2, 3, 3]);
  });

  testWidgets('solo se guarda el mejor resultado', (tester) async {
    await startApp(tester);
    expect(AppState.instance.recordGame('ingles-animales', 6), 2);
    expect(AppState.instance.recordGame('ingles-animales', 2), 1);
    expect(AppState.instance.bestFor('ingles-animales'), 2);
  });

  testWidgets('si se equivoca, le explica, le señala la respuesta y luego repasa', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Sumar', progressKey: 'suma-5', makeQuestion: (r) => additionQuestion(r, 5)),
    ));
    await tester.pumpAndSettle();

    (int, int) current() {
      final prompt = tester.widget<Text>(find.textContaining('= ?')).data!;
      final n = RegExp(r'\d+').allMatches(prompt).map((m) => int.parse(m[0]!)).toList();
      return (n[0], n[1]);
    }

    final (a, b) = current();
    final wrongButton = find.descendant(
      of: find.byWidgetPredicate((w) => w is BigButton && w.label != '${a + b}' && w.key.toString().contains('option')),
      matching: find.byType(InkWell),
    ).first;
    await tester.tap(wrongButton);
    await tester.pump();
    expect(find.text('👂 Escucha…'), findsOneWidget);

    // Mientras explica, no se puede responder.
    await tester.tap(find.widgetWithText(InkWell, '${a + b}'));
    await tester.pump();
    expect(find.text('👂 Escucha…'), findsOneWidget);

    await waitFor(tester, seconds: 15);
    expect(find.text('👂 Escucha…'), findsNothing);
    expect(spoken, containsAll(['uno', 'dos', '$a más $b son ${a + b}. ¡Toca el ${a + b}!']));
    final correct = tester.widget<BigButton>(find.widgetWithText(BigButton, '${a + b}'));
    expect(correct.color, AppColors.yellow, reason: 'la respuesta correcta queda señalada');

    var sawReview = false;
    for (var round = 0; round < Config.roundsPerGame; round++) {
      if (find.text('🔁 Repaso').evaluate().isNotEmpty) {
        sawReview = true;
        expect(current(), (a, b), reason: 'el repaso repite la pregunta fallada');
      }
      final (x, y) = current();
      await tester.tap(find.widgetWithText(InkWell, '${x + y}'));
      await waitFor(tester);
    }
    expect(sawReview, isTrue);
    expect(find.textContaining('9 de 10 a la primera'), findsOneWidget);
  });
}
