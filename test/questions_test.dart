import 'dart:math';

import 'package:aprende_jugando/logic/content.dart';
import 'package:aprende_jugando/logic/questions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las sumas respetan el nivel y tienen una sola respuesta correcta', () {
    final r = Random(1);
    for (final max in [5, 10, 20]) {
      for (var i = 0; i < 500; i++) {
        final q = additionQuestion(r, max);
        final nums = RegExp(r'\d+').allMatches(q.prompt).map((m) => int.parse(m[0]!)).toList();
        final sum = nums[0] + nums[1];
        expect(nums.every((n) => n >= 1), isTrue);
        expect(sum, lessThanOrEqualTo(max));
        expect(q.answer, '$sum');
        expect(q.options.toSet().length, 3, reason: 'opciones repetidas: ${q.options}');
        expect(q.options.every((o) => int.parse(o) >= 0), isTrue);
        expect(q.addition!.sum, sum);
        expect(q.addition!.drawable, sum <= 10);
      }
    }
  });

  test('la respuesta correcta no es siempre el número del medio', () {
    final r = Random(4);
    final ranks = <int>{};
    for (var i = 0; i < 300; i++) {
      final q = additionQuestion(r, 10);
      final sorted = q.options.map(int.parse).toList()..sort();
      ranks.add(sorted.indexOf(int.parse(q.answer)));
    }
    expect(ranks, {0, 1, 2});
  });

  test('inglés: el dibujo correcto corresponde a la palabra', () {
    final r = Random(2);
    for (final topic in topics) {
      for (var i = 0; i < 200; i++) {
        final q = englishQuestion(r, topic);
        final pair = topic.words.firstWhere((w) => w.$1 == q.prompt);
        expect(q.answer, pair.$2);
        expect(q.options.toSet().length, 3);
        expect(q.speechLang, 'en');
      }
    }
  });

  test('al equivocarse en una suma pequeña, cuenta los dibujos uno a uno', () {
    final q = Question(
      prompt: '2 + 1 = ?', options: ['5', '3', '2'], answerIndex: 1,
      speech: '2 más 1', speechLang: 'es', addition: const Addition(2, 1, '🍎'),
    );
    final steps = explainMistake(q, 0);
    expect(steps.first.text, contains('Tocaste el 5'));
    expect([for (final s in steps) if (s.count != null) s.count], [1, 2, 3, 3]);
    expect(steps.where((s) => !s.highlightAnswer).map((s) => s.text), containsAll(['uno', 'dos', 'tres']));
    expect(steps.last.highlightAnswer, isTrue);
    expect(steps.last.text, contains('2 más 1 son 3'));
  });

  test('en sumas grandes cuenta hacia adelante desde el primer número', () {
    final q = Question(
      prompt: '12 + 3 = ?', options: ['15', '14', '17'], answerIndex: 0,
      speech: '12 más 3', speechLang: 'es', addition: const Addition(12, 3, '⭐'),
    );
    final counts = [for (final s in explainMistake(q, 1)) if (s.count != null) s.count];
    expect(counts, [12, 13, 14, 15, 15]);
  });

  test('en inglés dice cómo se llama lo que tocó y cuál era', () {
    final q = englishQuestion(Random(3), topics.first);
    final wrong = (q.answerIndex + 1) % 3;
    final steps = explainMistake(q, wrong);
    final english = [for (final s in steps) if (s.lang == 'en') s.text];
    expect(english, [q.optionWords![wrong], q.speech]);
    expect(steps.last.highlightAnswer, isTrue);
  });
}
