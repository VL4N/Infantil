import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Estrellas y estado Premium, guardados en el teléfono.
class AppState extends ChangeNotifier {
  AppState._();
  static final instance = AppState._();

  SharedPreferences? _prefs;
  int stars = 0;
  bool premium = false;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    stars = _prefs!.getInt('stars') ?? 0;
    premium = _prefs!.getBool('premium') ?? false;
    notifyListeners();
  }

  void addStar() {
    stars++;
    _prefs?.setInt('stars', stars);
    notifyListeners();
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
