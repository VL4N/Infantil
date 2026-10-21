import 'package:flutter/material.dart';

import '../logic/lang.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';

/// La primera pantalla, la primera vez que se abre la app: elegir el idioma.
/// En español aprende inglés; en inglés aprende español. Se puede cambiar en la zona de papás.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            Center(child: Owl(size: 110, night: p.night)),
            const SizedBox(height: 16),
            // En los dos idiomas: todavía no se sabe cuál lee.
            const Text('Elige el idioma\nChoose your language',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 24),
            LanguageChoices(onChosen: (_) => Navigator.pushReplacement(context, homeRoute())),
          ],
        ),
      ),
    );
  }
}

/// La pantalla de inicio: elegir quién juega (si hay varios niños) o el menú.
Route<void> homeRoute() => MaterialPageRoute(
      builder: (_) => AppState.instance.profiles.length > 1 ? const ProfilePickerScreen() : const MenuScreen(),
    );

/// Los botones de cada idioma. El del teléfono (o el elegido) va primero y resaltado.
class LanguageChoices extends StatelessWidget {
  const LanguageChoices({super.key, required this.onChosen});
  final void Function(AppLang lang) onChosen;

  static const _options = {
    AppLang.es: ('🇪🇸', 'Español', 'Aprende inglés'),
    AppLang.en: ('🇺🇸', 'English', 'Learn Spanish'),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = Lang.current;
    final langs = [first, ...AppLang.values.where((l) => l != first)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final lang in langs) ...[
          BigButton(
            key: Key('lang-${lang.name}'),
            label: '${_options[lang]!.$1} ${_options[lang]!.$2}\n${_options[lang]!.$3}',
            fontSize: 22,
            color: lang == first ? p.math : null,
            textColor: lang == first ? p.mathInk : null,
            onTap: () {
              AppState.instance.setLang(lang);
              onChosen(lang);
            },
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
