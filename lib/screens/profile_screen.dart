import 'package:flutter/material.dart';

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
    Voice.say('¿Quién va a jugar?', 'es');
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
            const Text('¿Quién va a jugar?',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
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
        title: const Text('Nombre del niño o niña'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Guardar')),
        ],
      );
}
