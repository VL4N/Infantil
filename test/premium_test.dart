import 'package:aprende_jugando/logic/lang.dart';
import 'package:aprende_jugando/logic/shop.dart';
import 'package:aprende_jugando/screens/premium_screen.dart';
import 'package:aprende_jugando/screens/shop_screen.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:aprende_jugando/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show spoken, startApp;

void main() {
  final state = AppState.instance;
  tearDown(() {
    Lang.current = AppLang.es;
    Palette.debugNight = null;
  });

  test('los trajes Premium vienen con Premium, sin gastar estrellas', () async {
    SharedPreferences.setMockInitialValues({'stars': 5});
    await state.load();
    final astronaut = shopItem('astronauta')!;
    expect(astronaut.premium, isTrue);
    expect(state.hasItem(astronaut), isFalse);
    state.wear('astronauta');
    expect(state.wearing, isNull, reason: 'sin Premium no se lo puede poner');

    state.setPremium(true);
    state.wear('astronauta');
    state.wear('galaxia');
    expect(state.wearing, 'astronauta');
    expect(state.featherPattern, 'galaxia');
    expect(state.stars, 5, reason: 'no cuesta estrellas');

    // Si se pierde Premium (reembolso), Owlito se los quita.
    state.setPremium(false);
    expect(state.wearing, isNull);
    expect(state.feathers, isNull);
  });

  testWidgets('en la tienda, sin Premium el traje 👑 pide ayuda a papá o a mamá', (tester) async {
    await startApp(tester, prefs: {'stars': 3});
    await tester.pumpWidget(MaterialApp(theme: buildTheme(Palette.day), home: const ShopScreen()));
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('item-astronauta'));
    await tester.scrollUntilVisible(card, 200);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: card, matching: find.text('👑 Premium')));
    await tester.pumpAndSettle();
    expect(spoken, contains('Pide ayuda a papá o a mamá'));
    expect(find.byKey(const Key('gate-input')), findsOneWidget, reason: 'se abre la pregunta para adultos');
  });

  testWidgets('con Premium, el traje 👑 se pone sin comprar', (tester) async {
    await startApp(tester, premium: true);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(Palette.day), home: const ShopScreen()));
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('item-mago'));
    await tester.scrollUntilVisible(card, 200);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: card, matching: find.text('Ponérselo')));
    await tester.pumpAndSettle();
    expect(state.wearing, 'mago');
  });

  for (final lang in AppLang.values) {
    for (final night in [false, true]) {
      testWidgets('la comparación de Premium no se corta (${lang.name}, ${night ? 'noche' : 'día'})', (tester) async {
        Palette.debugNight = night;
        tester.view.physicalSize = const Size(320, 568) * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await startApp(tester, prefs: {'lang': lang.name});
        await tester.pumpWidget(MaterialApp(theme: buildTheme(night ? Palette.nightStyle : Palette.day), home: const PremiumScreen()));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('premium-comparison')), findsOneWidget);
        expect(find.text('👑 Premium'), findsOneWidget);
      });
    }
  }
}
