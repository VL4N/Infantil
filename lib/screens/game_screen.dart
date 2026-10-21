import 'dart:math';

import 'package:flutter/material.dart';

import '../config.dart';
import '../logic/daily.dart';
import '../logic/lang.dart';
import '../logic/lines.dart';
import '../logic/questions.dart';
import '../services/app_state.dart';
import '../services/sfx.dart';
import '../services/voice.dart';
import '../theme.dart';
import 'result_screen.dart';

/// Partida de [Config.roundsPerGame] preguntas (sumas, restas o el idioma que aprende).
/// Si el niño se equivoca, la app le explica con voz y la pregunta vuelve más tarde como repaso.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.title, required this.progressKey, required this.makeQuestion, this.random});

  final String title;

  /// Nivel o tema que se juega (p. ej. 'suma-5', 'ingles-animales'), para guardar su progreso.
  final String progressKey;
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
  final Set<String> _seen = {}; // preguntas que ya salieron (para no repetirlas)
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
      _q = freshQuestion(widget.makeQuestion, _random, _seen);
      _isReview = false;
    }
    _firstTry = true;
    _locked = false;
    _wrong.clear();
    _counted = null;
    _highlightAnswer = false;
    final q = _q;
    () async {
      bool current() => mounted && identical(q, _q);
      if (_isReview) await Voice.say(letsReview, Lang.native);
      if (q.intro != null && current()) await Voice.say(q.intro!, Lang.native);
      if (current()) await Voice.say(q.ask ?? q.speech, q.askLang ?? q.speechLang);
    }();
  }

  Future<void> _tap(int i) async {
    if (_locked || _explaining || _wrong.contains(i)) return;
    if (i != _q.answerIndex) {
      setState(() {
        _wrong.add(i);
        if (_firstTry && !_isReview) _reviews.add((_round + _reviewAfter, _q));
        if (_firstTry && _q.speechLang == Lang.target) AppState.instance.recordMiss(_q.speech);
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
    Sfx.acierto();
    setState(() {
      _locked = true;
      _round++;
      _flash = _firstTry ? '⭐' : '👍';
    });
    // La partida se guarda en cuanto termina, antes de la voz, para no perderla si la voz se atasca.
    final finished = _round >= Config.roundsPerGame;
    final previousBest = AppState.instance.bestFor(widget.progressKey);
    final earned = finished ? AppState.instance.recordGame(widget.progressKey, AppState.starsFor(_correct)) : 0;
    // Al terminar el reto de hoy, estrellas extra (solo la primera vez del día).
    final bonus = finished && widget.progressKey == challengeKey ? AppState.instance.completeChallenge() : 0;
    if (_q.speechLang == Lang.target) {
      // La felicitación en el idioma del niño y solo la palabra en el que aprende.
      await Voice.say(_firstTry ? praiseFirstTry : praiseRetry, Lang.native);
      if (mounted) await Voice.say(_q.speech, Lang.target);
    } else {
      await Voice.say(_firstTry ? _q.answer : greatNumber(_q.answer), Lang.native);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    if (finished) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            detail: tr('$_correct de ${Config.roundsPerGame} a la primera.',
                    '$_correct of ${Config.roundsPerGame} right on the first try.') +
                (bonus > 0
                    ? tr('\n¡Reto de hoy completado! +$bonus estrellas extra.', "\nToday's challenge complete! +$bonus extra stars.")
                    : ''),
            english: _q.speechLang == Lang.target,
            earned: earned,
            previousBest: previousBest,
            starsWon: _correct + bonus,
            playAgain: () => GameScreen(title: widget.title, progressKey: widget.progressKey, makeQuestion: widget.makeQuestion),
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
                  backgroundColor: context.palette.track,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: _isReview
                    ? Text(tr('🔁 Repaso', '🔁 Review'),
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                    : null,
              ),
              if (q.speechLang == Lang.target && !q.pictureOptions) ...[
                Text(
                  q.count != null
                      ? tr('¿Cuántos hay? Dilo en inglés', 'How many? Say it in Spanish')
                      : tr('¿Cómo se dice en inglés?', 'How do you say it in Spanish?'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                if (q.count != null)
                  _CountingInEnglish(q.prompt.split(' '), counted: _counted)
                else
                  Text(q.prompt, key: const Key('prompt'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 110)),
              ] else if (q.speechLang == Lang.target) ...[
                Text(tr('Escucha y toca el dibujo correcto', 'Listen and touch the right picture'),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                BigButton(
                  label: '🔊 ${q.prompt}',
                  color: context.palette.accent,
                  textColor: context.palette.accentInk,
                  fontSize: 32,
                  onTap: _explaining ? null : () => Voice.say(q.speech, Lang.target),
                ),
              ] else ...[
                if (q.addition!.drawable)
                  _CountingPicture(q.addition!, counted: _counted)
                else if (_counted != null)
                  _CountingOn(q.addition!, upTo: _counted!),
                const SizedBox(height: 12),
                Text(
                  q.prompt,
                  key: const Key('prompt'),
                  textAlign: TextAlign.center,
                  // "¿Cuántas manzanas hay?" es más largo que "2 + 3 = ?".
                  style: TextStyle(fontSize: q.addition!.kind == AddKind.count ? 36 : 52, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 28),
              if (q.speechLang == Lang.target && !q.pictureOptions)
                // Palabras: una debajo de otra, cada una con su botón para escucharla.
                for (var i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(child: _option(i, fontSize: 32)),
                        const SizedBox(width: 10),
                        BigButton(
                          key: Key('listen-$i'),
                          label: '🔊',
                          fontSize: 28,
                          color: context.palette.accent,
                          padding: const EdgeInsets.all(18),
                          onTap: _explaining ? null : () => Voice.say(q.options[i], Lang.target),
                        ),
                      ],
                    ),
                  )
              else
                Row(
                  children: [
                    for (var i = 0; i < q.options.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _option(i, fontSize: q.pictureOptions ? 52 : 40),
                        ),
                      ),
                  ],
                ),
              if (_explaining) ...[
                const SizedBox(height: 20),
                Text(tr('👂 Escucha…', '👂 Listen…'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
              ],
            ],
          ),
          if (_flash != null)
            IgnorePointer(
              child: Center(child: _HappyOwl(key: ValueKey('$_round$_flash'), star: _flash == '⭐')),
            ),
        ],
      ),
    );
  }

  Widget _option(int i, {required double fontSize}) => AnimatedScale(
        scale: _highlightAnswer && i == _q.answerIndex && !_locked ? 1.12 : 1,
        duration: const Duration(milliseconds: 300),
        child: BigButton(
          key: Key('option-$i'),
          label: _q.options[i],
          fontSize: fontSize,
          color: _optionColor(i),
          textColor: _wrong.contains(i) || (_locked && i == _q.answerIndex)
              ? Colors.white
              : i == _q.answerIndex && _highlightAnswer
                  ? const Color(0xFF3B2A55)
                  : null,
          onTap: () => _tap(i),
        ),
      );

  Color? _optionColor(int i) {
    if (_wrong.contains(i)) return AppColors.orange;
    if (i == _q.answerIndex && _locked) return AppColors.green;
    if (i == _q.answerIndex && _highlightAnswer) return AppColors.yellow;
    return null;
  }
}

/// Al acertar, Owlito salta de alegría (con una estrella si fue a la primera).
class _HappyOwl extends StatelessWidget {
  const _HappyOwl({super.key, required this.star});
  final bool star;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      key: const Key('happy-owl'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (_, t, child) => Transform.translate(
        // Dos saltitos: sube y baja dos veces.
        offset: Offset(0, -40 * (sin(t * 2 * pi)).abs() * (1 - t * .4)),
        child: Transform.scale(scale: .6 + .4 * Curves.easeOutBack.transform(min(1, t * 2.5)), child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (star) Icon(Icons.star_rounded, size: 70, color: p.star, shadows: const [Shadow(blurRadius: 8, color: Color(0x55000000))]),
          Owl(size: 130, night: p.night, wearing: AppState.instance.wearing, feathers: AppState.instance.featherColors),
        ],
      ),
    );
  }
}

/// Dibujos de la suma. Al explicar, se numeran uno a uno mientras la voz cuenta.
class _CountingPicture extends StatelessWidget {
  const _CountingPicture(this.add, {this.counted});
  final Addition add;
  final int? counted;

  Widget _item(int n, Color accent, {bool removed = false}) {
    final done = !removed && counted != null && n <= counted!;
    final current = !removed && counted == n;
    final picture = Text(add.object, key: const Key('counted-object'), style: const TextStyle(fontSize: 34));
    return AnimatedScale(
      scale: current ? 1.3 : 1,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (removed)
            // En la resta, los que se van se ven tachados.
            Stack(
              key: const Key('removed-object'),
              alignment: Alignment.center,
              children: [
                Opacity(opacity: .35, child: picture),
                const Icon(Icons.close_rounded, size: 40, color: AppColors.red),
              ],
            )
          else
            picture,
          SizedBox(
            height: 26,
            child: done
                ? Text('$n', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent))
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    Widget group(int from, int count) => Flexible(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [for (var n = from; n < from + count; n++) _item(n, accent)],
          ),
        );
    if (add.kind == AddKind.count) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [group(1, add.a)]);
    }
    if (add.kind == AddKind.sub) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        children: [
          for (var n = 1; n <= add.a; n++) _item(n, accent, removed: n > add.result),
        ],
      );
    }
    // En "2 + ? = 5" el segundo grupo está escondido hasta que se cuenta en la explicación.
    final revealed = add.kind == AddKind.missing ? ((counted ?? 0) - add.a).clamp(0, add.b) : add.b;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        group(1, add.a),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('+', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: accent)),
        ),
        if (revealed == 0)
          Text('?', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: accent))
        else
          group(add.a + 1, revealed),
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
    final p = context.palette;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        if (add.kind == AddKind.sub)
          // Resta grande: contar hacia atrás desde el primer número (15 → 14 → 13…).
          for (var n = add.a; n >= upTo; n--)
            Chip(
              backgroundColor: n == add.a ? p.accent : (n == upTo ? AppColors.yellow : p.card),
              label: Text(
                n == add.a ? '$n' : '−1 → $n',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: n == add.a ? p.accentInk : (n == upTo ? const Color(0xFF3B2A55) : p.cardInk)),
              ),
            )
        else
          for (var n = add.a; n <= upTo; n++)
            Chip(
              backgroundColor: n == add.a ? p.accent : (n == upTo ? AppColors.yellow : p.card),
              label: Text(
                n == add.a ? '$n' : '+1 → $n',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: n == add.a ? p.accentInk : (n == upTo ? const Color(0xFF3B2A55) : p.cardInk)),
              ),
            ),
      ],
    );
  }
}

/// Dibujos para contar en el idioma que aprende. Al explicar, cada uno muestra su número en ese idioma.
class _CountingInEnglish extends StatelessWidget {
  const _CountingInEnglish(this.pictures, {this.counted});
  final List<String> pictures;
  final int? counted;

  @override
  Widget build(BuildContext context) => Wrap(
        key: const Key('prompt'),
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          for (var i = 0; i < pictures.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pictures[i], key: const Key('counted-object'), style: const TextStyle(fontSize: 46)),
                SizedBox(
                  height: 24,
                  child: counted != null && i < counted!
                      ? Text(targetNumbers[i], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.palette.accent))
                      : null,
                ),
              ],
            ),
        ],
      );
}
