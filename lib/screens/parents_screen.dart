import 'package:flutter/material.dart';

import '../logic/content.dart';
import '../logic/lang.dart';
import '../logic/stickers.dart';
import '../services/app_state.dart';
import '../services/reminder.dart';
import '../theme.dart';
import 'language_screen.dart';
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
      appBar: AppBar(title: Text(tr('Resumen para papás', 'Summary for parents'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Week(name: state.profile.name),
          const SizedBox(height: 24),
          Text(tr('Desde el principio', 'Since the start'), style: title),
          const SizedBox(height: 8),
          Text('📅 ${tr('Días jugados', 'Days played')}: ${state.days.length}', style: body),
          Text('🎮 ${tr('Partidas terminadas', 'Games finished')}: ${state.played.values.fold(0, (a, b) => a + b)}', style: body),
          Text('⭐ ${tr('Estrellas ganadas', 'Stars earned')}: ${state.starsEarned} (${tr('para gastar', 'to spend')}: ${state.stars})', style: body),
          Text('🏅 ${tr('Medallas del día', 'Daily medals')}: ${state.medals}', style: body),
          Text('📒 ${tr('Stickers del álbum', 'Album stickers')}: ${state.stickers.length} / $totalStickers', style: body),
          const SizedBox(height: 24),
          Text(tr('Lo que practicó', 'What they practiced'), style: title),
          const SizedBox(height: 8),
          if (games.isEmpty) Text(tr('Todavía no terminó ninguna partida.', 'No games finished yet.'), style: body),
          for (final g in games)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(progressLabel(g.key), style: body),
              subtitle: Text(g.value == 1 ? tr('1 partida', '1 game') : '${g.value} ${tr('partidas', 'games')}'),
              trailing: StarRating(stars: state.bestFor(g.key), size: 22),
            ),
          const SizedBox(height: 24),
          Text(tr('Palabras en inglés que más le cuestan', 'Spanish words that are hardest'), style: title),
          const SizedBox(height: 8),
          if (hardest.isEmpty) Text(tr('Ninguna por ahora. ¡Muy bien!', 'None for now. Great job!'), style: body),
          for (final w in hardest)
            Text('• ${w.key}: ${w.value == 1 ? tr('1 error', '1 mistake') : '${w.value} ${tr('errores', 'mistakes')}'}', style: body),
          const SizedBox(height: 24),
          Text(
            tr('Consejo: repasen juntos esas palabras en voz alta y jueguen ese tema en Parejas.',
                'Tip: practice those words out loud together and play that topic in Pairs.'),
            style: TextStyle(fontSize: 16, color: context.palette.ink),
          ),
          const SizedBox(height: 32),
          const _Profiles(),
          const SizedBox(height: 32),
          const _ReminderSetting(),
          const SizedBox(height: 32),
          const _LanguageSetting(),
        ],
      ),
    );
  }
}

/// Resumen de los últimos 7 días, en una frase fácil de leer.
class _Week extends StatelessWidget {
  const _Week({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    final days = state.weekDays;
    final text = days == 0
        ? tr('Esta semana $name todavía no jugó. ¡Un ratito al día ayuda mucho!',
            "$name hasn't played this week yet. A little every day helps a lot!")
        : tr(
            'Esta semana $name jugó ${days == 1 ? '1 día' : '$days días'}, '
                'terminó ${state.weekGames == 1 ? '1 partida' : '${state.weekGames} partidas'} '
                'y respondió bien a la primera ${state.weekAnswers == 1 ? '1 pregunta' : '${state.weekAnswers} preguntas'}.',
            'This week $name played ${days == 1 ? '1 day' : '$days days'}, '
                'finished ${state.weekGames == 1 ? '1 game' : '${state.weekGames} games'} '
                'and got ${state.weekAnswers == 1 ? '1 answer' : '${state.weekAnswers} answers'} right on the first try.');
    return Container(
      key: const Key('week-summary'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.cardBorder ?? p.star, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🗓️ ${tr('Esta semana', 'This week')}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 18, height: 1.3)),
          if (days > 0) ...[
            const SizedBox(height: 6),
            Text(
              tr('🏅 Ganó la medalla del día ${state.weekMedals} de 7 días.',
                  "🏅 Won the daily medal ${state.weekMedals} of 7 days."),
              key: const Key('week-medals'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (icon, n, label) in [
                ('📅', days, tr('días', 'days')),
                ('🎮', state.weekGames, tr('partidas', 'games')),
                ('⭐', state.weekAnswers, tr('aciertos', 'right')),
              ])
                Expanded(
                  child: Column(
                    children: [
                      Text('$icon $n', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      Text(label, style: TextStyle(fontSize: 15, color: p.inkSoft)),
                    ],
                  ),
                ),
            ],
          ),
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
          Text(tr('Niños que juegan', 'Kids who play'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(
              tr('Cada uno tiene su propio progreso y sus estrellas. Este resumen es del que está jugando.',
                  'Each one has their own progress and stars. This summary is for the one playing now.'),
              style: const TextStyle(fontSize: 15)),
          for (final p in state.profiles)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name, style: const TextStyle(fontSize: 18)),
              subtitle: Text([
                state.ageOf(p.id)?.label ?? tr('Edad sin elegir', 'Age not chosen'),
                if (p.id == state.profile.id) tr('Está jugando ahora', 'Playing now'),
              ].join(' · ')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<AgeGroup>(
                    key: Key('age-menu-${p.id}'),
                    tooltip: tr('Edad', 'Age'),
                    icon: const Icon(Icons.cake_rounded),
                    onSelected: (age) => state.setAgeOf(p.id, age),
                    itemBuilder: (_) => [for (final age in AgeGroup.values) PopupMenuItem(value: age, child: Text(age.label))],
                  ),
                  IconButton(
                    tooltip: tr('Cambiar nombre', 'Rename'),
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () async {
                      final name = await askName(context, initial: p.name);
                      if (name != null) state.renameProfile(p.id, name);
                    },
                  ),
                  if (state.profiles.length > 1)
                    IconButton(
                      tooltip: tr('Borrar', 'Delete'),
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(tr('¿Borrar a ${p.name}?', 'Delete ${p.name}?')),
                            content: Text(tr('Se borra su progreso, sus estrellas y lo que compró en la tienda.',
                                'This deletes their progress, stars and what they bought in the shop.')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Cancelar', 'Cancel'))),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('Borrar', 'Delete'))),
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
              label: Text(tr('Agregar otro niño o niña', 'Add another child')),
              onPressed: () async {
                final name = await askName(context);
                if (name == null || !context.mounted) return;
                final age = await showDialog<AgeGroup>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text(tr('¿Cuántos años tiene?', 'How old are they?')),
                    children: [
                      for (final age in AgeGroup.values)
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, age),
                          child: Text(age.label, style: const TextStyle(fontSize: 20)),
                        ),
                    ],
                  ),
                );
                state.addProfile(name, age: age);
              },
            ),
        ],
      ),
    );
  }
}

/// Aviso diario en el teléfono para jugar un ratito, a la hora que elijan los papás.
class _ReminderSetting extends StatelessWidget {
  const _ReminderSetting();

  Future<void> _set(BuildContext context, {required bool on, int? hour}) async {
    final state = AppState.instance;
    if (!on) {
      await Reminder.disable();
      state.setReminder(on: false, hour: hour);
      return;
    }
    final ok = await Reminder.enable(hour ?? state.reminderHour);
    state.setReminder(on: ok, hour: hour);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('Para el recordatorio, permite las notificaciones de la app en los ajustes del teléfono.',
            "For the reminder, allow the app's notifications in the phone settings.")),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const Key('reminder-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Recordatorio diario', 'Daily reminder'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            subtitle: Text(tr('Un aviso al día: "¡Owlito te espera!"', 'One reminder a day: "Owlito is waiting for you!"')),
            value: state.reminderOn,
            onChanged: (on) => _set(context, on: on),
          ),
          if (state.reminderOn)
            Row(
              children: [
                Text(tr('Hora:', 'Time:'), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: state.reminderHour,
                  items: [
                    for (var h = 8; h <= 20; h++) DropdownMenuItem(
                        value: h,
                        child: Text('${h > 12 ? h - 12 : h}:00 ${h < 12 ? tr('a. m.', 'AM') : tr('p. m.', 'PM')}')),
                  ],
                  onChanged: (h) => _set(context, on: true, hour: h),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Idioma de la app: el del niño (aprende el otro). Al cambiarlo se vuelve al menú, ya en el idioma nuevo.
class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('Idioma', 'Language'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LanguageChoices(onChosen: (_) => Navigator.pushAndRemoveUntil(context, homeRoute(), (_) => false)),
        ],
      );
}

