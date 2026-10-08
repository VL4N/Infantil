import 'package:flutter/material.dart';

import '../logic/content.dart';
import '../services/app_state.dart';
import '../theme.dart';

/// Resumen para papás (detrás de la pregunta para adultos): qué practicó y qué le cuesta.
class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final games = state.played.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final hardest = state.hardestWords();
    const title = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
    const body = TextStyle(fontSize: 18);
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen para papás')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('📅 Días jugados: ${state.days.length}', style: body),
          Text('🎮 Partidas terminadas: ${state.played.values.fold(0, (a, b) => a + b)}', style: body),
          Text('⭐ Estrellas ganadas: ${state.stars}', style: body),
          const SizedBox(height: 24),
          const Text('Lo que practicó', style: title),
          const SizedBox(height: 8),
          if (games.isEmpty) const Text('Todavía no terminó ninguna partida.', style: body),
          for (final g in games)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(progressLabel(g.key), style: body),
              subtitle: Text(g.value == 1 ? '1 partida' : '${g.value} partidas'),
              trailing: StarRating(stars: state.bestFor(g.key), size: 22),
            ),
          const SizedBox(height: 24),
          const Text('Palabras en inglés que más le cuestan', style: title),
          const SizedBox(height: 8),
          if (hardest.isEmpty) const Text('Ninguna por ahora. ¡Muy bien!', style: body),
          for (final w in hardest)
            Text('• ${w.key}: ${w.value == 1 ? '1 error' : '${w.value} errores'}', style: body),
          const SizedBox(height: 24),
          const Text(
            'Consejo: repasen juntos esas palabras en voz alta y jueguen ese tema en Parejas.',
            style: TextStyle(fontSize: 16, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
