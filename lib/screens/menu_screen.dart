import 'package:flutter/material.dart';

import '../logic/content.dart';
import '../logic/daily.dart';
import '../logic/lang.dart';
import '../logic/letters.dart';
import '../logic/lines.dart';
import '../logic/numbers.dart';
import '../logic/questions.dart';
import '../logic/stickers.dart';
import '../services/app_state.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'album_screen.dart';
import 'game_screen.dart';
import 'medals_screen.dart';
import 'memory_screen.dart';
import 'parental_gate.dart';
import 'parents_screen.dart';
import 'premium_screen.dart';
import 'profile_screen.dart';
import 'result_screen.dart' show MedalBadge;
import 'shop_screen.dart';

Future<void> openPremium(BuildContext context) async {
  if (await parentalGate(context) && context.mounted) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
  }
}

/// Contenido bloqueado: avisa al niño y pide la pregunta para adultos.
Future<void> askPremium(BuildContext context) {
  Voice.say(askForHelp, Lang.native);
  return openPremium(context);
}

AppBar _appBar(String title) => AppBar(
      title: Text(title),
      actions: [ListenableBuilder(
        listenable: AppState.instance,
        builder: (_, _) => StarCounter(stars: AppState.instance.stars),
      )],
    );

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final games = [
      _Game(tr('Sumar', 'Add'), tr('Hasta 5 · 10 · 20', 'Up to 5 · 10 · 20'), p.math, p.mathInk, const _PlusIcon(),
          () => _open(context, const MathLevelsScreen())),
      _Game(tr('Restar', 'Subtract'), tr('Hasta 5 · 10 · 20', 'Up to 5 · 10 · 20'), p.subtract, p.subtractInk, const _MinusIcon(),
          () => _open(context, const MathLevelsScreen(subtract: true))),
      _Game(learnName, '${topics.length} ${tr('temas', 'topics')}', p.english, p.englishInk, const _AbcIcon(),
          () => _open(context, const EnglishTopicsScreen())),
      _Game(tr('Parejas', 'Pairs'), tr('Memoria en inglés', 'Memory in Spanish'), p.memory, p.memoryInk, const _CardsIcon(),
          () => _open(context, const EnglishTopicsScreen(memory: true))),
      _Game(tr('Números', 'Numbers'), tr('¿Qué sigue? · ¿Cuál es mayor?', 'What comes next? · Which is bigger?'), p.numbers,
          p.numbersInk, const _NumbersIcon(), () => _open(context, const NumbersScreen())),
      _Game(tr('Letras', 'Letters'), tr('Abecedario y primeras lecturas', 'ABCs and first reading'), p.letters, p.lettersInk,
          const _LettersIcon(), () => _open(context, const LettersScreen())),
      _Game(tr('Álbum', 'Album'), tr('${AppState.instance.stickers.length} de $totalStickers stickers', '${AppState.instance.stickers.length} of $totalStickers stickers'),
          p.album, p.albumInk, const _AlbumIcon(), () => _open(context, const AlbumScreen())),
      _Game(tr('Tienda', 'Shop'), tr('Gasta tus estrellas en Owlito', 'Spend your stars on Owlito'), p.star, const Color(0xFF3B2A55), const _StoreIcon(),
          () => _open(context, const ShopScreen())),
    ];
    final shop = games.last;
    return Scaffold(
      body: Stack(
        children: [
          if (p.night) const Positioned.fill(child: NightSky()),
          SafeArea(
            child: ListenableBuilder(
              listenable: AppState.instance,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  _Header(night: p.night, onStars: shop.onTap),
                  if (AppState.instance.profiles.length > 1) _WhoPlays(),
                  const SizedBox(height: 18),
                  ..._body(context, games),
                  const SizedBox(height: 24),
                  const _ParentsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de las partidas de hoy y los juegos en cuadrícula. De día ("Caramelo") y de noche
  /// ("Noche estrellada") es la misma pantalla; solo cambian los colores.
  List<Widget> _body(BuildContext context, List<_Game> games) {
    final today = AppState.instance.gamesToday;
    final left = AppState.dailyGoal - today;
    return [
      _ChallengeCard(today: today, left: left),
      const SizedBox(height: 18),
      Text(tr('¿Qué jugamos?', 'What shall we play?'),
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      for (var i = 0; i < games.length; i += 2) ...[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _GameButton(games[i])),
              // La tienda (la última, si quedan impares) ocupa toda la fila.
              if (i + 1 < games.length) ...[
                const SizedBox(width: 14),
                Expanded(child: _GameButton(games[i + 1])),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ];
  }
}


/// Reto de hoy (preguntas nuevas cada día y estrellas extra) y la medalla de las partidas de hoy.
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.today, required this.left});
  final int today;
  final int left;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = AppState.instance;
    final done = state.challengeDoneToday;
    final mood = state.owlMood;
    final streak = state.challengeStreak;
    void play() {
      final topicsToPlay = [for (final t in topics) if (state.canPlayTopic(t.key)) t];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            title: tr('Reto de hoy', "Today's challenge"),
            progressKey: challengeKey,
            makeQuestion: challengeQuestions(topicsToPlay),
            random: challengeRandom(state.now(), state.profile.id),
          ),
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('RETO DE HOY', "TODAY'S CHALLENGE"), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.inkSoft)),
          const SizedBox(height: 6),
          Row(
            children: [
              LivelyOwl(size: 64, night: p.night, wearing: state.wearing, feathers: state.featherColors, pattern: state.featherPattern, mood: mood),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  key: const Key('challenge-text'),
                  switch (mood) {
                    OwlMood.happy => tr('¡Reto completado! Owlito está feliz. Mañana hay uno nuevo.',
                        'Challenge complete! Owlito is happy. A new one comes tomorrow.'),
                    OwlMood.sad => tr('Owlito está triste: ayer no hubo reto. ¡Juega el de hoy para alegrarlo!',
                        "Owlito is sad: no challenge yesterday. Play today's to cheer Owlito up!"),
                    OwlMood.normal => tr('Preguntas nuevas cada día. ¡Gana ${AppState.challengeBonus} estrellas extra!',
                        'New questions every day. Win ${AppState.challengeBonus} extra stars!'),
                  },
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.15),
                ),
              ),
            ],
          ),
          if (streak >= 2) ...[
            const SizedBox(height: 6),
            Text(tr('🔥 $streak días seguidos con el reto', '🔥 $streak days in a row'),
                key: const Key('challenge-streak'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.inkSoft)),
          ],
          const SizedBox(height: 12),
          BigButton(
            key: const Key('challenge'),
            label: done ? tr('Jugar otra vez', 'Play again') : tr('¡Jugar el reto!', 'Play the challenge!'),
            fontSize: done ? 20 : 24,
            color: done ? null : p.math,
            textColor: done ? null : p.mathInk,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            onTap: play,
          ),
          const SizedBox(height: 14),
          if (left <= 0)
            Row(
              key: const Key('medal-today'),
              children: [
                const MedalBadge(size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('¡Ganaste la medalla de hoy! Tienes ${state.medals} ${state.medals == 1 ? 'medalla' : 'medallas'}.',
                        "You won today's medal! You have ${state.medals} ${state.medals == 1 ? 'medal' : 'medals'}."),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            )
          else
            Text(
              today == 0
                  ? tr('🏅 Termina ${AppState.dailyGoal} partidas hoy y gana la medalla del día (+${AppState.medalBonus} estrellas).',
                      "🏅 Finish ${AppState.dailyGoal} games today to win today's medal (+${AppState.medalBonus} stars).")
                  : tr('🏅 ¡Vas muy bien! ${left == 1 ? 'Una partida más' : '$left partidas más'} para la medalla de hoy.',
                      "🏅 Great going! ${left == 1 ? 'One more game' : '$left more games'} for today's medal."),
              style: TextStyle(fontSize: 16, color: p.inkSoft),
            ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (today / AppState.dailyGoal).clamp(0, 1).toDouble(),
              minHeight: 12,
              color: p.math,
              backgroundColor: p.bg,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('open-medals'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedalsScreen())),
            child: Text(
              state.rewardsToClaim > 0
                  ? tr('🎁 ¡Tienes un premio de medallas para reclamar!', '🎁 You have a medal prize to claim!')
                  : tr('🏅 Ver los premios de medallas', '🏅 See the medal prizes'),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

class _Game {
  const _Game(this.title, this.subtitle, this.color, this.ink, this.icon, this.onTap);
  final String title;
  final String subtitle;
  final Color color;
  final Color ink;
  final Widget icon;
  final VoidCallback onTap;
}

class _Header extends StatelessWidget {
  const _Header({required this.night, required this.onStars});
  final bool night;

  /// Tocar las estrellas abre la tienda.
  final VoidCallback onStars;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          LivelyOwl(
              size: 44,
              night: night,
              wearing: AppState.instance.wearing,
              feathers: AppState.instance.featherColors,
              pattern: AppState.instance.featherPattern,
              mood: AppState.instance.owlMood),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr('Aprende Jugando', 'Learn & Play'),
                style: TextStyle(fontSize: 22, fontWeight: night ? FontWeight.w900 : FontWeight.w700)),
          ),
          // Las medallas abren el camino de medallas (con un 🎁 si hay un premio para reclamar).
          Semantics(
            button: true,
            label: tr('Camino de medallas', 'Medal path'),
            child: InkWell(
              key: const Key('medal-count'),
              borderRadius: BorderRadius.circular(99),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedalsScreen())),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text('${AppState.instance.rewardsToClaim > 0 ? '🎁' : ''}🏅 ${AppState.instance.medals}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: tr('Tienda de Owlito', "Owlito's shop"),
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: onStars,
              child: StarCounter(stars: AppState.instance.stars),
            ),
          ),
        ],
      );
}

/// Con varios niños: quién está jugando, y el botón para cambiar.
class _WhoPlays extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text('${tr('Juega', 'Playing')}: ${AppState.instance.profile.name}',
                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePickerScreen()),
              (_) => false,
            ),
            child: Text(tr('Cambiar', 'Change'), style: TextStyle(fontSize: 18, color: context.palette.ink, decoration: TextDecoration.underline)),
          ),
        ],
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(28),
        border: p.cardBorder == null ? null : Border.all(color: p.cardBorder!, width: 2),
        boxShadow: p.night ? null : const [BoxShadow(color: Color(0xFFF3C6DA), offset: Offset(0, 6))],
      ),
      child: child,
    );
  }
}

/// Botón grande de un juego: color vivo con relieve.
class _GameButton extends StatelessWidget {
  const _GameButton(this.game);
  final _Game game;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(30);
    // El cuadrito del ícono: blanco de día, azul noche de noche.
    final tile = context.palette.night ? context.palette.bg : Colors.white;
    final title = Text(game.title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: game.ink, height: 1));
    final subtitle = Text(game.subtitle, style: TextStyle(fontSize: 15, color: game.ink));
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: shade(game.color), offset: const Offset(0, 8))],
      ),
      child: Material(
        color: game.color,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: game.onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconTile(color: tile, size: 56, child: game.icon),
                const SizedBox(height: 12),
                title,
                const SizedBox(height: 4),
                subtitle,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.color, required this.size, required this.child});
  final Color color;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Center(child: SizedBox(width: size * 0.55, height: size * 0.55, child: FittedBox(child: child))),
      );
}

/// El color de los íconos: el del juego (un poco más oscuro sobre el blanco de día).
Color _iconInk(BuildContext context, Color game, [double dayShade = 0]) =>
    context.palette.night ? game : shade(game, dayShade);

class _PlusIcon extends StatelessWidget {
  const _PlusIcon();
  @override
  Widget build(BuildContext context) => Icon(Icons.add_rounded, size: 40, color: _iconInk(context, context.palette.math));
}

class _MinusIcon extends StatelessWidget {
  const _MinusIcon();
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.remove_rounded, size: 40, color: _iconInk(context, context.palette.subtract, .12));
}

class _AbcIcon extends StatelessWidget {
  const _AbcIcon();
  @override
  Widget build(BuildContext context) => Text('ABC',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _iconInk(context, context.palette.english, .1)));
}

class _NumbersIcon extends StatelessWidget {
  const _NumbersIcon();
  @override
  Widget build(BuildContext context) => Text('123',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _iconInk(context, context.palette.numbers, .1)));
}

class _LettersIcon extends StatelessWidget {
  const _LettersIcon();
  @override
  Widget build(BuildContext context) => Text('Aa',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _iconInk(context, context.palette.letters, .12)));
}

class _CardsIcon extends StatelessWidget {
  const _CardsIcon();
  @override
  Widget build(BuildContext context) => Icon(Icons.style_rounded, size: 40, color: _iconInk(context, context.palette.memory));
}

class _AlbumIcon extends StatelessWidget {
  const _AlbumIcon();
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.collections_bookmark_rounded, size: 40, color: _iconInk(context, context.palette.album, .15));
}

class _StoreIcon extends StatelessWidget {
  const _StoreIcon();
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.storefront_rounded, size: 40, color: _iconInk(context, context.palette.star, .2));
}

/// Zona para papás y mamás: bien visible, con sus dos botones (detrás de la pregunta para adultos).
class _ParentsCard extends StatelessWidget {
  const _ParentsCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final premium = AppState.instance.premium;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom_rounded, size: 28, color: p.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(tr('Para papás y mamás', 'For moms and dads'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          // Ya jugó todo lo gratis: se les cuenta a los papás (con calma, sin insistir) qué más trae Premium.
          if (AppState.instance.finishedFreeContent) ...[
            const SizedBox(height: 10),
            InkWell(
              key: const Key('free-done'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => openPremium(context),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.star.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tr('🎉 ${AppState.instance.profile.name} ya jugó todo lo gratis. Con Premium sigue con '
                          '${topics.where((t) => !AppState.instance.isTopicFree(t.key)).length} temas más, '
                          'más niveles, trajes y páginas del álbum.',
                      '🎉 ${AppState.instance.profile.name} has played everything free. Premium adds '
                          '${topics.where((t) => !AppState.instance.isTopicFree(t.key)).length} more topics, '
                          'more levels, outfits and album pages.'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.25),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _ParentButton(
            icon: Icons.insights_rounded,
            label: tr('Resumen, niños, idioma y aviso', 'Summary, kids, language, reminder'),
            onTap: () async {
              if (await parentalGate(context) && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentsScreen()));
              }
            },
          ),
          const SizedBox(height: 10),
          _ParentButton(
            icon: premium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
            label: premium ? tr('Premium activo', 'Premium active') : tr('Premium: todo sin anuncios', 'Premium: everything, no ads'),
            // Con Premium activo también se abre, para ver que ya está comprado (sin pregunta: no hay nada que pagar).
            onTap: premium
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()))
                : () => openPremium(context),
          ),
        ],
      ),
    );
  }
}

class _ParentButton extends StatelessWidget {
  const _ParentButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        disabledForegroundColor: p.ink,
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: p.inkSoft, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class MathLevelsScreen extends StatelessWidget {
  const MathLevelsScreen({super.key, this.subtract = false});

  /// Niveles de restas en lugar de sumas.
  final bool subtract;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: _appBar(subtract ? tr('Restar', 'Subtract') : tr('Sumar', 'Add')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(tr('Elige un nivel', 'Pick a level'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 26)),
            for (final (max, _) in mathLevels) ...[
              const SizedBox(height: 16),
              BigButton(
                label: mathLevelLabel(max),
                locked: !state.canPlayMath(max),
                stars: state.canPlayMath(max) ? state.todayFor(subtract ? subtractKey(max) : mathKey(max)) : null,
                onTap: () => state.canPlayMath(max)
                    ? Navigator.push(context, MaterialPageRoute(
                        builder: (_) => subtract
                            ? GameScreen(title: tr('Restar', 'Subtract'), progressKey: subtractKey(max), makeQuestion: (r) => subtractionQuestion(r, max))
                            : GameScreen(title: tr('Sumar', 'Add'), progressKey: mathKey(max), makeQuestion: (r) => mathQuestion(r, max)),
                      ))
                    : askPremium(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EnglishTopicsScreen extends StatelessWidget {
  const EnglishTopicsScreen({super.key, this.memory = false});

  /// Abre el juego de parejas en lugar de las preguntas.
  final bool memory;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: _appBar(memory ? tr('Parejas', 'Pairs') : learnName),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(tr('Elige un tema', 'Pick a topic'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 26)),
            for (final topic in topics) ...[
              const SizedBox(height: 16),
              BigButton(
                label: topic.label,
                locked: !state.canPlayTopic(topic.key),
                stars: state.canPlayTopic(topic.key)
                    ? state.todayFor(memory ? memoryKey(topic) : topicKey(topic))
                    : null,
                onTap: () => state.canPlayTopic(topic.key)
                    ? Navigator.push(context, MaterialPageRoute(
                        builder: (_) => memory
                            ? MemoryScreen(topic: topic, progressKey: memoryKey(topic))
                            : GameScreen(title: learnName, progressKey: topicKey(topic), makeQuestion: (r) => englishMixedQuestion(r, topic)),
                      ))
                    : askPremium(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sección Números: "¿Qué número sigue?" y "¿Cuál es mayor?".
class NumbersScreen extends StatelessWidget {
  const NumbersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: _appBar(tr('Números', 'Numbers')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(tr('Elige un juego', 'Pick a game'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 26)),
            for (final level in numberLevels) ...[
              const SizedBox(height: 16),
              BigButton(
                label: level.label,
                fontSize: 22,
                locked: !state.canPlayNumbers(level.key),
                stars: state.canPlayNumbers(level.key) ? state.todayFor(level.key) : null,
                onTap: () => state.canPlayNumbers(level.key)
                    ? Navigator.push(context, MaterialPageRoute(
                        builder: (_) => GameScreen(title: tr('Números', 'Numbers'), progressKey: level.key, makeQuestion: level.make),
                      ))
                    : askPremium(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sección Letras: el abecedario y las primeras lecturas, en el idioma del niño.
class LettersScreen extends StatelessWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: _appBar(tr('Letras', 'Letters')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(tr('Elige un juego', 'Pick a game'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 26)),
            for (final level in letterLevels) ...[
              const SizedBox(height: 16),
              BigButton(
                label: level.label,
                fontSize: 22,
                locked: !state.canPlayLetters(level.key),
                stars: state.canPlayLetters(level.key) ? state.todayFor(level.key) : null,
                onTap: () => state.canPlayLetters(level.key)
                    ? Navigator.push(context, MaterialPageRoute(
                        builder: (_) => GameScreen(title: tr('Letras', 'Letters'), progressKey: level.key, makeQuestion: level.make),
                      ))
                    : askPremium(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
