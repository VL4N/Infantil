import 'dart:math';

import 'content.dart';

const _objects = ['🍎', '⭐', '🐟', '🎈', '🍓', '🐞', '🚗', '🌸'];

class Question {
  const Question({
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.speech,
    required this.speechLang,
    this.visual,
    this.pictureOptions = false,
  });

  /// Texto grande de la pregunta ("2 + 3 = ?" o "dog").
  final String prompt;

  /// Dibujos para contar, p. ej. ("🍎🍎", "🍎🍎🍎").
  final (String, String)? visual;
  final List<String> options;
  final int answerIndex;
  final String speech;
  final String speechLang;

  /// Las opciones son dibujos (más grandes) en lugar de números.
  final bool pictureOptions;

  String get answer => options[answerIndex];
}

typedef QuestionMaker = Question Function(Random random);

Question additionQuestion(Random r, int max) {
  final a = 1 + r.nextInt(max - 1);
  final b = 1 + r.nextInt(max - a);
  final sum = a + b;
  final obj = _objects[r.nextInt(_objects.length)];

  final wrong = <int>{};
  while (wrong.length < 2) {
    final w = sum + (r.nextBool() ? 1 : -1) * (1 + r.nextInt(3));
    if (w >= 0 && w != sum) wrong.add(w);
  }
  final options = [sum, ...wrong]..shuffle(r);
  return Question(
    prompt: '$a + $b = ?',
    visual: sum <= 10 ? (obj * a, obj * b) : null,
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(sum),
    speech: '$a más $b',
    speechLang: 'es',
  );
}

Question englishQuestion(Random r, Topic topic) {
  final words = topic.words;
  final target = words[r.nextInt(words.length)];
  final others = (words.where((w) => w != target).toList()..shuffle(r)).take(2);
  final options = [target, ...others]..shuffle(r);
  return Question(
    prompt: target.$1,
    options: [for (final o in options) o.$2],
    answerIndex: options.indexOf(target),
    speech: target.$1,
    speechLang: 'en',
    pictureOptions: true,
  );
}
