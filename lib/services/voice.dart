import 'package:flutter_tts/flutter_tts.dart';

/// Voz del propio teléfono (español latino e inglés).
class Voice {
  static final _tts = FlutterTts();

  static Future<void> init() async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {}
  }

  /// [lang]: 'es' o 'en'.
  static Future<void> say(String text, String lang) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(lang == 'en' ? 'en-US' : 'es-US');
      await _tts.speak(text);
    } catch (_) {
      // Sin motor de voz (o en tests): la app sigue funcionando en silencio.
    }
  }
}
