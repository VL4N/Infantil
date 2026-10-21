import 'package:flutter/material.dart';

import '../logic/lang.dart';
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
            const Center(child: Text('👑', style: TextStyle(fontSize: 90))),
            Text(tr('Aprende Jugando Premium', 'Learn & Play Premium'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
                tr('✅ Todos los niveles y temas\n✅ Sin publicidad\n✅ Pago único, sin suscripción',
                    '✅ All levels and topics\n✅ No ads\n✅ One-time payment, no subscription'),
                style: const TextStyle(fontSize: 20, height: 1.8)),
            const SizedBox(height: 24),
            if (state.premium)
              BigButton(
                  label: tr('✅ Ya tienes Premium', '✅ You have Premium'),
                  onTap: null,
                  color: AppColors.green,
                  textColor: Colors.white)
            else
              BigButton(
                label: billing.busy ? tr('Procesando…', 'Processing…') : tr('Desbloquear por ${billing.price}', 'Unlock for ${billing.price}'),
                color: AppColors.yellow,
                onTap: billing.busy ? null : billing.buy,
              ),
            const SizedBox(height: 12),
            if (!state.premium) ...[
              TextButton(onPressed: billing.restore, child: Text(tr('Restaurar compra', 'Restore purchase'), style: const TextStyle(fontSize: 18))),
              TextButton(
                key: const Key('redeem'),
                onPressed: () => _redeem(context),
                child: Text(tr('Tengo un código', 'I have a code'), style: const TextStyle(fontSize: 18)),
              ),
            ],
            if (billing.error != null)
              Text(billing.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontSize: 16)),
            const SizedBox(height: 12),
            Text(tr('El pago se hace de forma segura con Google Play.', 'Payment is handled securely by Google Play.'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: context.palette.inkSoft)),
          ],
        ),
      ),
    );
  }

  Future<void> _redeem(BuildContext context) async {
    final code = await showDialog<String>(context: context, builder: (_) => const _CodeDialog());
    if (code == null || code.trim().isEmpty || !context.mounted) return;
    final ok = AppState.instance.redeemCode(code);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          ok ? tr('¡Listo! Premium activado.', 'Done! Premium is on.') : tr('Ese código no es válido.', "That code isn't valid."),
          style: const TextStyle(fontSize: 18)),
    ));
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
