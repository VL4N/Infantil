import 'dart:math';

import 'package:aprende_jugando/logic/lang.dart';
import 'package:aprende_jugando/logic/letters.dart';
import 'package:aprende_jugando/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show spoken, startApp, waitFor;

void main() {
  tearDown(() => Lang.current = AppLang.es);

  for (final lang in AppLang.values) {
    test('las preguntas de letras tienen una sola respuesta correcta (${lang.name})', () {
      Lang.current = lang;
      final r = Random(5);
      expect(alphabet.length, lang == AppLang.es ? 27 : 26);
      for (final level in letterLevels) {
        for (var i = 0; i < 1500; i++) {
          final q = level.make(r);
          expect(q.options.toSet(), hasLength(3), reason: '${level.key}: opciones distintas');
          expect(q.letters, isNotNull);
          final answer = q.options[q.answerIndex];
          switch (level.key) {
            case 'letras-empieza':
              expect(q.letters!.display, startsWith('_'));
              expect(firstLetter('${answer.toLowerCase()}${q.letters!.display.substring(1)}').upper, answer);
            case 'letras-minuscula':
              expect(answer, q.letters!.display.toLowerCase());
            case 'letras-leer':
              expect(q.letters!.words, isTrue);
            case 'letras-frase':
              final group = sentenceGroups.firstWhere((g) => g.any((s) => tr(s.es, s.en) == q.letters!.display));
              expect(group.firstWhere((s) => tr(s.es, s.en) == q.letters!.display).picture, answer);
            case 'letras-completa':
              expect(q.letters!.display, contains('___'));
              expect(blanks.firstWhere((b) => b.text == q.letters!.display).answer, answer);
          }
        }
      }
    });

    test('las palabras para leer empiezan con una letra que suena (${lang.name})', () {
      Lang.current = lang;
      final words = readingWords;
      expect(words.length, greaterThan(40));
      for (final w in words) {
        expect(w.word.contains(' '), isFalse);
        if (lang == AppLang.es) expect(w.word.toLowerCase().startsWith('h'), isFalse, reason: 'la hache es muda');
        expect(firstLetter(w.word).upper, isNotEmpty);
      }
    });
  }

  testWidgets('al equivocarse en "¿Con qué letra empieza?", Owlito dice la letra correcta', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Letras', progressKey: 'letras-empieza', makeQuestion: (r) => startsWithQuestion(Random(1))),
    ));
    await tester.pumpAndSettle();
    final q = startsWithQuestion(Random(1));
    expect(spoken, [q.speech]);
    expect(find.text(q.letters!.display), findsOneWidget);
    expect(find.byKey(const Key('letters-picture')), findsOneWidget);
    await tester.tap(find.byKey(Key('option-${(q.answerIndex + 1) % 3}')));
    await waitFor(tester, seconds: 8);
    expect(spoken, contains(q.letters!.explain.single));
    await tester.tap(find.byKey(Key('option-${q.answerIndex}')));
    await waitFor(tester, seconds: 4);
    expect(spoken, contains(q.letters!.praise));
  });

  testWidgets('"Lee la palabra" muestra el dibujo y cada palabra una sola vez', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Letras', progressKey: 'letras-leer', makeQuestion: (r) => readWordQuestion(Random(2))),
    ));
    await tester.pumpAndSettle();
    final q = readWordQuestion(Random(2));
    expect(find.byKey(const Key('letters-picture')), findsOneWidget);
    for (final o in q.options) {
      await tester.scrollUntilVisible(find.text(o), 100);
      expect(find.text(o), findsOneWidget);
    }
  });
}
