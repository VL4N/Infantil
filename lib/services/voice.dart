import 'package:flutter_tts/flutter_tts.dart';

/// Voz del propio teléfono (español latino e inglés).
///
/// En algunos teléfonos el motor de voz tarda en arrancar o no responde nunca:
/// flutter_tts deja las llamadas en espera hasta entonces. Por eso nada de la app
/// espera a la voz sin límite: hasta que el motor está listo, la app sigue en silencio.
class Voice {
  static final _tts = FlutterTts();
  static bool _ready = false;

  /// Se llama sin esperar (después de mostrar la app). Si el motor tarda, la voz
  /// se activa sola cuando responde.
  static Future<void> init() async {
    try {
      await _tts.setSpeechRate(0.45);
      // say() espera a que termine de hablar, para encadenar explicaciones.
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    } catch (_) {}
  }

  /// [lang]: 'es' o 'en'. Termina cuando acaba de hablar (o enseguida si no hay voz).
  static Future<void> say(String text, String lang) async {
    if (!_ready) return;
    try {
      await () async {
        await _tts.stop();
        await _tts.setLanguage(lang == 'en' ? 'en-US' : 'es-US');
        await _tts.speak(text);
      }()
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sin motor de voz (o en tests): la app sigue funcionando en silencio.
    }
  }

  static Future<void> stop() async {
    if (!_ready) return;
    try {
      await _tts.stop().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
