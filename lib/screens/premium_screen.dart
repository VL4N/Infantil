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
            if (!state.premium)
              TextButton(onPressed: billing.restore, child: const Text('Restaurar compra', style: TextStyle(fontSize: 18))),
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
}
