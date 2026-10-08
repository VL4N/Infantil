import 'content.dart';
import 'questions.dart';

/// Catálogo de TODO lo que dice la voz de la app, para grabarlo de antemano con una
/// voz natural (Piper) incluida en la app. Así suena igual en todos los teléfonos,
/// sin depender del motor de voz de cada uno. Lo que no esté aquí se dice con la voz
/// del teléfono, como respaldo. test/phrases_test.dart comprueba que no falte nada.
///
/// Cada frase es (texto, idioma) con idioma 'es' o 'en'.
Set<(String, String)> allPhrases() {
  final p = <(String, String)>{};
  void es(String t) => p.add((t, 'es'));
  void en(String t) => p.add((t, 'en'));

  // Frases fijas de las pantallas.
  for (final t in [
    '¡Repasemos!',
    'Pide ayuda a papá o a mamá',
    'Busca las parejas',
    '¡Eres una estrella!',
    '¡Muy bien!',
    '¡Sigue practicando!',
    '¿Cuántos hay?',
    letsCount,
    'Casi. Tocaste',
    'Contemos juntos en inglés',
    'Este dibujo en inglés se dice',
    'Casi. Ese dibujo en inglés se dice',
    'Y este es',
    '¡Tócalo!',
  ]) {
    es(t);
  }
  for (final t in ['Great job!', 'How many?', 'What is this?']) {
    en(t);
  }

  // Números: en palabras (al contar) y en cifras (al acertar), y lo que tocó al equivocarse.
  const maxNumber = 23; // la suma más grande (20) + 3 de las opciones incorrectas
  for (var n = 0; n <= maxNumber; n++) {
    es(numberWord(n));
    es('$n');
    es('¡Muy bien, $n!');
    es(touchedNumber('$n'));
  }

  // Sumas de todos los niveles.
  final maxSum = mathLevels.map((l) => l.$1).reduce((a, b) => a > b ? a : b);
  for (var a = 1; a <= maxSum; a++) {
    es('Hay $a. ¡Toca el $a!');
    for (var b = 1; a + b <= maxSum; b++) {
      final s = a + b;
      es('$a más $b');
      es('$a más cuánto es $s');
      es('Tenemos $a, ¡contemos hasta $s!');
      es('Contamos $b más. $a más $b son $s. ¡Toca el $b!');
      es('Empezamos en el $a, y contamos $b más.');
      es('$a más $b son $s. ¡Toca el $s!');
    }
  }

  // Inglés: cada palabra sola, y las felicitaciones con la palabra.
  for (final topic in topics) {
    for (final (word, _) in topic.words) {
      en(word);
      en('Yes! $word');
      en('Very good! $word');
    }
  }
  for (final word in englishNumbers) {
    en(word);
    en('Yes! $word');
    en('Very good! $word');
  }
  return p;
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
