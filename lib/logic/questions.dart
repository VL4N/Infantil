import 'dart:math';

import 'content.dart';
import 'lang.dart';

const _objects = ['🍎', '⭐', '🐟', '🎈', '🍓', '🐢', '🚗', '🌸'];

/// Cómo se pregunta por cada dibujo al contar: "¿Cuántas manzanas hay?".
const _howMany = {
  '🍎': ('¿Cuántas manzanas hay?', 'How many apples are there?'),
  '⭐': ('¿Cuántas estrellas hay?', 'How many stars are there?'),
  '🐟': ('¿Cuántos peces hay?', 'How many fish are there?'),
  '🎈': ('¿Cuántos globos hay?', 'How many balloons are there?'),
  '🍓': ('¿Cuántas fresas hay?', 'How many strawberries are there?'),
  '🐢': ('¿Cuántas tortugas hay?', 'How many turtles are there?'),
  '🚗': ('¿Cuántos carros hay?', 'How many cars are there?'),
  '🌸': ('¿Cuántas flores hay?', 'How many flowers are there?'),
};

String _howManyFor(String object) {
  final (es, en) = _howMany[object]!;
  return tr(es, en);
}

/// Todas las preguntas de contar en el idioma de la app (para grabar sus voces).
Iterable<String> get howManyPhrases => _howMany.keys.map(_howManyFor);

class Question {
  const Question({
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.speech,
    required this.speechLang,
    this.ask,
    this.askLang,
    this.intro,
    this.count,
    this.addition,
    this.optionWords,
    this.pictureOptions = false,
  });

  /// Texto grande de la pregunta ("2 + 3 = ?" o "dog").
  final String prompt;

  /// Datos de la suma (para dibujar y explicar los errores).
  final Addition? addition;

  /// Palabra (en el idioma que aprende) de cada opción, para explicar los errores.
  final List<String>? optionWords;
  final List<String> options;
  final int answerIndex;
  final String speech;
  final String speechLang;

  /// Lo que dice la voz al mostrar la pregunta, si no es [speech] (para no decir la respuesta).
  final String? ask;

  /// Idioma de [ask] (si no se indica, el de [speech]).
  final String? askLang;

  /// Instrucción antes de la pregunta, en el idioma del niño ("Escucha y toca el dibujo.").
  final String? intro;

  /// Al contar en el idioma que aprende: cuántos dibujos hay.
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

const _numberWordsEs = [
  'cero', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve', 'diez',
  'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete', 'dieciocho', 'diecinueve', 'veinte',
];
const _numberWordsEn = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
  'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen', 'twenty',
];

/// El número en palabras, en el idioma de la app (para contar en voz alta).
String numberWord(int n) {
  final words = Lang.current == AppLang.es ? _numberWordsEs : _numberWordsEn;
  return n >= 0 && n < words.length ? words[n] : '$n';
}

/// Frases cortas y reutilizables: la voz de la app viene grabada frase por frase
/// (ver logic/phrases.dart), así que se evita juntar dos números variables en una frase.
String touchedNumber(String option) => tr('Casi. Tocaste el $option.', 'Almost. You touched $option.');
String get letsCount => tr('¡Vamos a contar juntos!', "Let's count together!");
String greatNumber(String n) => tr('¡Muy bien, $n!', 'Great job, $n!');

/// En el idioma que aprende solo se dice lo que hay que adivinar: las instrucciones van en el idioma del niño.
String get askWhatIs => tr('¿Cómo se dice en inglés?', 'How do you say it in Spanish?');
String get askHowMany => tr('¿Cuántos hay? Dilo en inglés.', 'How many are there? Say it in Spanish.');
String get listenAndTouch => tr('Escucha y toca el dibujo.', 'Listen and touch the picture.');
String get praiseFirstTry => tr('¡Muy bien!', 'Great job!');
String get praiseRetry => tr('¡Eso es!', "That's it!");
String get countWhatsLeft => tr('Contemos los que quedan.', "Let's count what's left.");
String touchTheNumber(int n) => tr('¡Toca el $n!', 'Touch the $n!');

/// Frases de las explicaciones de inglés (o de español, para quien aprende español).
String get almostYouTouched => tr('Casi. Tocaste', 'Almost. You touched');
String get countTogetherInTarget => tr('Contemos juntos en inglés', "Let's count together in Spanish");
String get thisPictureIs => tr('Este dibujo en inglés se dice', 'In Spanish, this picture is');
String get almostThatPictureIs => tr('Casi. Ese dibujo en inglés se dice', 'Almost. In Spanish, that picture is');
String get andThisOneIs => tr('Y este es', 'And this one is');
String get touchIt => tr('¡Tócalo!', 'Touch it!');

/// Frases de las sumas y restas (todas sus combinaciones se graban: ver logic/phrases.dart).
String thereAre(int a) => tr('Hay $a. ¡Toca el $a!', 'There are $a. Touch the $a!');
String plus(int a, int b) => tr('$a más $b', '$a plus $b');
String plusWhat(int a, int s) => tr('$a más cuánto es $s', '$a plus what makes $s');
String weHaveCountTo(int a, int s) => tr('Tenemos $a, ¡contemos hasta $s!', "We have $a. Let's count to $s!");
String countedMore(int a, int b, int s) =>
    tr('Contamos $b más. $a más $b son $s. ¡Toca el $b!', 'We counted $b more. $a plus $b is $s. Touch the $b!');
String startAndCountOn(int a, int b) => tr('Empezamos en el $a, y contamos $b más.', 'We start at $a and count $b more.');
String plusIs(int a, int b, int s) => tr('$a más $b son $s. ¡Toca el $s!', '$a plus $b is $s. Touch the $s!');
String weHave(int a) => tr('Tenemos $a.', 'We have $a.');
String startAt(int a) => tr('Empezamos en el $a.', 'We start at $a.');
String minus(int a, int b) => tr('$a menos $b', '$a minus $b');
String minusIs(int a, int b) => tr('$a menos $b son ${a - b}.', '$a minus $b is ${a - b}.');
String takeAway(int b) => tr('Quitamos $b.', 'We take away $b.');
String countBack(int b) => tr('Contamos $b hacia atrás.', 'We count back $b.');

/// Explicación con voz de una respuesta equivocada, para aprender en ese momento.
List<ExplainStep> explainMistake(Question q, int chosen) {
  final add = q.addition;
  final n = Lang.native;
  if (add != null && add.kind == AddKind.count) {
    return [
      ExplainStep(touchedNumber(q.options[chosen]), n),
      ExplainStep(letsCount, n),
      for (var i = 1; i <= add.a; i++) ExplainStep(numberWord(i), n, count: i),
      ExplainStep(thereAre(add.a), n, count: add.a, highlightAnswer: true),
    ];
  }
  if (add != null && add.kind == AddKind.sub) {
    final r = add.result;
    return [
      ExplainStep(touchedNumber(q.options[chosen]), n),
      if (add.drawable) ...[
        ExplainStep(weHave(add.a), n),
        ExplainStep(takeAway(add.b), n),
        ExplainStep(countWhatsLeft, n),
        for (var i = 1; i <= r; i++) ExplainStep(numberWord(i), n, count: i),
      ] else ...[
        ExplainStep(startAt(add.a), n, count: add.a),
        ExplainStep(countBack(add.b), n, count: add.a),
        for (var i = add.a - 1; i >= r; i--) ExplainStep(numberWord(i), n, count: i),
      ],
      ExplainStep(minusIs(add.a, add.b), n, count: r, highlightAnswer: true),
      ExplainStep(touchTheNumber(r), n, count: r, highlightAnswer: true),
    ];
  }
  if (add != null && add.kind == AddKind.missing) {
    return [
      ExplainStep(touchedNumber(q.options[chosen]), n),
      ExplainStep(weHaveCountTo(add.a, add.sum), n, count: add.a),
      for (var i = add.a + 1; i <= add.sum; i++) ExplainStep(numberWord(i), n, count: i),
      ExplainStep(countedMore(add.a, add.b, add.sum), n, count: add.sum, highlightAnswer: true),
    ];
  }
  if (add != null) {
    final steps = <ExplainStep>[
      ExplainStep(touchedNumber(q.options[chosen]), n),
      ExplainStep(letsCount, n),
    ];
    if (add.drawable) {
      for (var i = 1; i <= add.sum; i++) {
        steps.add(ExplainStep(numberWord(i), n, count: i));
      }
    } else {
      steps.add(ExplainStep(startAndCountOn(add.a, add.b), n, count: add.a));
      for (var i = add.a + 1; i <= add.sum; i++) {
        steps.add(ExplainStep(numberWord(i), n, count: i));
      }
    }
    steps.add(ExplainStep(plusIs(add.a, add.b, add.sum), n, count: add.sum, highlightAnswer: true));
    return steps;
  }

  final t = Lang.target;
  final words = q.optionWords!;
  final count = q.count;
  if (count != null) {
    return [
      ExplainStep(almostYouTouched, n),
      ExplainStep(words[chosen], t),
      ExplainStep(countTogetherInTarget, n),
      for (var i = 1; i <= count; i++) ExplainStep(targetNumbers[i - 1], t, count: i, highlightAnswer: i == count),
      ExplainStep(touchIt, n, highlightAnswer: true),
    ];
  }
  if (!q.pictureOptions) {
    return [
      ExplainStep(almostYouTouched, n),
      ExplainStep(words[chosen], t),
      ExplainStep(thisPictureIs, n, highlightAnswer: true),
      ExplainStep(q.speech, t, highlightAnswer: true),
      ExplainStep(touchIt, n, highlightAnswer: true),
    ];
  }
  return [
    ExplainStep(almostThatPictureIs, n),
    ExplainStep(words[chosen], t),
    ExplainStep(andThisOneIs, n, highlightAnswer: true),
    ExplainStep(q.speech, t, highlightAnswer: true),
    ExplainStep(touchIt, n, highlightAnswer: true),
  ];
}

typedef QuestionMaker = Question Function(Random random);

/// Qué hace distinta a una pregunta: la suma, cuántos hay que contar o la palabra.
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
    prompt: _howManyFor(obj),
    addition: Addition(n, 0, obj, kind: AddKind.count),
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(n),
    speech: _howManyFor(obj),
    speechLang: Lang.native,
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
    speech: plusWhat(a, sum),
    speechLang: Lang.native,
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
    speech: plus(a, b),
    speechLang: Lang.native,
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
    speech: minus(a, b),
    speechLang: Lang.native,
  );
}

/// El número más grande que puede salir como opción (la suma de 20 más 3).
const maxOption = 23;

/// Escucha la palabra (en el idioma que aprende) y toca el dibujo.
Question englishQuestion(Random r, Topic topic) {
  final words = topic.words;
  final target = words[r.nextInt(words.length)];
  final others = (words.where((w) => w != target).toList()..shuffle(r)).take(2);
  final options = [target, ...others]..shuffle(r);
  return Question(
    prompt: target.text,
    options: [for (final o in options) o.picture],
    optionWords: [for (final o in options) o.text],
    answerIndex: options.indexOf(target),
    speech: target.text,
    speechLang: Lang.target,
    intro: listenAndTouch,
    pictureOptions: true,
  );
}

/// Pregunta de un tema del idioma que aprende: "escucha y toca el dibujo" (la mitad), "mira el dibujo y
/// elige la palabra" (una de cada tres) y contar los dibujos en ese idioma (una de cada seis).
Question englishMixedQuestion(Random r, Topic topic) => switch (r.nextInt(6)) {
      0 || 1 => englishWordQuestion(r, topic),
      2 => englishCountQuestion(r, topic),
      _ => englishQuestion(r, topic),
    };

/// Los números del 1 al 10 en el idioma que aprende (del tema Números): one, two… o uno, dos…
List<String> get targetNumbers => [for (final w in topics.firstWhere((t) => t.key == 'numeros').words) w.text];

/// Cuenta los dibujos y elige el número en el idioma que aprende: hasta 5, o hasta 10 en el tema Números.
Question englishCountQuestion(Random r, Topic topic) {
  final max = topic.key == 'numeros' ? 10 : 5;
  final n = 1 + r.nextInt(max);
  // Para contar se usa un dibujo del tema (en Números, que son cifras, una estrella).
  final picture = topic.key == 'numeros' ? '⭐' : topic.words[r.nextInt(topic.words.length)].picture;
  final options = _options(r, n, {for (var d = -2; d <= 2; d++) if (n + d >= 1 && n + d <= 10) n + d});
  final numbers = targetNumbers;
  final words = [for (final o in options) numbers[o - 1]];
  return Question(
    prompt: List.filled(n, picture).join(' '),
    options: words,
    optionWords: words,
    answerIndex: options.indexOf(n),
    speech: numbers[n - 1],
    ask: askHowMany,
    askLang: Lang.native,
    count: n,
    speechLang: Lang.target,
  );
}

/// Mira el dibujo y elige cómo se dice en el idioma que aprende.
Question englishWordQuestion(Random r, Topic topic) {
  final words = topic.words;
  final target = words[r.nextInt(words.length)];
  final others = (words.where((w) => w != target).toList()..shuffle(r)).take(2);
  final options = [target, ...others]..shuffle(r);
  return Question(
    prompt: target.picture,
    options: [for (final o in options) o.text],
    optionWords: [for (final o in options) o.text],
    answerIndex: options.indexOf(target),
    speech: target.text,
    ask: askWhatIs,
    askLang: Lang.native,
    speechLang: Lang.target,
  );
}
