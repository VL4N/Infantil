import 'dart:math';

import 'lang.dart';
import 'questions.dart';

/// Sección "Tablas" (para los grandes, de 6 a 10 años): tablas de multiplicar y sumas y restas
/// hasta 100 con decenas. Solo combinaciones fijas, para que cada frase venga grabada.

/// Lo que se ve y se dice en una pregunta de esta sección.
class TablesQuestion {
  const TablesQuestion({required this.hint, required this.explain});

  /// Ayuda escrita que aparece al equivocarse ("3 + 3 + 3 + 3 = 12").
  final String hint;

  /// Explicación con voz (la última frase resalta la respuesta).
  final List<ExplainStep> explain;
}

// ---------- Frases ----------

String times(int a, int b) => tr('$a por $b', '$a times $b');
String timesMeans(int a, int b) =>
    tr('$a por $b es sumar el $a, $b ${b == 1 ? 'vez' : 'veces'}.', '$a times $b means adding $a, $b ${b == 1 ? 'time' : 'times'}.');
String timesIs(int a, int b) => tr('$a por $b son ${a * b}. ¡Toca el ${a * b}!', '$a times $b is ${a * b}. Touch the ${a * b}!');
String plusIsTouch(int a, int b) => tr('$a más $b son ${a + b}. ¡Toca el ${a + b}!', '$a plus $b is ${a + b}. Touch the ${a + b}!');
String minusIsTouch(int a, int b) => tr('$a menos $b son ${a - b}. ¡Toca el ${a - b}!', '$a minus $b is ${a - b}. Touch the ${a - b}!');

/// Tres opciones distintas entre 0 y 100, con la respuesta.
List<int> _options(Random r, int answer, List<int> near) {
  final others = {for (final n in near) if (n != answer && n >= 0 && n <= 100) n}.toList()..shuffle(r);
  return [answer, ...others.take(2)]..shuffle(r);
}

// ---------- Tablas de multiplicar ----------

/// "3 × 4 = ?" de las tablas de [tables] (por 1 a 10).
Question tableQuestion(Random r, List<int> tables) {
  final a = tables[r.nextInt(tables.length)];
  final b = 1 + r.nextInt(10);
  final p = a * b;
  final options = _options(r, p, [p + a, p - a, p + 1, p - 1, p + 2, p + 10, p - 10]);
  return Question(
    prompt: '$a × $b = ?',
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(p),
    speech: times(a, b),
    speechLang: Lang.native,
    tables: TablesQuestion(
      hint: '${List.filled(b, '$a').join(' + ')} = $p',
      explain: [
        ExplainStep(timesMeans(a, b), Lang.native),
        // Contar de [a] en [a]: 3, 6, 9, 12.
        for (var k = 1; k <= b; k++) ExplainStep('${a * k}', Lang.native, count: k),
        ExplainStep(timesIs(a, b), Lang.native, highlightAnswer: true),
      ],
    ),
  );
}

// ---------- Sumas y restas hasta 100 ----------

/// "30 + 40" (decenas) o "50 + 7" (decenas y unidades).
Question sum100Question(Random r) {
  final int a, b;
  if (r.nextBool()) {
    a = 10 * (1 + r.nextInt(9));
    b = 10 * (1 + r.nextInt(10 - a ~/ 10));
  } else {
    a = 10 * (1 + r.nextInt(9));
    b = 1 + r.nextInt(9);
  }
  final s = a + b;
  // Errores típicos: equivocarse en una decena o en una unidad (si no alcanzan, de a dos).
  final options = _options(r, s, b % 10 == 0 ? [s + 10, s - 10, s + 1, s - 20] : [s + 10, s - 10, s + 1, s - 1]);
  return Question(
    prompt: '$a + $b = ?',
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(s),
    speech: plus(a, b),
    speechLang: Lang.native,
    tables: TablesQuestion(
      hint: b % 10 == 0
          ? tr('${a ~/ 10} decenas + ${b ~/ 10} decenas = ${s ~/ 10} decenas', '${a ~/ 10} tens + ${b ~/ 10} tens = ${s ~/ 10} tens')
          : tr('$a + $b: las decenas quedan igual', '$a + $b: the tens stay the same'),
      explain: [ExplainStep(plusIsTouch(a, b), Lang.native, highlightAnswer: true)],
    ),
  );
}

/// "70 − 30" (decenas) o "47 − 7" (se quitan las unidades).
Question sub100Question(Random r) {
  final int a, b;
  if (r.nextBool()) {
    a = 10 * (2 + r.nextInt(9));
    b = 10 * (1 + r.nextInt(a ~/ 10 - 1));
  } else {
    final u = 1 + r.nextInt(9);
    a = 10 * (1 + r.nextInt(9)) + u;
    b = u;
  }
  final d = a - b;
  final options = _options(r, d, [d + 10, d - 10, d + 1, d - 1, a]);
  return Question(
    prompt: '$a − $b = ?',
    options: [for (final o in options) '$o'],
    answerIndex: options.indexOf(d),
    speech: minus(a, b),
    speechLang: Lang.native,
    tables: TablesQuestion(
      hint: b % 10 == 0
          ? tr('${a ~/ 10} decenas − ${b ~/ 10} decenas = ${d ~/ 10} decenas', '${a ~/ 10} tens − ${b ~/ 10} tens = ${d ~/ 10} tens')
          : tr('$a − $b: se quitan las unidades', '$a − $b: take away the ones'),
      explain: [ExplainStep(minusIsTouch(a, b), Lang.native, highlightAnswer: true)],
    ),
  );
}

/// Un juego de la sección Tablas (se guarda su progreso con [key]).
class TablesLevel {
  const TablesLevel(this.key, this.icon, this.nameEs, this.nameEn, this.make);
  final String key;
  final String icon;
  final String nameEs;
  final String nameEn;
  final QuestionMaker make;

  String get label => '$icon ${tr(nameEs, nameEn)}';
}

final tablesLevels = [
  TablesLevel('tablas-2-5-10', '✖️', 'Tablas del 2, 5 y 10', 'Tables of 2, 5 and 10', (r) => tableQuestion(r, [2, 5, 10])),
  const TablesLevel('suma-100', '➕', 'Sumar hasta 100', 'Add up to 100', sum100Question),
  TablesLevel('tablas-3-4', '✖️', 'Tablas del 3 y 4', 'Tables of 3 and 4', (r) => tableQuestion(r, [3, 4])),
  TablesLevel('tablas-6-9', '✖️', 'Tablas del 6 al 9', 'Tables of 6 to 9', (r) => tableQuestion(r, [6, 7, 8, 9])),
  const TablesLevel('resta-100', '➖', 'Restar hasta 100', 'Subtract up to 100', sub100Question),
  TablesLevel('tablas-mix', '🔀', 'Tablas mezcladas', 'Mixed tables', (r) => tableQuestion(r, [2, 3, 4, 5, 6, 7, 8, 9, 10])),
];

/// Todas las frases de la sección Tablas en el idioma actual (para grabarlas).
Iterable<String> get tablesPhrases sync* {
  for (var a = 2; a <= 10; a++) {
    for (var b = 1; b <= 10; b++) {
      yield times(a, b);
      yield timesMeans(a, b);
      yield timesIs(a, b);
    }
  }
  for (var a = 10; a <= 90; a += 10) {
    for (var b = 10; a + b <= 100; b += 10) {
      yield plus(a, b);
      yield plusIsTouch(a, b);
    }
    for (var b = 1; b <= 9; b++) {
      yield plus(a, b);
      yield plusIsTouch(a, b);
      yield minus(a + b, b);
      yield minusIsTouch(a + b, b);
    }
  }
  for (var a = 20; a <= 100; a += 10) {
    for (var b = 10; b < a; b += 10) {
      yield minus(a, b);
      yield minusIsTouch(a, b);
    }
  }
  // Los números del 0 al 100 (para contar de 3 en 3 y para felicitar con la respuesta).
  for (var n = 0; n <= 100; n++) {
    yield '$n';
    yield greatNumber('$n');
    yield touchedNumber('$n');
  }
}
