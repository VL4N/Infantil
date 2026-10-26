import 'dart:math';

import 'package:aprende_jugando/logic/questions.dart';
import 'package:aprende_jugando/screens/game_screen.dart';
import 'package:aprende_jugando/screens/menu_screen.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:aprende_jugando/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show spoken, startApp, waitFor;

void main() {
  /// Toca una opción equivocada de la suma que está en pantalla.
  Future<void> tapWrong(WidgetTester tester, Question q) async {
    await tester.tap(find.byKey(Key('option-${(q.answerIndex + 1) % q.options.length}')));
  }

  Widget sumGame(Question q) => MaterialApp(home: GameScreen(title: 'Sumar', progressKey: 'suma-10', makeQuestion: (_) => q));

  testWidgets('a los grandes, la explicación de un error es corta (sin contar todo)', (tester) async {
    final q = mathQuestion(Random(3), 10);
    final full = explainMistake(q, (q.answerIndex + 1) % q.options.length);
    final short = full.skipWhile((s) => !s.highlightAnswer).toList();
    expect(short.length, lessThan(full.length));

    await startApp(tester, prefs: {'ageGroup': 'big'});
    await tester.pumpWidget(sumGame(q));
    await tester.pumpAndSettle();
    spoken.clear();
    await tapWrong(tester, q);
    await waitFor(tester, seconds: 12);
    expect(spoken.first, short.first.text, reason: 'empieza directo con la respuesta');
    expect(spoken, isNot(contains(full.first.text)));
  });

  testWidgets('a los pequeños, la explicación completa; y "Ya entendí" la salta', (tester) async {
    final q = mathQuestion(Random(3), 10);
    final full = explainMistake(q, (q.answerIndex + 1) % q.options.length);

    await startApp(tester);
    await tester.pumpWidget(sumGame(q));
    await tester.pumpAndSettle();
    spoken.clear();
    await tapWrong(tester, q);
    await tester.pump(const Duration(milliseconds: 500));
    expect(spoken.first, full.first.text);
    expect(find.byKey(const Key('skip-explanation')), findsNothing, reason: 'aparece después de un momento');
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('skip-explanation')), findsOneWidget);
    await tester.tap(find.byKey(const Key('skip-explanation')));
    await tester.pump();
    final saidBefore = spoken.length;
    await waitFor(tester, seconds: 5);
    expect(spoken.length, saidBefore, reason: 'ya no sigue explicando');
    // Se puede tocar la respuesta enseguida.
    await tester.tap(find.byKey(Key('option-${q.answerIndex}')));
    await waitFor(tester);
    expect(find.text('👍'), findsNothing);
  });

  testWidgets('la primera vez se pregunta la edad; los niveles de su edad dicen "Para tu edad"', (tester) async {
    await startApp(tester, prefs: {'ageGroup': ''});
    SharedPreferences.setMockInitialValues({'lang': 'es'});
    await AppState.instance.load();
    expect(AppState.instance.ageGroup, isNull);
    await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('age-card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('age-big')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('age-card')), findsNothing);
    await AppState.instance.load();
    expect(AppState.instance.ageGroup, AgeGroup.big);

    await tester.pumpWidget(const MaterialApp(home: MathLevelsScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('for-your-age-suma-20')), findsOneWidget);
    expect(find.byKey(const Key('for-your-age-suma-5')), findsNothing);
    expect(tester.getSize(find.byType(BigButton).last).width, 800 - 40,
        reason: 'la marca no cambia el ancho del botón');
  });

  test('cada niño tiene su edad', () async {
    SharedPreferences.setMockInitialValues({'lang': 'es', 'ageGroup': 'small'});
    final state = AppState.instance;
    await state.load();
    final id = state.addProfile('Mateo', age: AgeGroup.big)!;
    expect(state.ageOf(0), AgeGroup.small);
    expect(state.ageOf(id), AgeGroup.big);
    state.switchProfile(id);
    expect(state.isBig, isTrue);
    state.setAgeOf(0, AgeGroup.big);
    state.switchProfile(0);
    expect(state.isBig, isTrue);
  });

  testWidgets('a los grandes no se les muestran los niveles de pequeños, y tienen gratis los de su edad', (tester) async {
    await startApp(tester, prefs: {'ageGroup': 'big'});
    final state = AppState.instance;
    expect(state.hidden('suma-5'), isTrue);
    expect(state.canPlayNumbers('sigue-20'), isTrue);
    expect(state.canPlayLetters('letras-minuscula'), isTrue);
    expect(state.canPlayLetters('letras-leer'), isFalse, reason: 'sigue siendo Premium');
    await tester.pumpWidget(const MaterialApp(home: MathLevelsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('🐣 Hasta 5'), findsNothing);
    expect(find.text('🐥 Hasta 10'), findsOneWidget);

    // Los pequeños ven todo.
    state.setAgeGroup(AgeGroup.small);
    await tester.pumpWidget(const MaterialApp(home: NumbersScreen()));
    await tester.pumpAndSettle();
    expect(state.hidden('sigue-10'), isFalse);
    expect(state.canPlayNumbers('sigue-20'), isFalse);
  });
}
