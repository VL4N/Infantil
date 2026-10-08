import 'package:flutter_tts/flutter_tts.dart';

/// Voz del propio teléfono (español latino e inglés).
class Voice {
  static final _tts = FlutterTts();

  static Future<void> init() async {
    try {
      await _tts.setSpeechRate(0.45);
      // say() espera a que termine de hablar, para encadenar explicaciones.
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  /// [lang]: 'es' o 'en'. Termina cuando acaba de hablar.
  static Future<void> say(String text, String lang) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(lang == 'en' ? 'en-US' : 'es-US');
      await _tts.speak(text).timeout(const Duration(seconds: 6));
    } catch (_) {
      // Sin motor de voz (o en tests): la app sigue funcionando en silencio.
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
