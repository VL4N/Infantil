import 'dart:math';

import 'package:aprende_jugando/logic/tables.dart';
import 'package:aprende_jugando/main.dart' show AprendeJugandoApp;
import 'package:aprende_jugando/screens/game_screen.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show spoken, startApp, waitFor;

void main() {
  test('las preguntas de tablas y hasta 100 tienen una sola respuesta correcta', () {
    final r = Random(4);
    for (final level in tablesLevels) {
      for (var i = 0; i < 3000; i++) {
        final q = level.make(r);
        expect(q.options.toSet(), hasLength(3), reason: '${level.key}: ${q.prompt}');
        final n = RegExp(r'\d+').allMatches(q.prompt).map((m) => int.parse(m[0]!)).toList();
        final answer = int.parse(q.options[q.answerIndex]);
        final expected = q.prompt.contains('×') ? n[0] * n[1] : q.prompt.contains('+') ? n[0] + n[1] : n[0] - n[1];
        expect(answer, expected, reason: q.prompt);
        expect(q.options.every((o) => int.parse(o) >= 0 && int.parse(o) <= 100), isTrue);
      }
    }
  });

  testWidgets('al equivocarse en una tabla, Owlito cuenta de 3 en 3 y se ve la suma', (tester) async {
    await startApp(tester, prefs: {'ageGroup': 'big'});
    final q = tableQuestion(Random(1), [3]);
    await tester.pumpWidget(MaterialApp(home: GameScreen(title: 'Tablas', progressKey: 'tablas-3-4', makeQuestion: (_) => q)));
    await tester.pumpAndSettle();
    expect(spoken, [q.speech]);
    await tester.tap(find.byKey(Key('option-${(q.answerIndex + 1) % 3}')));
    await tester.pump();
    expect(find.byKey(const Key('tables-hint')), findsOneWidget);
    await waitFor(tester, seconds: 20);
    // Los grandes escuchan la explicación completa en las tablas (no la corta).
    expect(spoken, containsAllInOrder([q.tables!.explain.first.text, '3', q.tables!.explain.last.text]));
  });

  testWidgets('la sección Tablas solo está para los grandes', (tester) async {
    await startApp(tester, prefs: {'ageGroup': 'small'});
    await tester.pumpAndSettle();
    expect(find.text('Tablas'), findsNothing);
    AppState.instance.setAgeGroup(AgeGroup.big);
    await tester.pumpWidget(const AprendeJugandoApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tablas'), 200);
    await tester.tap(find.text('Tablas'));
    await tester.pumpAndSettle();
    expect(find.text('✖️ Tablas del 2, 5 y 10'), findsOneWidget);
    expect(find.textContaining('Tablas del 3 y 4'), findsOneWidget);
    expect(AppState.instance.canPlayTables('tablas-3-4'), isFalse, reason: 'las demás son Premium');
  });

  testWidgets('en un teléfono pequeño con letra grande nada se corta (tabla del 9 por 10)', (tester) async {
    tester.view.physicalSize = const Size(320, 568) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await startApp(tester, prefs: {'ageGroup': 'big', 'premium': true});
    var r = 0;
    late final q = () {
      for (;; r++) {
        final q = tableQuestion(Random(r), [9]);
        if (q.prompt.startsWith('9 × 10')) return q;
      }
    }();
    await tester.pumpWidget(MaterialApp(home: GameScreen(title: 'Tablas', progressKey: 'tablas-mix', makeQuestion: (_) => q)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(Key('option-${(q.answerIndex + 1) % 3}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('option-${(q.answerIndex + 1) % 3}')));
    await tester.pump();
    expect(find.text('9 + 9 + 9 + 9 + 9 + 9 + 9 + 9 + 9 + 9 = 90', skipOffstage: false), findsOneWidget);
    await waitFor(tester, seconds: 25);
  });
}
