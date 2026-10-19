import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../logic/shop.dart';

/// Un niño que juega en este teléfono. El primero (id 0) guarda su progreso con las claves
/// de siempre, así no se pierde lo jugado antes de que hubiera perfiles.
class Profile {
  const Profile(this.id, this.name);
  final int id;
  final String name;
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
      const {'premium', 'profiles', 'profile'}.contains(key) || key.startsWith('reminder');

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
  bool premium = false;

  /// Mejor resultado (0 a 3 estrellas) de cada nivel de suma o tema de inglés.
  final Map<String, int> best = {};

  /// Partidas terminadas de cada nivel o tema.
  final Map<String, int> played = {};

  /// Días en que terminó al menos una partida ('2026-10-08').
  final Set<String> days = {};

  /// Veces que se equivocó con cada palabra en inglés.
  final Map<String, int> misses = {};

  /// Reloj para los días jugados (se cambia en las pruebas).
  DateTime Function() now = DateTime.now;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    premium = _prefs!.getBool('premium') ?? false;
    profiles
      ..clear()
      ..addAll([
        for (final p in _prefs!.getStringList('profiles') ?? const ['0|Jugador 1'])
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
  int? addProfile(String name) {
    if (profiles.length >= maxProfiles) return null;
    final id = profiles.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    profiles.add(Profile(id, name.trim().isEmpty ? 'Jugador ${profiles.length + 1}' : name.trim()));
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
    stars++;
    starsEarned++;
    _prefs?.setInt(_k('stars'), stars);
    _prefs?.setInt(_k('starsEarned'), starsEarned);
    notifyListeners();
  }

  /// Compra algo de la tienda (y Owlito se lo pone). Devuelve false si no le alcanzan las estrellas.
  bool buy(String id, int price) {
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
    if (item == null || !owned.contains(id)) return;
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

  /// Partidas terminadas hoy.
  int get gamesToday => _gamesDay == _day(now()) ? _gamesOnDay : 0;

  static String _day(DateTime t) => '${t.year}-${'${t.month}'.padLeft(2, '0')}-${'${t.day}'.padLeft(2, '0')}';

  static int starsFor(int correct) => correct >= 8 ? 3 : correct >= 5 ? 2 : correct >= 1 ? 1 : 0;

  int bestFor(String key) => best[key] ?? 0;

  /// Guarda una partida terminada: cuenta la partida y el día, y las estrellas (0 a 3)
  /// si mejoran el resultado anterior. Devuelve las estrellas.
  int recordGame(String key, int earned) {
    if (earned > bestFor(key)) {
      best[key] = earned;
      _prefs?.setInt(_k('best:$key'), earned);
    }
    played[key] = (played[key] ?? 0) + 1;
    _prefs?.setInt(_k('played:$key'), played[key]!);
    final today = _day(now());
    if (days.add(today)) _prefs?.setStringList(_k('days'), days.toList());
    _gamesOnDay = gamesToday + 1;
    _gamesDay = today;
    _prefs?.setString(_k('gamesDay'), today);
    _prefs?.setInt(_k('gamesOnDay'), _gamesOnDay);
    notifyListeners();
    return earned;
  }

  /// Anota que se equivocó con una palabra en inglés.
  void recordMiss(String word) {
    misses[word] = (misses[word] ?? 0) + 1;
    _prefs?.setInt(_k('miss:$word'), misses[word]!);
  }

  /// Palabras en inglés con más errores, de más a menos.
  List<MapEntry<String, int>> hardestWords([int count = 5]) =>
      (misses.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(count).toList();

  void setPremium(bool value) {
    if (premium == value) return;
    premium = value;
    _prefs?.setBool('premium', value);
    notifyListeners();
  }

  bool isMathLevelFree(int max) => Config.freeMathMax.contains(max);
  bool isTopicFree(String key) => Config.freeEnglishTopics.contains(key);
  bool canPlayMath(int max) => premium || isMathLevelFree(max);
  bool canPlayTopic(String key) => premium || isTopicFree(key);
}
