import 'dart:math';

import 'package:aprende_jugando/logic/content.dart';
import 'package:aprende_jugando/logic/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hay 4 parejas: cada palabra con su dibujo', () {
    final game = MemoryGame(Random(1), topics.first);
    expect(game.cards.length, 8);
    final words = {for (final c in game.cards) c.word};
    expect(words.length, 4);
    for (final w in words) {
      final pair = game.cards.where((c) => c.word == w).toList();
      expect(pair.map((c) => c.showsPicture).toSet(), {true, false});
      expect(topics.first.words, contains((w, pair.first.picture)));
    }
  });

  test('dos cartas distintas se vuelven a tapar; una pareja se queda', () {
    final game = MemoryGame(Random(2), topics.first);
    final a = 0;
    final other = game.cards.indexWhere((c) => c.word != game.cards[a].word);
    final partner = game.cards.indexWhere((c) => c.word == game.cards[a].word && c != game.cards[a]);

    expect(game.flip(a), FlipResult.first);
    expect(game.flip(a), isNull, reason: 'no se puede tocar la misma carta');
    expect(game.flip(other), FlipResult.miss);
    expect(game.flip(partner), isNull, reason: 'hay que esperar a que se tapen');
    game.hideMiss();
    expect(game.isFaceUp(a), isFalse);

    expect(game.flip(a), FlipResult.first);
    expect(game.flip(partner), FlipResult.match);
    expect(game.isFaceUp(a) && game.isFaceUp(partner), isTrue);
    expect(game.tries, 2);
  });

  test('las estrellas dependen de los intentos', () {
    final game = MemoryGame(Random(3), topics.first);
    final stars = <int>[];
    for (final tries in [4, 6, 7, 9, 10]) {
      game.tries = tries;
      stars.add(game.stars);
    }
    expect(stars, [3, 3, 2, 2, 1]);
  });
}
