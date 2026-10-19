import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Efectos de sonido (assets/sonidos/, hechos con tool/generar_sonidos.py).
/// Suenan junto con la voz, sin cortarla.
class Sfx {
  /// Las pruebas lo apagan (no hay reproductor de audio).
  @visibleForTesting
  static bool enabled = true;

  static AudioPlayer? _player;

  static Future<void> acierto() => _play('acierto');
  static Future<void> celebracion() => _play('celebracion');
  static Future<void> toque() => _play('toque');

  static Future<void> _play(String name) async {
    if (!enabled) return;
    try {
      final player = _player ??= AudioPlayer()
        // Sin pedir el "foco" de audio: así no se detiene la voz que está hablando.
        ..setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
      await player.stop().timeout(const Duration(seconds: 2));
      await player.play(AssetSource('sonidos/$name.mp3'), volume: 0.55).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Sin sonido antes que bloquear el juego.
    }
  }
}
