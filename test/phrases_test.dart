import 'dart:io';
import 'dart:math';

import 'package:aprende_jugando/logic/content.dart';
import 'package:aprende_jugando/logic/phrases.dart';
import 'package:aprende_jugando/logic/questions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = allPhrases();

  /// Todo lo que puede decir la voz con una pregunta: al mostrarla, al acertar y al equivocarse.
  Iterable<(String, String)> spoken(Question q) sync* {
    final lang = q.speechLang;
    if (q.intro != null) yield (q.intro!, 'es');
    yield (q.ask ?? q.speech, q.askLang ?? lang);
    yield (q.speech, lang);
    if (lang == 'en') {
      yield (praiseFirstTry, 'es');
      yield (praiseRetry, 'es');
      for (final o in q.optionWords ?? const <String>[]) {
        yield (o, 'en');
      }
    } else {
      yield (q.answer, 'es');
      yield ('¡Muy bien, ${q.answer}!', 'es');
    }
    for (var i = 0; i < q.options.length; i++) {
      if (i == q.answerIndex) continue;
      for (final step in explainMistake(q, i)) {
        yield (step.text, step.lang);
      }
    }
  }

  test('todas las frases de las sumas y restas están grabadas', () {
    final r = Random(7);
    final missing = <String>{};
    for (final (max, _) in mathLevels) {
      for (var i = 0; i < 3000; i++) {
        for (final p in spoken(mathQuestion(r, max))) {
          if (!catalog.contains(p)) missing.add('${p.$2}: ${p.$1}');
        }
        for (final p in spoken(subtractionQuestion(r, max))) {
          if (!catalog.contains(p)) missing.add('${p.$2}: ${p.$1}');
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('todas las frases de inglés están grabadas', () {
    final r = Random(8);
    final missing = <String>{};
    for (final topic in topics) {
      for (var i = 0; i < 800; i++) {
        for (final p in spoken(englishMixedQuestion(r, topic))) {
          if (!catalog.contains(p)) missing.add('${p.$2}: ${p.$1}');
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('las frases fijas de las pantallas están grabadas', () {
    // Busca Voice.say('texto fijo', 'idioma') en el código de las pantallas.
    final literal = RegExp(r"""Voice\.say\('([^'$]*)',\s*'(es|en)'\)""");
    final missing = <String>{};
    var found = 0;
    for (final file in Directory('lib/screens').listSync().whereType<File>()) {
      for (final m in literal.allMatches(file.readAsStringSync())) {
        found++;
        if (!catalog.contains((m[1]!, m[2]!))) missing.add('${m[2]}: ${m[1]}');
      }
    }
    expect(found, greaterThan(3), reason: 'la búsqueda debería encontrar frases fijas');
    expect(missing, isEmpty);
  });

  test('los nombres de archivo no se repiten y son estables', () {
    final names = {for (final (t, l) in catalog) clipName(t, l)};
    expect(names.length, catalog.length);
    // Mismo valor que calcula tool/generar_voces.py.
    expect(clipName('Great job!', 'en'), 'e52d14e578541d93.mp3');
  });
}
