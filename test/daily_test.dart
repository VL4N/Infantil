import 'package:aprende_jugando/logic/content.dart';
import 'package:aprende_jugando/logic/daily.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:aprende_jugando/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show startApp;

void main() {
  final state = AppState.instance;
  var day = DateTime(2026, 10, 20, 10);
  setUp(() async {
    day = DateTime(2026, 10, 20, 10);
    state.now = () => day;
    SharedPreferences.setMockInitialValues({});
    await state.load();
  });
  tearDown(() => state.now = DateTime.now);

  test('las estrellas de cada nivel empiezan de nuevo cada día; el mejor resultado queda', () async {
    state.recordGame('suma-5', 3);
    expect(state.todayFor('suma-5'), 3);
    day = DateTime(2026, 10, 21, 8);
    expect(state.todayFor('suma-5'), 0);
    expect(state.bestFor('suma-5'), 3);
    state.recordGame('suma-5', 1);
    expect(state.todayFor('suma-5'), 1);
    await state.load(); // se guarda en el teléfono
    expect(state.todayFor('suma-5'), 1);
  });

  test('el reto de hoy da estrellas extra una sola vez al día y lleva la racha', () async {
    final before = state.stars;
    expect(state.completeChallenge(), AppState.challengeBonus);
    expect(state.completeChallenge(), 0);
    expect(state.stars, before + AppState.challengeBonus);
    expect(state.challengeStreak, 1);

    day = DateTime(2026, 10, 21, 10);
    expect(state.challengeStreak, 1); // todavía se puede seguir hoy
    expect(state.completeChallenge(), AppState.challengeBonus);
    expect(state.challengeStreak, 2);
    await state.load();
    expect(state.challengeStreak, 2);

    day = DateTime(2026, 10, 23, 10); // un día sin reto: se pierde la racha
    expect(state.challengeStreak, 0);
    state.completeChallenge();
    expect(state.challengeStreak, 1);
  });

  test('Owlito se pone triste si ayer no se hizo el reto, y feliz al hacerlo', () {
    expect(state.owlMood, OwlMood.normal); // primera vez: nada que reclamar
    state.recordGame('suma-5', 2);
    expect(state.owlMood, OwlMood.normal);

    day = DateTime(2026, 10, 21, 10); // ayer jugó pero no hizo el reto
    expect(state.owlMood, OwlMood.sad);
    state.completeChallenge();
    expect(state.owlMood, OwlMood.happy);

    day = DateTime(2026, 10, 22, 10); // ayer sí lo hizo: espera el de hoy
    expect(state.owlMood, OwlMood.normal);
    day = DateTime(2026, 10, 23, 10);
    expect(state.owlMood, OwlMood.sad);
  });

  test('las preguntas del reto son las mismas todo el día y cambian al día siguiente', () {
    final make = challengeQuestions(topics);
    List<String> round(DateTime d, int profile) {
      final r = challengeRandom(d, profile);
      return [for (var i = 0; i < 10; i++) make(r).speech];
    }

    final today = round(DateTime(2026, 10, 20, 8), 0);
    expect(round(DateTime(2026, 10, 20, 20), 0), today);
    expect(round(DateTime(2026, 10, 21, 8), 0), isNot(today));
    expect(round(DateTime(2026, 10, 20, 8), 1), isNot(today));
  });

  testWidgets('el menú muestra el reto y a Owlito triste si ayer no se hizo', (tester) async {
    state.now = () => DateTime(2026, 10, 21, 10);
    await startApp(tester, prefs: {
      'days': ['2026-10-20'],
      'challengeDay': '2026-10-19',
    });
    expect(find.byKey(const Key('challenge')), findsOneWidget);
    expect(find.textContaining('Owlito está triste'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Owl && w.mood == OwlMood.sad), findsWidgets);

    state.completeChallenge();
    await tester.pump();
    expect(find.textContaining('Owlito está feliz'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Owl && w.mood == OwlMood.happy), findsWidgets);
  });
}
