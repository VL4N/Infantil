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
    this.addition,
    this.optionWords,
    this.pictureOptions = false,
  });

  /// Texto grande de la pregunta ("2 + 3 = ?" o "dog").
  final String prompt;

  /// Datos de la suma (para dibujar y explicar los errores).
  final Addition? addition;

  /// Palabra en inglés de cada opción (para explicar los errores).
  final List<String>? optionWords;
  final List<String> options;
  final int answerIndex;
  final String speech;
  final String speechLang;

  /// Las opciones son dibujos (más grandes) en lugar de números.
  final bool pictureOptions;

  String get answer => options[answerIndex];
}

class Addition {
  const Addition(this.a, this.b, this.object);
  final int a;
  final int b;
  final String object;

  int get sum => a + b;

  /// Con pocos objetos se cuentan los dibujos; con más, se cuenta hacia adelante.
  bool get drawable => sum <= 10;
}

/// Un paso de la explicación cuando el niño se equivoca.
class ExplainStep {
  const ExplainStep(this.text, this.lang, {this.count, this.highlightAnswer = false});
  final String text;
  final String lang;

  /// Cuántos dibujos van contados (o el número al que se llegó contando).
  final int? count;
  final bool highlightAnswer;
}

const _numberWords = [
  'cero', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve', 'diez',
  'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete', 'dieciocho', 'diecinueve', 'veinte',
];

String numberWord(int n) => n >= 0 && n < _numberWords.length ? _numberWords[n] : '$n';

/// Explicación con voz de una respuesta equivocada, para aprender en ese momento.
List<ExplainStep> explainMistake(Question q, int chosen) {
  final add = q.addition;
  if (add != null) {
    final steps = <ExplainStep>[
      ExplainStep('Casi. Tocaste el ${q.options[chosen]}. ¡Vamos a contar juntos!', 'es'),
    ];
    if (add.drawable) {
      for (var i = 1; i <= add.sum; i++) {
        steps.add(ExplainStep(numberWord(i), 'es', count: i));
      }
    } else {
      steps.add(ExplainStep('Empezamos en el ${add.a}, y contamos ${add.b} más.', 'es', count: add.a));
      for (var i = add.a + 1; i <= add.sum; i++) {
        steps.add(ExplainStep(numberWord(i), 'es', count: i));
      }
    }
    steps.add(ExplainStep('${add.a} más ${add.b} son ${add.sum}. ¡Toca el ${add.sum}!', 'es',
        count: add.sum, highlightAnswer: true));
    return steps;
  }

  final words = q.optionWords!;
  return [
    const ExplainStep('Casi. Ese dibujo en inglés se dice', 'es'),
    ExplainStep(words[chosen], 'en'),
    const ExplainStep('Y este es', 'es', highlightAnswer: true),
    ExplainStep(q.speech, 'en', highlightAnswer: true),
    const ExplainStep('¡Tócalo!', 'es', highlightAnswer: true),
  ];
}

typedef QuestionMaker = Question Function(Random random);

Question additionQuestion(Random r, int max) {
  final a = 1 + r.nextInt(max - 1);
  final b = 1 + r.nextInt(max - a);
  final sum = a + b;
  final obj = _objects[r.nextInt(_objects.length)];

  // Errores típicos: quedarse corto o pasarse al contar, o responder uno de los sumandos.
  // Así la respuesta no es siempre el número del medio y adivinar no sirve.
  final candidates = <int>{for (var d = -3; d <= 3; d++) sum + d, a, b}
    ..removeWhere((w) => w == sum || w < 0);
  final wrong = (candidates.toList()..shuffle(r)).take(2);
  final options = [sum, ...wrong]..shuffle(r);
  return Question(
    prompt: '$a + $b = ?',
    addition: Addition(a, b, obj),
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
    optionWords: [for (final o in options) o.$1],
    answerIndex: options.indexOf(target),
    speech: target.$1,
    speechLang: 'en',
    pictureOptions: true,
  );
}
