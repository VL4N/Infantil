import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../logic/lang.dart';
import '../logic/content.dart';
import '../logic/shop.dart';
import '../logic/stickers.dart';
import '../theme.dart' show OwlMood;

/// Un niño que juega en este teléfono. El primero (id 0) guarda su progreso con las claves
/// de siempre, así no se pierde lo jugado antes de que hubiera perfiles.
class Profile {
  const Profile(this.id, this.name);
  final int id;
  final String name;
}

/// Edad del niño: cambia qué niveles se recomiendan y lo larga que es la explicación de un error.
enum AgeGroup {
  /// 3 a 5 años: explicaciones completas, contando.
  small,

  /// 6 a 10 años: explicaciones cortas.
  big;

  String get label => this == small ? tr('3 a 5 años', '3 to 5 years') : tr('6 a 10 años', '6 to 10 years');
}

/// Estrellas, progreso por nivel/tema, resumen para papás y estado Premium, guardados en el teléfono.
/// Todo es de cada niño (perfil), menos Premium y el recordatorio, que son del teléfono.
class AppState extends ChangeNotifier {
  AppState._();
  static final instance = AppState._();

  SharedPreferences? _prefs;

  /// Hasta cuántos niños pueden jugar en el mismo teléfono.
  static const maxProfiles = 4;

  final List<Profile> profiles = [];
  int _profileId = 0;

  Profile get profile => profiles.firstWhere((p) => p.id == _profileId, orElse: () => profiles.first);

  /// Clave guardada del niño que está jugando.
  String _k(String key) => _profileId == 0 ? key : 'p$_profileId:$key';

  static final _otherProfileKey = RegExp(r'^p\d+:');
  static bool _isGlobal(String key) =>
      const {'premium', 'profiles', 'profile', 'lang'}.contains(key) || key.startsWith('reminder');

  /// Estrellas que tiene para gastar en la tienda de Owlito.
  int stars = 0;

  /// Todas las estrellas que ganó desde que instaló la app (no bajan al comprar).
  int starsEarned = 0;

  /// Cosas de la tienda que ya compró, y la que lleva puesta Owlito (null: ninguna).
  final Set<String> owned = {};
  String? wearing;

  /// Color de plumas que compró y tiene puesto (null: el de siempre).
  String? feathers;

  /// Los colores de esas plumas, para dibujar a Owlito.
  (int, int, int)? get featherColors => shopItem(feathers)?.feathers;

  /// Dibujo especial de esas plumas ('arcoiris', 'galaxia'), o null.
  String? get featherPattern => shopItem(feathers)?.pattern;

  /// Si puede ponerse algo de la tienda: lo compró con estrellas, o es un traje Premium y tiene Premium.
  bool hasItem(ShopItem item) => item.premium ? premium : owned.contains(item.id);
  bool premium = false;

  /// Si ya eligieron el idioma de la app (se pregunta la primera vez que se abre).
  bool langChosen = false;

  /// Mejor resultado (0 a 3 estrellas) de cada nivel de suma o tema de inglés.
  final Map<String, int> best = {};

  /// Partidas terminadas de cada nivel o tema.
  final Map<String, int> played = {};

  /// Días en que terminó al menos una partida ('2026-10-08').
  final Set<String> days = {};

  /// Veces que se equivocó con cada palabra del idioma que aprende.
  final Map<String, int> misses = {};

  /// Reloj para los días jugados (se cambia en las pruebas).
  DateTime Function() now = DateTime.now;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    premium = _prefs!.getBool('premium') ?? false;
    final lang = _prefs!.getString('lang');
    // Quien ya jugaba antes de que hubiera idiomas usaba la app en español: no se le pregunta.
    langChosen = lang != null || _prefs!.containsKey('stars') || _prefs!.containsKey('days');
    Lang.current = switch (lang) {
      'en' => AppLang.en,
      'es' => AppLang.es,
      _ => langChosen ? AppLang.es : _deviceLang(),
    };
    reminderOn = _prefs!.getBool('reminderOn') ?? false;
    reminderHour = _prefs!.getInt('reminderHour') ?? 17;
    profiles
      ..clear()
      ..addAll([
        for (final p in _prefs!.getStringList('profiles') ?? ['0|${tr('Jugador', 'Player')} 1'])
          Profile(int.parse(p.substring(0, p.indexOf('|'))), p.substring(p.indexOf('|') + 1)),
      ]);
    _profileId = _prefs!.getInt('profile') ?? profiles.first.id;
    if (!profiles.any((p) => p.id == _profileId)) _profileId = profiles.first.id;
    _loadProfile();
  }

  /// Lee el progreso del niño que está jugando.
  void _loadProfile() {
    final prefs = _prefs!;
    stars = prefs.getInt(_k('stars')) ?? 0;
    // Antes de la tienda solo se guardaba 'stars': entonces todas eran ganadas.
    starsEarned = prefs.getInt(_k('starsEarned')) ?? stars;
    owned
      ..clear()
      ..addAll(prefs.getStringList(_k('owned')) ?? const []);
    wearing = prefs.getString(_k('wearing'));
    feathers = prefs.getString(_k('feathers'));
    _takeOffPremiumWithoutPremium();
    best.clear();
    played.clear();
    misses.clear();
    for (final key in prefs.getKeys()) {
      final String k;
      if (_profileId == 0) {
        // El primer niño no tiene prefijo: se saltan las claves de los demás ("p1:", "p2:"…).
        if (_otherProfileKey.hasMatch(key)) continue;
        k = key;
      } else {
        if (!key.startsWith('p$_profileId:')) continue;
        k = key.substring('p$_profileId:'.length);
      }
      if (k.startsWith('best:')) best[k.substring(5)] = prefs.getInt(key) ?? 0;
      if (k.startsWith('played:')) played[k.substring(7)] = prefs.getInt(key) ?? 0;
      if (k.startsWith('miss:')) misses[k.substring(5)] = prefs.getInt(key) ?? 0;
    }
    _todayBestDay = prefs.getString(_k('todayBestDay')) ?? '';
    _todayBest
      ..clear()
      ..addEntries([
        for (final e in prefs.getStringList(_k('todayBest')) ?? const <String>[])
          if (e.contains('=')) MapEntry(e.substring(0, e.lastIndexOf('=')), int.tryParse(e.substring(e.lastIndexOf('=') + 1)) ?? 0),
      ]);
    _challengeDay = prefs.getString(_k('challengeDay')) ?? '';
    ageGroup = AgeGroup.values.where((a) => a.name == prefs.getString(_k('ageGroup'))).firstOrNull;
    stickers
      ..clear()
      ..addAll(prefs.getStringList(_k('stickers')) ?? const []);
    _daily
      ..clear()
      ..addEntries([
        for (final e in prefs.getStringList(_k('daily')) ?? const <String>[])
          if (e.split(RegExp('[=,]')).length == 3)
            MapEntry(e.substring(0, e.indexOf('=')), (
              int.tryParse(e.split(RegExp('[=,]'))[1]) ?? 0,
              int.tryParse(e.split(RegExp('[=,]'))[2]) ?? 0,
            )),
      ]);
    _streak = prefs.getInt(_k('streak')) ?? 0;
    medals = prefs.getInt(_k('medals')) ?? 0;
    _newMedal = false;
    _gamesDay = prefs.getString(_k('gamesDay')) ?? '';
    _gamesOnDay = prefs.getInt(_k('gamesOnDay')) ?? 0;
    days
      ..clear()
      ..addAll(prefs.getStringList(_k('days')) ?? const []);
    notifyListeners();
  }

  void _saveProfiles() => _prefs?.setStringList('profiles', [for (final p in profiles) '${p.id}|${p.name}']);

  /// Cambia al niño que va a jugar.
  void switchProfile(int id) {
    if (!profiles.any((p) => p.id == id)) return;
    _profileId = id;
    _prefs?.setInt('profile', id);
    if (_prefs != null) {
      _loadProfile();
    } else {
      notifyListeners();
    }
  }

  /// Agrega un niño (hasta [maxProfiles]). Devuelve su id, o null si ya no caben.
  int? addProfile(String name, {AgeGroup? age}) {
    if (profiles.length >= maxProfiles) return null;
    final id = profiles.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    if (age != null) _prefs?.setString('p$id:ageGroup', age.name);
    profiles.add(Profile(id, name.trim().isEmpty ? '${tr('Jugador', 'Player')} ${profiles.length + 1}' : name.trim()));
    _saveProfiles();
    notifyListeners();
    return id;
  }

  void renameProfile(int id, String name) {
    final i = profiles.indexWhere((p) => p.id == id);
    if (i < 0 || name.trim().isEmpty) return;
    profiles[i] = Profile(id, name.trim());
    _saveProfiles();
    notifyListeners();
  }

  /// Edad del niño que juega (null: todavía no la eligieron; se usa la de los pequeños).
  AgeGroup? ageGroup;
  bool get isBig => ageGroup == AgeGroup.big;

  void setAgeGroup(AgeGroup age) {
    ageGroup = age;
    _prefs?.setString(_k('ageGroup'), age.name);
    notifyListeners();
  }

  /// Edad de otro niño (para la lista de la zona de papás).
  AgeGroup? ageOf(int id) {
    final saved = _prefs?.getString(id == 0 ? 'ageGroup' : 'p$id:ageGroup');
    return AgeGroup.values.where((a) => a.name == saved).firstOrNull;
  }

  void setAgeOf(int id, AgeGroup age) {
    if (id == _profileId) return setAgeGroup(age);
    _prefs?.setString(id == 0 ? 'ageGroup' : 'p$id:ageGroup', age.name);
    notifyListeners();
  }

  /// Niveles de los pequeños que no se muestran a los grandes (para que la app no les parezca "de bebé").
  bool hidden(String key) => isBig && _smallOnly.contains(key);
  static const _smallOnly = {'suma-5', 'resta-5', 'sigue-10', 'mayor-10', 'letras-cual'};

  /// Niveles que se recomiendan para la edad del niño (se marcan "Para tu edad").
  bool recommended(String key) => (isBig ? _forBig : _forSmall).contains(key);
  static const _forSmall = {'suma-5', 'suma-10', 'resta-5', 'resta-10', 'sigue-10', 'mayor-10', 'letras-cual', 'letras-empieza'};
  static const _forBig = {
    'suma-10', 'suma-20', 'resta-10', 'resta-20', 'sigue-20', 'dos-20', 'mayor-20', 'letras-minuscula', 'letras-leer',
  };

  /// Borra un niño y todo su progreso (siempre queda al menos uno).
  void removeProfile(int id) {
    if (profiles.length <= 1 || !profiles.any((p) => p.id == id)) return;
    profiles.removeWhere((p) => p.id == id);
    for (final key in _prefs?.getKeys().toList() ?? const <String>[]) {
      final mine = id == 0 ? !_isGlobal(key) && !_otherProfileKey.hasMatch(key) : key.startsWith('p$id:');
      if (mine) _prefs!.remove(key);
    }
    _saveProfiles();
    if (_profileId == id) {
      switchProfile(profiles.first.id);
    } else {
      notifyListeners();
    }
  }

  void addStar() {
    countAnswer();
    addStars(1);
  }

  /// Una respuesta correcta a la primera (o una pareja), para el resumen de la semana.
  void countAnswer() => _countToday(answers: 1);

  /// Las estrellas de una partida se suman al terminarla: si sale a la mitad, no se las lleva.
  void addStars(int n) {
    if (n <= 0) return;
    stars += n;
    starsEarned += n;
    _prefs?.setInt(_k('stars'), stars);
    _prefs?.setInt(_k('starsEarned'), starsEarned);
    notifyListeners();
  }

  /// Compra algo de la tienda (y Owlito se lo pone). Devuelve false si no le alcanzan las estrellas.
  bool buy(String id, int price) {
    final item = shopItem(id);
    // Lo Premium y los premios de medallas no se compran con estrellas.
    if (item != null && (item.premium || item.medals > 0)) return false;
    if (owned.contains(id) || stars < price) return false;
    stars -= price;
    owned.add(id);
    _prefs?.setInt(_k('stars'), stars);
    _prefs?.setStringList(_k('owned'), owned.toList());
    wear(id);
    return true;
  }

  /// Owlito se pone algo que ya compró: un accesorio o un color de plumas.
  void wear(String id) {
    final item = shopItem(id);
    if (item == null || !hasItem(item)) return;
    if (item.isFeathers) {
      feathers = id;
      _prefs?.setString(_k('feathers'), id);
    } else {
      wearing = id;
      _prefs?.setString(_k('wearing'), id);
    }
    notifyListeners();
  }

  /// Owlito vuelve a como era: sin accesorio y con sus plumas de siempre.
  void takeOffAll() {
    wearing = null;
    feathers = null;
    _prefs?.remove(_k('wearing'));
    _prefs?.remove(_k('feathers'));
    notifyListeners();
  }

  /// Estrellas de una partida según los aciertos a la primera (de [Config.roundsPerGame]).
  /// Partidas por día para ganar la medalla del día (en la pantalla de inicio).
  static const dailyGoal = 5;
  String _gamesDay = '';
  int _gamesOnDay = 0;

  /// Medallas del día ganadas (una por día, al terminar [dailyGoal] partidas); cada una da [medalBonus] estrellas.
  static const medalBonus = 5;
  int medals = 0;
  bool _newMedal = false;
  bool get medalToday => gamesToday >= dailyGoal;

  /// Si la última partida guardada ganó la medalla de hoy (para mostrarla una sola vez).
  bool takeNewMedal() {
    final won = _newMedal;
    _newMedal = false;
    return won;
  }

  /// Premio del camino de medallas que ya puede reclamar (tiene las medallas y todavía no lo tiene).
  bool canClaim(ShopItem item) => item.medals > 0 && medals >= item.medals && !owned.contains(item.id);
  int get rewardsToClaim => medalRewards.where(canClaim).length;

  /// Reclama un premio del camino de medallas y Owlito se lo pone.
  bool claim(ShopItem item) {
    if (!canClaim(item)) return false;
    owned.add(item.id);
    _prefs?.setStringList(_k('owned'), owned.toList());
    wear(item.id);
    notifyListeners();
    return true;
  }

  /// Partidas terminadas hoy.
  int get gamesToday => _gamesDay == _day(now()) ? _gamesOnDay : 0;

  static String _day(DateTime t) => '${t.year}-${'${t.month}'.padLeft(2, '0')}-${'${t.day}'.padLeft(2, '0')}';

  static int starsFor(int correct) => correct >= 8 ? 3 : correct >= 5 ? 2 : correct >= 1 ? 1 : 0;

  int bestFor(String key) => best[key] ?? 0;

  /// Estrellas de hoy en cada nivel o tema: cada día empiezan de nuevo en ☆☆☆, para que
  /// siempre haya algo que ganar. El mejor resultado de siempre queda en [bestFor].
  final Map<String, int> _todayBest = {};
  String _todayBestDay = '';
  int todayFor(String key) => _todayBestDay == _day(now()) ? (_todayBest[key] ?? 0) : 0;

  /// Reto de hoy: preguntas nuevas cada día y estrellas extra la primera vez que se completa.
  static const challengeBonus = 10;
  String _challengeDay = '';
  bool get challengeDoneToday => _challengeDay == _day(now());
  int _streak = 0;

  String get _yesterday => _day(now().subtract(const Duration(days: 1)));

  /// Días seguidos con el reto hecho (se pierde si un día no se hace).
  int get challengeStreak => challengeDoneToday || _challengeDay == _yesterday ? _streak : 0;

  /// Cómo se ve Owlito: feliz con el reto de hoy hecho, triste si ayer no se hizo
  /// (y el niño ya había jugado antes), normal mientras espera el reto de hoy.
  OwlMood get owlMood {
    if (challengeDoneToday) return OwlMood.happy;
    if (_challengeDay == _yesterday) return OwlMood.normal;
    final today = _day(now());
    return days.any((d) => d != today) ? OwlMood.sad : OwlMood.normal;
  }

  /// Marca el reto de hoy como hecho y da las estrellas extra (solo la primera vez del día).
  int completeChallenge() {
    if (challengeDoneToday) return 0;
    _streak = _challengeDay == _yesterday ? _streak + 1 : 1;
    _challengeDay = _day(now());
    _prefs?.setString(_k('challengeDay'), _challengeDay);
    _prefs?.setInt(_k('streak'), _streak);
    stars += challengeBonus;
    starsEarned += challengeBonus;
    _prefs?.setInt(_k('stars'), stars);
    _prefs?.setInt(_k('starsEarned'), starsEarned);
    notifyListeners();
    return challengeBonus;
  }

  /// Guarda una partida terminada: cuenta la partida y el día, y las estrellas (0 a 3)
  /// si mejoran el resultado anterior. Devuelve las estrellas.
  int recordGame(String key, int earned) {
    if (earned > bestFor(key)) {
      best[key] = earned;
      _prefs?.setInt(_k('best:$key'), earned);
    }
    final today = _day(now());
    if (_todayBestDay != today) {
      _todayBest.clear();
      _todayBestDay = today;
    }
    if (earned > (_todayBest[key] ?? 0)) _todayBest[key] = earned;
    _prefs?.setString(_k('todayBestDay'), today);
    _prefs?.setStringList(_k('todayBest'), [for (final e in _todayBest.entries) '${e.key}=${e.value}']);
    played[key] = (played[key] ?? 0) + 1;
    _prefs?.setInt(_k('played:$key'), played[key]!);
    if (days.add(today)) _prefs?.setStringList(_k('days'), days.toList());
    _gamesOnDay = gamesToday + 1;
    _gamesDay = today;
    _prefs?.setString(_k('gamesDay'), today);
    _prefs?.setInt(_k('gamesOnDay'), _gamesOnDay);
    if (_gamesOnDay == dailyGoal) {
      medals++;
      _newMedal = true;
      stars += medalBonus;
      starsEarned += medalBonus;
      _prefs?.setInt(_k('medals'), medals);
      _prefs?.setInt(_k('stars'), stars);
      _prefs?.setInt(_k('starsEarned'), starsEarned);
    }
    _countToday(games: 1);
    notifyListeners();
    return earned;
  }

  // ---------- Resumen de la semana para papás ----------

  /// Partidas terminadas y respuestas correctas a la primera de cada día (se guardan las últimas 2 semanas).
  final Map<String, (int, int)> _daily = {};

  void _countToday({int games = 0, int answers = 0}) {
    final today = _day(now());
    final (g, a) = _daily[today] ?? (0, 0);
    _daily[today] = (g + games, a + answers);
    final keep = {for (var i = 0; i < 14; i++) _day(now().subtract(Duration(days: i)))};
    _daily.removeWhere((day, _) => !keep.contains(day));
    _prefs?.setStringList(_k('daily'), [for (final e in _daily.entries) '${e.key}=${e.value.$1},${e.value.$2}']);
  }

  Iterable<(int, int)> get _thisWeek =>
      [for (var i = 0; i < 7; i++) _daily[_day(now().subtract(Duration(days: i)))]].whereType<(int, int)>();

  /// En los últimos 7 días: días que jugó, partidas terminadas y respuestas correctas a la primera.
  int get weekDays => _thisWeek.where((d) => d.$1 > 0 || d.$2 > 0).length;
  int get weekGames => _thisWeek.fold(0, (n, d) => n + d.$1);
  int get weekAnswers => _thisWeek.fold(0, (n, d) => n + d.$2);
  int get weekMedals => _thisWeek.where((d) => d.$1 >= dailyGoal).length;

  /// Si ya jugó todos los niveles y temas gratis (para contarle a los papás qué más trae Premium).
  bool get finishedFreeContent => !premium && [
        for (final max in Config.freeMathMax) ...[mathKey(max), subtractKey(max)],
        for (final t in topics) if (isTopicFree(t.key)) topicKey(t),
        ...freeNumberLevels,
        ...freeLetterLevels,
        if (isBig) ...Config.freeTablesLevels,
      ].where((key) => !hidden(key)).every((key) => (played[key] ?? 0) > 0);

  /// Juegos de Números y Letras gratis, según la edad.
  List<String> get freeNumberLevels => isBig ? Config.freeNumberLevelsBig : Config.freeNumberLevels;
  List<String> get freeLetterLevels => isBig ? Config.freeLetterLevelsBig : Config.freeLetterLevels;

  // ---------- Álbum de stickers ----------

  /// Stickers que ya tiene ("página:dibujo").
  final Set<String> stickers = {};

  bool canFillPage(StickerPage page) => !page.premium || premium;

  /// Pega un sticker nuevo en el álbum (al terminar una partida). Llena primero la página
  /// que va más avanzada, para que se completen. Al completar una página gana [pageBonus] estrellas.
  /// Devuelve null si ya tiene todos los que puede tener.
  ({String sticker, StickerPage page, bool completed})? awardSticker([Random? random]) {
    final open = [
      for (final page in stickerPages)
        if (canFillPage(page) && page.stickers.any((s) => !stickers.contains(stickerId(page, s)))) page,
    ];
    if (open.isEmpty) return null;
    int have(StickerPage p) => p.stickers.where((s) => stickers.contains(stickerId(p, s))).length;
    final page = open.reduce((a, b) => have(b) > have(a) ? b : a);
    final missing = [for (final s in page.stickers) if (!stickers.contains(stickerId(page, s))) s];
    final picture = missing[(random ?? Random()).nextInt(missing.length)];
    final sticker = stickerId(page, picture);
    stickers.add(sticker);
    _prefs?.setStringList(_k('stickers'), stickers.toList());
    final completed = missing.length == 1;
    if (completed) {
      stars += pageBonus;
      starsEarned += pageBonus;
      _prefs?.setInt(_k('stars'), stars);
      _prefs?.setInt(_k('starsEarned'), starsEarned);
    }
    notifyListeners();
    return (sticker: sticker, page: page, completed: completed);
  }

  /// Anota que se equivocó con una palabra en inglés.
  void recordMiss(String word) {
    misses[word] = (misses[word] ?? 0) + 1;
    _prefs?.setInt(_k('miss:$word'), misses[word]!);
  }

  /// Palabras en inglés con más errores, de más a menos.
  List<MapEntry<String, int>> hardestWords([int count = 5]) =>
      (misses.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(count).toList();

  /// Recordatorio diario (del teléfono, no de cada niño).
  bool reminderOn = false;
  int reminderHour = 17;

  void setReminder({required bool on, int? hour}) {
    reminderOn = on;
    reminderHour = hour ?? reminderHour;
    _prefs?.setBool('reminderOn', on);
    _prefs?.setInt('reminderHour', reminderHour);
    notifyListeners();
  }

  /// El idioma del teléfono, si es uno de los de la app (si no, español).
  static AppLang _deviceLang() =>
      PlatformDispatcher.instance.locale.languageCode == 'en' ? AppLang.en : AppLang.es;

  /// Cambia el idioma de la app (el del niño; aprende el otro). Es del teléfono, no de cada niño.
  void setLang(AppLang lang) {
    Lang.current = lang;
    langChosen = true;
    _prefs?.setString('lang', lang.name);
    notifyListeners();
  }

  void setPremium(bool value) {
    if (premium == value) return;
    premium = value;
    _prefs?.setBool('premium', value);
    _takeOffPremiumWithoutPremium();
    notifyListeners();
  }

  /// Sin Premium (p. ej. si se reembolsó), Owlito se quita los trajes Premium.
  void _takeOffPremiumWithoutPremium() {
    if (premium) return;
    if (shopItem(wearing)?.premium ?? false) {
      wearing = null;
      _prefs?.remove(_k('wearing'));
    }
    if (shopItem(feathers)?.premium ?? false) {
      feathers = null;
      _prefs?.remove(_k('feathers'));
    }
  }

  /// Abre Premium con el código de revisión. Devuelve si el código es correcto.
  bool redeemCode(String code) {
    final ok = sha256.convert(utf8.encode(code.trim().toUpperCase())).toString() == Config.reviewCodeSha256;
    if (ok) setPremium(true);
    return ok;
  }

  bool isMathLevelFree(int max) => Config.freeMathMax.contains(max);
  bool isTopicFree(String key) => Config.freeEnglishTopics.contains(key);
  bool canPlayNumbers(String key) => premium || freeNumberLevels.contains(key);
  bool canPlayLetters(String key) => premium || freeLetterLevels.contains(key);
  bool canPlayTables(String key) => premium || Config.freeTablesLevels.contains(key);
  bool canPlayMath(int max) => premium || isMathLevelFree(max);
  bool canPlayTopic(String key) => premium || isTopicFree(key);
}
