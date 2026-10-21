class Topic {
  const Topic(this.key, this.label, this.words);
  final String key;
  final String label;

  /// Pares (palabra en inglés, dibujo).
  final List<(String, String)> words;
}

const topics = [
  Topic('animales', '🐶 Animales', [
    ('dog', '🐶'), ('cat', '🐱'), ('cow', '🐮'), ('pig', '🐷'), ('duck', '🦆'),
    ('fish', '🐟'), ('bird', '🐦'), ('horse', '🐴'), ('lion', '🦁'), ('monkey', '🐵'),
  ]),
  Topic('frutas', '🍎 Frutas', [
    ('apple', '🍎'), ('banana', '🍌'), ('grapes', '🍇'), ('orange', '🍊'), ('strawberry', '🍓'),
    ('pear', '🍐'), ('watermelon', '🍉'), ('cherry', '🍒'), ('lemon', '🍋'), ('pineapple', '🍍'),
  ]),
  Topic('colores', '🎨 Colores', [
    ('red', '🟥'), ('blue', '🟦'), ('green', '🟩'), ('yellow', '🟨'), ('orange', '🟧'),
    ('purple', '🟪'), ('black', '⬛'), ('white', '⬜'), ('brown', '🟫'),
  ]),
  Topic('numeros', '🔢 Números', [
    ('one', '1'), ('two', '2'), ('three', '3'), ('four', '4'), ('five', '5'),
    ('six', '6'), ('seven', '7'), ('eight', '8'), ('nine', '9'), ('ten', '10'),
  ]),
  Topic('cuerpo', '👃 Cuerpo', [
    ('eye', '👁️'), ('ear', '👂'), ('nose', '👃'), ('mouth', '👄'), ('tooth', '🦷'),
    ('tongue', '👅'), ('hand', '✋'), ('arm', '💪'), ('leg', '🦵'), ('foot', '🦶'),
  ]),
  Topic('ropa', '👕 Ropa', [
    ('shirt', '👕'), ('pants', '👖'), ('dress', '👗'), ('shoes', '👟'), ('hat', '🎩'),
    ('socks', '🧦'), ('coat', '🧥'), ('glasses', '👓'), ('scarf', '🧣'), ('gloves', '🧤'),
  ]),
  Topic('familia', '👪 Familia', [
    ('mom', '👩'), ('dad', '👨'), ('baby', '👶'), ('grandma', '👵'),
    ('grandpa', '👴'), ('girl', '👧'), ('boy', '👦'), ('family', '👪'),
  ]),
  Topic('saludos', '👋 Saludos', [
    ('hello', '👋'), ('good morning', '🌅'), ('good night', '🌙'), ('thank you', '🙏'),
    ('yes', '👍'), ('no', '👎'), ('I love you', '❤️'), ('happy birthday', '🎂'),
  ]),
  // Dibujos de emojis antiguos, para que se vean también en teléfonos con Android 7.
  Topic('comida', '🍞 Comida', [
    ('bread', '🍞'), ('milk', '🥛'), ('egg', '🥚'), ('cheese', '🧀'), ('rice', '🍚'),
    ('pizza', '🍕'), ('cake', '🍰'), ('chicken', '🍗'), ('soup', '🍲'), ('ice cream', '🍦'),
  ]),
  Topic('casa', '🏠 Casa', [
    ('house', '🏠'), ('bed', '🛏️'), ('door', '🚪'), ('sofa', '🛋️'), ('bathtub', '🛁'),
    ('toilet', '🚽'), ('key', '🔑'), ('clock', '⏰'), ('TV', '📺'), ('light', '💡'),
  ]),
  Topic('escuela', '🎒 Escuela', [
    ('school', '🏫'), ('book', '📖'), ('pencil', '✏️'), ('backpack', '🎒'), ('scissors', '✂️'),
    ('crayon', '🖍️'), ('ruler', '📏'), ('paper', '📄'), ('computer', '💻'), ('bus', '🚌'),
  ]),
  Topic('clima', '🌦️ Clima', [
    ('sun', '☀️'), ('rain', '🌧️'), ('cloud', '☁️'), ('snow', '❄️'),
    ('wind', '🌬️'), ('rainbow', '🌈'), ('storm', '⛈️'), ('umbrella', '☂️'),
  ]),
  Topic('acciones', '🏃 Acciones', [
    ('run', '🏃'), ('swim', '🏊'), ('sleep', '😴'), ('read', '📚'), ('sing', '🎤'),
    ('dance', '💃'), ('write', '✍️'), ('play', '⚽'), ('eat', '🍴'), ('drink', '🍹'),
  ]),
];

const mathLevels = [(5, '🐣 Hasta 5'), (10, '🐥 Hasta 10'), (20, '🦅 Hasta 20')];

/// Claves para guardar el progreso de cada nivel de suma y tema de inglés.
String mathKey(int max) => 'suma-$max';
String subtractKey(int max) => 'resta-$max';
String topicKey(Topic topic) => 'ingles-${topic.key}';
String memoryKey(Topic topic) => 'parejas-${topic.key}';

/// Nombre para papás de un nivel o tema guardado con [mathKey], [topicKey] o [memoryKey].
String progressLabel(String key) {
  if (key == 'reto-hoy') return 'Reto de hoy';
  final dash = key.indexOf('-');
  final kind = dash < 0 ? '' : key.substring(0, dash);
  final rest = key.substring(dash + 1);
  if (kind == 'suma' || kind == 'resta') {
    final level = mathLevels.where((l) => '${l.$1}' == rest).firstOrNull;
    return '${kind == 'suma' ? 'Sumar' : 'Restar'} ${level?.$2 ?? rest}';
  }
  final topic = topics.where((t) => t.key == rest).firstOrNull;
  return '${kind == 'parejas' ? 'Parejas' : 'Inglés'} ${topic?.label ?? rest}';
}
