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
import 'profile_screen.dart';
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
      _Game('Inglés', '${topics.length} temas', p.english, p.englishInk, const _AbcIcon(),
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
          Owl(size: 44, night: night, wearing: AppState.instance.wearing, feathers: AppState.instance.featherColors),
          const SizedBox(width: 8),
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

/// Con varios niños: quién está jugando, y el botón para cambiar.
class _WhoPlays extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text('Juega: ${AppState.instance.profile.name}',
                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePickerScreen()),
              (_) => false,
            ),
            child: Text('Cambiar', style: TextStyle(fontSize: 18, color: context.palette.ink, decoration: TextDecoration.underline)),
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
  const _GameButton(this.game, {this.wide = false});
  final _Game game;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(30);
    // El cuadrito del ícono: blanco de día, azul noche de noche.
    final tile = context.palette.night ? context.palette.bg : Colors.white;
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
                      _IconTile(color: tile, size: 76, child: game.icon),
                    ],
                  )
                : Column(
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

class _CardsIcon extends StatelessWidget {
  const _CardsIcon();
  @override
  Widget build(BuildContext context) => Icon(Icons.style_rounded, size: 40, color: _iconInk(context, context.palette.memory));
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
              const Expanded(
                child: Text('Para papás y mamás', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ParentButton(
            icon: Icons.insights_rounded,
            label: 'Resumen, niños y recordatorio',
            onTap: () async {
              if (await parentalGate(context) && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentsScreen()));
              }
            },
          ),
          const SizedBox(height: 10),
          _ParentButton(
            icon: premium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
            label: premium ? 'Premium activo' : 'Premium: todo sin anuncios',
            onTap: premium ? null : () => openPremium(context),
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
