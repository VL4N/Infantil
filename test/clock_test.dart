import 'dart:math';

import 'package:aprende_jugando/logic/clock.dart';
import 'package:aprende_jugando/logic/lang.dart';
import 'package:aprende_jugando/logic/questions.dart';
import 'package:aprende_jugando/main.dart' show AprendeJugandoApp;
import 'package:aprende_jugando/screens/game_screen.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show spoken, startApp, waitFor;

void main() {
  tearDown(() => Lang.current = AppLang.es);

  test('cómo se dice la hora', () {
    expect(timeName((hour: 1, minute: 0)), 'la una en punto');
    expect(timeName((hour: 3, minute: 30)), 'las 3 y media');
    expect(timeName((hour: 12, minute: 45)), 'la una menos cuarto');
    expect(timeName((hour: 7, minute: 25)), 'las 7 y 25');
    expect(digital((hour: 7, minute: 5)), '7:05');
    Lang.current = AppLang.en;
    expect(timeName((hour: 3, minute: 15)), 'quarter past 3');
    expect(timeName((hour: 2, minute: 45)), 'quarter to 3');
    expect(timeName((hour: 9, minute: 5)), '9 oh five');
  });

  test('las preguntas de la hora tienen una sola respuesta correcta', () {
    final r = Random(3);
    for (final level in clockLevels) {
      for (var i = 0; i < 2000; i++) {
        final q = level.make(r);
        final c = q.clock!;
        expect(q.options.toSet(), hasLength(3), reason: '${level.key}: ${q.options}');
        expect(q.options[q.answerIndex], digital(c.time));
        expect(clockMinutes[level.key], contains(c.time.minute));
        for (final t in c.optionTimes) {
          expect(t.hour, inInclusiveRange(1, 12));
          expect(t.minute % 5, 0);
        }
      }
    }
  });

  testWidgets('al equivocarse con el reloj, Owlito explica las dos agujas', (tester) async {
    await startApp(tester, prefs: {'ageGroup': 'big'});
    Question make(Random _) {
      var q = clockQuestion(Random(2), [30]);
      for (var s = 3; q.clock!.pickClock; s++) {
        q = clockQuestion(Random(s), [30]);
      }
      return q;
    }

    final q = make(Random());
    await tester.pumpWidget(MaterialApp(home: GameScreen(title: 'La hora', progressKey: 'reloj-media', makeQuestion: make)));
    await tester.pumpAndSettle();
    expect(spoken, [whatTimeIsIt]);
    expect(find.byType(ClockFace), findsOneWidget);
    await tester.tap(find.byKey(Key('option-${(q.answerIndex + 1) % 3}')));
    await waitFor(tester, seconds: 10);
    // Los grandes escuchan la explicación completa (las agujas son lo que hay que aprender).
    expect(spoken, containsAllInOrder([shortHand(q.clock!.time), longHand(30), itIsTouch(q.clock!.time)]));
  });

  testWidgets('"¿Qué reloj marca…?" muestra tres relojes para tocar', (tester) async {
    await startApp(tester, prefs: {'ageGroup': 'big'});
    var seed = 0;
    while (!clockQuestion(Random(seed), [0, 30]).clock!.pickClock) {
      seed++;
    }
    final q = clockQuestion(Random(seed), [0, 30]);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'La hora', progressKey: 'reloj-media', makeQuestion: (_) => clockQuestion(Random(seed), [0, 30])),
    ));
    await tester.pumpAndSettle();
    expect(spoken, [whichClockShows(q.clock!.time)]);
    expect(find.text(digital(q.clock!.time)), findsOneWidget);
    expect(find.byType(ClockFace), findsNWidgets(3));
    await tester.tap(find.byKey(Key('option-${q.answerIndex}')));
    await waitFor(tester, seconds: 3);
    expect(spoken, contains(greatTime(q.clock!.time)));
  });

  testWidgets('la sección La hora solo está para los grandes', (tester) async {
    await startApp(tester, prefs: {'ageGroup': 'small'});
    await tester.pumpAndSettle();
    expect(find.text('La hora'), findsNothing);
    AppState.instance.setAgeGroup(AgeGroup.big);
    await tester.pumpWidget(const AprendeJugandoApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('La hora'), 200);
    await tester.tap(find.text('La hora'));
    await tester.pumpAndSettle();
    expect(find.text('🕒 En punto'), findsOneWidget);
    expect(AppState.instance.canPlayClock('reloj-media'), isTrue);
    expect(AppState.instance.canPlayClock('reloj-5'), isFalse, reason: 'las demás son Premium');
  });

  test('a los pequeños no se les muestran los juegos de leer oraciones', () {
    AppState.instance.setAgeGroup(AgeGroup.small);
    expect(AppState.instance.hidden('letras-frase'), isTrue);
    AppState.instance.setAgeGroup(AgeGroup.big);
    expect(AppState.instance.hidden('letras-frase'), isFalse);
    expect(AppState.instance.canPlayLetters('letras-frase'), isTrue, reason: 'gratis para los grandes');
  });
}
