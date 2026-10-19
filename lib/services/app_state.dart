import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../logic/shop.dart';

/// Estrellas, progreso por nivel/tema, resumen para papás y estado Premium, guardados en el teléfono.
class AppState extends ChangeNotifier {
  AppState._();
  static final instance = AppState._();

  SharedPreferences? _prefs;

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
    stars = _prefs!.getInt('stars') ?? 0;
    // Antes de la tienda solo se guardaba 'stars': entonces todas eran ganadas.
    starsEarned = _prefs!.getInt('starsEarned') ?? stars;
    owned
      ..clear()
      ..addAll(_prefs!.getStringList('owned') ?? const []);
    wearing = _prefs!.getString('wearing');
    feathers = _prefs!.getString('feathers');
    premium = _prefs!.getBool('premium') ?? false;
    best.clear();
    played.clear();
    misses.clear();
    for (final key in _prefs!.getKeys()) {
      if (key.startsWith('best:')) best[key.substring(5)] = _prefs!.getInt(key) ?? 0;
      if (key.startsWith('played:')) played[key.substring(7)] = _prefs!.getInt(key) ?? 0;
      if (key.startsWith('miss:')) misses[key.substring(5)] = _prefs!.getInt(key) ?? 0;
    }
    _gamesDay = _prefs!.getString('gamesDay') ?? '';
    _gamesOnDay = _prefs!.getInt('gamesOnDay') ?? 0;
    days
      ..clear()
      ..addAll(_prefs!.getStringList('days') ?? const []);
    notifyListeners();
  }

  void addStar() {
    stars++;
    starsEarned++;
    _prefs?.setInt('stars', stars);
    _prefs?.setInt('starsEarned', starsEarned);
    notifyListeners();
  }

  /// Compra algo de la tienda (y Owlito se lo pone). Devuelve false si no le alcanzan las estrellas.
  bool buy(String id, int price) {
    if (owned.contains(id) || stars < price) return false;
    stars -= price;
    owned.add(id);
    _prefs?.setInt('stars', stars);
    _prefs?.setStringList('owned', owned.toList());
    wear(id);
    return true;
  }

  /// Owlito se pone algo que ya compró: un accesorio o un color de plumas.
  void wear(String id) {
    final item = shopItem(id);
    if (item == null || !owned.contains(id)) return;
    if (item.isFeathers) {
      feathers = id;
      _prefs?.setString('feathers', id);
    } else {
      wearing = id;
      _prefs?.setString('wearing', id);
    }
    notifyListeners();
  }

  /// Owlito vuelve a como era: sin accesorio y con sus plumas de siempre.
  void takeOffAll() {
    wearing = null;
    feathers = null;
    _prefs?.remove('wearing');
    _prefs?.remove('feathers');
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
      _prefs?.setInt('best:$key', earned);
    }
    played[key] = (played[key] ?? 0) + 1;
    _prefs?.setInt('played:$key', played[key]!);
    final today = _day(now());
    if (days.add(today)) _prefs?.setStringList('days', days.toList());
    _gamesOnDay = gamesToday + 1;
    _gamesDay = today;
    _prefs?.setString('gamesDay', today);
    _prefs?.setInt('gamesOnDay', _gamesOnDay);
    notifyListeners();
    return earned;
  }

  /// Anota que se equivocó con una palabra en inglés.
  void recordMiss(String word) {
    misses[word] = (misses[word] ?? 0) + 1;
    _prefs?.setInt('miss:$word', misses[word]!);
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
