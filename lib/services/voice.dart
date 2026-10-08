import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../logic/phrases.dart';

/// Voz de la app (español latino e inglés).
///
/// Primero intenta la voz grabada incluida en la app (assets/voz/, generada con
/// Piper a partir de lib/logic/phrases.dart): suena natural e igual en todos los
/// teléfonos. Si una frase no está grabada, usa la voz del propio teléfono.
///
/// En algunos teléfonos el motor de voz tarda en arrancar o no responde nunca:
/// flutter_tts deja las llamadas en espera hasta entonces. Por eso nada de la app
/// espera a la voz sin límite: hasta que el motor está listo, la app sigue en silencio.
///
/// Para que suene lo más natural posible se usa el motor de Google si está
/// instalado (el de algunos fabricantes, p. ej. Xiaomi, suena muy robótico) y,
/// entre sus voces, la de mejor calidad para cada idioma.
class Voice {
  static final _tts = FlutterTts();
  static bool _ready = false;

  /// Audios grabados disponibles (rutas `assets/voz/<archivo>.mp3`).
  static Set<String> _clips = {};

  /// Las pruebas lo apagan para escuchar la voz simulada del teléfono.
  @visibleForTesting
  static bool useClips = true;
  static AudioPlayer? _player;
  static const _googleEngine = 'com.google.android.tts';

  /// Voz elegida para cada idioma ('es', 'en'); vacía si no hay lista de voces.
  static final Map<String, Map<String, String>> _voices = {};

  /// Tono algo más alto y alegre que el normal, pensado para niños.
  static const pitch = 1.15;
  static const rate = 0.45;

  /// Se llama sin esperar (después de mostrar la app). Si el motor tarda, la voz
  /// se activa sola cuando responde.
  static Future<void> init() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _clips = manifest.listAssets().where((a) => a.startsWith('assets/voz/')).toSet();
    } catch (_) {}
    try {
      await _useGoogleEngineIfAvailable();
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      // say() espera a que termine de hablar, para encadenar explicaciones.
      await _tts.awaitSpeakCompletion(true);
      await _pickVoices();
      _ready = true;
    } catch (_) {}
  }

  static Future<void> _useGoogleEngineIfAvailable() async {
    try {
      final engines = await _tts.getEngines.timeout(const Duration(seconds: 5));
      final current = await _tts.getDefaultEngine.timeout(const Duration(seconds: 5));
      if (engines is List && engines.contains(_googleEngine) && current != _googleEngine) {
        await _tts.setEngine(_googleEngine).timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Si no se puede cambiar, se usa el motor del teléfono.
    }
  }

  static Future<void> _pickVoices() async {
    try {
      final raw = await _tts.getVoices.timeout(const Duration(seconds: 5));
      if (raw is! List) return;
      final voices = [
        for (final v in raw)
          if (v is Map) {for (final e in v.entries) '${e.key}': '${e.value}'},
      ];
      for (final lang in ['es', 'en']) {
        final best = bestVoice(voices, lang);
        if (best != null) _voices[lang] = {'name': best['name']!, 'locale': best['locale']!};
      }
    } catch (_) {}
  }

  /// La voz más natural para [lang] ('es' o 'en'): instalada, de la mejor calidad,
  /// sin necesitar internet si es posible y con el acento preferido
  /// (español latino; inglés de EE. UU.).
  @visibleForTesting
  static Map<String, String>? bestVoice(List<Map<String, String>> voices, String lang) {
    const quality = {'very high': 5, 'high': 4, 'normal': 3, 'low': 2, 'very low': 1};
    final accents = lang == 'en'
        ? ['en-US', 'en-GB', 'en']
        : ['es-US', 'es-MX', 'es-419', 'es-CO', 'es-AR', 'es-ES', 'es'];
    // Acentos preferidos: latinoamericano en español, de EE. UU. en inglés.
    final preferred = lang == 'en' ? ['en-US'] : ['es-US', 'es-MX', 'es-419', 'es-CO', 'es-AR'];
    int accent(String locale) {
      final i = accents.indexWhere((a) => locale.toLowerCase().startsWith(a.toLowerCase()));
      return i < 0 ? -1 : accents.length - i;
    }

    Map<String, String>? best;
    var bestScore = -1;
    for (final v in voices) {
      final name = v['name'] ?? '';
      final locale = (v['locale'] ?? '').replaceAll('_', '-');
      final a = accent(locale);
      if (name.isEmpty || a < 0) continue;
      if ((v['features'] ?? '').contains('notInstalled')) continue;
      final offline = v['network_required'] != '1';
      // El acento preferido pesa más que un escalón de calidad, pero no que dos.
      final isPreferred = preferred.any((p) => locale.toLowerCase().startsWith(p.toLowerCase()));
      final score = (quality[v['quality']] ?? 3) * 100 + (offline ? 50 : 0) + (isPreferred ? 150 : 0) + a;
      if (score > bestScore) {
        bestScore = score;
        best = {...v, 'locale': locale};
      }
    }
    return best;
  }

  /// [lang]: 'es' o 'en'. Termina cuando acaba de hablar (o enseguida si no hay voz).
  static Future<void> say(String text, String lang) async {
    final clip = 'assets/voz/${clipName(text, lang)}';
    if (useClips && _clips.contains(clip)) {
      await _playClip(clip);
      return;
    }
    if (!_ready) return;
    try {
      await () async {
        await _tts.stop();
        final voice = _voices[lang];
        if (voice != null) {
          await _tts.setVoice(voice);
        } else {
          await _tts.setLanguage(lang == 'en' ? 'en-US' : 'es-US');
        }
        await _tts.speak(text);
      }()
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sin motor de voz (o en tests): la app sigue funcionando en silencio.
    }
  }

  static Future<void> _playClip(String clip) async {
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      final done = player.onPlayerComplete.first;
      await player.play(AssetSource(clip.substring('assets/'.length)));
      await done.timeout(const Duration(seconds: 10));
    } catch (_) {
      // Si el audio no se puede reproducir, se sigue sin voz antes que bloquear el juego.
    }
  }

  static Future<void> stop() async {
    try {
      await _player?.stop().timeout(const Duration(seconds: 2));
    } catch (_) {}
    if (!_ready) return;
    try {
      await _tts.stop().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
