import 'dart:math';

import 'package:flutter/material.dart';

import '../config.dart';
import '../logic/questions.dart';
import '../services/app_state.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'result_screen.dart';

/// Partida de [Config.roundsPerGame] preguntas (sumas o inglés).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.title, required this.makeQuestion, this.random});

  final String title;
  final QuestionMaker makeQuestion;
  final Random? random;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final Random _random = widget.random ?? Random();
  late Question _q;
  int _round = 0;
  int _correct = 0;
  bool _firstTry = true;
  bool _locked = false;
  final Set<int> _wrong = {};
  String? _flash;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    _q = widget.makeQuestion(_random);
    _firstTry = true;
    _locked = false;
    _wrong.clear();
    Voice.say(_q.speech, _q.speechLang);
  }

  Future<void> _tap(int i) async {
    if (_locked || _wrong.contains(i)) return;
    if (i != _q.answerIndex) {
      setState(() {
        _wrong.add(i);
        _firstTry = false;
        _flash = '🙈';
      });
      return;
    }
    if (_firstTry) {
      _correct++;
      AppState.instance.addStar();
    }
    setState(() {
      _locked = true;
      _round++;
      _flash = _firstTry ? '⭐' : '👍';
    });
    Voice.say(_q.speechLang == 'en' ? (_firstTry ? 'Yes! ${_q.speech}' : _q.speech) : _q.answer, _q.speechLang);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_round >= Config.roundsPerGame) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            correct: _correct,
            english: _q.speechLang == 'en',
            playAgain: () => GameScreen(title: widget.title, makeQuestion: widget.makeQuestion),
          ),
        ),
      );
    } else {
      setState(() {
        _flash = null;
        _next();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [ListenableBuilder(
          listenable: AppState.instance,
          builder: (_, _) => StarCounter(stars: AppState.instance.stars),
        )],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: _round / Config.roundsPerGame,
                    minHeight: 14,
                    color: AppColors.green,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                if (q.speechLang == 'en') ...[
                  const Text('Escucha y toca el dibujo correcto', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  BigButton(
                    label: '🔊 ${q.prompt}',
                    color: AppColors.blue,
                    textColor: Colors.white,
                    fontSize: 32,
                    onTap: () => Voice.say(q.speech, 'en'),
                  ),
                ] else ...[
                  if (q.visual != null) _CountingPicture(q.visual!),
                  const SizedBox(height: 12),
                  Text(q.prompt, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    for (var i = 0; i < q.options.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: BigButton(
                            key: Key('option-$i'),
                            label: q.options[i],
                            fontSize: q.pictureOptions ? 52 : 40,
                            color: _wrong.contains(i)
                                ? AppColors.red
                                : (_locked && i == q.answerIndex ? AppColors.green : Colors.white),
                            textColor: _wrong.contains(i) || (_locked && i == q.answerIndex) ? Colors.white : AppColors.ink,
                            onTap: () => _tap(i),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_flash != null)
            IgnorePointer(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('$_round$_flash${_wrong.length}'),
                  tween: Tween(begin: 0.5, end: 1),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, s, child) => Transform.scale(scale: s, child: child),
                  child: Text(_flash!, style: const TextStyle(fontSize: 110)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountingPicture extends StatelessWidget {
  const _CountingPicture(this.groups);
  final (String, String) groups;

  @override
  Widget build(BuildContext context) {
    Widget group(String s) => Flexible(
          child: Text(s, textAlign: TextAlign.center, style: const TextStyle(fontSize: 34)),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        group(groups.$1),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('+', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.blue)),
        ),
        group(groups.$2),
      ],
    );
  }
}
