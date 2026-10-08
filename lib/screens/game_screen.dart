import 'dart:math';

import 'package:flutter/material.dart';

import '../config.dart';
import '../logic/questions.dart';
import '../services/app_state.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'result_screen.dart';

/// Partida de [Config.roundsPerGame] preguntas (sumas o inglés).
/// Si el niño se equivoca, la app le explica con voz y la pregunta vuelve más tarde como repaso.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.title, required this.makeQuestion, this.random});

  final String title;
  final QuestionMaker makeQuestion;
  final Random? random;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// Cuántas preguntas después vuelve a salir una pregunta fallada.
  static const _reviewAfter = 3;

  late final Random _random = widget.random ?? Random();
  late Question _q;
  int _round = 0;
  int _correct = 0;
  bool _firstTry = true;
  bool _isReview = false;
  bool _locked = false;
  final Set<int> _wrong = {};
  final List<(int, Question)> _reviews = []; // (ronda en que vuelve, pregunta)
  String? _flash;

  // Explicación en curso.
  bool _explaining = false;
  int? _counted;
  bool _highlightAnswer = false;
  int _explainToken = 0;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _explainToken++;
    Voice.stop();
    super.dispose();
  }

  void _next() {
    final left = Config.roundsPerGame - _round;
    final i = _reviews.indexWhere((r) => r.$1 <= _round || left <= _reviews.length);
    if (i >= 0) {
      _q = _reviews.removeAt(i).$2;
      _isReview = true;
    } else {
      _q = widget.makeQuestion(_random);
      _isReview = false;
    }
    _firstTry = true;
    _locked = false;
    _wrong.clear();
    _counted = null;
    _highlightAnswer = false;
    final q = _q;
    final intro = _isReview ? Voice.say('¡Repasemos!', 'es') : Future<void>.value();
    intro.then((_) {
      if (mounted && identical(q, _q)) Voice.say(q.speech, q.speechLang);
    });
  }

  Future<void> _tap(int i) async {
    if (_locked || _explaining || _wrong.contains(i)) return;
    if (i != _q.answerIndex) {
      setState(() {
        _wrong.add(i);
        if (_firstTry && !_isReview) _reviews.add((_round + _reviewAfter, _q));
        _firstTry = false;
        _flash = null;
      });
      await _explain(i);
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
    await Voice.say(
      _q.speechLang == 'en' ? (_firstTry ? 'Yes! ${_q.speech}' : 'Very good! ${_q.speech}') : (_firstTry ? _q.answer : '¡Muy bien, ${_q.answer}!'),
      _q.speechLang,
    );
    await Future.delayed(const Duration(milliseconds: 500));
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

  /// Explica el error paso a paso con voz y dibujos.
  Future<void> _explain(int chosen) async {
    final token = ++_explainToken;
    setState(() => _explaining = true);
    for (final step in explainMistake(_q, chosen)) {
      if (!mounted || token != _explainToken) return;
      setState(() {
        if (step.count != null) _counted = step.count;
        if (step.highlightAnswer) _highlightAnswer = true;
      });
      await Future.wait([
        Voice.say(step.text, step.lang),
        Future.delayed(Duration(milliseconds: step.count != null ? 650 : 1100)),
      ]);
    }
    if (mounted && token == _explainToken) setState(() => _explaining = false);
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
          ListView(
            padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: _isReview
                    ? const Text('🔁 Repaso', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                    : null,
              ),
              if (q.speechLang == 'en') ...[
                const Text('Escucha y toca el dibujo correcto', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                BigButton(
                  label: '🔊 ${q.prompt}',
                  color: AppColors.blue,
                  textColor: Colors.white,
                  fontSize: 32,
                  onTap: _explaining ? null : () => Voice.say(q.speech, 'en'),
                ),
              ] else ...[
                if (q.addition!.drawable)
                  _CountingPicture(q.addition!, counted: _counted)
                else if (_counted != null)
                  _CountingOn(q.addition!, upTo: _counted!),
                const SizedBox(height: 12),
                Text(q.prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  for (var i = 0; i < q.options.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedScale(
                          scale: _highlightAnswer && i == q.answerIndex && !_locked ? 1.12 : 1,
                          duration: const Duration(milliseconds: 300),
                          child: BigButton(
                            key: Key('option-$i'),
                            label: q.options[i],
                            fontSize: q.pictureOptions ? 52 : 40,
                            color: _optionColor(i),
                            textColor: _wrong.contains(i) || (_locked && i == q.answerIndex) ? Colors.white : AppColors.ink,
                            onTap: () => _tap(i),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_explaining) ...[
                const SizedBox(height: 20),
                const Text('👂 Escucha…', textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
              ],
            ],
          ),
          if (_flash != null)
            IgnorePointer(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('$_round$_flash'),
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

  Color _optionColor(int i) {
    if (_wrong.contains(i)) return Colors.orange.shade300;
    if (i == _q.answerIndex && _locked) return AppColors.green;
    if (i == _q.answerIndex && _highlightAnswer) return AppColors.yellow;
    return Colors.white;
  }
}

/// Dibujos de la suma. Al explicar, se numeran uno a uno mientras la voz cuenta.
class _CountingPicture extends StatelessWidget {
  const _CountingPicture(this.add, {this.counted});
  final Addition add;
  final int? counted;

  Widget _item(int n) {
    final done = counted != null && n <= counted!;
    final current = counted == n;
    return AnimatedScale(
      scale: current ? 1.3 : 1,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(add.object, style: const TextStyle(fontSize: 34)),
          SizedBox(
            height: 26,
            child: done
                ? Text('$n', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.blue))
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget group(int from, int count) => Flexible(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [for (var n = from; n < from + count; n++) _item(n)],
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        group(1, add.a),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('+', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.blue)),
        ),
        group(add.a + 1, add.b),
      ],
    );
  }
}

/// Para sumas grandes: contar hacia adelante desde el primer número (12 → 13 → 14…).
class _CountingOn extends StatelessWidget {
  const _CountingOn(this.add, {required this.upTo});
  final Addition add;
  final int upTo;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var n = add.a; n <= upTo; n++)
          Chip(
            backgroundColor: n == add.a ? AppColors.blue : (n == upTo ? AppColors.yellow : Colors.white),
            label: Text(
              n == add.a ? '$n' : '+1 → $n',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: n == add.a ? Colors.white : AppColors.ink),
            ),
          ),
      ],
    );
  }
}
