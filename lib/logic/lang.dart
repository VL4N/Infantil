/// Idioma de la app: el que habla el niño. Aprende el otro
/// (en español aprende inglés; en inglés aprende español).
enum AppLang { es, en }

class Lang {
  static AppLang current = AppLang.es;

  /// Idioma del niño ('es' o 'en'): instrucciones, voz de Owlito y matemáticas.
  static String get native => current.name;

  /// Idioma que aprende ('en' o 'es'): las palabras de los temas y de Parejas.
  static String get target => current == AppLang.es ? 'en' : 'es';
}

/// El texto en el idioma de la app: `tr('Sumar', 'Add')`.
String tr(String es, String en) => Lang.current == AppLang.es ? es : en;
