import 'content.dart';
import 'lang.dart';
import 'lines.dart';
import 'numbers.dart';
import 'questions.dart';

/// Catálogo de TODO lo que dice la voz de la app, para grabarlo de antemano con una
/// voz natural (Piper) incluida en la app. Así suena igual en todos los teléfonos,
/// sin depender del motor de voz de cada uno. Lo que no esté aquí se dice con la voz
/// del teléfono, como respaldo. test/phrases_test.dart comprueba que no falte nada.
///
/// Cada frase es (texto, idioma) con idioma 'es' o 'en'. Incluye la app en los dos idiomas:
/// en español (aprende inglés) y en inglés (aprende español).
Set<(String, String)> allPhrases() {
  final p = <(String, String)>{};
  final before = Lang.current;
  try {
    for (final lang in AppLang.values) {
      Lang.current = lang;
      _addPhrases(p);
    }
  } finally {
    Lang.current = before;
  }
  return p;
}

/// Las frases de la app en el idioma actual ([Lang.current]).
void _addPhrases(Set<(String, String)> p) {
  void native(String t) => p.add((t, Lang.native));
  void target(String t) => p.add((t, Lang.target));

  // Frases fijas de las pantallas y de las preguntas.
  for (final t in [
    ...screenLines,
    ...howManyPhrases,
    letsCount,
    countWhatsLeft,
    almostYouTouched,
    countTogetherInTarget,
    thisPictureIs,
    almostThatPictureIs,
    andThisOneIs,
    touchIt,
    askWhatIs,
    askHowMany,
    listenAndTouch,
    praiseFirstTry,
    praiseRetry,
    askNext,
    askBigger,
    countByTwo,
  ]) {
    native(t);
  }
  for (var n = 1; n <= 20; n++) {
    native(biggerIs(n));
  }

  // Números: en palabras (al contar) y en cifras (al acertar), y lo que tocó al equivocarse.
  for (var n = 0; n <= maxOption; n++) {
    native(numberWord(n));
    native('$n');
    native(greatNumber('$n'));
    native(touchedNumber('$n'));
    native(touchTheNumber(n));
  }

  // Sumas de todos los niveles.
  final maxSum = mathLevels.map((l) => l.$1).reduce((a, b) => a > b ? a : b);
  for (var a = 1; a <= maxSum; a++) {
    native(thereAre(a));
    for (var b = 1; a + b <= maxSum; b++) {
      final s = a + b;
      native(plus(a, b));
      native(plusWhat(a, s));
      native(weHaveCountTo(a, s));
      native(countedMore(a, b, s));
      native(startAndCountOn(a, b));
      native(plusIs(a, b, s));
    }
  }

  // Restas de todos los niveles (frases cortas, para no grabar todas las combinaciones).
  for (var a = 2; a <= maxSum; a++) {
    native(weHave(a));
    native(startAt(a));
    for (var b = 1; b < a; b++) {
      native(minus(a, b));
      native(minusIs(a, b));
    }
  }
  for (var b = 1; b < maxSum; b++) {
    native(takeAway(b));
    native(countBack(b));
  }

  // Idioma que aprende: cada palabra sola.
  for (final topic in topics) {
    for (final word in topic.words) {
      target(word.text);
    }
  }
}

/// Nombre del archivo de audio de una frase: un hash estable del idioma y el texto
/// (FNV-1a de 64 bits). El script que genera los audios (tool/generar_voces.py)
/// usa exactamente la misma fórmula.
String clipName(String text, String lang) {
  var h = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final byte in _utf8('$lang|$text')) {
    h = ((h ^ BigInt.from(byte)) * prime) & mask;
  }
  return '${h.toRadixString(16).padLeft(16, '0')}.mp3';
}

List<int> _utf8(String s) {
  final out = <int>[];
  for (final rune in s.runes) {
    if (rune < 0x80) {
      out.add(rune);
    } else if (rune < 0x800) {
      out..add(0xC0 | (rune >> 6))..add(0x80 | (rune & 0x3F));
    } else if (rune < 0x10000) {
      out..add(0xE0 | (rune >> 12))..add(0x80 | ((rune >> 6) & 0x3F))..add(0x80 | (rune & 0x3F));
    } else {
      out
        ..add(0xF0 | (rune >> 18))
        ..add(0x80 | ((rune >> 12) & 0x3F))
        ..add(0x80 | ((rune >> 6) & 0x3F))
        ..add(0x80 | (rune & 0x3F));
    }
  }
  return out;
}
