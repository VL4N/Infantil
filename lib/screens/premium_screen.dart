import 'package:flutter/material.dart';

import '../config.dart';
import '../logic/content.dart';
import '../logic/lang.dart';
import '../logic/letters.dart';
import '../logic/tables.dart';
import '../logic/numbers.dart';
import '../logic/shop.dart';
import '../logic/stickers.dart';
import '../services/app_state.dart';
import '../services/billing.dart';
import '../theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    Billing.instance.loadProduct();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final billing = Billing.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListenableBuilder(
        listenable: Listenable.merge([state, billing]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Owlito con un traje y plumas Premium, para que se vea lo que trae.
            Center(
              child: Owl(
                size: 110,
                night: context.palette.night,
                wearing: 'astronauta',
                feathers: shopItem('arcoiris')!.feathers,
                pattern: 'arcoiris',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('👑 Aprende Jugando Premium', '👑 Learn & Play Premium'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const _Comparison(),
            const SizedBox(height: 24),
            if (state.premium)
              BigButton(
                label: tr('✅ Ya tienes Premium', '✅ You have Premium'),
                onTap: null,
                color: AppColors.green,
                textColor: Colors.white,
              )
            else
              BigButton(
                label: billing.busy
                    ? tr('Procesando…', 'Processing…')
                    : tr('Desbloquear por ${billing.price}', 'Unlock for ${billing.price}'),
                color: AppColors.yellow,
                onTap: billing.busy ? null : billing.buy,
              ),
            const SizedBox(height: 12),
            if (!state.premium) ...[
              TextButton(
                onPressed: billing.restore,
                child: Text(tr('Restaurar compra', 'Restore purchase'), style: const TextStyle(fontSize: 18)),
              ),
              TextButton(
                key: const Key('redeem'),
                onPressed: () => _redeem(context),
                child: Text(tr('Tengo un código', 'I have a code'), style: const TextStyle(fontSize: 18)),
              ),
            ],
            if (billing.error != null)
              Text(
                billing.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.red, fontSize: 16),
              ),
            const SizedBox(height: 12),
            Text(
              tr('El pago se hace de forma segura con Google Play.', 'Payment is handled securely by Google Play.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.palette.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeem(BuildContext context) async {
    final code = await showDialog<String>(context: context, builder: (_) => const _CodeDialog());
    if (code == null || code.trim().isEmpty || !context.mounted) return;
    final ok = AppState.instance.redeemCode(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? tr('¡Listo! Premium activado.', 'Done! Premium is on.')
              : tr('Ese código no es válido.', "That code isn't valid."),
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr('Código de Premium', 'Premium code')),
    content: TextField(
      key: const Key('code-input'),
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'OWL-XXXX-XXXX-XXXX-XXXX'),
      onSubmitted: (v) => Navigator.pop(context, v),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Cancelar', 'Cancel'))),
      FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(tr('Activar', 'Activate'))),
    ],
  );
}

/// Qué trae la versión gratis y qué trae Premium, con números, para que se vea lo que se gana.
class _Comparison extends StatelessWidget {
  const _Comparison();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final freeMax = Config.freeMathMax.reduce((a, b) => a > b ? a : b);
    final allMax = mathLevels.map((l) => l.$1).reduce((a, b) => a > b ? a : b);
    final freeOutfits = shopItems.where((i) => !i.premium).length;
    final rows = [
      (tr('Sumar y restar', 'Add and subtract'), '${tr('Hasta', 'Up to')} $freeMax', '${tr('Hasta', 'Up to')} $allMax'),
      (tr('Juegos de números', 'Number games'), '${AppState.instance.freeNumberLevels.length}', '${numberLevels.length}'),
      (tr('Tablas y mates hasta 100', 'Times tables and math to 100'), '${Config.freeTablesLevels.length}', '${tablesLevels.length}'),
      (tr('Juegos de letras', 'Letter games'), '${AppState.instance.freeLetterLevels.length}', '${letterLevels.length}'),
      (
        tr('Temas de inglés y Parejas', 'Spanish topics and Pairs'),
        '${Config.freeEnglishTopics.length}',
        '${topics.length}',
      ),
      (tr('Trajes de Owlito', "Owlito's outfits"), '$freeOutfits', '${shopItems.length}'),
      (
        tr('Páginas del álbum', 'Album pages'),
        '${stickerPages.where((s) => !s.premium).length}',
        '${stickerPages.length}',
      ),
      (tr('Anuncios', 'Ads'), tr('Sí', 'Yes'), tr('No', 'No')),
      (tr('Pago', 'Payment'), '—', tr('Una sola vez', 'Just once')),
    ];
    Widget cell(String text, {bool bold = false, Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? p.cardInk),
      ),
    );
    return Container(
      key: const Key('premium-comparison'),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: p.cardBorder == null ? null : Border.all(color: p.cardBorder!, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(5), 1: FlexColumnWidth(3), 2: FlexColumnWidth(4)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              const SizedBox(),
              cell(tr('Gratis', 'Free'), bold: true, color: p.inkSoft),
              Container(
                color: AppColors.yellow,
                child: cell('👑 Premium', bold: true, color: const Color(0xFF3B2A55)),
              ),
            ],
          ),
          for (final (name, free, premium) in rows)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.cardInk),
                  ),
                ),
                cell(free, color: p.inkSoft),
                Container(color: AppColors.yellow.withValues(alpha: .25), child: cell(premium, bold: true)),
              ],
            ),
        ],
      ),
    );
  }
}
