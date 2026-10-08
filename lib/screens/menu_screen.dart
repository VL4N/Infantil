import 'package:flutter/material.dart';

import '../logic/content.dart';
import '../logic/questions.dart';
import '../services/app_state.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'game_screen.dart';
import 'parental_gate.dart';
import 'premium_screen.dart';

Future<void> openPremium(BuildContext context) async {
  if (await parentalGate(context) && context.mounted) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
  }
}

/// Contenido bloqueado: avisa al niño y pide la pregunta para adultos.
Future<void> _lockedTap(BuildContext context) {
  Voice.say('Pide ayuda a papá o a mamá', 'es');
  return openPremium(context);
}

AppBar _appBar(String title) => AppBar(
      title: Text(title),
      actions: [ListenableBuilder(
        listenable: AppState.instance,
        builder: (_, _) => StarCounter(stars: AppState.instance.stars),
      )],
    );

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar('Aprende Jugando'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('¿Qué quieres aprender hoy?', textAlign: TextAlign.center, style: TextStyle(fontSize: 26)),
          const SizedBox(height: 20),
          BigButton(
            label: '➕  Sumar',
            fontSize: 36,
            color: AppColors.blue,
            textColor: Colors.white,
            padding: const EdgeInsets.all(32),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MathLevelsScreen())),
          ),
          const SizedBox(height: 18),
          BigButton(
            label: '🇬🇧  Inglés',
            fontSize: 36,
            color: AppColors.green,
            textColor: Colors.white,
            padding: const EdgeInsets.all(32),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnglishTopicsScreen())),
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: AppState.instance,
            builder: (context, _) => AppState.instance.premium
                ? const Text('👑 Premium activo', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))
                : TextButton(
                    onPressed: () => openPremium(context),
                    child: const Text('👑 Versión Premium (para papás)', style: TextStyle(fontSize: 18)),
                  ),
          ),
        ],
      ),
    );
  }
}

class MathLevelsScreen extends StatelessWidget {
  const MathLevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: _appBar('Sumar'),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Elige un nivel', textAlign: TextAlign.center, style: TextStyle(fontSize: 26)),
            for (final (max, label) in mathLevels) ...[
              const SizedBox(height: 16),
              BigButton(
                label: label,
                locked: !state.canPlayMath(max),
                stars: state.canPlayMath(max) ? state.bestFor(mathKey(max)) : null,
                onTap: () => state.canPlayMath(max)
                    ? Navigator.push(context, MaterialPageRoute(
                        builder: (_) => GameScreen(title: 'Sumar', progressKey: mathKey(max), makeQuestion: (r) => mathQuestion(r, max)),
                      ))
                    : _lockedTap(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EnglishTopicsScreen extends StatelessWidget {
  const EnglishTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: _appBar('Inglés'),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Elige un tema', textAlign: TextAlign.center, style: TextStyle(fontSize: 26)),
            for (final topic in topics) ...[
              const SizedBox(height: 16),
              BigButton(
                label: topic.label,
                locked: !state.canPlayTopic(topic.key),
                stars: state.canPlayTopic(topic.key) ? state.bestFor(topicKey(topic)) : null,
                onTap: () => state.canPlayTopic(topic.key)
                    ? Navigator.push(context, MaterialPageRoute(
                        builder: (_) => GameScreen(title: 'Inglés', progressKey: topicKey(topic), makeQuestion: (r) => englishMixedQuestion(r, topic)),
                      ))
                    : _lockedTap(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
