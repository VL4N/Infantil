import 'package:flutter/material.dart';

import '../logic/lang.dart';
import '../logic/lines.dart';
import '../logic/shop.dart';
import '../services/app_state.dart';
import '../services/sfx.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'medals_screen.dart';
import 'menu_screen.dart' show openPremium;

/// Tienda de Owlito: las estrellas ganadas se gastan en ropa y accesorios para el búho.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Tienda de Owlito', "Owlito's shop")),
        actions: [ListenableBuilder(listenable: state, builder: (_, _) => StarCounter(stars: state.stars))],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Owl(size: 130, night: p.night, wearing: state.wearing, feathers: state.featherColors, pattern: state.featherPattern)),
            const SizedBox(height: 12),
            Text(
              tr('Tienes ${state.stars} ${state.stars == 1 ? 'estrella' : 'estrellas'} para gastar',
                  'You have ${state.stars} ${state.stars == 1 ? 'star' : 'stars'} to spend'),
              key: const Key('shop-balance'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(
              tr('Ganas una estrella por cada respuesta correcta a la primera y por cada pareja. '
                      'Los trajes con 👑 vienen con Premium.',
                  'You win a star for every answer right on the first try and for every pair. '
                      'Outfits with 👑 come with Premium.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: p.inkSoft),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedalsScreen())),
                child: Text(tr('🏅 Premios especiales del camino de medallas', '🏅 Special prizes on the medal path'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink, decoration: TextDecoration.underline)),
              ),
            ),
            for (final (title, feathers) in [(tr('Ropa y accesorios', 'Clothes and accessories'), false), (tr('Plumaje', 'Feathers'), true)]) ...[
              const SizedBox(height: 24),
              Text(title, key: Key('shop-section-${feathers ? 'plumaje' : 'ropa'}'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _Grid(_section(feathers: feathers)),
            ],
            if (state.wearing != null || state.feathers != null) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: state.takeOffAll,
                  child: Text(tr('Quitarle todo a Owlito', 'Take everything off Owlito'), style: TextStyle(fontSize: 16, color: p.ink)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Las cosas de una sección, de la más barata a la más cara; las de Premium 👑 al final.
List<ShopItem> _section({required bool feathers}) => [
      for (final premium in [false, true])
        ...shopItems.where((i) => i.isFeathers == feathers && i.premium == premium && i.medals == 0).toList()
          ..sort((a, b) => a.price.compareTo(b.price)),
    ];

class _Grid extends StatelessWidget {
  const _Grid(this.items);
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final columns = box.maxWidth >= 560 ? 3 : 2;
          final width = (box.maxWidth - 14 * (columns - 1)) / columns;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [for (final item in items) SizedBox(width: width, child: _ItemCard(item))],
          );
        },
      );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard(this.item);
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    final owned = state.hasItem(item);
    final wearing = state.wearing == item.id || state.feathers == item.id;
    final missing = item.price - state.stars;
    final String label;
    var price = 0; // se muestra con una estrella al lado
    final VoidCallback? onTap;
    Color color = p.math;
    Color ink = p.mathInk;
    if (wearing) {
      label = tr('Puesto', 'Wearing');
      onTap = null;
      color = AppColors.green;
      ink = Colors.white;
    } else if (owned) {
      label = tr('Ponérselo', 'Put on');
      onTap = () => state.wear(item.id);
    } else if (item.premium) {
      // Sin Premium: el niño pide ayuda y se abre la pregunta para adultos.
      label = '👑 Premium';
      color = p.accent;
      ink = p.accentInk;
      onTap = () {
        Voice.say(askForHelp, Lang.native);
        openPremium(context);
      };
    } else if (missing <= 0) {
      label = tr('Comprar', 'Buy');
      price = item.price;
      onTap = () {
        if (state.buy(item.id, item.price)) {
          Sfx.celebracion();
          Voice.say(greatJob, Lang.native);
        }
      };
    } else {
      label = tr('Te faltan', 'You need');
      price = missing;
      onTap = null;
      color = p.night ? p.bg : const Color(0xFFF6DCE8);
      ink = p.inkSoft;
    }
    return Container(
      key: Key('item-${item.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: p.cardBorder == null ? null : Border.all(color: p.cardBorder!, width: 2),
        boxShadow: p.night ? null : const [BoxShadow(color: Color(0xFFF3C6DA), offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          item.isFeathers
              ? Owl(size: 72, night: p.night, feathers: item.feathers, pattern: item.pattern)
              : Owl(size: 72, night: p.night, wearing: item.id),
          const SizedBox(height: 6),
          Text('${item.premium ? '👑 ' : ''}${item.name}',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.cardInk)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: color,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(label,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
                      ),
                      if (price > 0) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded, size: 18, color: ink),
                        Text('$price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
