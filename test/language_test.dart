import 'package:aprende_jugando/logic/content.dart';
import 'package:aprende_jugando/logic/lang.dart';
import 'package:aprende_jugando/logic/questions.dart';
import 'package:aprende_jugando/main.dart' show AprendeJugandoApp;
import 'package:aprende_jugando/screens/game_screen.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:aprende_jugando/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show answerGate, spoken, startApp, waitFor;

void main() {
  tearDown(() => Lang.current = AppLang.es);

  testWidgets('la primera vez se elige el idioma; en inglés todo el menú está en inglés', (tester) async {
    await startApp(tester);
    // Sin idioma guardado (y sin haber jugado antes), se pregunta.
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    await tester.pumpWidget(const AprendeJugandoApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Choose your language'), findsOneWidget);

    await tester.tap(find.byKey(const Key('lang-en')));
    await tester.pumpAndSettle();
    expect(Lang.current, AppLang.en);
    // Después del idioma: el nombre y la edad del niño.
    expect(find.text("Hi! I'm Owlito. What's your name?"), findsOneWidget);
    await tester.tap(find.byKey(const Key('first-start')));
    await tester.pumpAndSettle();
    expect(find.text("Hi! I'm Owlito. What's your name?"), findsOneWidget, reason: 'sin edad no se puede seguir');
    await tester.enterText(find.byKey(const Key('first-name')), 'Emma');
    await tester.tap(find.byKey(const Key('first-age-big')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('first-start')));
    await tester.pumpAndSettle();
    expect(AppState.instance.isBig, isTrue);
    expect(AppState.instance.profile.name, 'Emma');
    expect(find.byKey(const Key('age-card')), findsNothing, reason: 'la edad ya se eligió');
    expect(find.text('What shall we play?'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Spanish'), 200);
    expect(find.text('Spanish'), findsOneWidget, reason: 'en inglés se aprende español');
    expect((await SharedPreferences.getInstance()).getString('lang'), 'en');

    // Al volver a abrir la app ya no pregunta.
    await AppState.instance.load();
    expect(AppState.instance.langChosen, isTrue);
  });

  testWidgets('quien ya jugaba antes de los idiomas sigue en español sin que se le pregunte', (tester) async {
    SharedPreferences.setMockInitialValues({'stars': 12});
    await AppState.instance.load();
    expect(AppState.instance.langChosen, isTrue);
    expect(Lang.current, AppLang.es);
  });

  testWidgets('en inglés las sumas se dicen y se explican en inglés', (tester) async {
    await startApp(tester, prefs: {'lang': 'en'});
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Add', progressKey: 'suma-5', makeQuestion: (r) => additionQuestion(r, 5)),
    ));
    await tester.pumpAndSettle();
    final add = RegExp(r'(\d+) \+ (\d+)').firstMatch(tester.widget<Text>(find.byKey(const Key('prompt'))).data!)!;
    final a = int.parse(add[1]!), b = int.parse(add[2]!);
    expect(spoken, ['$a plus $b']);

    final options = [for (var i = 0; i < 3; i++) tester.widget<BigButton>(find.byKey(Key('option-$i'))).label];
    await tester.tap(find.byKey(Key('option-${options.indexWhere((o) => o != '${a + b}')}')));
    await waitFor(tester, seconds: 20);
    expect(spoken, containsAllInOrder(["Let's count together!", 'one', '$a plus $b is ${a + b}. Touch the ${a + b}!']));
  });

  testWidgets('en inglés se aprende español: instrucciones en inglés y palabras en español', (tester) async {
    await startApp(tester, prefs: {'lang': 'en'});
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(title: 'Spanish', progressKey: 'ingles-animales', makeQuestion: (r) => englishWordQuestion(r, topics.first)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('How do you say it in Spanish?'), findsOneWidget);
    expect(spoken, ['How do you say it in Spanish?']);

    final picture = tester.widget<Text>(find.byKey(const Key('prompt'))).data!;
    final answer = topics.first.words.firstWhere((w) => w.picture == picture);
    final options = [for (var i = 0; i < 3; i++) tester.widget<BigButton>(find.byKey(Key('option-$i'))).label];
    expect(options, contains(answer.es), reason: 'las opciones son palabras en español');

    final wrong = options.indexWhere((o) => o != answer.es);
    await tester.tap(find.byKey(Key('option-$wrong')));
    await waitFor(tester, seconds: 10);
    expect(spoken, containsAllInOrder([options[wrong], 'In Spanish, this picture is', answer.es, 'Touch it!']));

    await tester.tap(find.byKey(Key('option-${options.indexOf(answer.es)}')));
    await waitFor(tester);
    expect(spoken.sublist(spoken.lastIndexOf("That's it!")).take(2), ["That's it!", answer.es]);
    expect(AppState.instance.hardestWords().map((e) => e.key), contains(answer.es));
  });

  testWidgets('los papás cambian el idioma y la app vuelve al menú en el idioma nuevo', (tester) async {
    await startApp(tester);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Resumen, niños, idioma y aviso'), 100);
    await tester.ensureVisible(find.text('Resumen, niños, idioma y aviso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resumen, niños, idioma y aviso'));
    await tester.pumpAndSettle();
    await answerGate(tester, correctly: true);

    await tester.scrollUntilVisible(find.byKey(const Key('lang-en')), 200);
    await tester.ensureVisible(find.byKey(const Key('lang-en')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lang-en')));
    await tester.pumpAndSettle();
    expect(find.text('What shall we play?'), findsOneWidget);
    expect(Lang.current, AppLang.en);
  });

  testWidgets('con Premium activo, el botón del menú muestra que ya está comprado', (tester) async {
    await startApp(tester, premium: true, prefs: {'lang': 'en'});
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Premium active'), 100);
    await tester.ensureVisible(find.text('Premium active'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Premium active'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('✅ You have Premium'), 200);
    expect(find.text('✅ You have Premium'), findsOneWidget);
  });
}
