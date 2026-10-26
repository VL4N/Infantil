import 'package:flutter/material.dart';

import '../logic/lang.dart';
import '../logic/lines.dart';
import '../services/app_state.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'menu_screen.dart';

/// Al abrir la app con varios niños: cada uno toca su nombre.
class ProfilePickerScreen extends StatefulWidget {
  const ProfilePickerScreen({super.key});

  @override
  State<ProfilePickerScreen> createState() => _ProfilePickerScreenState();
}

class _ProfilePickerScreenState extends State<ProfilePickerScreen> {
  @override
  void initState() {
    super.initState();
    Voice.say(whoIsPlaying, Lang.native);
  }

  /// Colores de plumas para distinguir a cada niño en esta pantalla.
  static const _colors = [null, (0xFF2F6FB5, 0xFF4A90D9, 0xFFCFE4FA), (0xFFC9558E, 0xFFE77FB0, 0xFFFADCEB), (0xFF2F8A5A, 0xFF4CAF7A, 0xFFD4F0DF)];

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text(whoIsPlaying,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            for (final (i, profile) in state.profiles.indexed) ...[
              Material(
                color: p.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: BorderSide(color: p.cardBorder ?? const Color(0xFFF3C6DA), width: 2),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () {
                    state.switchProfile(profile.id);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MenuScreen()),
                      (_) => false,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Owl(size: 64, night: p.night, feathers: _colors[i % _colors.length]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(profile.name,
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: p.cardInk)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pide un nombre (para agregar o cambiar el nombre de un niño).
Future<String?> askName(BuildContext context, {String initial = ''}) =>
    showDialog<String>(context: context, builder: (_) => _NameDialog(initial));

class _NameDialog extends StatefulWidget {
  const _NameDialog(this.initial);
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(tr('Nombre del niño o niña', "Child's name")),
        content: TextField(
          key: const Key('profile-name'),
          controller: _controller,
          autofocus: true,
          maxLength: 16,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Cancelar', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(tr('Guardar', 'Save'))),
        ],
      );
}

/// La primera vez, después del idioma: el nombre y la edad del niño (todo se puede cambiar en la zona de papás).
class FirstProfileScreen extends StatefulWidget {
  const FirstProfileScreen({super.key});

  @override
  State<FirstProfileScreen> createState() => _FirstProfileScreenState();
}

class _FirstProfileScreenState extends State<FirstProfileScreen> {
  final _name = TextEditingController();
  AgeGroup? _age;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _start() {
    final state = AppState.instance;
    if (_name.text.trim().isNotEmpty) state.renameProfile(state.profile.id, _name.text);
    state.setAgeGroup(_age!);
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MenuScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            Center(child: Owl(size: 96, night: p.night)),
            const SizedBox(height: 12),
            Text(tr('¡Hola! Soy Owlito. ¿Cómo te llamas?', "Hi! I'm Owlito. What's your name?"),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              key: const Key('first-name'),
              controller: _name,
              maxLength: 16,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: tr('Nombre', 'Name'),
                filled: true,
                fillColor: p.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 12),
            Text(tr('¿Cuántos años tienes?', 'How old are you?'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (i, age) in AgeGroup.values.indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: BigButton(
                      key: Key('first-age-${age.name}'),
                      label: '${age == AgeGroup.small ? '🐣' : '🦉'}\n${age.label}',
                      fontSize: 20,
                      color: _age == age ? (age == AgeGroup.small ? p.subtract : p.numbers) : null,
                      textColor: _age == age ? (age == AgeGroup.small ? p.subtractInk : p.numbersInk) : null,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      onTap: () => setState(() => _age = age),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            BigButton(
              key: const Key('first-start'),
              label: tr('¡A jugar! ▶', "Let's play! ▶"),
              fontSize: 26,
              color: _age == null ? null : p.math,
              textColor: _age == null ? null : p.mathInk,
              // Primero hay que elegir la edad (el nombre es opcional).
              onTap: _age == null ? null : _start,
            ),
            const SizedBox(height: 8),
            Text(tr('Los papás pueden cambiarlo después en "Para papás y mamás".',
                    'Parents can change this later in "For moms and dads".'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.inkSoft)),
          ],
        ),
      ),
    );
  }
}
