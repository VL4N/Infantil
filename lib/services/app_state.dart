import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Estrellas, progreso por nivel/tema y estado Premium, guardados en el teléfono.
class AppState extends ChangeNotifier {
  AppState._();
  static final instance = AppState._();

  SharedPreferences? _prefs;
  int stars = 0;
  bool premium = false;

  /// Mejor resultado (0 a 3 estrellas) de cada nivel de suma o tema de inglés.
  final Map<String, int> best = {};

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    stars = _prefs!.getInt('stars') ?? 0;
    premium = _prefs!.getBool('premium') ?? false;
    best.clear();
    for (final key in _prefs!.getKeys()) {
      if (key.startsWith('best:')) best[key.substring(5)] = _prefs!.getInt(key) ?? 0;
    }
    notifyListeners();
  }

  void addStar() {
    stars++;
    _prefs?.setInt('stars', stars);
    notifyListeners();
  }

  /// Estrellas de una partida según los aciertos a la primera (de [Config.roundsPerGame]).
  static int starsFor(int correct) => correct >= 8 ? 3 : correct >= 5 ? 2 : correct >= 1 ? 1 : 0;

  int bestFor(String key) => best[key] ?? 0;

  /// Guarda el resultado de una partida si mejora el anterior. Devuelve las estrellas ganadas.
  int recordGame(String key, int correct) {
    final earned = starsFor(correct);
    if (earned > bestFor(key)) {
      best[key] = earned;
      _prefs?.setInt('best:$key', earned);
      notifyListeners();
    }
    return earned;
  }

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
