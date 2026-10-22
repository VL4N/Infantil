import 'lang.dart';
import 'numbers.dart';

/// Una palabra de un tema, en los dos idiomas, con su dibujo.
class Word {
  const Word(this.en, this.es, this.picture);
  final String en;
  final String es;
  final String picture;

  /// La palabra en el idioma que aprende el niño.
  String get text => Lang.target == 'en' ? en : es;
}

class Topic {
  const Topic(this.key, this.emoji, this.nameEs, this.nameEn, this.words);

  /// Para guardar el progreso (no cambia con el idioma).
  final String key;
  final String emoji;
  final String nameEs;
  final String nameEn;
  final List<Word> words;

  String get label => '$emoji ${tr(nameEs, nameEn)}';
}

const topics = [
  Topic('animales', '🐶', 'Animales', 'Animals', [
    Word('dog', 'perro', '🐶'), Word('cat', 'gato', '🐱'), Word('cow', 'vaca', '🐮'), Word('pig', 'cerdo', '🐷'),
    Word('duck', 'pato', '🦆'), Word('fish', 'pez', '🐟'), Word('bird', 'pájaro', '🐦'), Word('horse', 'caballo', '🐴'),
    Word('lion', 'león', '🦁'), Word('monkey', 'mono', '🐵'),
  ]),
  Topic('frutas', '🍎', 'Frutas', 'Fruits', [
    Word('apple', 'manzana', '🍎'), Word('banana', 'plátano', '🍌'), Word('grapes', 'uvas', '🍇'),
    Word('orange', 'naranja', '🍊'), Word('strawberry', 'fresa', '🍓'), Word('pear', 'pera', '🍐'),
    Word('watermelon', 'sandía', '🍉'), Word('cherry', 'cereza', '🍒'), Word('lemon', 'limón', '🍋'),
    Word('pineapple', 'piña', '🍍'),
  ]),
  Topic('colores', '🎨', 'Colores', 'Colors', [
    Word('red', 'rojo', '🟥'), Word('blue', 'azul', '🟦'), Word('green', 'verde', '🟩'), Word('yellow', 'amarillo', '🟨'),
    Word('orange', 'anaranjado', '🟧'), Word('purple', 'morado', '🟪'), Word('black', 'negro', '⬛'),
    Word('white', 'blanco', '⬜'), Word('brown', 'marrón', '🟫'),
  ]),
  Topic('numeros', '🔢', 'Números', 'Numbers', [
    Word('one', 'uno', '1'), Word('two', 'dos', '2'), Word('three', 'tres', '3'), Word('four', 'cuatro', '4'),
    Word('five', 'cinco', '5'), Word('six', 'seis', '6'), Word('seven', 'siete', '7'), Word('eight', 'ocho', '8'),
    Word('nine', 'nueve', '9'), Word('ten', 'diez', '10'),
  ]),
  Topic('cuerpo', '👃', 'Cuerpo', 'Body', [
    Word('eye', 'ojo', '👁️'), Word('ear', 'oreja', '👂'), Word('nose', 'nariz', '👃'), Word('mouth', 'boca', '👄'),
    Word('tooth', 'diente', '🦷'), Word('tongue', 'lengua', '👅'), Word('hand', 'mano', '✋'), Word('arm', 'brazo', '💪'),
    Word('leg', 'pierna', '🦵'), Word('foot', 'pie', '🦶'),
  ]),
  Topic('ropa', '👕', 'Ropa', 'Clothes', [
    Word('shirt', 'camisa', '👕'), Word('pants', 'pantalón', '👖'), Word('dress', 'vestido', '👗'),
    Word('shoes', 'zapatos', '👟'), Word('hat', 'sombrero', '🎩'), Word('socks', 'calcetines', '🧦'),
    Word('coat', 'abrigo', '🧥'), Word('glasses', 'lentes', '👓'), Word('scarf', 'bufanda', '🧣'),
    Word('gloves', 'guantes', '🧤'),
  ]),
  Topic('familia', '👪', 'Familia', 'Family', [
    Word('mom', 'mamá', '👩'), Word('dad', 'papá', '👨'), Word('baby', 'bebé', '👶'), Word('grandma', 'abuela', '👵'),
    Word('grandpa', 'abuelo', '👴'), Word('girl', 'niña', '👧'), Word('boy', 'niño', '👦'), Word('family', 'familia', '👪'),
  ]),
  Topic('saludos', '👋', 'Saludos', 'Greetings', [
    Word('hello', 'hola', '👋'), Word('good morning', 'buenos días', '🌅'), Word('good night', 'buenas noches', '🌙'),
    Word('thank you', 'gracias', '🙏'), Word('yes', 'sí', '👍'), Word('no', 'no', '👎'),
    Word('I love you', 'te quiero', '❤️'), Word('happy birthday', 'feliz cumpleaños', '🎂'),
  ]),
  // Dibujos de emojis antiguos, para que se vean también en teléfonos con Android 7.
  Topic('comida', '🍞', 'Comida', 'Food', [
    Word('bread', 'pan', '🍞'), Word('milk', 'leche', '🥛'), Word('egg', 'huevo', '🥚'), Word('cheese', 'queso', '🧀'),
    Word('rice', 'arroz', '🍚'), Word('pizza', 'pizza', '🍕'), Word('cake', 'pastel', '🍰'), Word('chicken', 'pollo', '🍗'),
    Word('soup', 'sopa', '🍲'), Word('ice cream', 'helado', '🍦'),
  ]),
  Topic('casa', '🏠', 'Casa', 'House', [
    Word('house', 'casa', '🏠'), Word('bed', 'cama', '🛏️'), Word('door', 'puerta', '🚪'), Word('sofa', 'sofá', '🛋️'),
    Word('bathtub', 'bañera', '🛁'), Word('toilet', 'inodoro', '🚽'), Word('key', 'llave', '🔑'), Word('clock', 'reloj', '⏰'),
    Word('TV', 'televisión', '📺'), Word('light', 'luz', '💡'),
  ]),
  Topic('escuela', '🎒', 'Escuela', 'School', [
    Word('school', 'escuela', '🏫'), Word('book', 'libro', '📖'), Word('pencil', 'lápiz', '✏️'),
    Word('backpack', 'mochila', '🎒'), Word('scissors', 'tijeras', '✂️'), Word('crayon', 'crayón', '🖍️'),
    Word('ruler', 'regla', '📏'), Word('paper', 'papel', '📄'), Word('computer', 'computadora', '💻'),
    Word('bus', 'autobús', '🚌'),
  ]),
  Topic('clima', '🌦️', 'Clima', 'Weather', [
    Word('sun', 'sol', '☀️'), Word('rain', 'lluvia', '🌧️'), Word('cloud', 'nube', '☁️'), Word('snow', 'nieve', '❄️'),
    Word('wind', 'viento', '🌬️'), Word('rainbow', 'arcoíris', '🌈'), Word('storm', 'tormenta', '⛈️'),
    Word('umbrella', 'paraguas', '☂️'),
  ]),
  Topic('acciones', '🏃', 'Acciones', 'Actions', [
    Word('run', 'correr', '🏃'), Word('swim', 'nadar', '🏊'), Word('sleep', 'dormir', '😴'), Word('read', 'leer', '📚'),
    Word('sing', 'cantar', '🎤'), Word('dance', 'bailar', '💃'), Word('write', 'escribir', '✍️'), Word('play', 'jugar', '⚽'),
    Word('eat', 'comer', '🍴'), Word('drink', 'beber', '🍹'),
  ]),
  Topic('vehiculos', '🚗', 'Vehículos', 'Vehicles', [
    Word('car', 'carro', '🚗'), Word('airplane', 'avión', '✈️'), Word('bicycle', 'bicicleta', '🚲'),
    Word('ship', 'barco', '🚢'), Word('train', 'tren', '🚆'), Word('truck', 'camión', '🚚'),
    Word('motorcycle', 'moto', '🏍️'), Word('helicopter', 'helicóptero', '🚁'), Word('rocket', 'cohete', '🚀'),
    Word('ambulance', 'ambulancia', '🚑'),
  ]),
  Topic('juguetes', '⚽', 'Juguetes', 'Toys', [
    Word('ball', 'pelota', '⚽'), Word('balloon', 'globo', '🎈'), Word('robot', 'robot', '🤖'), Word('dice', 'dado', '🎲'),
    Word('video game', 'videojuego', '🎮'), Word('guitar', 'guitarra', '🎸'), Word('drum', 'tambor', '🥁'),
    Word('trumpet', 'trompeta', '🎺'),
  ]),
  Topic('mar', '🐙', 'Animales del mar', 'Sea animals', [
    Word('whale', 'ballena', '🐋'), Word('dolphin', 'delfín', '🐬'), Word('octopus', 'pulpo', '🐙'),
    Word('shark', 'tiburón', '🦈'), Word('crab', 'cangrejo', '🦀'), Word('turtle', 'tortuga', '🐢'),
    Word('shell', 'concha', '🐚'), Word('squid', 'calamar', '🦑'),
  ]),
  Topic('emociones', '😀', 'Emociones', 'Feelings', [
    Word('happy', 'feliz', '😀'), Word('sad', 'triste', '😢'), Word('angry', 'enojado', '😠'),
    Word('scared', 'asustado', '😱'), Word('surprised', 'sorprendido', '😮'), Word('tired', 'cansado', '😩'),
    Word('sick', 'enfermo', '🤒'), Word('calm', 'tranquilo', '😌'),
  ]),
];

const mathLevels = [(5, '🐣'), (10, '🐥'), (20, '🦅')];

/// Nombre de un nivel de sumas o restas: "🐣 Hasta 5".
String mathLevelLabel(int max) {
  final icon = mathLevels.where((l) => l.$1 == max).firstOrNull?.$2;
  return '${icon == null ? '' : '$icon '}${tr('Hasta', 'Up to')} $max';
}

/// Claves para guardar el progreso de cada nivel de suma y tema de idioma (no cambian con el idioma).
String mathKey(int max) => 'suma-$max';
String subtractKey(int max) => 'resta-$max';
String topicKey(Topic topic) => 'ingles-${topic.key}';
String memoryKey(Topic topic) => 'parejas-${topic.key}';

/// Nombre para papás de un nivel o tema guardado con [mathKey], [topicKey] o [memoryKey].
String progressLabel(String key) {
  if (key == 'reto-hoy') return tr('Reto de hoy', "Today's challenge");
  final number = numberLevels.where((l) => l.key == key).firstOrNull;
  if (number != null) return '${tr('Números', 'Numbers')} ${number.label}';
  final dash = key.indexOf('-');
  final kind = dash < 0 ? '' : key.substring(0, dash);
  final rest = key.substring(dash + 1);
  if (kind == 'suma' || kind == 'resta') {
    final max = int.tryParse(rest);
    return '${kind == 'suma' ? tr('Sumar', 'Add') : tr('Restar', 'Subtract')} ${max == null ? rest : mathLevelLabel(max)}';
  }
  final topic = topics.where((t) => t.key == rest).firstOrNull;
  return '${kind == 'parejas' ? tr('Parejas', 'Pairs') : learnName} ${topic?.label ?? rest}';
}

/// Nombre del idioma que aprende el niño: "Inglés" o "Spanish".
String get learnName => tr('Inglés', 'Spanish');
