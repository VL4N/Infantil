import 'package:flutter/material.dart';

import '../logic/content.dart';
import '../logic/questions.dart';
import '../services/app_state.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'game_screen.dart';
import 'memory_screen.dart';
import 'parental_gate.dart';
import 'parents_screen.dart';
import 'premium_screen.dart';
import 'shop_screen.dart';

Future<void> openPremium(BuildContext context) async {
  if (await parentalGate(context) && context.mounted) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
  }
}

/// Contenido bloqueado: avisa al niño y pide la pregunta para adultos.
Future<void> _lockedTap(BuildContext context) {
  Voice.say('Pide ayuda a papá o a mamá', 'es');
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
      _Game('Sumar', 'Hasta 5 · 10 · 20', p.math, p.mathInk, const _PlusIcon(),
          () => _open(context, const MathLevelsScreen())),
      _Game('Restar', 'Hasta 5 · 10 · 20', p.subtract, p.subtractInk, const _MinusIcon(),
          () => _open(context, const MathLevelsScreen(subtract: true))),
      _Game('Inglés', '7 temas', p.english, p.englishInk, const _AbcIcon(),
          () => _open(context, const EnglishTopicsScreen())),
      _Game('Parejas', 'Memoria en inglés', p.memory, p.memoryInk, const _CardsIcon(),
          () => _open(context, const EnglishTopicsScreen(memory: true))),
      _Game('Tienda', 'Gasta tus estrellas en Owlito', p.star, const Color(0xFF3B2A55), const _StoreIcon(),
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
                  const SizedBox(height: 18),
                  if (p.night) ..._nightBody(context, games) else ..._dayBody(context, games),
                  const SizedBox(height: 20),
                  _ParentLinks(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Caramelo": tarjeta de las partidas de hoy y los juegos en cuadrícula.
  List<Widget> _dayBody(BuildContext context, List<_Game> games) {
    final p = context.palette;
    final today = AppState.instance.gamesToday;
    final left = AppState.dailyGoal - today;
    return [
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PARTIDAS DE HOY', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.inkSoft)),
            const SizedBox(height: 6),
            Text(
              today == 0
                  ? '¡Juega ${AppState.dailyGoal} partidas y gana la medalla de hoy!'
                  : left > 0
                      ? '¡Vas muy bien! ${left == 1 ? 'Una partida más' : '$left partidas más'} para tu medalla'
                      : '¡Ganaste la medalla de hoy!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.15),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (today / AppState.dailyGoal).clamp(0, 1).toDouble(),
                minHeight: 16,
                color: p.math,
                backgroundColor: p.bg,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Text('¿Qué jugamos?', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      for (final pair in [games.sublist(0, 2), games.sublist(2, 4)]) ...[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _GameButton(pair[0])),
              const SizedBox(width: 14),
              Expanded(child: _GameButton(pair[1])),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      _GameButton(games[4], wide: true),
    ];
  }

  /// "Noche estrellada": Owlito saluda y los juegos van en lista.
  List<Widget> _nightBody(BuildContext context, List<_Game> games) {
    final p = context.palette;
    return [
      const SizedBox(height: 8),
      Center(child: Owl(size: 110, night: true, wearing: AppState.instance.wearing)),
      const SizedBox(height: 10),
      const Text('¡Hola! ¿Qué aprendemos hoy?',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.15)),
      const SizedBox(height: 6),
      Text('Cada respuesta correcta enciende una estrella',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: p.inkSoft)),
      const SizedBox(height: 20),
      for (final g in games) ...[_GameRow(g), const SizedBox(height: 14)],
    ];
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
          if (!night) ...[Owl(size: 44, wearing: AppState.instance.wearing), const SizedBox(width: 8)],
          Expanded(
            child: Text('Aprende Jugando',
                style: TextStyle(fontSize: 22, fontWeight: night ? FontWeight.w900 : FontWeight.w700)),
          ),
          Semantics(
            button: true,
            label: 'Tienda de Owlito',
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: onStars,
              child: StarCounter(stars: AppState.instance.stars),
            ),
          ),
        ],
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0xFFF3C6DA), offset: Offset(0, 6))],
        ),
        child: child,
      );
}

/// Botón grande de un juego (de día): color vivo con relieve.
class _GameButton extends StatelessWidget {
  const _GameButton(this.game, {this.wide = false});
  final _Game game;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(30);
    final title = Text(game.title, style: TextStyle(fontSize: wide ? 34 : 26, fontWeight: FontWeight.w700, color: game.ink, height: 1));
    final subtitle = Text(game.subtitle, style: TextStyle(fontSize: wide ? 17 : 15, color: game.ink));
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
            child: wide
                ? Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 4), subtitle]),
                      ),
                      _IconTile(color: Colors.white, size: 76, child: game.icon),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconTile(color: Colors.white, size: 56, child: game.icon),
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

/// Fila de un juego (de noche): tarjeta azul con el ícono de color.
class _GameRow extends StatelessWidget {
  const _GameRow(this.game);
  final _Game game;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(24);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: p.cardBorder ?? p.card, width: 2)),
      child: InkWell(
        borderRadius: radius,
        onTap: game.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _IconTile(color: game.color, size: 60, child: game.icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.05)),
                    Text(game.subtitle, style: TextStyle(fontSize: 15, color: p.inkSoft)),
                  ],
                ),
              ),
            ],
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

/// El color de los íconos: el del juego sobre fondo blanco de día; el del fondo de noche.
Color _iconInk(BuildContext context, Color game) => context.palette.night ? context.palette.bg : game;

class _PlusIcon extends StatelessWidget {
  const _PlusIcon();
  @override
  Widget build(BuildContext context) => Icon(Icons.add_rounded, size: 40, color: _iconInk(context, context.palette.math));
}

class _MinusIcon extends StatelessWidget {
  const _MinusIcon();
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.remove_rounded, size: 40, color: _iconInk(context, shade(context.palette.subtract, .12)));
}

class _AbcIcon extends StatelessWidget {
  const _AbcIcon();
  @override
  Widget build(BuildContext context) => Text('ABC',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _iconInk(context, shade(context.palette.english, .1))));
}

class _CardsIcon extends StatelessWidget {
  const _CardsIcon();
  @override
  Widget build(BuildContext context) => Icon(Icons.style_rounded, size: 40, color: _iconInk(context, context.palette.memory));
}

class _StoreIcon extends StatelessWidget {
  const _StoreIcon();
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.storefront_rounded, size: 40, color: _iconInk(context, shade(context.palette.star, .2)));
}

class _ParentLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.palette.ink, decoration: TextDecoration.underline);
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        AppState.instance.premium
            ? Padding(padding: const EdgeInsets.all(12), child: Text('Premium activo', style: style.copyWith(decoration: TextDecoration.none)))
            : TextButton(onPressed: () => openPremium(context), child: Text('Premium para papás', style: style)),
        TextButton(
          onPressed: () async {
            if (await parentalGate(context) && context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentsScreen()));
            }
          },
          child: Text('Resumen para papás', style: style),
        ),
      ],
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
      appBar: _appBar(subtract ? 'Restar' : 'Sumar'),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Elige un nivel', textAlign: TextAlign.center, style: TextStyle(fontSize: 26)),
            for (final (max, label) in mathLevels) ...[
              const SizedBox(height: 16),
              BigButton(
                label: label,
                locked: !state.canPlayMath(max),
                stars: state.canPlayMath(max) ? state.bestFor(subtract ? subtractKey(max) : mathKey(max)) : null,
                onTap: () => state.canPlayMath(max)
                    ? Navigator.push(context, MaterialPageRoute(
                        builder: (_) => subtract
                            ? GameScreen(title: 'Restar', progressKey: subtractKey(max), makeQuestion: (r) => subtractionQuestion(r, max))
                            : GameScreen(title: 'Sumar', progressKey: mathKey(max), makeQuestion: (r) => mathQuestion(r, max)),
                      ))
                    : _lockedTap(context),
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
      appBar: _appBar(memory ? 'Parejas' : 'Inglés'),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Elige un tema', textAlign: TextAlign.center, style: TextStyle(fontSize: 26)),
            for (final topic in topics) ...[
              const SizedBox(height: 16),
              BigButton(
                label: topic.label,
                locked: !state.canPlayTopic(topic.key),
                stars: state.canPlayTopic(topic.key)
                    ? state.bestFor(memory ? memoryKey(topic) : topicKey(topic))
                    : null,
                onTap: () => state.canPlayTopic(topic.key)
                    ? Navigator.push(context, MaterialPageRoute(
                        builder: (_) => memory
                            ? MemoryScreen(topic: topic, progressKey: memoryKey(topic))
                            : GameScreen(title: 'Inglés', progressKey: topicKey(topic), makeQuestion: (r) => englishMixedQuestion(r, topic)),
                      ))
                    : _lockedTap(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
