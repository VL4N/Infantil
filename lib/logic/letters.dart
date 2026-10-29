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
  const LetterQuestion({
    this.picture,
    required this.display,
    required this.praise,
    required this.explain,
    this.words = false,
    this.sentence = false,
  });

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

  /// [display] es una oración (se ve más chica que una letra o una palabra).
  final bool sentence;
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

String get readAndTouchPicture => tr('Lee la oración y toca el dibujo.', 'Read the sentence and touch the picture.');
String get readAndComplete => tr('Lee y completa la oración.', 'Read and finish the sentence.');
String saysSentence(String sentence) => tr('Aquí dice: $sentence', 'It says: $sentence');
String greatSentence(String sentence) => tr('¡Muy bien! $sentence', 'Great! $sentence');
String completeIs(String sentence, String word) =>
    tr('$sentence ¡Toca $word!', '$sentence Touch $word!');

// ---------- Oraciones para leer ----------

/// Oración con su dibujo, en los dos idiomas.
typedef Sentence = ({String picture, String es, String en});

/// De a tres, con dibujos que se parecen ("La manzana es roja" y "La manzana es verde"):
/// las opciones son los tres dibujos de un grupo, así hay que leer la oración entera.
const sentenceGroups = <List<Sentence>>[
  [
    (picture: '🍎', es: 'La manzana es roja.', en: 'The apple is red.'),
    (picture: '🍏', es: 'La manzana es verde.', en: 'The apple is green.'),
    (picture: '🍌', es: 'El plátano es amarillo.', en: 'The banana is yellow.'),
  ],
  [
    (picture: '☀️', es: 'El sol brilla de día.', en: 'The sun shines in the day.'),
    (picture: '🌙', es: 'La luna sale de noche.', en: 'The moon comes out at night.'),
    (picture: '⭐', es: 'Las estrellas brillan de noche.', en: 'The stars shine at night.'),
  ],
  [
    (picture: '🐟', es: 'El pez nada en el agua.', en: 'The fish swims in the water.'),
    (picture: '🐦', es: 'El pájaro vuela alto.', en: 'The bird flies high.'),
    (picture: '🐸', es: 'La rana salta.', en: 'The frog jumps.'),
  ],
  [
    (picture: '🐶', es: 'El perro ladra.', en: 'The dog barks.'),
    (picture: '🐱', es: 'El gato toma leche.', en: 'The cat drinks milk.'),
    (picture: '🐮', es: 'La vaca da leche.', en: 'The cow gives milk.'),
  ],
  [
    (picture: '🌧️', es: 'Hoy llueve mucho.', en: 'It is raining a lot.'),
    (picture: '⛄', es: 'Hace mucho frío.', en: 'It is very cold.'),
    (picture: '🌈', es: 'Salió el arcoíris.', en: 'The rainbow came out.'),
  ],
  [
    (picture: '🚗', es: 'El carro es rojo.', en: 'The car is red.'),
    (picture: '🚌', es: 'El autobús es grande.', en: 'The bus is big.'),
    (picture: '🚲', es: 'La bici tiene dos ruedas.', en: 'The bike has two wheels.'),
  ],
  [
    (picture: '🎂', es: 'Hoy es mi cumpleaños.', en: 'Today is my birthday.'),
    (picture: '🎈', es: 'Tengo un globo.', en: 'I have a balloon.'),
    (picture: '🎁', es: 'Tengo un regalo.', en: 'I have a present.'),
  ],
  [
    (picture: '😴', es: 'El niño tiene sueño.', en: 'The boy is sleepy.'),
    (picture: '😋', es: 'La niña tiene hambre.', en: 'The girl is hungry.'),
    (picture: '😢', es: 'El bebé llora.', en: 'The baby cries.'),
  ],
  [
    (picture: '🍕', es: 'Me gusta la pizza.', en: 'I like pizza.'),
    (picture: '🍦', es: 'El helado está frío.', en: 'The ice cream is cold.'),
    (picture: '🍪', es: 'La galleta es dulce.', en: 'The cookie is sweet.'),
  ],
  [
    (picture: '🦁', es: 'El león es fuerte.', en: 'The lion is strong.'),
    (picture: '🐢', es: 'La tortuga es lenta.', en: 'The turtle is slow.'),
    (picture: '🐇', es: 'El conejo es rápido.', en: 'The rabbit is fast.'),
  ],
  [
    (picture: '🌳', es: 'El árbol es alto.', en: 'The tree is tall.'),
    (picture: '🌸', es: 'La flor huele bien.', en: 'The flower smells nice.'),
    (picture: '🍂', es: 'Las hojas se caen.', en: 'The leaves fall.'),
  ],
  [
    (picture: '⚽', es: 'Juego con la pelota.', en: 'I play with the ball.'),
    (picture: '📚', es: 'Leo un libro.', en: 'I read a book.'),
    (picture: '🎨', es: 'Pinto un dibujo.', en: 'I paint a picture.'),
  ],
];

/// Oración con una palabra que falta ("El pájaro ___ alto."), la palabra y dos que no van.
typedef Blank = ({String text, String answer, List<String> wrong});

const _blanksEs = <Blank>[
  (text: 'El pájaro ___ alto.', answer: 'vuela', wrong: ['nada', 'ladra']),
  (text: 'El pez ___ en el agua.', answer: 'nada', wrong: ['vuela', 'corre']),
  (text: 'El perro ___ fuerte.', answer: 'ladra', wrong: ['lee', 'vuela']),
  (text: 'Yo ___ un libro.', answer: 'leo', wrong: ['bebo', 'duermo']),
  (text: 'Yo ___ agua.', answer: 'bebo', wrong: ['leo', 'canto']),
  (text: 'La vaca da ___.', answer: 'leche', wrong: ['pan', 'sol']),
  (text: 'De noche sale la ___.', answer: 'luna', wrong: ['mesa', 'sopa']),
  (text: 'El cielo es ___.', answer: 'azul', wrong: ['rápido', 'dulce']),
  (text: 'Me lavo las manos con ___.', answer: 'jabón', wrong: ['arena', 'leche']),
  (text: 'El hielo está muy ___.', answer: 'frío', wrong: ['caliente', 'alto']),
  (text: 'Veo con los ___.', answer: 'ojos', wrong: ['pies', 'dientes']),
  (text: 'Oigo con las ___.', answer: 'orejas', wrong: ['manos', 'rodillas']),
  (text: 'El gato dice ___.', answer: 'miau', wrong: ['guau', 'mu']),
  (text: 'Duermo en mi ___.', answer: 'cama', wrong: ['sopa', 'nube']),
  (text: 'Cuando llueve abro mi ___.', answer: 'paraguas', wrong: ['helado', 'zapato']),
  (text: 'El fuego es muy ___.', answer: 'caliente', wrong: ['frío', 'suave']),
  (text: 'Las abejas hacen ___.', answer: 'miel', wrong: ['leche', 'pan']),
  (text: 'Me pongo los ___ en los pies.', answer: 'zapatos', wrong: ['guantes', 'lentes']),
  (text: 'El conejo come ___.', answer: 'zanahorias', wrong: ['piedras', 'sillas']),
  (text: 'Me cepillo los ___.', answer: 'dientes', wrong: ['zapatos', 'libros']),
];

const _blanksEn = <Blank>[
  (text: 'The bird ___ high.', answer: 'flies', wrong: ['swims', 'barks']),
  (text: 'The fish ___ in the water.', answer: 'swims', wrong: ['flies', 'reads']),
  (text: 'The dog ___ loudly.', answer: 'barks', wrong: ['reads', 'flies']),
  (text: 'I ___ a book.', answer: 'read', wrong: ['drink', 'sleep']),
  (text: 'I ___ water.', answer: 'drink', wrong: ['read', 'sing']),
  (text: 'The cow gives ___.', answer: 'milk', wrong: ['bread', 'sun']),
  (text: 'At night we see the ___.', answer: 'moon', wrong: ['table', 'soup']),
  (text: 'The sky is ___.', answer: 'blue', wrong: ['fast', 'sweet']),
  (text: 'I wash my hands with ___.', answer: 'soap', wrong: ['sand', 'milk']),
  (text: 'The ice is very ___.', answer: 'cold', wrong: ['hot', 'tall']),
  (text: 'I see with my ___.', answer: 'eyes', wrong: ['feet', 'teeth']),
  (text: 'I hear with my ___.', answer: 'ears', wrong: ['hands', 'knees']),
  (text: 'The cat says ___.', answer: 'meow', wrong: ['woof', 'moo']),
  (text: 'I sleep in my ___.', answer: 'bed', wrong: ['soup', 'cloud']),
  (text: 'When it rains I open my ___.', answer: 'umbrella', wrong: ['ice cream', 'shoe']),
  (text: 'Fire is very ___.', answer: 'hot', wrong: ['cold', 'soft']),
  (text: 'Bees make ___.', answer: 'honey', wrong: ['milk', 'bread']),
  (text: 'I put ___ on my feet.', answer: 'shoes', wrong: ['gloves', 'glasses']),
  (text: 'The rabbit eats ___.', answer: 'carrots', wrong: ['rocks', 'soap']),
  (text: 'I brush my ___.', answer: 'teeth', wrong: ['shoes', 'books']),
];

List<Blank> get blanks => Lang.current == AppLang.es ? _blanksEs : _blanksEn;

/// La oración completa: "El pájaro vuela alto."
String filled(Blank b) => b.text.replaceFirst('___', b.answer);

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

/// "Lee la oración y toca el dibujo": las opciones son los tres dibujos de un grupo.
Question readSentenceQuestion(Random r) {
  final group = sentenceGroups[r.nextInt(sentenceGroups.length)];
  final answer = group[r.nextInt(group.length)];
  final options = [...group]..shuffle(r);
  final text = tr(answer.es, answer.en);
  return Question(
    prompt: tr('Lee y toca el dibujo', 'Read and touch the picture'),
    options: [for (final o in options) o.picture],
    answerIndex: options.indexOf(answer),
    speech: readAndTouchPicture,
    speechLang: Lang.native,
    letters: LetterQuestion(display: text, praise: greatSentence(text), explain: [saysSentence(text)], sentence: true),
  );
}

/// "El pájaro ___ alto.": se elige la palabra que falta (una debajo de otra).
Question completeSentenceQuestion(Random r) {
  final b = blanks[r.nextInt(blanks.length)];
  final options = [b.answer, ...b.wrong]..shuffle(r);
  return Question(
    prompt: tr('Completa la oración', 'Finish the sentence'),
    options: options,
    answerIndex: options.indexOf(b.answer),
    speech: readAndComplete,
    speechLang: Lang.native,
    letters: LetterQuestion(
      display: b.text,
      praise: greatSentence(filled(b)),
      explain: [completeIs(filled(b), b.answer)],
      words: true,
      sentence: true,
    ),
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
  LetterLevel('letras-frase', '📝', 'Lee la oración', 'Read the sentence', readSentenceQuestion),
  LetterLevel('letras-completa', '✏️', 'Completa la oración', 'Finish the sentence', completeSentenceQuestion),
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
  yield readAndTouchPicture;
  yield readAndComplete;
  for (final group in sentenceGroups) {
    for (final sentence in group) {
      final text = tr(sentence.es, sentence.en);
      yield saysSentence(text);
      yield greatSentence(text);
    }
  }
  for (final b in blanks) {
    yield greatSentence(filled(b));
    yield completeIs(filled(b), b.answer);
  }
}
