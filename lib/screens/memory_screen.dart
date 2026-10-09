import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/content.dart';
import '../logic/memory.dart';
import '../services/app_state.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'result_screen.dart';

/// Juego de parejas: destapa dos cartas y junta cada dibujo con su palabra en inglés.
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
    Voice.say('Busca las parejas', 'es');
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
    switch (result) {
      case FlipResult.first:
      case FlipResult.miss:
        // La palabra se lee en voz alta, para quien todavía no lee.
        if (!card.showsPicture) Voice.say(card.word, 'en');
        if (result == FlipResult.miss) {
          await Future.delayed(const Duration(milliseconds: 1400));
          if (!mounted) return;
          setState(_game.hideMiss);
        }
      case FlipResult.match:
        AppState.instance.addStar();
        // La partida se guarda en cuanto termina, antes de la voz, para no perderla si la voz se atasca.
        final done = _game.done;
        final previousBest = AppState.instance.bestFor(widget.progressKey);
        final earned = done ? AppState.instance.recordGame(widget.progressKey, _game.stars) : 0;
        await Voice.say('Yes! ${card.word}', 'en');
        if (!mounted || !done) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              earned: earned,
              previousBest: previousBest,
              detail: 'Encontraste las ${_game.pairs} parejas en ${_game.tries} intentos.',
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
        title: const Text('Parejas'),
        actions: [ListenableBuilder(
          listenable: AppState.instance,
          builder: (_, _) => StarCounter(stars: AppState.instance.stars),
        )],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Junta cada dibujo con su palabra', textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
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
      color: matched ? AppColors.green : (up ? Colors.white : AppColors.blue),
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
                  color: matched ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
