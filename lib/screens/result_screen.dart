import 'package:flutter/material.dart';

import '../logic/lang.dart';
import '../logic/lines.dart';
import '../logic/stickers.dart';
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
    this.sticker,
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

  /// El sticker que ganó para el álbum (ver AppState.awardSticker), o null.
  final ({String sticker, StickerPage page, bool completed})? sticker;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String get _message => widget.earned >= 3
      ? youAreAStar
      : widget.earned >= 2
          ? greatJob
          : keepPracticing;

  @override
  void initState() {
    super.initState();
    Sfx.celebracion();
    () async {
      await Voice.say(_message, Lang.native);
      final won = widget.sticker;
      if (won != null && mounted) await Voice.say(won.completed ? pageComplete : newSticker, Lang.native);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('¡Bravo!', 'Hooray!'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: Text('🏆', style: TextStyle(fontSize: 100))),
          Center(child: StarRating(stars: widget.earned, size: 52)),
          if (widget.earned > widget.previousBest && widget.previousBest > 0)
            Text(tr('¡Nuevo récord!', 'New record!'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(
            '$_message\n${widget.detail}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26),
          ),
          if (widget.starsWon > 0) ...[
            const SizedBox(height: 12),
            Text(
              tr('+${widget.starsWon} ${widget.starsWon == 1 ? 'estrella' : 'estrellas'} para la tienda.'
                  ' Ahora tienes ${AppState.instance.stars}.',
                  '+${widget.starsWon} ${widget.starsWon == 1 ? 'star' : 'stars'} for the shop.'
                  ' Now you have ${AppState.instance.stars}.'),
              key: const Key('stars-won'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
          if (widget.sticker case final won?) ...[
            const SizedBox(height: 16),
            _StickerWon(won),
          ],
          const SizedBox(height: 20),
          // Único lugar con publicidad: al terminar, nunca durante el juego.
          const Center(child: AdBanner()),
          const SizedBox(height: 20),
          BigButton(
            label: tr('🔁 Otra vez', '🔁 Play again'),
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.playAgain())),
          ),
          const SizedBox(height: 14),
          BigButton(label: tr('🏠 Inicio', '🏠 Home'), onTap: () => Navigator.popUntil(context, (r) => r.isFirst)),
        ],
      ),
    );
  }
}

/// El sticker nuevo para el álbum, y si con él completó una página.
class _StickerWon extends StatelessWidget {
  const _StickerWon(this.won);
  final ({String sticker, StickerPage page, bool completed}) won;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final have = won.page.stickers.where((s) => AppState.instance.stickers.contains(stickerId(won.page, s))).length;
    return Container(
      key: const Key('sticker-won'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.yellow, width: 3),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFFFF4D6), shape: BoxShape.circle),
            child: Text(stickerPicture(won.sticker), style: const TextStyle(fontSize: 42)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              won.completed
                  ? tr('¡Completaste la página ${won.page.name}! +$pageBonus estrellas.',
                      'You completed the ${won.page.name} page! +$pageBonus stars.')
                  : tr('¡Sticker nuevo para tu álbum! Página ${won.page.name}: $have de ${won.page.stickers.length}.',
                      'New sticker for your album! ${won.page.name} page: $have of ${won.page.stickers.length}.'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.cardInk),
            ),
          ),
        ],
      ),
    );
  }
}

