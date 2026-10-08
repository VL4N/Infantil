import 'package:aprende_jugando/services/voice.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, String> v(String name, String locale, String quality, {bool network = false, bool installed = true}) => {
      'name': name,
      'locale': locale,
      'quality': quality,
      'network_required': network ? '1' : '0',
      'features': installed ? '' : 'notInstalled',
    };

void main() {
  final voices = [
    v('es-es-x-eea-local', 'es-ES', 'very high'),
    v('es-us-x-esc-local', 'es-US', 'normal'),
    v('es-us-x-esd-local', 'es-US', 'very high'),
    v('es-us-x-sfb-network', 'es-US', 'very high', network: true),
    v('en-gb-x-gba-local', 'en-GB', 'very high'),
    v('en-us-x-iog-local', 'en-US', 'high'),
    v('en-us-x-tpf-local', 'en-US', 'very high', installed: false),
    v('fr-fr-x-frc-local', 'fr-FR', 'very high'),
  ];

  test('español: la de mejor calidad, sin internet y con acento latino', () {
    expect(Voice.bestVoice(voices, 'es')!['name'], 'es-us-x-esd-local');
  });

  test('inglés: ignora voces no instaladas y prefiere acento de EE. UU.', () {
    // en-US "very high" no está instalada; en-US "high" gana a en-GB "very high".
    expect(Voice.bestVoice(voices, 'en')!['name'], 'en-us-x-iog-local');
  });

  test('una voz mucho mejor gana aunque tenga otro acento', () {
    final pocas = [v('es-us-low', 'es-US', 'low'), v('es-es-vh', 'es-ES', 'very high')];
    expect(Voice.bestVoice(pocas, 'es')!['name'], 'es-es-vh');
  });

  test('si no hay voces del idioma, no elige ninguna', () {
    expect(Voice.bestVoice([v('fr-fr-x', 'fr-FR', 'high')], 'es'), isNull);
    expect(Voice.bestVoice([], 'en'), isNull);
  });

  test('acepta locales con guion bajo', () {
    expect(Voice.bestVoice([v('a', 'es_US', 'high')], 'es')!['locale'], 'es-US');
  });
}
