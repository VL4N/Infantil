import 'package:flutter/material.dart';

import '../logic/content.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'profile_screen.dart';

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
          Text('⭐ Estrellas ganadas: ${state.starsEarned} (para gastar: ${state.stars})', style: body),
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
          Text(
            'Consejo: repasen juntos esas palabras en voz alta y jueguen ese tema en Parejas.',
            style: TextStyle(fontSize: 16, color: context.palette.ink),
          ),
          const SizedBox(height: 32),
          const _Profiles(),
        ],
      ),
    );
  }
}

/// Niños que juegan en este teléfono: cada uno con su progreso, estrellas y tienda.
class _Profiles extends StatelessWidget {
  const _Profiles();

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Niños que juegan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Cada uno tiene su propio progreso y sus estrellas. Este resumen es del que está jugando.',
              style: TextStyle(fontSize: 15)),
          for (final p in state.profiles)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name, style: const TextStyle(fontSize: 18)),
              subtitle: p.id == state.profile.id ? const Text('Está jugando ahora') : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Cambiar nombre',
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () async {
                      final name = await askName(context, initial: p.name);
                      if (name != null) state.renameProfile(p.id, name);
                    },
                  ),
                  if (state.profiles.length > 1)
                    IconButton(
                      tooltip: 'Borrar',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('¿Borrar a ${p.name}?'),
                            content: const Text('Se borra su progreso, sus estrellas y lo que compró en la tienda.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar')),
                            ],
                          ),
                        );
                        if (ok == true) state.removeProfile(p.id);
                      },
                    ),
                ],
              ),
            ),
          if (state.profiles.length < AppState.maxProfiles)
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Agregar otro niño o niña'),
              onPressed: () async {
                final name = await askName(context);
                if (name != null) state.addProfile(name);
              },
            ),
        ],
      ),
    );
  }
}
