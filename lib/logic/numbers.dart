import 'dart:math';

import 'lang.dart';
import 'questions.dart';

/// Ejercicios de la sección "Números": "¿Qué número sigue?" y "¿Cuál es mayor?".

/// Una serie de números que va de [step] en [step]; falta el que sigue.
class Sequence {
  const Sequence(this.numbers, this.step);
  final List<int> numbers;
  final int step;
  int get next => numbers.last + step;
}

/// Dos cantidades para comparar. Con [object], se ven como dibujos para contar.
class Comparison {
  const Comparison(this.a, this.b, {this.object});
  final int a;
  final int b;
  final String? object;
  int get bigger => max(a, b);
}

/// Un nivel de la sección Números (se guarda su progreso con [key]).
class NumberLevel {
  const NumberLevel(this.key, this.icon, this.make);
  final String key;
  final String icon;
  final QuestionMaker make;

  String get label => switch (key) {
        'sigue-10' => '$icon ${tr('¿Qué sigue? Hasta 10', 'What comes next? Up to 10')}',
        'sigue-20' => '$icon ${tr('¿Qué sigue? Hasta 20', 'What comes next? Up to 20')}',
        'dos-20' => '$icon ${tr('De 2 en 2', 'Count by 2s')}',
        'mayor-10' => '$icon ${tr('¿Cuál es mayor? Con dibujos', 'Which is bigger? Pictures')}',
        _ => '$icon ${tr('¿Cuál es mayor? Hasta 20', 'Which is bigger? Up to 20')}',
      };
}

final numberLevels = [
  NumberLevel('sigue-10', '🔢', (r) => sequenceQuestion(r, 10, 1)),
  NumberLevel('sigue-20', '🔢', (r) => sequenceQuestion(r, 20, 1)),
  NumberLevel('dos-20', '🦘', (r) => sequenceQuestion(r, 20, 2)),
  NumberLevel('mayor-10', '⚖️', (r) => compareQuestion(r, 10)),
  NumberLevel('mayor-20', '⚖️', (r) => compareQuestion(r, 20)),
];

String get askNext => tr('¿Qué número sigue?', 'What number comes next?');
String get askBigger => tr('¿Cuál es mayor?', 'Which is bigger?');
String get countByTwo => tr('Contamos de dos en dos.', "Let's count by twos.");
String biggerIs(int n) => tr('El $n es mayor. ¡Toca el $n!', '$n is bigger. Touch the $n!');

const _objects = ['🍎', '⭐', '🐟', '🎈', '🍓', '🐢', '🚗', '🌸'];

/// Tres números que van de [step] en [step] (sin pasar de [max]); hay que elegir el que sigue.
Question sequenceQuestion(Random r, int max, int step) {
  // De 1 en 1 empieza en 1 o más; de 2 en 2 puede empezar en 0 (0, 2, 4…).
  final lowest = step == 1 ? 1 : 0;
  final start = lowest + r.nextInt(max - 3 * step - lowest + 1);
  final numbers = [for (var i = 0; i < 3; i++) start + i * step];
  final next = numbers.last + step;
  // Errores típicos: repetir el último, contar de 1 en 1 o pasarse.
  final wrong = {next - 1, next + 1, next + step, numbers.last}..removeWhere((w) => w == next || w < 0);
  final options = [next, ...(wrong.toList()..shuffle(r)).take(2)]..shuffle(r);
  return Question(
    prompt: askNext,
    sequence: Sequence(numbers, step),
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(next),
    speech: askNext,
    speechLang: Lang.native,
  );
}

/// Dos cantidades distintas; hay que tocar la mayor. Hasta 10 se ven como dibujos.
Question compareQuestion(Random r, int max) {
  final a = 1 + r.nextInt(max);
  var b = 1 + r.nextInt(max - 1);
  if (b >= a) b++;
  final object = max <= 10 ? _objects[r.nextInt(_objects.length)] : null;
  return Question(
    prompt: askBigger,
    comparison: Comparison(a, b, object: object),
    options: ['$a', '$b'],
    answerIndex: a > b ? 0 : 1,
    speech: askBigger,
    speechLang: Lang.native,
  );
}

/// Explicación con voz de un error en la sección Números.
List<ExplainStep> explainNumbers(Question q, int chosen) {
  final n = Lang.native;
  final seq = q.sequence;
  if (seq != null) {
    final next = seq.next;
    return [
      ExplainStep(touchedNumber(q.options[chosen]), n),
      ExplainStep(seq.step == 2 ? countByTwo : letsCount, n),
      for (final x in seq.numbers) ExplainStep(numberWord(x), n, count: x),
      ExplainStep(numberWord(next), n, count: next, highlightAnswer: true),
      ExplainStep(touchTheNumber(next), n, count: next, highlightAnswer: true),
    ];
  }
  final cmp = q.comparison!;
  return [
    ExplainStep(touchedNumber(q.options[chosen]), n),
    ExplainStep(biggerIs(cmp.bigger), n, highlightAnswer: true),
  ];
}
