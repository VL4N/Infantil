import 'package:aprende_jugando/config.dart';
import 'package:aprende_jugando/logic/content.dart';
import 'package:aprende_jugando/logic/memory.dart';
import 'package:aprende_jugando/logic/questions.dart';
import 'package:aprende_jugando/main.dart';
import 'package:aprende_jugando/screens/game_screen.dart';
import 'package:aprende_jugando/screens/memory_screen.dart';
import 'dart:math';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:aprende_jugando/screens/parents_screen.dart';
import 'package:aprende_jugando/services/reminder.dart';
import 'package:aprende_jugando/services/sfx.dart';
import 'package:aprende_jugando/services/voice.dart';
import 'package:aprende_jugando/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voz simulada: responde al instante, como si ya hubiera terminado de hablar.
final spoken = <String>[];

Future<void> startApp(WidgetTester tester, {bool premium = false, Map<String, Object> prefs = const {}}) async {
  spoken.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
    if (call.method == 'speak') spoken.add('${call.arguments is Map ? call.arguments['text'] : call.arguments}');
    return 1;
  });
  Voice.useClips = false;
  Sfx.enabled = false;
  LivelyOwl.animate = false;
  await Voice.init();
  SharedPreferences.setMockInitialValues({'premium': premium, ...prefs});
  await AppState.instance.load();
  await tester.pumpWidget(const AprendeJugandoApp());
}

Future<void> answerGate(WidgetTester tester, {required bool correctly}) async {
  final q = tester.widget<Text>(find.textContaining('¿Cuánto es')).data!;
  final n = RegExp(r'\d+').allMatches(q).map((m) => int.parse(m[0]!)).toList();
  await tester.enterText(find.byKey(const Key('gate-input')), '${correctly ? n[0] * n[1] : 1}');
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

Future<void> waitFor(WidgetTester tester, {int seconds = 3}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Respuesta correcta de la pregunta de suma en pantalla, para cualquier formato.
int mathAnswer(WidgetTester tester) {
  final prompt = tester.widget<Text>(find.byKey(const Key('prompt'))).data!;
  final n = RegExp(r'\d+').allMatches(prompt).map((m) => int.parse(m[0]!)).toList();
  if (prompt.contains('+ ?')) return n[1] - n[0];
  if (prompt.contains('−')) return n[0] - n[1];
  if (n.length == 2) return n[0] + n[1];
  // "¿Cuántas manzanas hay?": se cuentan los dibujos.
  return find.byKey(const Key('counted-object')).evaluate().length;
}

void main() {
  testWidgets('el nivel de pago pide la pregunta para adultos', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Sumar'));
    await tester.pumpAndSettle();
    expect(find.text('🦅 Hasta 20 🔒'), findsOneWidget);
    expect(find.text('🐣 Hasta 5'), findsOneWidget);

    await tester.tap(find.text('🦅 Hasta 20 🔒'));
    await tester.pumpAndSettle();
    await answerGate(tester, correctly: false);
    expect(find.text('Aprende Jugando Premium'), findsNothing);
    expect(find.textContaining('Respuesta incorrecta'), findsOneWidget);

    await answerGate(tester, correctly: true);
    expect(find.text('Aprende Jugando Premium'), findsOneWidget);
    expect(find.text('Desbloquear por ${Config.fallbackPrice}'), findsOneWidget);
  });

  testWidgets('con Premium no hay candados', (tester) async {
    await startApp(tester, premium: true);
    await tester.scrollUntilVisible(find.text('Inglés'), 100);
    await tester.ensureVisible(find.text('Inglés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inglés'));
    await tester.pumpAndSettle();
    expect(find.textContaining('🔒'), findsNothing);
  });

  testWidgets('una partida completa de sumas termina con estrellas', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Sumar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🐣 Hasta 5'));
    await tester.pumpAndSettle();

    for (var i = 0; i < Config.roundsPerGame; i++) {
      await tester.tap(find.widgetWithText(InkWell, '${mathAnswer(tester)}'));
      if (i == 0) {
        // Al acertar, Owlito salta de alegría.
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(const Key('happy-owl')), findsOneWidget);
      }
      await waitFor(tester);
    }
    expect(find.textContaining('10 de 10 a la primera'), findsOneWidget);
    expect(find.text('★★★'), findsOneWidget);
    expect(AppState.instance.stars, 10);
    expect(find.textContaining('+10 estrellas para la tienda. Ahora tienes 10.'), findsOneWidget);

    // El mejor resultado queda guardado y se ve en el botón del nivel.
    await tester.ensureVisible(find.text('🏠 Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🏠 Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sumar'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.widgetWithText(BigButton, '🐣 Hasta 5'), matching: find.text('★★★')), findsOneWidget);
    expect(find.descendant(of: find.widgetWithText(BigButton, '🐥 Hasta 10'), matching: find.text('☆☆☆')), findsOneWidget);
    await AppState.instance.load();
    expect(AppState.instance.bestFor('suma-5'), 3);
  });

  testWidgets('en "2 + ? = 5" el segundo grupo aparece al contar', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Sumar', progressKey: 'suma-10', makeQuestion: (r) => missingQuestion(r, 10)),
    ));
    await tester.pumpAndSettle();
    final answer = mathAnswer(tester);
    final prompt = tester.widget<Text>(find.byKey(const Key('prompt'))).data!;
    final a = int.parse(prompt.split(' ').first);
    expect(find.text('?'), findsOneWidget, reason: 'lo que falta está escondido');
    if (a + answer <= 10) expect(find.byKey(const Key('counted-object')), findsNWidgets(a));

    final wrong = find.descendant(
      of: find.byWidgetPredicate((w) => w is BigButton && w.label != '$answer' && w.key.toString().contains('option')),
      matching: find.byType(InkWell),
    ).first;
    await tester.tap(wrong);
    await waitFor(tester, seconds: 20);
    expect(spoken.last, contains('¡Toca el $answer!'));
    if (a + answer <= 10) expect(find.byKey(const Key('counted-object')), findsNWidgets(a + answer));
  });

  testWidgets('restas: los que se van se ven tachados y al equivocarse cuenta lo que queda', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Restar', progressKey: 'resta-10', makeQuestion: (r) => subtractionQuestion(r, 10)),
    ));
    await tester.pumpAndSettle();
    final prompt = tester.widget<Text>(find.byKey(const Key('prompt'))).data!;
    final n = RegExp(r'\d+').allMatches(prompt).map((m) => int.parse(m[0]!)).toList();
    final (a, b) = (n[0], n[1]);
    expect(spoken.last, '$a menos $b');
    expect(find.byKey(const Key('counted-object')), findsNWidgets(a));
    expect(find.byKey(const Key('removed-object')), findsNWidgets(b));

    final answer = mathAnswer(tester);
    expect(answer, a - b);
    final wrong = find.descendant(
      of: find.byWidgetPredicate((w) => w is BigButton && w.label != '$answer' && w.key.toString().contains('option')),
      matching: find.byType(InkWell),
    ).first;
    await tester.tap(wrong);
    await waitFor(tester, seconds: 20);
    expect(spoken, containsAllInOrder(['Tenemos $a.', 'Quitamos $b.', 'Contemos los que quedan.', '$a menos $b son $answer.', '¡Toca el $answer!']));
  });

  testWidgets('inglés: mira el dibujo, escucha las palabras y elige', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Inglés', progressKey: 'ingles-animales', makeQuestion: (r) => englishWordQuestion(r, topics.first)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo se dice en inglés?'), findsOneWidget);
    expect(spoken, ['¿Cómo se dice en inglés?'], reason: 'la instrucción en español; solo lo que se adivina va en inglés');

    final picture = tester.widget<Text>(find.byKey(const Key('prompt'))).data!;
    final answer = topics.first.words.firstWhere((w) => w.$2 == picture).$1;
    final options = [for (var i = 0; i < 3; i++) tester.widget<BigButton>(find.byKey(Key('option-$i'))).label];

    await tester.tap(find.byKey(const Key('listen-0')));
    await tester.pump();
    expect(spoken.last, options[0], reason: 'el 🔊 lee la palabra sin responder');
    expect(find.text('👂 Escucha…'), findsNothing);

    final wrong = options.indexWhere((o) => o != answer);
    await tester.tap(find.byKey(Key('option-$wrong')));
    await waitFor(tester, seconds: 10);
    expect(spoken, containsAllInOrder([options[wrong], 'Este dibujo en inglés se dice', answer]));

    await tester.tap(find.byKey(Key('option-${options.indexOf(answer)}')));
    await waitFor(tester);
    expect(spoken.sublist(spoken.lastIndexOf('¡Eso es!')).take(2), ['¡Eso es!', answer]);
  });

  testWidgets('parejas: se juega desde el menú y guarda las estrellas', (tester) async {
    await startApp(tester);
    await tester.scrollUntilVisible(find.text('Parejas'), 100);
    await tester.ensureVisible(find.text('Parejas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parejas'));
    await tester.pumpAndSettle();
    expect(find.text('🍎 Frutas'), findsOneWidget);
    expect(find.text('🎨 Colores 🔒'), findsOneWidget);
    for (final premium in ['👃 Cuerpo', '👕 Ropa', '👪 Familia', '👋 Saludos']) {
      await tester.scrollUntilVisible(find.text('$premium 🔒'), 100);
      expect(find.text('$premium 🔒'), findsOneWidget, reason: 'los temas nuevos son Premium');
    }

    // Pantalla de teléfono en vertical, como en la app real.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.7;
    addTearDown(tester.view.reset);

    // Misma semilla que la pantalla, para saber dónde está cada carta.
    await tester.pumpWidget(MaterialApp(
      home: MemoryScreen(topic: topics.first, progressKey: memoryKey(topics.first), random: Random(4)),
    ));
    await tester.pumpAndSettle();
    final cards = MemoryGame(Random(4), topics.first).cards;
    expect(find.text('❓'), findsNWidgets(8));

    // Un error: dos cartas que no son pareja se vuelven a tapar.
    final a = cards.indexWhere((c) => !c.showsPicture);
    final b = cards.indexWhere((c) => c.word != cards[a].word);
    await tester.tap(find.byKey(Key('card-$a')));
    await tester.pump();
    expect(spoken.last, cards[a].word, reason: 'la palabra se lee en voz alta');
    await tester.tap(find.byKey(Key('card-$b')));
    await tester.pump();
    expect(find.text('❓'), findsNWidgets(6));
    await waitFor(tester, seconds: 2);
    expect(find.text('❓'), findsNWidgets(8));

    // Luego todas las parejas.
    for (final word in {for (final c in cards) c.word}) {
      for (var i = 0; i < cards.length; i++) {
        if (cards[i].word == word) {
          await tester.tap(find.byKey(Key('card-$i')));
          await tester.pump();
        }
      }
      expect(spoken, containsAllInOrder(['¡Muy bien!', word]));
      await waitFor(tester, seconds: 1);
    }
    expect(find.textContaining('Encontraste las 4 parejas en 5 intentos'), findsOneWidget);
    expect(find.text('★★★'), findsOneWidget);
    expect(AppState.instance.bestFor('parejas-animales'), 3);
  });

  testWidgets('inglés: "How many?" cuenta los dibujos en inglés al equivocarse', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Inglés', progressKey: 'ingles-frutas', makeQuestion: (r) => englishCountQuestion(r, topics[1])),
    ));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuántos hay? Dilo en inglés'), findsOneWidget);
    expect(spoken, ['¿Cuántos hay? Dilo en inglés.']);

    final n = find.byKey(const Key('counted-object')).evaluate().length;
    final options = [for (var i = 0; i < 3; i++) tester.widget<BigButton>(find.byKey(Key('option-$i'))).label];
    final wrong = options.indexWhere((o) => o != englishNumbers[n - 1]);
    await tester.tap(find.byKey(Key('option-$wrong')));
    await waitFor(tester, seconds: 15);
    expect(spoken, containsAllInOrder(['Contemos juntos en inglés', ...englishNumbers.take(n)]));
    expect(find.text(englishNumbers[n - 1]), findsWidgets, reason: 'cada dibujo muestra su número en inglés');

    await tester.tap(find.byKey(Key('option-${options.indexOf(englishNumbers[n - 1])}')));
    await waitFor(tester);
    expect(spoken.sublist(spoken.lastIndexOf('¡Eso es!')).take(2), ['¡Eso es!', englishNumbers[n - 1]]);
  });

  testWidgets('resumen para papás: días, partidas y palabras difíciles, detrás de la pregunta', (tester) async {
    await startApp(tester);
    final state = AppState.instance;
    state.now = () => DateTime(2026, 10, 8, 9);
    state.recordGame('suma-5', 3);
    state.recordGame('suma-5', 1);
    state.now = () => DateTime(2026, 10, 9, 18);
    state.recordGame('ingles-animales', 2);
    state.recordMiss('cow');
    state.recordMiss('cow');
    state.recordMiss('duck');
    addTearDown(() => state.now = DateTime.now);

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Resumen, niños y recordatorio'), 100);
    await tester.ensureVisible(find.text('Resumen, niños y recordatorio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resumen, niños y recordatorio'));
    await tester.pumpAndSettle();
    await answerGate(tester, correctly: true);

    expect(find.text('📅 Días jugados: 2'), findsOneWidget);
    expect(find.text('🎮 Partidas terminadas: 3'), findsOneWidget);
    expect(find.text('Sumar 🐣 Hasta 5'), findsOneWidget);
    expect(find.text('2 partidas'), findsOneWidget);
    expect(find.text('Inglés 🐶 Animales'), findsOneWidget);
    expect(find.text('• cow: 2 errores'), findsOneWidget);
    expect(find.text('• duck: 1 error'), findsOneWidget);

    // Queda guardado en el teléfono.
    await state.load();
    expect(state.days, {'2026-10-08', '2026-10-09'});
    expect(state.played['suma-5'], 2);
    expect(state.hardestWords().first.key, 'cow');
  });

  testWidgets('equivocarse en inglés anota la palabra', (tester) async {
    await startApp(tester);
    final q = englishQuestion(Random(1), topics.first);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Inglés', progressKey: 'ingles-animales', makeQuestion: (_) => q),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('option-${(q.answerIndex + 1) % 3}')));
    await waitFor(tester, seconds: 8);
    expect(AppState.instance.misses, {q.speech: 1});
  });

  testWidgets('tienda: con las estrellas se compran cosas para Owlito', (tester) async {
    await startApp(tester, prefs: {'stars': 20});
    final state = AppState.instance;
    expect(state.starsEarned, 20, reason: 'las estrellas de antes de la tienda cuentan como ganadas');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tienda'), 100);
    await tester.ensureVisible(find.text('Tienda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tienda'));
    await tester.pumpAndSettle();
    expect(find.text('Tienes 20 estrellas para gastar'), findsOneWidget);

    // No le alcanza para la corona (80).
    await tester.scrollUntilVisible(find.byKey(const Key('item-corona')), 100);
    expect(find.descendant(of: find.byKey(const Key('item-corona')), matching: find.text('60')), findsOneWidget);
    expect(state.buy('corona', 80), isFalse);

    // Compra el gorro (15): se descuentan, Owlito se lo pone y las ganadas no bajan.
    await tester.scrollUntilVisible(find.byKey(const Key('item-gorro')), -100);
    await tester.tap(find.descendant(of: find.byKey(const Key('item-gorro')), matching: find.text('Comprar')));
    await tester.pumpAndSettle();
    expect(state.stars, 5);
    expect(state.starsEarned, 20);
    expect(state.wearing, 'gorro');
    expect(find.descendant(of: find.byKey(const Key('item-gorro')), matching: find.text('Puesto')), findsOneWidget);
    expect(state.buy('gorro', 15), isFalse, reason: 'no se compra dos veces');

    // Al ganar más, el contador sube en las dos cuentas; se guarda al reabrir.
    state.addStar();
    expect((state.stars, state.starsEarned), (6, 21));
    await state.load();
    expect((state.stars, state.starsEarned, state.wearing), (6, 21, 'gorro'));
    expect(state.owned, {'gorro'});
    // Plumas de colores: van aparte del accesorio.
    state.addStar();
    for (var i = 0; i < 20; i++) {
      state.addStar();
    }
    expect(state.buy('azul', 20), isTrue);
    expect((state.wearing, state.feathers), ('gorro', 'azul'));
    expect(state.featherColors, isNotNull);
    state.takeOffAll();
    expect((state.wearing, state.feathers), (null, null));
    state.wear('gorro');
    expect(state.wearing, 'gorro');
  });

  testWidgets('perfiles: cada niño tiene su progreso y lo de antes queda en el primero', (tester) async {
    // Progreso guardado antes de que hubiera perfiles.
    await startApp(tester, prefs: {'stars': 7, 'best:suma-5': 2, 'played:suma-5': 1});
    final state = AppState.instance;
    expect((state.profiles.length, state.profile.name, state.stars), (1, 'Jugador 1', 7));

    final ana = state.addProfile('Ana')!;
    state.switchProfile(ana);
    expect((state.profile.name, state.stars, state.bestFor('suma-5'), state.played.length), ('Ana', 0, 0, 0));
    state.addStar();
    state.recordGame('ingles-frutas', 1);
    state.recordMiss('apple');

    state.switchProfile(0);
    expect((state.stars, state.bestFor('suma-5'), state.bestFor('ingles-frutas'), state.misses.isEmpty), (7, 2, 0, true));

    // Se guarda al reabrir la app, con el niño que estaba jugando.
    state.switchProfile(ana);
    await state.load();
    expect((state.profile.name, state.stars, state.bestFor('ingles-frutas'), state.misses['apple']), ('Ana', 1, 1, 1));

    // Al borrar a Ana se borra su progreso y vuelve el primero.
    state.removeProfile(ana);
    expect((state.profiles.length, state.profile.id, state.stars), (1, 0, 7));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('p$ana:')), isEmpty);
    expect(prefs.getInt('best:suma-5'), 2);
  });

  testWidgets('con varios niños, al abrir se elige quién juega', (tester) async {
    await startApp(tester, prefs: {'profiles': ['0|Leo', '1|Ana'], 'p1:stars': 3});
    await tester.pumpAndSettle();
    expect(find.text('¿Quién va a jugar?'), findsOneWidget);
    expect(spoken, contains('¿Quién va a jugar?'));
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();
    expect(find.text('Juega: Ana'), findsOneWidget);
    expect(find.text('3'), findsOneWidget, reason: 'las estrellas de Ana');
  });

  testWidgets('recordatorio diario: los papás lo activan y eligen la hora', (tester) async {
    await startApp(tester);
    final calls = <int?>[];
    Reminder.debugSchedule = (hour) async {
      calls.add(hour);
      return true;
    };
    addTearDown(() => Reminder.debugSchedule = null);
    await tester.pumpWidget(const MaterialApp(home: ParentsScreen()));
    await tester.scrollUntilVisible(find.byKey(const Key('reminder-switch')), 200);
    await tester.tap(find.byKey(const Key('reminder-switch')));
    await tester.pumpAndSettle();
    expect(AppState.instance.reminderOn, isTrue);
    expect(calls, [17]);
    await tester.tap(find.byKey(const Key('reminder-switch')));
    await tester.pumpAndSettle();
    expect(AppState.instance.reminderOn, isFalse);
    expect(calls, [17, null]);
    await AppState.instance.load();
    expect(AppState.instance.reminderOn, isFalse);
  });

  test('las estrellas de una partida dependen de los aciertos a la primera', () {
    expect([for (final c in [0, 1, 4, 5, 7, 8, 10]) AppState.starsFor(c)], [0, 1, 1, 2, 2, 3, 3]);
  });

  testWidgets('solo se guarda el mejor resultado', (tester) async {
    await startApp(tester);
    expect(AppState.instance.recordGame('ingles-animales', 2), 2);
    expect(AppState.instance.recordGame('ingles-animales', 1), 1);
    expect(AppState.instance.bestFor('ingles-animales'), 2);
  });

  testWidgets('si se equivoca, le explica, le señala la respuesta y luego repasa', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Sumar', progressKey: 'suma-5', makeQuestion: (r) => additionQuestion(r, 5)),
    ));
    await tester.pumpAndSettle();

    (int, int) current() {
      final prompt = tester.widget<Text>(find.textContaining('= ?')).data!;
      final n = RegExp(r'\d+').allMatches(prompt).map((m) => int.parse(m[0]!)).toList();
      return (n[0], n[1]);
    }

    final (a, b) = current();
    final wrongButton = find.descendant(
      of: find.byWidgetPredicate((w) => w is BigButton && w.label != '${a + b}' && w.key.toString().contains('option')),
      matching: find.byType(InkWell),
    ).first;
    await tester.tap(wrongButton);
    await tester.pump();
    expect(find.text('👂 Escucha…'), findsOneWidget);

    // Mientras explica, no se puede responder.
    await tester.tap(find.widgetWithText(InkWell, '${a + b}'));
    await tester.pump();
    expect(find.text('👂 Escucha…'), findsOneWidget);

    await waitFor(tester, seconds: 15);
    expect(find.text('👂 Escucha…'), findsNothing);
    expect(spoken, containsAll(['uno', 'dos', '$a más $b son ${a + b}. ¡Toca el ${a + b}!']));
    final correct = tester.widget<BigButton>(find.widgetWithText(BigButton, '${a + b}'));
    expect(correct.color, AppColors.yellow, reason: 'la respuesta correcta queda señalada');

    var sawReview = false;
    for (var round = 0; round < Config.roundsPerGame; round++) {
      if (find.text('🔁 Repaso').evaluate().isNotEmpty) {
        sawReview = true;
        expect(current(), (a, b), reason: 'el repaso repite la pregunta fallada');
      }
      final (x, y) = current();
      await tester.tap(find.widgetWithText(InkWell, '${x + y}'));
      await waitFor(tester);
    }
    expect(sawReview, isTrue);
    expect(find.textContaining('9 de 10 a la primera'), findsOneWidget);
  });
}
