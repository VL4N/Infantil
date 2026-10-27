import 'dart:io';
import 'dart:math';

import 'package:aprende_jugando/logic/content.dart';
import 'package:aprende_jugando/logic/lang.dart';
import 'package:aprende_jugando/logic/letters.dart';
import 'package:aprende_jugando/logic/tables.dart';
import 'package:aprende_jugando/logic/lines.dart';
import 'package:aprende_jugando/logic/numbers.dart';
import 'package:aprende_jugando/logic/phrases.dart';
import 'package:aprende_jugando/logic/questions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = allPhrases();
  tearDown(() => Lang.current = AppLang.es);

  /// Todo lo que puede decir la voz con una pregunta: al mostrarla, al acertar y al equivocarse.
  Iterable<(String, String)> spoken(Question q) sync* {
    final lang = q.speechLang;
    if (q.intro != null) yield (q.intro!, Lang.native);
    yield (q.ask ?? q.speech, q.askLang ?? lang);
    yield (q.speech, lang);
    if (q.letters case final l?) {
      yield (l.praise, Lang.native);
    } else if (lang == Lang.target) {
      yield (praiseFirstTry, Lang.native);
      yield (praiseRetry, Lang.native);
      for (final o in q.optionWords ?? const <String>[]) {
        yield (o, Lang.target);
      }
    } else {
      yield (q.answer, Lang.native);
      yield (greatNumber(q.answer), Lang.native);
    }
    for (var i = 0; i < q.options.length; i++) {
      if (i == q.answerIndex) continue;
      for (final step in explainMistake(q, i)) {
        yield (step.text, step.lang);
      }
    }
  }

  for (final lang in AppLang.values) {
    test('todas las frases de las sumas y restas están grabadas (${lang.name})', () {
      Lang.current = lang;
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

    test('todas las frases de la sección Tablas están grabadas (${lang.name})', () {
      Lang.current = lang;
      final r = Random(12);
      final missing = <String>{};
      for (final level in tablesLevels) {
        for (var i = 0; i < 3000; i++) {
          for (final p in spoken(level.make(r))) {
            if (!catalog.contains(p)) missing.add('${p.$2}: ${p.$1}');
          }
        }
      }
      expect(missing, isEmpty);
    });

    test('todas las frases de la sección Letras están grabadas (${lang.name})', () {
      Lang.current = lang;
      final r = Random(11);
      final missing = <String>{};
      for (final level in letterLevels) {
        for (var i = 0; i < 2000; i++) {
          for (final p in spoken(level.make(r))) {
            if (!catalog.contains(p)) missing.add('${p.$2}: ${p.$1}');
          }
        }
      }
      expect(missing, isEmpty);
    });

    test('todas las frases de la sección Números están grabadas (${lang.name})', () {
      Lang.current = lang;
      final r = Random(9);
      final missing = <String>{};
      for (final level in numberLevels) {
        for (var i = 0; i < 2000; i++) {
          for (final p in spoken(level.make(r))) {
            if (!catalog.contains(p)) missing.add('${p.$2}: ${p.$1}');
          }
        }
      }
      expect(missing, isEmpty);
    });

    test('todas las frases del idioma que aprende están grabadas (${lang.name})', () {
      Lang.current = lang;
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

    test('las frases fijas de las pantallas están grabadas (${lang.name})', () {
      Lang.current = lang;
      expect([for (final t in screenLines) if (!catalog.contains((t, Lang.native))) t], isEmpty);
    });
  }

  test('las pantallas no dicen frases sueltas (todas están en logic/lines.dart)', () {
    // Una frase escrita directo en Voice.say no se graba ni se traduce.
    final literal = RegExp(r"""Voice\.say\(\s*(tr\(|'|")""");
    final found = <String>[];
    for (final file in Directory('lib/screens').listSync().whereType<File>()) {
      for (final m in literal.allMatches(file.readAsStringSync())) {
        found.add('${file.path}: ${m[0]}');
      }
    }
    expect(found, isEmpty);
  });

  test('las palabras de los dos idiomas se graban con la voz de cada idioma', () {
    expect(catalog, containsAll([('dog', 'en'), ('perro', 'es'), ('Great job!', 'en'), ('¡Muy bien!', 'es')]));
    expect(catalog.contains(('perro', 'en')), isFalse);
  });

  test('los nombres de archivo no se repiten y son estables', () {
    final names = {for (final (t, l) in catalog) clipName(t, l)};
    expect(names.length, catalog.length);
    // Mismo valor que calcula tool/generar_voces.py.
    expect(clipName('Great job!', 'en'), 'e52d14e578541d93.ogg');
  });
}
