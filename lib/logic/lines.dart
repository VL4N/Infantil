import 'lang.dart';

/// Frases fijas que dice Owlito en las pantallas, en el idioma de la app.
/// Están todas aquí para grabarlas de antemano (ver logic/phrases.dart).
String get letsReview => tr('¡Repasemos!', "Let's review!");
String get askForHelp => tr('Pide ayuda a papá o a mamá', 'Ask mom or dad for help');
String get findThePairs => tr('Busca las parejas', 'Find the pairs');
String get whoIsPlaying => tr('¿Quién va a jugar?', "Who's playing?");
String get youAreAStar => tr('¡Eres una estrella!', "You're a star!");
String get greatJob => tr('¡Muy bien!', 'Great job!');
String get keepPracticing => tr('¡Sigue practicando!', 'Keep practicing!');
String get newSticker => tr('¡Ganaste un sticker nuevo!', 'You won a new sticker!');
String get pageComplete => tr('¡Completaste una página del álbum!', 'You completed an album page!');

/// Todas las de arriba (para grabarlas).
List<String> get screenLines =>
    [letsReview, askForHelp, findThePairs, whoIsPlaying, youAreAStar, greatJob, keepPracticing, newSticker, pageComplete];
