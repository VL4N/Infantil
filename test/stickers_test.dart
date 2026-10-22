import 'dart:math';

import 'package:aprende_jugando/logic/shop.dart';
import 'package:aprende_jugando/logic/stickers.dart';
import 'package:aprende_jugando/screens/album_screen.dart';
import 'package:aprende_jugando/screens/medals_screen.dart';
import 'package:aprende_jugando/screens/parents_screen.dart';
import 'package:aprende_jugando/screens/shop_screen.dart';
import 'package:aprende_jugando/services/app_state.dart';
import 'package:aprende_jugando/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show spoken, startApp;

void main() {
  final state = AppState.instance;

  test('los stickers llenan primero la página más avanzada y no se repiten', () async {
    SharedPreferences.setMockInitialValues({'stickers': ['frutas:🍎']});
    await state.load();
    final r = Random(1);
    final first = state.awardSticker(r)!;
    expect(first.page.key, 'frutas', reason: 'la página que ya tiene un sticker');
    for (var i = 0; i < 5; i++) {
      expect(state.awardSticker(r)!.completed, isFalse);
    }
    final stars = state.stars;
    final last = state.awardSticker(r)!;
    expect(last.page.key, 'frutas');
    expect(last.completed, isTrue);
    expect(state.stars, stars + pageBonus, reason: 'completar una página da estrellas extra');
    expect(state.stickers.where((s) => s.startsWith('frutas:')), hasLength(8));

    // Se guardan.
    await state.load();
    expect(state.stickers, hasLength(8));
  });

  test('sin Premium, las páginas 👑 no se llenan', () async {
    SharedPreferences.setMockInitialValues({});
    await state.load();
    final free = stickerPages.where((p) => !p.premium).fold(0, (n, p) => n + p.stickers.length);
    for (var i = 0; i < free; i++) {
      expect(state.awardSticker()!.page.premium, isFalse);
    }
    expect(state.awardSticker(), isNull, reason: 'ya tiene todos los gratis');

    state.setPremium(true);
    expect(state.awardSticker()!.page.premium, isTrue);
  });

  test('resumen de la semana: días, partidas y aciertos de los últimos 7 días', () async {
    SharedPreferences.setMockInitialValues({});
    await state.load();
    var today = DateTime(2026, 10, 1, 10);
    state.now = () => today;
    addTearDown(() => state.now = DateTime.now);

    state.addStar();
    state.addStar();
    state.recordGame('suma-5', 2);
    today = today.add(const Duration(days: 2));
    state.addStar();
    state.recordGame('suma-5', 1);
    expect((state.weekDays, state.weekGames, state.weekAnswers), (2, 2, 3));

    // Se guarda, y lo de hace más de una semana ya no cuenta.
    await state.load();
    expect(state.weekGames, 2);
    today = today.add(const Duration(days: 6));
    expect((state.weekDays, state.weekGames, state.weekAnswers), (1, 1, 1));
    today = today.add(const Duration(days: 1));
    expect(state.weekDays, 0);
  });

  test('avisa a los papás cuando ya jugó todo lo gratis', () async {
    SharedPreferences.setMockInitialValues({});
    await state.load();
    expect(state.finishedFreeContent, isFalse);
    for (final key in [
      'suma-5', 'suma-10', 'resta-5', 'resta-10', 'ingles-animales', 'ingles-frutas', 'ingles-colores',
      'sigue-10', 'mayor-10',
    ]) {
      state.recordGame(key, 1);
    }
    // Las claves gratis salen de la configuración: si cambia, este test lo avisa.
    expect(state.finishedFreeContent, isTrue);
    state.setPremium(true);
    expect(state.finishedFreeContent, isFalse, reason: 'con Premium no hay nada que contar');
  });

  testWidgets('el álbum muestra los stickers y las páginas 👑 piden ayuda', (tester) async {
    await startApp(tester, prefs: {'stickers': ['granja:🐶', 'granja:🐱']});
    await tester.pumpWidget(MaterialApp(theme: buildTheme(Palette.day), home: const AlbumScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Tienes 2 de $totalStickers stickers'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('album-granja')), matching: find.text('🐶')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('album-granja')), matching: find.text('2 / 8')), findsOneWidget);

    final button = find.byKey(const Key('album-premium-espacio'));
    await tester.scrollUntilVisible(button, 200);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(spoken, contains('Pide ayuda a papá o a mamá'));
    expect(find.byKey(const Key('gate-input')), findsOneWidget);
  });

  testWidgets('el resumen para papás empieza con la semana', (tester) async {
    await startApp(tester);
    state.addStar();
    state.recordGame('suma-5', 1);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(Palette.day), home: const ParentsScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('week-summary')), findsOneWidget);
    expect(find.textContaining('jugó 1 día, terminó 1 partida y respondió bien a la primera 1 pregunta'), findsOneWidget);
  });

  testWidgets('en el menú, el aviso de Premium sale solo al terminar lo gratis', (tester) async {
    await startApp(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('free-done')), findsNothing);
    for (final key in ['suma-5', 'suma-10', 'resta-5', 'resta-10', 'ingles-animales', 'ingles-frutas', 'sigue-10', 'mayor-10']) {
      state.recordGame(key, 1);
    }
    await tester.pumpAndSettle();
    final nudge = find.byKey(const Key('free-done'));
    await tester.scrollUntilVisible(nudge, 200);
    await tester.pumpAndSettle();
    await tester.tap(nudge);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gate-input')), findsOneWidget, reason: 'Premium sigue detrás de la pregunta para adultos');
  });

  test('medalla del día: al terminar las partidas del día, una vez, con estrellas extra', () async {
    SharedPreferences.setMockInitialValues({});
    await state.load();
    var today = DateTime(2026, 10, 5, 10);
    state.now = () => today;
    addTearDown(() => state.now = DateTime.now);
    for (var i = 0; i < AppState.dailyGoal - 1; i++) {
      state.recordGame('suma-5', 1);
    }
    expect((state.medals, state.takeNewMedal(), state.medalToday), (0, false, false));
    state.recordGame('suma-5', 1);
    expect((state.medals, state.stars, state.medalToday), (1, AppState.medalBonus, true));
    expect(state.takeNewMedal(), isTrue);
    expect(state.takeNewMedal(), isFalse, reason: 'se muestra una sola vez');
    state.recordGame('suma-5', 1);
    expect(state.medals, 1, reason: 'una medalla por día');

    // Al día siguiente se puede ganar otra; se guardan y se cuentan en la semana.
    today = today.add(const Duration(days: 1));
    for (var i = 0; i < AppState.dailyGoal; i++) {
      state.recordGame('suma-5', 1);
    }
    await state.load();
    expect((state.medals, state.weekMedals), (2, 2));
  });

  testWidgets('la tienda separa la ropa del plumaje, de la más barata a la más cara', (tester) async {
    await startApp(tester);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(Palette.day), home: const ShopScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Ropa y accesorios'), findsOneWidget);
    expect(find.byKey(const Key('item-gorro')), findsOneWidget, reason: 'primero la ropa, empezando por lo más barato');
    await tester.scrollUntilVisible(find.byKey(const Key('item-azul')), 300);
    final plumaje = tester.getTopLeft(find.byKey(const Key('shop-section-plumaje'))).dy;
    expect(tester.getTopLeft(find.byKey(const Key('item-azul'))).dy, greaterThan(plumaje));
    final free = shopItems.where((i) => !i.premium);
    expect(free.where((i) => i.isFeathers).length, greaterThanOrEqualTo(10));
    expect(free.where((i) => !i.isFeathers).length, greaterThanOrEqualTo(10));
  });

  test('camino de medallas: los premios se reclaman con medallas, no se compran', () async {
    SharedPreferences.setMockInitialValues({'stars': 500, 'medals': 6});
    await state.load();
    final glasses = shopItem('lentes_estrella')!, fire = shopItem('fuego')!;
    expect(state.buy(glasses.id, 0), isFalse, reason: 'no se compra con estrellas');
    expect(state.rewardsToClaim, 1);
    expect(state.canClaim(fire), isFalse, reason: 'faltan medallas');
    expect(state.claim(glasses), isTrue);
    expect(state.wearing, 'lentes_estrella', reason: 'Owlito se lo pone');
    expect(state.claim(glasses), isFalse, reason: 'una sola vez');
    expect((state.rewardsToClaim, state.stars), (0, 500));
    await state.load();
    expect(state.owned, contains('lentes_estrella'));
  });

  testWidgets('pantalla del camino de medallas: barra hacia el próximo premio y botón para reclamar', (tester) async {
    await startApp(tester, prefs: {'medals': 8});
    await tester.pumpWidget(MaterialApp(theme: buildTheme(Palette.day), home: const MedalsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Tienes 8 medallas'), findsOneWidget);
    expect(find.text('8 de 12 medallas'), findsOneWidget);
    await tester.tap(find.byKey(const Key('medal-button-lentes_estrella')));
    await tester.pumpAndSettle();
    expect(AppState.instance.wearing, 'lentes_estrella');
    expect(find.descendant(of: find.byKey(const Key('medal-step-lentes_estrella')), matching: find.text('Puesto')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('medal-step-campeon')), 300);
    expect(find.descendant(of: find.byKey(const Key('medal-step-campeon')), matching: find.text('Te faltan 17 medallas')),
        findsOneWidget);
  });
}
