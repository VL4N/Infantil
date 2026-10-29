import 'dart:math';

import 'package:flutter/material.dart';

import '../config.dart';
import '../logic/clock.dart';
import '../logic/daily.dart';
import '../logic/lang.dart';
import '../logic/lines.dart';
import '../logic/numbers.dart';
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

  /// Ya se puede saltar la explicación (pasaron unos segundos).
  bool _canSkip = false;

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
      AppState.instance.countAnswer();
    }
    Sfx.acierto();
    setState(() {
      _locked = true;
      _round++;
      _flash = _firstTry ? '⭐' : '👍';
    });
    // La partida se guarda en cuanto termina, antes de la voz, para no perderla si la voz se atasca.
    final finished = _round >= Config.roundsPerGame;
    // Las estrellas se ganan al terminar la partida, no a la mitad.
    if (finished) AppState.instance.addStars(_correct);
    final previousBest = AppState.instance.bestFor(widget.progressKey);
    final earned = finished ? AppState.instance.recordGame(widget.progressKey, AppState.starsFor(_correct)) : 0;
    // Al terminar el reto de hoy, estrellas extra (solo la primera vez del día).
    final bonus = finished && widget.progressKey == challengeKey ? AppState.instance.completeChallenge() : 0;
    final sticker = finished ? AppState.instance.awardSticker() : null;
    final medal = finished && AppState.instance.takeNewMedal();
    if (_q.letters case final l?) {
      await Voice.say(l.praise, Lang.native);
    } else if (_q.clock case final c?) {
      await Voice.say(c.praise, Lang.native);
    } else if (_q.speechLang == Lang.target) {
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
            starsWon: _correct + bonus + (medal ? AppState.medalBonus : 0),
            sticker: sticker,
            medal: medal,
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
    setState(() {
      _explaining = true;
      _canSkip = false;
    });
    // El botón para saltar la explicación aparece después de un momento (para que la escuchen un poco).
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && token == _explainToken && _explaining) setState(() => _canSkip = true);
    });
    var steps = explainMistake(_q, chosen);
    // Para los grandes, la explicación corta: solo la respuesta, sin contar todo.
    // (En las tablas y la hora no: contar de 3 en 3 y mirar las agujas es justo lo que hay que aprender.)
    if (AppState.instance.isBig && _q.tables == null && _q.clock == null && steps.any((s) => s.highlightAnswer)) {
      steps = steps.skipWhile((s) => !s.highlightAnswer).toList();
    }
    for (final step in steps) {
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

  /// "Ya entendí": corta la explicación y deja marcada la respuesta para que la toque.
  void _skipExplanation() {
    _explainToken++;
    Voice.stop();
    setState(() {
      _explaining = false;
      _highlightAnswer = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        // Las estrellas de esta partida: se suman a las de la tienda al terminarla.
        actions: [StarCounter(key: const Key('game-stars'), stars: _correct, pending: true)],
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
              ] else if (q.tables case final t?) ...[
                const SizedBox(height: 24),
                Text(q.prompt, key: const Key('prompt'), textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold)),
                // Al equivocarse, la ayuda escrita: "3 + 3 + 3 + 3 = 12".
                if (_wrong.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(t.hint,
                      key: const Key('tables-hint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.palette.inkSoft)),
                ],
              ] else if (q.clock case final c?) ...[
                Text(c.pickClock ? tr('¿Qué reloj marca esta hora?', 'Which clock shows this time?') : q.prompt,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (c.pickClock)
                  Text(q.prompt, key: const Key('prompt'), textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800))
                else
                  Center(child: ClockFace(c.time, key: const Key('prompt'), size: 220, showHands: _wrong.isNotEmpty)),
                const SizedBox(height: 8),
                Center(
                  child: BigButton(
                    key: const Key('listen-again'),
                    label: '🔊',
                    fontSize: 28,
                    color: context.palette.accent,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
                    onTap: _explaining ? null : () => Voice.say(q.speech, Lang.native),
                  ),
                ),
              ] else if (q.letters case final l?) ...[
                Text(q.prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (l.picture != null)
                  Text(l.picture!, key: const Key('letters-picture'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 96)),
                if (l.display.isNotEmpty)
                  Text(l.display,
                      key: const Key('prompt'),
                      textAlign: TextAlign.center,
                      style: l.sentence
                          ? const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)
                          : TextStyle(fontSize: l.picture == null ? 110 : 52, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 8),
                // Para volver a escuchar la pregunta.
                Center(
                  child: BigButton(
                    key: const Key('listen-again'),
                    label: '🔊',
                    fontSize: 28,
                    color: context.palette.accent,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
                    onTap: _explaining ? null : () => Voice.say(q.speech, Lang.native),
                  ),
                ),
              ] else if (q.sequence != null) ...[
                Text(q.prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _SequenceRow(q.sequence!, counted: _counted, reveal: _highlightAnswer || _locked, showJumps: _wrong.isNotEmpty),
              ] else if (q.comparison != null) ...[
                Text(q.prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _ComparisonCards(q.comparison!, onTap: _tap),
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
              if (q.clock?.pickClock ?? false)
                // "¿Qué reloj marca las 3?": tres relojes para tocar, grandes (dos arriba y uno abajo).
                LayoutBuilder(
                  builder: (context, box) {
                    final width = min(170.0, (box.maxWidth - 14) / 2);
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        for (var i = 0; i < q.options.length; i++)
                          SizedBox(width: width, child: _clockOption(i, q.clock!.optionTimes[i], showHands: _wrong.isNotEmpty)),
                      ],
                    );
                  },
                )
              else if ((q.letters?.words ?? false) || q.clock != null)
                // Palabras u horas para leer: una debajo de otra.
                // (Sin botón para escucharlas: hay que leerlas.)
                for (var i = 0; i < q.options.length; i++)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: _option(i, fontSize: q.clock != null ? 38 : 34))
              else if (q.speechLang == Lang.target && !q.pictureOptions)
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
                          child: _option(i, fontSize: q.pictureOptions || q.letters != null ? 52 : 40),
                        ),
                      ),
                  ],
                ),
              if (_explaining) ...[
                const SizedBox(height: 20),
                Text(tr('👂 Escucha…', '👂 Listen…'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
                if (_canSkip) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      key: const Key('skip-explanation'),
                      onPressed: _skipExplanation,
                      child: Text(tr('⏭ Ya entendí', '⏭ Got it'),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.palette.ink)),
                    ),
                  ),
                ],
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
          // "¿Cuál es mayor?" con números: el número ya está en la tarjeta de arriba; el botón la señala.
          label: _q.comparison != null && _q.comparison!.object == null ? '👆' : _q.options[i],
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

  /// Un reloj para tocar (con el color de las opciones: naranja si se equivocó, verde al acertar…).
  Widget _clockOption(int i, ClockTime time, {required bool showHands}) {
    final p = context.palette;
    final color = _optionColor(i) ?? p.card;
    return AnimatedScale(
      scale: _highlightAnswer && i == _q.answerIndex && !_locked ? 1.08 : 1,
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: p.cardBorder == null || _optionColor(i) != null ? BorderSide.none : BorderSide(color: p.cardBorder!, width: 2),
        ),
        child: InkWell(
          key: Key('option-$i'),
          borderRadius: BorderRadius.circular(22),
          onTap: () => _tap(i),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, box) => ClockFace(time, size: box.maxWidth, showHands: showHands),
            ),
          ),
        ),
      ),
    );
  }

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
          Owl(size: 130, night: p.night, wearing: AppState.instance.wearing, feathers: AppState.instance.featherColors, pattern: AppState.instance.featherPattern),
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

/// "¿Qué número sigue?": los números en fila y un "?" al final. Al explicar se marca el que se cuenta.
class _SequenceRow extends StatelessWidget {
  const _SequenceRow(this.seq, {this.counted, required this.reveal, required this.showJumps});
  final Sequence seq;
  final int? counted;
  final bool reveal;

  /// El salto ("+1" o "+2") solo se ve después de equivocarse: antes, el niño tiene que descubrirlo.
  final bool showJumps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget box(int i, String text, {Color? color, Color? ink, bool marked = false}) => Container(
          key: ValueKey('sequence-$i'),
          width: 64,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color ?? p.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: marked ? p.accent : (p.cardBorder ?? Colors.transparent), width: marked ? 4 : 2),
          ),
          child: FittedBox(
            child: Text(text, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: ink ?? p.cardInk)),
          ),
        );
    // Entre número y número, el salto ("+1" o "+2"). Su lugar queda reservado para que nada se mueva al aparecer.
    const width = 64.0, gap = 16.0, hop = 30.0;
    Widget jump(int i) => Positioned(
          key: ValueKey('sequence-step-$i'),
          left: (i + 1) * (width + gap) - gap / 2 - 22,
          top: 0,
          width: 44,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(99)),
            child: Text('+${seq.step}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.accentInk)),
          ),
        );
    final boxes = [
      for (final (i, n) in seq.numbers.indexed) box(i, '$n', marked: counted == n),
      reveal
          ? box(3, '${seq.next}', color: AppColors.yellow, ink: const Color(0xFF3B2A55))
          : box(3, '?', color: p.accent, ink: p.accentInk),
    ];
    return FittedBox(
      key: const Key('prompt'),
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 4 * width + 3 * gap,
        height: 72 + hop,
        child: Stack(
          children: [
            for (final (i, b) in boxes.indexed) Positioned(left: i * (width + gap), top: hop, child: b),
            if (showJumps) for (var i = 0; i < 3; i++) jump(i),
          ],
        ),
      ),
    );
  }
}

/// "¿Cuál es mayor?": dos grupos de dibujos (o dos números), uno sobre cada botón. Tocar una tarjeta
/// es lo mismo que tocar su botón.
class _ComparisonCards extends StatelessWidget {
  const _ComparisonCards(this.cmp, {required this.onTap});
  final Comparison cmp;
  final void Function(int option) onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget side(int option, int n) => Expanded(
          child: GestureDetector(
            onTap: () => onTap(option),
            child: Container(
              key: const Key('compare-side'),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minHeight: 130),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(20),
                border: p.cardBorder == null ? null : Border.all(color: p.cardBorder!, width: 2),
              ),
              child: cmp.object == null
                  ? Text('$n', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: p.cardInk))
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 2,
                      runSpacing: 2,
                      children: [for (var i = 0; i < n; i++) Text(cmp.object!, style: const TextStyle(fontSize: 26))],
                    ),
            ),
          ),
        );
    return IntrinsicHeight(
      key: const Key('prompt'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [side(0, cmp.a), side(1, cmp.b)]),
    );
  }
}


/// Reloj de agujas: la corta (las horas) y la larga (los minutos), con los números del 1 al 12.
/// Con [showHands] se ve en qué número señala cada aguja (después de equivocarse).
class ClockFace extends StatelessWidget {
  const ClockFace(this.time, {super.key, required this.size, this.showHands = false});
  final ClockTime time;
  final double size;
  final bool showHands;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ClockPainter(
          time,
          face: p.night ? p.card : Colors.white,
          rim: p.accent,
          ink: p.night ? p.cardInk : const Color(0xFF3B2A55),
          hourHand: AppColors.orange,
          minuteHand: p.accent,
          font: p.font,
          showHands: showHands,
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.time,
      {required this.face, required this.rim, required this.ink, required this.hourHand, required this.minuteHand, required this.font, required this.showHands});
  final ClockTime time;
  final Color face, rim, ink, hourHand, minuteHand;
  final String? font;
  final bool showHands;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = face);
    canvas.drawCircle(c, r - r * .04, Paint()
      ..color = rim
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .08);
    Offset at(double turns, double length) =>
        c + Offset(sin(turns * 2 * pi), -cos(turns * 2 * pi)) * length;
    // Rayitas de los minutos (más gruesas en cada número).
    for (var i = 0; i < 60; i++) {
      final big = i % 5 == 0;
      canvas.drawLine(at(i / 60, r * (big ? .78 : .82)), at(i / 60, r * .86), Paint()
        ..color = ink.withValues(alpha: big ? .8 : .35)
        ..strokeWidth = r * (big ? .025 : .012));
    }
    for (var n = 1; n <= 12; n++) {
      final tp = TextPainter(
        text: TextSpan(text: '$n', style: TextStyle(color: ink, fontSize: r * .2, fontWeight: FontWeight.w800, fontFamily: font)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at(n / 12, r * .63) - Offset(tp.width / 2, tp.height / 2));
    }
    final hourTurns = (time.hour % 12 + time.minute / 60) / 12;
    final minuteTurns = time.minute / 60;
    // Al explicar: un círculo en el número que señala cada aguja.
    if (showHands) {
      canvas.drawCircle(at(minuteTurns, r * .63), r * .15, Paint()..color = minuteHand.withValues(alpha: .25));
      canvas.drawCircle(at(time.hour / 12, r * .63), r * .15, Paint()..color = hourHand.withValues(alpha: .25));
    }
    Paint hand(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, at(minuteTurns, r * .74), hand(minuteHand, r * .06));
    canvas.drawLine(c, at(hourTurns, r * .45), hand(hourHand, r * .09));
    canvas.drawCircle(c, r * .07, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.time != time || old.showHands != showHands || old.face != face || old.rim != rim || old.ink != ink;
}
