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
];

const mathLevels = [(5, '🐣 Hasta 5'), (10, '🐥 Hasta 10'), (20, '🦅 Hasta 20')];

/// Claves para guardar el progreso de cada nivel de suma y tema de inglés.
String mathKey(int max) => 'suma-$max';
String topicKey(Topic topic) => 'ingles-${topic.key}';
