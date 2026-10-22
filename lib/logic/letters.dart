import 'dart:math';

import 'content.dart';
import 'lang.dart';
import 'questions.dart';

/// Sección "Letras": el abecedario y las primeras lecturas, en el idioma del niño
/// (en español aprende las letras del español; en inglés, las del inglés).

/// Una letra y cómo se llama en voz alta ("be", "bee").
typedef Letter = ({String upper, String name});

const _lettersEs = <Letter>[
  (upper: 'A', name: 'a'), (upper: 'B', name: 'be'), (upper: 'C', name: 'ce'), (upper: 'D', name: 'de'),
  (upper: 'E', name: 'e'), (upper: 'F', name: 'efe'), (upper: 'G', name: 'ge'), (upper: 'H', name: 'hache'),
  (upper: 'I', name: 'i'), (upper: 'J', name: 'jota'), (upper: 'K', name: 'ka'), (upper: 'L', name: 'ele'),
  (upper: 'M', name: 'eme'), (upper: 'N', name: 'ene'), (upper: 'Ñ', name: 'eñe'), (upper: 'O', name: 'o'),
  (upper: 'P', name: 'pe'), (upper: 'Q', name: 'cu'), (upper: 'R', name: 'erre'), (upper: 'S', name: 'ese'),
  (upper: 'T', name: 'te'), (upper: 'U', name: 'u'), (upper: 'V', name: 'uve'), (upper: 'W', name: 'uve doble'),
  (upper: 'X', name: 'equis'), (upper: 'Y', name: 'ye'), (upper: 'Z', name: 'zeta'),
];

// Escritas como suenan, para que la voz en inglés diga el nombre de la letra (y no "a" como artículo).
const _lettersEn = <Letter>[
  (upper: 'A', name: 'ay'), (upper: 'B', name: 'bee'), (upper: 'C', name: 'see'), (upper: 'D', name: 'dee'),
  (upper: 'E', name: 'ee'), (upper: 'F', name: 'ef'), (upper: 'G', name: 'gee'), (upper: 'H', name: 'aitch'),
  (upper: 'I', name: 'eye'), (upper: 'J', name: 'jay'), (upper: 'K', name: 'kay'), (upper: 'L', name: 'el'),
  (upper: 'M', name: 'em'), (upper: 'N', name: 'en'), (upper: 'O', name: 'oh'), (upper: 'P', name: 'pee'),
  (upper: 'Q', name: 'cue'), (upper: 'R', name: 'ar'), (upper: 'S', name: 'ess'), (upper: 'T', name: 'tee'),
  (upper: 'U', name: 'you'), (upper: 'V', name: 'vee'), (upper: 'W', name: 'double you'), (upper: 'X', name: 'ex'),
  (upper: 'Y', name: 'why'), (upper: 'Z', name: 'zee'),
];

/// El abecedario del idioma del niño.
List<Letter> get alphabet => Lang.current == AppLang.es ? _lettersEs : _lettersEn;

Letter letterOf(String upper) => alphabet.firstWhere((l) => l.upper == upper);

/// Lo que se ve y se dice en una pregunta de letras.
class LetterQuestion {
  const LetterQuestion({this.picture, required this.display, required this.praise, required this.explain, this.words = false});

  /// Dibujo grande (en "¿Con qué letra empieza?" y "Lee la palabra").
  final String? picture;

  /// Texto grande: la letra ("A") o la palabra sin su primera letra ("_erro").
  final String display;

  /// Lo que dice Owlito al acertar.
  final String praise;

  /// Lo que dice Owlito al equivocarse (la última frase resalta la respuesta).
  final List<String> explain;

  /// Las opciones son palabras (una debajo de otra), no letras.
  final bool words;
}

// ---------- Frases ----------

String whereIsLetter(Letter l) => tr('¿Dónde está la letra ${l.name}?', 'Where is the letter ${l.name}?');
String thisIsLetter(Letter l) => tr('Esta es la ${l.name}. ¡Tócala!', 'This is ${l.name}. Touch it!');
String greatLetter(Letter l) => tr('¡Muy bien! Es la ${l.name}.', 'Great! It is ${l.name}.');
String whichSmall(Letter l) => tr('¿Cuál es la ${l.name} minúscula?', 'Which one is small ${l.name}?');
String thisIsSmall(Letter l) => tr('La ${l.name} minúscula es esta. ¡Tócala!', 'This is small ${l.name}. Touch it!');
String greatSmall(Letter l) => tr('¡Muy bien! Es la ${l.name} minúscula.', 'Great! That is small ${l.name}.');
String startsWithWhat(String word) => tr('¿Con qué letra empieza $word?', 'What letter does $word start with?');
String startsWithLetter(String word, Letter l) =>
    tr('$word empieza con la ${l.name}. ¡Toca la ${l.name}!', '$word starts with ${l.name}. Touch ${l.name}!');
String greatStarts(String word, Letter l) =>
    tr('¡Muy bien! $word empieza con la ${l.name}.', 'Great! $word starts with ${l.name}.');
String get whichWord => tr('¿Qué palabra es este dibujo?', 'Which word is this picture?');
String saysWord(String word) => tr('Aquí dice $word. ¡Tócala!', 'This one says $word. Touch it!');
String greatWord(String word) => tr('¡Muy bien! Dice $word.', 'Great! It says $word.');

// ---------- Palabras para leer ----------

/// Temas con dibujos claros para leer (sin colores, números, saludos ni acciones).
const _readingTopics = ['animales', 'frutas', 'cuerpo', 'ropa', 'comida', 'casa', 'escuela', 'clima', 'vehiculos', 'juguetes', 'mar'];

/// Palabras del idioma del niño, de una sola palabra y no muy largas, que empiezan con una letra que suena
/// como su nombre: sin la hache muda ni "ll"/"ch" en español, ni "sh"/"ch"/"th"/"wh" en inglés.
List<({String word, String picture, String topic})> get readingWords => [
      for (final t in topics)
        if (_readingTopics.contains(t.key))
          for (final w in t.words)
            if (_good(tr(w.es, w.en))) (word: tr(w.es, w.en), picture: w.picture, topic: t.key),
    ];

bool _good(String word) {
  if (word.contains(' ') || word.length > 8 || word != word.toLowerCase()) return false;
  final start = word.length < 2 ? word : word.substring(0, 2);
  final tricky = Lang.current == AppLang.es ? const ['ll', 'ch'] : const ['sh', 'ch', 'th', 'wh', 'kn', 'wr', 'ey'];
  if (tricky.contains(start)) return false;
  final first = _plain(word[0]).toUpperCase();
  if (Lang.current == AppLang.es && first == 'H') return false;
  return alphabet.any((l) => l.upper == first);
}

/// Sin tilde (la primera letra de "árbol" es la A).
String _plain(String c) => const {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'}[c] ?? c;

Letter firstLetter(String word) => letterOf(_plain(word[0]).toUpperCase());

/// La palabra escrita con la primera letra escondida: "_erro".
String hideFirst(String word) => '_${word.substring(1)}';

// ---------- Preguntas ----------

List<Letter> _withDistractors(Random r, Letter answer, {Set<String> avoid = const {}}) {
  final others = alphabet.where((l) => l != answer && !avoid.contains(l.upper)).toList()..shuffle(r);
  return [answer, ...others.take(2)]..shuffle(r);
}

/// "¿Dónde está la letra be?": toca la letra que dice Owlito.
Question findLetterQuestion(Random r) {
  final answer = alphabet[r.nextInt(alphabet.length)];
  final options = _withDistractors(r, answer);
  return Question(
    prompt: tr('Toca la letra', 'Touch the letter'),
    options: [for (final o in options) o.upper],
    answerIndex: options.indexOf(answer),
    speech: whereIsLetter(answer),
    speechLang: Lang.native,
    letters: LetterQuestion(display: '', praise: greatLetter(answer), explain: [thisIsLetter(answer)]),
  );
}

/// "¿Con qué letra empieza perro?": dibujo y palabra sin su primera letra.
Question startsWithQuestion(Random r) {
  final words = readingWords;
  final w = words[r.nextInt(words.length)];
  final answer = firstLetter(w.word);
  final options = _withDistractors(r, answer);
  return Question(
    prompt: tr('¿Con qué letra empieza?', 'What letter does it start with?'),
    options: [for (final o in options) o.upper],
    answerIndex: options.indexOf(answer),
    speech: startsWithWhat(w.word),
    speechLang: Lang.native,
    letters: LetterQuestion(
      picture: w.picture,
      display: hideFirst(w.word),
      praise: greatStarts(w.word, answer),
      explain: [startsWithLetter(w.word, answer)],
    ),
  );
}

/// "¿Cuál es la be minúscula?": se ve la mayúscula y se elige la minúscula.
Question lowercaseQuestion(Random r) {
  final answer = alphabet[r.nextInt(alphabet.length)];
  final options = _withDistractors(r, answer);
  return Question(
    prompt: tr('¿Cuál es su minúscula?', 'Which is its small letter?'),
    options: [for (final o in options) o.upper.toLowerCase()],
    answerIndex: options.indexOf(answer),
    speech: whichSmall(answer),
    speechLang: Lang.native,
    letters: LetterQuestion(display: answer.upper, praise: greatSmall(answer), explain: [thisIsSmall(answer)]),
  );
}

/// "¿Qué palabra es este dibujo?": se lee la palabra correcta entre tres del mismo tema.
Question readWordQuestion(Random r) {
  final words = readingWords;
  final w = words[r.nextInt(words.length)];
  final same = words.where((o) => o.topic == w.topic && o.word != w.word).toList()..shuffle(r);
  final rest = words.where((o) => o.topic != w.topic && o.word != w.word).toList()..shuffle(r);
  // Del mismo tema (para que haya que leer, no adivinar por el dibujo); si no alcanzan, de otros.
  final others = [...same, ...rest];
  final options = [w.word, ...others.take(2).map((o) => o.word)]..shuffle(r);
  return Question(
    prompt: tr('Lee y toca la palabra', 'Read and touch the word'),
    options: options,
    answerIndex: options.indexOf(w.word),
    speech: whichWord,
    speechLang: Lang.native,
    letters: LetterQuestion(picture: w.picture, display: '', praise: greatWord(w.word), explain: [saysWord(w.word)], words: true),
  );
}

/// Un juego de la sección Letras (se guarda su progreso con [key]).
class LetterLevel {
  const LetterLevel(this.key, this.icon, this.nameEs, this.nameEn, this.make);
  final String key;
  final String icon;
  final String nameEs;
  final String nameEn;
  final QuestionMaker make;

  String get label => '$icon ${tr(nameEs, nameEn)}';
}

const letterLevels = [
  LetterLevel('letras-cual', '🔤', '¿Dónde está la letra?', 'Find the letter', findLetterQuestion),
  LetterLevel('letras-empieza', '🍎', '¿Con qué letra empieza?', 'First letter', startsWithQuestion),
  LetterLevel('letras-minuscula', '🔡', 'Mayúscula y minúscula', 'Big and small letters', lowercaseQuestion),
  LetterLevel('letras-leer', '📖', 'Lee la palabra', 'Read the word', readWordQuestion),
];

/// Todas las frases de la sección Letras en el idioma actual (para grabarlas).
Iterable<String> get letterPhrases sync* {
  for (final l in alphabet) {
    yield whereIsLetter(l);
    yield thisIsLetter(l);
    yield greatLetter(l);
    yield whichSmall(l);
    yield thisIsSmall(l);
    yield greatSmall(l);
  }
  yield whichWord;
  for (final w in readingWords) {
    final l = firstLetter(w.word);
    yield startsWithWhat(w.word);
    yield startsWithLetter(w.word, l);
    yield greatStarts(w.word, l);
    yield saysWord(w.word);
    yield greatWord(w.word);
  }
}
