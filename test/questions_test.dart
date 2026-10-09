import 'dart:math';

import 'package:aprende_jugando/logic/content.dart';
import 'package:aprende_jugando/logic/questions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _countSaysWhat();

  test('en una partida no se repiten preguntas ni palabras', () {
    for (final (max, _) in mathLevels) {
      _noRepeats('Sumar $max', (r) => mathQuestion(r, max));
    }
    for (final topic in topics) {
      _noRepeats(topic.key, (r) => englishMixedQuestion(r, topic));
    }
  });

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

  test('"¿Cuántos hay?" y "2 + ? = 5" tienen una sola respuesta correcta', () {
    final r = Random(5);
    for (var i = 0; i < 500; i++) {
      final c = countQuestion(r, 5);
      expect(c.addition!.kind, AddKind.count);
      expect(c.answer, '${c.addition!.a}');
      expect(c.addition!.a, inInclusiveRange(1, 5));
      expect(c.options.toSet().length, 3);
      expect(c.options.every((o) => int.parse(o) >= 1), isTrue);

      for (final max in [10, 20]) {
        final m = missingQuestion(r, max);
        final add = m.addition!;
        expect(m.prompt, '${add.a} + ? = ${add.sum}');
        expect(m.answer, '${add.b}');
        expect(add.sum, lessThanOrEqualTo(max));
        expect(m.options.toSet().length, 3);
        expect(m.options.every((o) => int.parse(o) >= 0), isTrue);
      }
    }
  });

  test('cada nivel mezcla formatos: contar en "Hasta 5", lo que falta en los demás', () {
    final r = Random(6);
    Set<AddKind> kinds(int max) => {for (var i = 0; i < 200; i++) mathQuestion(r, max).addition!.kind};
    expect(kinds(5), {AddKind.sum, AddKind.count});
    expect(kinds(10), {AddKind.sum, AddKind.missing});
    expect(kinds(20), {AddKind.sum, AddKind.missing});
  });

  test('al equivocarse en "¿Cuántos hay?" cuenta los dibujos', () {
    final q = Question(
      prompt: '¿Cuántos hay?', options: ['2', '3', '4'], answerIndex: 1,
      speech: '¿Cuántos hay?', speechLang: 'es', addition: const Addition(3, 0, '🍎', kind: AddKind.count),
    );
    final steps = explainMistake(q, 0);
    expect([for (final s in steps) if (s.count != null) s.count], [1, 2, 3, 3]);
    expect(steps.last.text, 'Hay 3. ¡Toca el 3!');
  });

  test('al equivocarse en "2 + ? = 5" cuenta desde el 2 hasta el 5', () {
    final q = Question(
      prompt: '2 + ? = 5', options: ['3', '5', '2'], answerIndex: 0,
      speech: '2 más cuánto es 5', speechLang: 'es', addition: const Addition(2, 3, '⭐', kind: AddKind.missing),
    );
    final steps = explainMistake(q, 1);
    expect([for (final s in steps) if (s.count != null) s.count], [2, 3, 4, 5, 5]);
    expect(steps.last.text, contains('¡Toca el 3!'));
  });

  test('cada tema de inglés tiene palabras y dibujos sin repetir, y alcanza para las parejas', () {
    for (final topic in topics) {
      expect(topic.words.length, greaterThanOrEqualTo(8), reason: topic.key);
      expect({for (final w in topic.words) w.$1}.length, topic.words.length, reason: topic.key);
      expect({for (final w in topic.words) w.$2}.length, topic.words.length, reason: topic.key);
      expect(topic.words.every((w) => !w.$2.contains(' ')), isTrue, reason: 'los dibujos no llevan espacios');
    }
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

  test('inglés al revés: el dibujo se muestra y se elige la palabra', () {
    final r = Random(7);
    for (final topic in topics) {
      for (var i = 0; i < 200; i++) {
        final q = englishWordQuestion(r, topic);
        final pair = topic.words.firstWhere((w) => w.$2 == q.prompt);
        expect(q.answer, pair.$1);
        expect(q.speech, pair.$1);
        expect(q.ask, 'What is this?', reason: 'la voz no dice la respuesta al empezar');
        expect(q.options.toSet().length, 3);
        expect(q.pictureOptions, isFalse);
      }
    }
  });

  test('los temas de inglés mezclan los tres formatos', () {
    final r = Random(8);
    final qs = [for (var i = 0; i < 200; i++) englishMixedQuestion(r, topics.first)];
    expect(qs.any((q) => q.pictureOptions), isTrue);
    expect(qs.any((q) => !q.pictureOptions && q.count == null), isTrue);
    expect(qs.any((q) => q.count != null), isTrue);
  });

  test('"How many?": se cuentan los dibujos y se elige el número en inglés', () {
    final r = Random(10);
    for (final topic in topics) {
      final max = topic.key == 'numeros' ? 10 : 5;
      for (var i = 0; i < 200; i++) {
        final q = englishCountQuestion(r, topic);
        final n = q.count!;
        expect(n, inInclusiveRange(1, max));
        expect(q.prompt.split(' ').length, n);
        expect(q.answer, englishNumbers[n - 1]);
        expect(q.ask, 'How many?');
        expect(q.options.toSet().length, 3);
        expect(q.options.every(englishNumbers.contains), isTrue);
      }
    }
  });

  test('al equivocarse en "How many?" cuenta en inglés', () {
    final q = Question(
      prompt: '🐶 🐶 🐶', options: ['two', 'three', 'four'], optionWords: ['two', 'three', 'four'], answerIndex: 1,
      speech: 'three', ask: 'How many?', count: 3, speechLang: 'en',
    );
    final steps = explainMistake(q, 2);
    expect([for (final s in steps) if (s.lang == 'en') s.text], ['four', 'one', 'two', 'three']);
    expect([for (final s in steps) if (s.count != null) s.count], [1, 2, 3]);
    expect(steps.last.highlightAnswer, isTrue);
  });

  test('al equivocarse en "elige la palabra" dice lo que tocó y cómo se dice el dibujo', () {
    final q = englishWordQuestion(Random(9), topics.first);
    final wrong = (q.answerIndex + 1) % 3;
    final steps = explainMistake(q, wrong);
    expect([for (final s in steps) if (s.lang == 'en') s.text], [q.options[wrong], q.answer]);
    expect(steps.last.highlightAnswer, isTrue);
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

void _noRepeats(String name, QuestionMaker make) {
  final r = Random(7);
  for (var game = 0; game < 300; game++) {
    final seen = <String>{};
    final keys = [for (var i = 0; i < 10; i++) questionKey(freshQuestion(make, r, seen))];
    expect(keys.toSet().length, keys.length, reason: '$name repite en una partida: $keys');
  }
}

void _countSaysWhat() {
  test('al contar, la voz dice qué se cuenta ("¿Cuántas manzanas hay?")', () {
    final r = Random(3);
    for (var i = 0; i < 200; i++) {
      final q = countQuestion(r, 5);
      expect(q.speech, matches(RegExp(r'^¿Cuánt[oa]s \w+ hay\?$')), reason: q.speech);
      expect(q.prompt, q.speech);
    }
  });
}
