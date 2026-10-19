import 'package:flutter/material.dart';

import '../services/ads.dart';
import '../services/app_state.dart';
import '../services/sfx.dart';
import '../services/voice.dart';
import '../theme.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.detail,
    required this.english,
    required this.earned,
    required this.previousBest,
    required this.playAgain,
    this.starsWon = 0,
  });

  /// Cómo le fue, p. ej. "8 de 10 a la primera."
  final String detail;
  final bool english;

  /// Estrellas de esta partida (0 a 3) y el mejor resultado que había antes.
  final int earned;
  final int previousBest;
  final Widget Function() playAgain;

  /// Estrellas que sumó en esta partida al contador (una por acierto a la primera o por pareja).
  final int starsWon;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String get _message => widget.earned >= 3
      ? '¡Eres una estrella!'
      : widget.earned >= 2
          ? '¡Muy bien!'
          : '¡Sigue practicando!';

  @override
  void initState() {
    super.initState();
    Sfx.celebracion();
    widget.english ? Voice.say('Great job!', 'en') : Voice.say(_message, 'es');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¡Bravo!')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: Text('🏆', style: TextStyle(fontSize: 100))),
          Center(child: StarRating(stars: widget.earned, size: 52)),
          if (widget.earned > widget.previousBest && widget.previousBest > 0)
            const Text('¡Nuevo récord!', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(
            '$_message\n${widget.detail}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26),
          ),
          if (widget.starsWon > 0) ...[
            const SizedBox(height: 12),
            Text(
              '+${widget.starsWon} ${widget.starsWon == 1 ? 'estrella' : 'estrellas'} para la tienda.'
              ' Ahora tienes ${AppState.instance.stars}.',
              key: const Key('stars-won'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 20),
          // Único lugar con publicidad: al terminar, nunca durante el juego.
          const Center(child: AdBanner()),
          const SizedBox(height: 20),
          BigButton(
            label: '🔁 Otra vez',
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.playAgain())),
          ),
          const SizedBox(height: 14),
          BigButton(label: '🏠 Inicio', onTap: () => Navigator.popUntil(context, (r) => r.isFirst)),
        ],
      ),
    );
  }
}
