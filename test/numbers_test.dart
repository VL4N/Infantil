import 'dart:math';

import 'package:aprende_jugando/logic/numbers.dart';
import 'package:aprende_jugando/logic/questions.dart';
import 'package:aprende_jugando/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show spoken, startApp, waitFor;

void main() {
  test('"¿Qué número sigue?": la respuesta sigue la serie y no pasa del máximo', () {
    final r = Random(1);
    for (final (max, step) in [(10, 1), (20, 1), (20, 2)]) {
      for (var i = 0; i < 2000; i++) {
        final q = sequenceQuestion(r, max, step);
        final seq = q.sequence!;
        expect(seq.numbers.length, 3);
        expect(seq.numbers[1] - seq.numbers[0], step);
        expect(seq.numbers.first, greaterThanOrEqualTo(step == 1 ? 1 : 0));
        if (step == 2) expect(seq.numbers.first.isEven, isTrue, reason: 'de 2 en 2 va por los pares');
        expect(seq.next, lessThanOrEqualTo(max));
        expect(q.answer, '${seq.next}');
        expect(q.options.toSet().length, 3, reason: 'opciones distintas');
        expect(q.options.every((o) => int.parse(o) >= 0 && int.parse(o) <= maxOption), isTrue);
      }
    }
  });

  test('"¿Cuál es mayor?": dos números distintos y la respuesta es el mayor', () {
    final r = Random(2);
    for (final top in [10, 20]) {
      for (var i = 0; i < 2000; i++) {
        final q = compareQuestion(r, top);
        final c = q.comparison!;
        expect(c.a, isNot(c.b));
        expect(c.a <= top && c.b <= top && c.a >= 1 && c.b >= 1, isTrue);
        expect(q.answer, '${max(c.a, c.b)}');
        expect(c.object != null, top <= 10, reason: 'hasta 10 se ven dibujos');
      }
    }
  });

  testWidgets('al equivocarse en la serie, Owlito cuenta y dice cuál sigue', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Números', progressKey: 'sigue-10', makeQuestion: (r) => sequenceQuestion(r, 10, 1)),
    ));
    await tester.pumpAndSettle();
    expect(spoken, ['¿Qué número sigue?']);
    expect(find.byKey(const ValueKey('sequence-3')), findsOneWidget, reason: 'tres números y el "?"');
    expect(find.text('+1'), findsNWidgets(3), reason: 'se ve el salto entre número y número');
    expect(find.text('?'), findsOneWidget);
    final options = [for (var i = 0; i < 3; i++) tester.widget<Text>(find.descendant(of: find.byKey(Key('option-$i')), matching: find.byType(Text))).data!];
    final seqText = [for (final e in find.descendant(of: find.byKey(const Key('prompt')), matching: find.byType(Text)).evaluate()) (e.widget as Text).data!];
    final next = int.parse(seqText[2]) + 1;
    await tester.tap(find.byKey(Key('option-${options.indexWhere((o) => o != '$next')}')));
    await waitFor(tester, seconds: 15);
    expect(spoken, containsAllInOrder(['¡Vamos a contar juntos!', '¡Toca el $next!']));
  });

  testWidgets('"¿Cuál es mayor?" con dibujos muestra los dos grupos', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Números', progressKey: 'mayor-10', makeQuestion: (r) => compareQuestion(r, 10)),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('compare-side')), findsNWidgets(2));
    expect(spoken, ['¿Cuál es mayor?']);
  });
}
