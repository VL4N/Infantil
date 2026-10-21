import 'dart:math';

import 'content.dart';

/// Una carta del juego de parejas: el dibujo o la palabra (en el idioma que aprende).
class MemoryCard {
  const MemoryCard(this.word, this.picture, {required this.showsPicture});
  final String word;
  final String picture;
  final bool showsPicture;

  String get face => showsPicture ? picture : word;
}

enum FlipResult { first, match, miss }

/// Juego de parejas: cada dibujo se junta con su palabra.
class MemoryGame {
  MemoryGame(Random r, Topic topic, {this.pairs = 4})
      : cards = [
          for (final word in (topic.words.toList()..shuffle(r)).take(pairs)) ...[
            MemoryCard(word.text, word.picture, showsPicture: true),
            MemoryCard(word.text, word.picture, showsPicture: false),
          ],
        ]..shuffle(r);

  final int pairs;
  final List<MemoryCard> cards;
  final Set<int> matched = {};

  /// Cartas destapadas que todavía no forman pareja (como mucho dos).
  final List<int> open = [];

  /// Veces que se destaparon dos cartas.
  int tries = 0;

  bool get done => matched.length == cards.length;
  bool isFaceUp(int i) => matched.contains(i) || open.contains(i);

  /// Destapa una carta. Devuelve null si no se puede tocar ahora.
  FlipResult? flip(int i) {
    if (isFaceUp(i) || open.length == 2) return null;
    open.add(i);
    if (open.length == 1) return FlipResult.first;
    tries++;
    if (cards[open[0]].word == cards[open[1]].word) {
      matched.addAll(open);
      open.clear();
      return FlipResult.match;
    }
    return FlipResult.miss;
  }

  /// Vuelve a tapar las dos cartas que no eran pareja.
  void hideMiss() => open.clear();

  /// 3 estrellas con pocos intentos de más, 1 si costó mucho.
  int get stars => tries <= pairs + 2 ? 3 : tries <= pairs + 5 ? 2 : 1;
}
