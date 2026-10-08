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
        expect(q.visual != null, sum <= 10);
      }
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
}
