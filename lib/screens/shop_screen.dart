import 'package:flutter/material.dart';

import '../logic/shop.dart';
import '../services/app_state.dart';
import '../services/sfx.dart';
import '../services/voice.dart';
import '../theme.dart';

/// Tienda de Owlito: las estrellas ganadas se gastan en ropa y accesorios para el búho.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de Owlito'),
        actions: [ListenableBuilder(listenable: state, builder: (_, _) => StarCounter(stars: state.stars))],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Owl(size: 130, night: p.night, wearing: state.wearing, feathers: state.featherColors)),
            const SizedBox(height: 12),
            Text(
              'Tienes ${state.stars} ${state.stars == 1 ? 'estrella' : 'estrellas'} para gastar',
              key: const Key('shop-balance'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(
              'Ganas una estrella por cada respuesta correcta a la primera y por cada pareja.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: p.inkSoft),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 560 ? 3 : 2;
                final width = (box.maxWidth - 14 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [for (final item in shopItems) SizedBox(width: width, child: _ItemCard(item))],
                );
              },
            ),
            if (state.wearing != null || state.feathers != null) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: state.takeOffAll,
                  child: Text('Quitarle todo a Owlito', style: TextStyle(fontSize: 16, color: p.ink)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard(this.item);
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    final owned = state.owned.contains(item.id);
    final wearing = state.wearing == item.id || state.feathers == item.id;
    final missing = item.price - state.stars;
    final String label;
    var price = 0; // se muestra con una estrella al lado
    final VoidCallback? onTap;
    Color color = p.math;
    Color ink = p.mathInk;
    if (wearing) {
      label = 'Puesto';
      onTap = null;
      color = AppColors.green;
      ink = Colors.white;
    } else if (owned) {
      label = 'Ponérselo';
      onTap = () => state.wear(item.id);
    } else if (missing <= 0) {
      label = 'Comprar';
      price = item.price;
      onTap = () {
        if (state.buy(item.id, item.price)) {
          Sfx.celebracion();
          Voice.say('¡Muy bien!', 'es');
        }
      };
    } else {
      label = 'Te faltan';
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
              ? Owl(size: 72, night: p.night, feathers: item.feathers)
              : Owl(size: 72, night: p.night, wearing: item.id),
          const SizedBox(height: 6),
          Text(item.name,
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
