import 'dart:math';

import 'content.dart';
import 'questions.dart';

/// Clave del reto de hoy (para guardar su resultado).
const challengeKey = 'reto-hoy';

/// Número del día (20261021) para que el reto sea el mismo todo el día y cambie al siguiente.
int dayNumber(DateTime t) => t.year * 10000 + t.month * 100 + t.day;

/// Las preguntas del reto de hoy: sumas, restas e inglés mezclados. Con la misma semilla
/// (el día y el niño) salen siempre las mismas; al día siguiente, otras.
Random challengeRandom(DateTime day, int profileId) => Random(dayNumber(day) * 7 + profileId);

/// Una pregunta del reto. Usa niveles hasta 10 y los temas de inglés que el niño puede jugar.
QuestionMaker challengeQuestions(List<Topic> playableTopics) => (r) => switch (r.nextInt(3)) {
      0 => additionQuestion(r, 10),
      1 => subtractionQuestion(r, 10),
      _ => englishMixedQuestion(r, playableTopics[r.nextInt(playableTopics.length)]),
    };
