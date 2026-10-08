// ignore_for_file: avoid_print
// Imprime todas las frases de la app como "archivo<TAB>idioma<TAB>texto", una por línea.
// Lo usa tool/generar_voces.py (en GitHub Actions) para grabarlas con Piper.
import 'package:aprende_jugando/logic/phrases.dart';

void main() {
  final phrases = allPhrases().toList()..sort((a, b) => '${a.$2}${a.$1}'.compareTo('${b.$2}${b.$1}'));
  for (final (text, lang) in phrases) {
    print('${clipName(text, lang)}\t$lang\t$text');
  }
}
