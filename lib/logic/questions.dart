import 'dart:math';

import 'content.dart';

const _objects = ['🍎', '⭐', '🐟', '🎈', '🍓', '🐞', '🚗', '🌸'];

/// Cómo se pregunta por cada dibujo al contar: "¿Cuántas manzanas hay?".
const _howMany = {
  '🍎': '¿Cuántas manzanas hay?',
  '⭐': '¿Cuántas estrellas hay?',
  '🐟': '¿Cuántos peces hay?',
  '🎈': '¿Cuántos globos hay?',
  '🍓': '¿Cuántas fresas hay?',
  '🐞': '¿Cuántas mariquitas hay?',
  '🚗': '¿Cuántos carros hay?',
  '🌸': '¿Cuántas flores hay?',
};

/// Todas las preguntas de contar (para grabar sus voces).
Iterable<String> get howManyPhrases => _howMany.values;

class Question {
  const Question({
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.speech,
    required this.speechLang,
    this.ask,
    this.count,
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

  /// Lo que dice la voz al mostrar la pregunta, si no es [speech] (para no decir la respuesta).
  final String? ask;

  /// En "How many?": cuántos dibujos hay que contar en inglés.
  final int? count;

  /// Las opciones son dibujos (más grandes) en lugar de números.
  final bool pictureOptions;

  String get answer => options[answerIndex];
}

/// Formatos de ejercicio de suma.
enum AddKind {
  /// "2 + 3 = ?"
  sum,

  /// "2 + ? = 5": cuánto falta.
  missing,

  /// "¿Cuántos hay?": contar dibujos (para los más pequeños). Usa solo [Addition.a].
  count,

  /// "5 − 2 = ?": resta. Hay [Addition.a] dibujos y se quitan [Addition.b].
  sub,
}

class Addition {
  const Addition(this.a, this.b, this.object, {this.kind = AddKind.sum});
  final int a;
  final int b;
  final String object;
  final AddKind kind;

  int get sum => a + b;

  /// El resultado: la suma, o en una resta lo que queda.
  int get result => kind == AddKind.sub ? a - b : a + b;

  /// Con pocos objetos se cuentan los dibujos; con más, se cuenta hacia adelante (o hacia atrás).
  bool get drawable => (kind == AddKind.sub ? a : sum) <= 10;
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

/// Frases cortas y reutilizables: la voz de la app viene grabada frase por frase
/// (ver logic/phrases.dart), así que se evita juntar dos números variables en una frase.
String touchedNumber(String option) => 'Casi. Tocaste el $option.';
const letsCount = '¡Vamos a contar juntos!';
const countWhatsLeft = 'Contemos los que quedan.';
String touchTheNumber(int n) => '¡Toca el $n!';

/// Explicación con voz de una respuesta equivocada, para aprender en ese momento.
List<ExplainStep> explainMistake(Question q, int chosen) {
  final add = q.addition;
  if (add != null && add.kind == AddKind.count) {
    return [
      ExplainStep(touchedNumber(q.options[chosen]), 'es'),
      const ExplainStep(letsCount, 'es'),
      for (var i = 1; i <= add.a; i++) ExplainStep(numberWord(i), 'es', count: i),
      ExplainStep('Hay ${add.a}. ¡Toca el ${add.a}!', 'es', count: add.a, highlightAnswer: true),
    ];
  }
  if (add != null && add.kind == AddKind.sub) {
    final r = add.result;
    return [
      ExplainStep(touchedNumber(q.options[chosen]), 'es'),
      if (add.drawable) ...[
        ExplainStep('Tenemos ${add.a}.', 'es'),
        ExplainStep('Quitamos ${add.b}.', 'es'),
        const ExplainStep(countWhatsLeft, 'es'),
        for (var i = 1; i <= r; i++) ExplainStep(numberWord(i), 'es', count: i),
      ] else ...[
        ExplainStep('Empezamos en el ${add.a}.', 'es', count: add.a),
        ExplainStep('Contamos ${add.b} hacia atrás.', 'es', count: add.a),
        for (var i = add.a - 1; i >= r; i--) ExplainStep(numberWord(i), 'es', count: i),
      ],
      ExplainStep('${add.a} menos ${add.b} son $r.', 'es', count: r, highlightAnswer: true),
      ExplainStep(touchTheNumber(r), 'es', count: r, highlightAnswer: true),
    ];
  }
  if (add != null && add.kind == AddKind.missing) {
    return [
      ExplainStep(touchedNumber(q.options[chosen]), 'es'),
      ExplainStep('Tenemos ${add.a}, ¡contemos hasta ${add.sum}!', 'es', count: add.a),
      for (var i = add.a + 1; i <= add.sum; i++) ExplainStep(numberWord(i), 'es', count: i),
      ExplainStep('Contamos ${add.b} más. ${add.a} más ${add.b} son ${add.sum}. ¡Toca el ${add.b}!', 'es',
          count: add.sum, highlightAnswer: true),
    ];
  }
  if (add != null) {
    final steps = <ExplainStep>[
      ExplainStep(touchedNumber(q.options[chosen]), 'es'),
      const ExplainStep(letsCount, 'es'),
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
  final count = q.count;
  if (count != null) {
    return [
      const ExplainStep('Casi. Tocaste', 'es'),
      ExplainStep(words[chosen], 'en'),
      const ExplainStep('Contemos juntos en inglés', 'es'),
      for (var i = 1; i <= count; i++) ExplainStep(englishNumbers[i - 1], 'en', count: i, highlightAnswer: i == count),
      const ExplainStep('¡Tócalo!', 'es', highlightAnswer: true),
    ];
  }
  if (!q.pictureOptions) {
    return [
      const ExplainStep('Casi. Tocaste', 'es'),
      ExplainStep(words[chosen], 'en'),
      const ExplainStep('Este dibujo en inglés se dice', 'es', highlightAnswer: true),
      ExplainStep(q.speech, 'en', highlightAnswer: true),
      const ExplainStep('¡Tócalo!', 'es', highlightAnswer: true),
    ];
  }
  return [
    const ExplainStep('Casi. Ese dibujo en inglés se dice', 'es'),
    ExplainStep(words[chosen], 'en'),
    const ExplainStep('Y este es', 'es', highlightAnswer: true),
    ExplainStep(q.speech, 'en', highlightAnswer: true),
    const ExplainStep('¡Tócalo!', 'es', highlightAnswer: true),
  ];
}

typedef QuestionMaker = Question Function(Random random);

/// Qué hace distinta a una pregunta: la suma, cuántos hay que contar o la palabra en inglés.
/// Así en una partida no sale dos veces la misma fruta aunque cambie el tipo de pregunta.
String questionKey(Question q) {
  final add = q.addition;
  if (add != null) return '${add.kind.name} ${add.a} ${add.b}';
  if (q.count != null) return 'count ${q.count}';
  return q.speech;
}

/// Una pregunta nueva que no haya salido todavía en la partida ([seen]).
Question freshQuestion(QuestionMaker make, Random r, Set<String> seen) {
  var q = make(r);
  for (var i = 0; i < 100 && seen.contains(questionKey(q)); i++) {
    q = make(r);
  }
  seen.add(questionKey(q));
  return q;
}

/// Pregunta de un nivel de suma, mezclando formatos: en "Hasta 5" también se cuentan dibujos;
/// en los niveles mayores también hay que encontrar el número que falta.
Question mathQuestion(Random r, int max) {
  if (r.nextInt(3) > 0) return additionQuestion(r, max);
  return max <= 5 ? countQuestion(r, max) : missingQuestion(r, max);
}

/// Dos números incorrectos al azar entre [candidates] (sin la respuesta ni negativos).
List<int> _options(Random r, int answer, Set<int> candidates) {
  candidates.removeWhere((w) => w == answer || w < 0);
  final wrong = (candidates.toList()..shuffle(r)).take(2);
  return [answer, ...wrong]..shuffle(r);
}

Question countQuestion(Random r, int max) {
  final n = 1 + r.nextInt(max);
  final obj = _objects[r.nextInt(_objects.length)];
  final options = _options(r, n, {for (var d = -2; d <= 2; d++) if (n + d > 0) n + d});
  return Question(
    prompt: _howMany[obj]!,
    addition: Addition(n, 0, obj, kind: AddKind.count),
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(n),
    speech: _howMany[obj]!,
    speechLang: 'es',
  );
}

Question missingQuestion(Random r, int max) {
  final a = 1 + r.nextInt(max - 1);
  final b = 1 + r.nextInt(max - a);
  final sum = a + b;
  final obj = _objects[r.nextInt(_objects.length)];
  // Errores típicos: contar uno de más o de menos, o responder uno de los números que se ven.
  final options = _options(r, b, {for (var d = -3; d <= 3; d++) b + d, a, sum});
  return Question(
    prompt: '$a + ? = $sum',
    addition: Addition(a, b, obj, kind: AddKind.missing),
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(b),
    speech: '$a más cuánto es $sum',
    speechLang: 'es',
  );
}

Question additionQuestion(Random r, int max) {
  final a = 1 + r.nextInt(max - 1);
  final b = 1 + r.nextInt(max - a);
  final sum = a + b;
  final obj = _objects[r.nextInt(_objects.length)];

  // Errores típicos: quedarse corto o pasarse al contar, o responder uno de los sumandos.
  // Así la respuesta no es siempre el número del medio y adivinar no sirve.
  final options = _options(r, sum, {for (var d = -3; d <= 3; d++) sum + d, a, b});
  return Question(
    prompt: '$a + $b = ?',
    addition: Addition(a, b, obj),
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(sum),
    speech: '$a más $b',
    speechLang: 'es',
  );
}

/// Resta: hay [a] dibujos y se van [b]. Siempre queda al menos uno.
Question subtractionQuestion(Random r, int max) {
  final a = 2 + r.nextInt(max - 1);
  final b = 1 + r.nextInt(a - 1);
  final rest = a - b;
  final obj = _objects[r.nextInt(_objects.length)];
  // Errores típicos: contar uno de más o de menos, responder uno de los números o sumar en vez de restar.
  final options = _options(r, rest, {
    for (var d = -3; d <= 3; d++) rest + d,
    a,
    b,
    if (a + b <= maxOption) a + b,
  });
  return Question(
    prompt: '$a − $b = ?',
    addition: Addition(a, b, obj, kind: AddKind.sub),
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(rest),
    speech: '$a menos $b',
    speechLang: 'es',
  );
}

/// El número más grande que puede salir como opción (la suma de 20 más 3).
const maxOption = 23;

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

/// Pregunta de un tema de inglés: "escucha y toca el dibujo" (la mitad), "mira el dibujo y elige la palabra"
/// (una de cada tres) y "How many?", contar los dibujos en inglés (una de cada seis).
Question englishMixedQuestion(Random r, Topic topic) => switch (r.nextInt(6)) {
      0 || 1 => englishWordQuestion(r, topic),
      2 => englishCountQuestion(r, topic),
      _ => englishQuestion(r, topic),
    };

/// one, two, three… ten (del tema Números).
final englishNumbers = [for (final w in topics.firstWhere((t) => t.key == 'numeros').words) w.$1];

/// Cuenta los dibujos y elige el número en inglés: hasta 5, o hasta 10 en el tema Números.
Question englishCountQuestion(Random r, Topic topic) {
  final max = topic.key == 'numeros' ? 10 : 5;
  final n = 1 + r.nextInt(max);
  // Para contar se usa un dibujo del tema (en Números, que son cifras, una estrella).
  final picture = topic.key == 'numeros' ? '⭐' : topic.words[r.nextInt(topic.words.length)].$2;
  final options = _options(r, n, {for (var d = -2; d <= 2; d++) if (n + d >= 1 && n + d <= 10) n + d});
  final words = [for (final o in options) englishNumbers[o - 1]];
  return Question(
    prompt: List.filled(n, picture).join(' '),
    options: words,
    optionWords: words,
    answerIndex: options.indexOf(n),
    speech: englishNumbers[n - 1],
    ask: 'How many?',
    count: n,
    speechLang: 'en',
  );
}

/// Mira el dibujo y elige cómo se dice en inglés.
Question englishWordQuestion(Random r, Topic topic) {
  final words = topic.words;
  final target = words[r.nextInt(words.length)];
  final others = (words.where((w) => w != target).toList()..shuffle(r)).take(2);
  final options = [target, ...others]..shuffle(r);
  return Question(
    prompt: target.$2,
    options: [for (final o in options) o.$1],
    optionWords: [for (final o in options) o.$1],
    answerIndex: options.indexOf(target),
    speech: target.$1,
    ask: 'What is this?',
    speechLang: 'en',
  );
}
