import 'package:flutter/material.dart';

import '../logic/lang.dart';
import '../logic/stickers.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'menu_screen.dart' show askPremium;

/// Álbum de stickers: se gana uno al terminar cada partida. Las páginas con 👑 se llenan con Premium.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Mi álbum', 'My album')),
        actions: [ListenableBuilder(listenable: state, builder: (_, _) => StarCounter(stars: state.stars))],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              tr('Tienes ${state.stickers.length} de $totalStickers stickers',
                  'You have ${state.stickers.length} of $totalStickers stickers'),
              key: const Key('album-count'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              tr('Gana un sticker en cada partida que terminas. ¡Completa una página y gana $pageBonus estrellas!',
                  'Win a sticker in every game you finish. Complete a page and win $pageBonus stars!'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: p.inkSoft),
            ),
            for (final page in stickerPages) ...[
              const SizedBox(height: 18),
              _Page(page),
            ],
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.page);
  final StickerPage page;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    final open = state.canFillPage(page);
    final have = page.stickers.where((s) => state.stickers.contains(stickerId(page, s))).length;
    final full = have == page.stickers.length;
    return Container(
      key: Key('album-${page.key}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: full ? p.star : (p.cardBorder ?? p.bg), width: full ? 3 : 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${page.premium ? '👑 ' : ''}${page.name}${full ? ' ✅' : ''}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              Text('$have / ${page.stickers.length}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.inkSoft)),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              const gap = 10.0;
              final size = (box.maxWidth - gap * 3) / 4;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final s in page.stickers)
                    _Slot(size: size, picture: state.stickers.contains(stickerId(page, s)) ? s : null, locked: !open),
                ],
              );
            },
          ),
          if (!open) ...[
            const SizedBox(height: 12),
            BigButton(
              key: Key('album-premium-${page.key}'),
              label: '👑 Premium',
              fontSize: 20,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              onTap: () => askPremium(context),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un lugar del álbum: el sticker si ya lo tiene, o un "?" (un candado en las páginas Premium).
class _Slot extends StatelessWidget {
  const _Slot({required this.size, required this.picture, required this.locked});
  final double size;
  final String? picture;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final has = picture != null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: has ? p.bg : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: has ? p.star : p.inkSoft.withValues(alpha: .4), width: has ? 3 : 2),
      ),
      child: Center(
        child: Text(
          picture ?? (locked ? '🔒' : '?'),
          style: TextStyle(
            fontSize: has ? size * .5 : size * .35,
            fontWeight: FontWeight.w700,
            color: p.inkSoft.withValues(alpha: .6),
          ),
        ),
      ),
    );
  }
}
