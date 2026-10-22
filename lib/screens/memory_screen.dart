import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/content.dart';
import '../logic/lang.dart';
import '../logic/lines.dart';
import '../logic/memory.dart';
import '../services/app_state.dart';
import '../services/sfx.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'result_screen.dart';

/// Juego de parejas: destapa dos cartas y junta cada dibujo con su palabra (en el idioma que aprende).
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key, required this.topic, required this.progressKey, this.random});

  final Topic topic;
  final String progressKey;
  final Random? random;

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  late final MemoryGame _game = MemoryGame(widget.random ?? Random(), widget.topic);

  @override
  void initState() {
    super.initState();
    Voice.say(findThePairs, Lang.native);
  }

  @override
  void dispose() {
    Voice.stop();
    super.dispose();
  }

  Future<void> _tap(int i) async {
    final result = _game.flip(i);
    if (result == null) return;
    final card = _game.cards[i];
    setState(() {});
    result == FlipResult.match ? Sfx.acierto() : Sfx.toque();
    switch (result) {
      case FlipResult.first:
      case FlipResult.miss:
        // La palabra se lee en voz alta, para quien todavía no lee.
        if (!card.showsPicture) Voice.say(card.word, Lang.target);
        if (result == FlipResult.miss) {
          await Future.delayed(const Duration(milliseconds: 1400));
          if (!mounted) return;
          setState(_game.hideMiss);
        }
      case FlipResult.match:
        AppState.instance.countAnswer();
        // La partida se guarda en cuanto termina, antes de la voz, para no perderla si la voz se atasca.
        final done = _game.done;
        // Las estrellas (una por pareja) se ganan al terminar, no a la mitad.
        if (done) AppState.instance.addStars(_game.pairs);
        final previousBest = AppState.instance.bestFor(widget.progressKey);
        final earned = done ? AppState.instance.recordGame(widget.progressKey, _game.stars) : 0;
        final sticker = done ? AppState.instance.awardSticker() : null;
        await Voice.say(greatJob, Lang.native);
        if (mounted) await Voice.say(card.word, Lang.target);
        if (!mounted || !done) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              earned: earned,
              previousBest: previousBest,
              starsWon: _game.pairs,
              sticker: sticker,
              detail: tr('Encontraste las ${_game.pairs} parejas en ${_game.tries} intentos.',
                  'You found all ${_game.pairs} pairs in ${_game.tries} tries.'),
              english: true,
              playAgain: () => MemoryScreen(topic: widget.topic, progressKey: widget.progressKey),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Parejas', 'Pairs')),
        actions: [StarCounter(key: const Key('game-stars'), stars: _game.matched.length ~/ 2, pending: true)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr('Junta cada dibujo con su palabra', 'Match each picture with its word'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              for (var i = 0; i < _game.cards.length; i++) _card(i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(int i) {
    final card = _game.cards[i];
    final up = _game.isFaceUp(i);
    final matched = _game.matched.contains(i);
    return Material(
      key: Key('card-$i'),
      color: matched ? AppColors.green : (up ? Colors.white : context.palette.accent),
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _tap(i),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: FittedBox(
              child: Text(
                up ? card.face : '❓',
                style: TextStyle(
                  fontSize: up && card.showsPicture ? 56 : 34,
                  fontWeight: FontWeight.bold,
                  color: matched ? Colors.white : const Color(0xFF3B2A55),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
