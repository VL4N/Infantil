import 'package:flutter/material.dart';

import '../logic/lang.dart';
import '../logic/lines.dart';
import '../logic/shop.dart';
import '../services/app_state.dart';
import '../services/sfx.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'result_screen.dart' show MedalBadge;

/// Camino de medallas: cada medalla del día acerca al siguiente premio, como un pase de temporada.
/// Los premios son exclusivos: no se compran con estrellas.
class MedalsScreen extends StatelessWidget {
  const MedalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Camino de medallas', 'Medal path'))),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final next = medalRewards.where((r) => state.medals < r.medals).firstOrNull;
          final previous = medalRewards.lastWhere((r) => state.medals >= r.medals, orElse: () => const ShopItem('', '', '', 0));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const MedalBadge(size: 64),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      tr('Tienes ${state.medals} ${state.medals == 1 ? 'medalla' : 'medallas'}',
                          'You have ${state.medals} ${state.medals == 1 ? 'medal' : 'medals'}'),
                      key: const Key('medals-total'),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tr('Gana una medalla cada día que terminas ${AppState.dailyGoal} partidas. ¡Junta medallas y gana premios que no están en la tienda!',
                    'Win a medal every day you finish ${AppState.dailyGoal} games. Collect medals and win prizes that are not in the shop!'),
                style: TextStyle(fontSize: 16, color: p.inkSoft),
              ),
              const SizedBox(height: 18),
              if (next != null) ...[
                Text(
                  tr('Próximo premio: ${next.name}', 'Next prize: ${next.name}'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    key: const Key('medals-progress'),
                    value: (state.medals - previous.medals) / (next.medals - previous.medals),
                    minHeight: 18,
                    color: AppColors.yellow,
                    backgroundColor: p.track,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr('${state.medals} de ${next.medals} medallas', '${state.medals} of ${next.medals} medals'),
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.inkSoft),
                ),
              ] else
                Text(
                  tr('¡Completaste el camino de medallas! Owlito es todo un campeón.',
                      'You completed the medal path! Owlito is a true champion.'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 20),
              for (final (i, reward) in medalRewards.indexed) _Step(reward, last: i == medalRewards.length - 1),
            ],
          );
        },
      ),
    );
  }
}

/// Un premio del camino: la cantidad de medallas a la izquierda (unidas por una línea) y el premio a la derecha.
class _Step extends StatelessWidget {
  const _Step(this.reward, {required this.last});
  final ShopItem reward;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    final reached = state.medals >= reward.medals;
    final owned = state.owned.contains(reward.id);
    final wearing = state.wearing == reward.id || state.feathers == reward.id;
    final String label;
    VoidCallback? onTap;
    Color color = p.math;
    Color ink = p.mathInk;
    if (wearing) {
      label = tr('Puesto', 'Wearing');
      color = AppColors.green;
      ink = Colors.white;
    } else if (owned) {
      label = tr('Ponérselo', 'Put on');
      onTap = () => state.wear(reward.id);
    } else if (reached) {
      label = tr('¡Reclamar!', 'Claim it!');
      color = AppColors.yellow;
      ink = const Color(0xFF3B2A55);
      onTap = () {
        if (state.claim(reward)) {
          Sfx.celebracion();
          Voice.say(greatJob, Lang.native);
        }
      };
    } else {
      final missing = reward.medals - state.medals;
      label = tr('Te ${missing == 1 ? 'falta 1 medalla' : 'faltan $missing medallas'}',
          'You need ${missing == 1 ? '1 more medal' : '$missing more medals'}');
      color = p.night ? p.bg : const Color(0xFFF6DCE8);
      ink = p.inkSoft;
    }
    return IntrinsicHeight(
      key: Key('medal-step-${reward.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? AppColors.yellow : p.card,
                    border: Border.all(color: reached ? AppColors.yellow : p.inkSoft.withValues(alpha: .4), width: 3),
                  ),
                  child: Text('🏅${reward.medals}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: reached ? const Color(0xFF3B2A55) : p.ink)),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 6, color: reached ? AppColors.yellow : p.inkSoft.withValues(alpha: .25)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: reached ? AppColors.yellow : (p.cardBorder ?? Colors.transparent), width: reached ? 3 : 2),
                ),
                child: Row(
                  children: [
                    Opacity(
                      opacity: reached ? 1 : .55,
                      child: reward.isFeathers
                          ? Owl(size: 64, night: p.night, feathers: reward.feathers, pattern: reward.pattern)
                          : Owl(size: 64, night: p.night, wearing: reward.id),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(reward.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.cardInk)),
                          const SizedBox(height: 8),
                          Material(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              key: Key('medal-button-${reward.id}'),
                              borderRadius: BorderRadius.circular(14),
                              onTap: onTap,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                child: Text(label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
