import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/billing.dart';
import '../theme.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

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
            const Text('Aprende Jugando Premium',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('✅ Todos los niveles y temas\n✅ Sin publicidad\n✅ Pago único, sin suscripción',
                style: TextStyle(fontSize: 20, height: 1.8)),
            const SizedBox(height: 24),
            if (state.premium)
              const BigButton(label: '✅ Ya tienes Premium', onTap: null, color: AppColors.green, textColor: Colors.white)
            else
              BigButton(
                label: billing.busy ? 'Procesando…' : 'Desbloquear por ${billing.price}',
                color: AppColors.yellow,
                onTap: billing.busy ? null : billing.buy,
              ),
            const SizedBox(height: 12),
            if (!state.premium) ...[
              TextButton(onPressed: billing.restore, child: const Text('Restaurar compra', style: TextStyle(fontSize: 18))),
              TextButton(
                key: const Key('redeem'),
                onPressed: () => _redeem(context),
                child: const Text('Tengo un código', style: TextStyle(fontSize: 18)),
              ),
            ],
            if (billing.error != null)
              Text(billing.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontSize: 16)),
            const SizedBox(height: 12),
            Text('El pago se hace de forma segura con Google Play.',
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
      content: Text(ok ? '¡Listo! Premium activado.' : 'Ese código no es válido.', style: const TextStyle(fontSize: 18)),
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
        title: const Text('Código de Premium'),
        content: TextField(
          key: const Key('code-input'),
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'OWL-XXXX-XXXX'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Activar')),
        ],
      );
}
