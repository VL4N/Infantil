import 'dart:math';

import 'lang.dart';
import 'questions.dart';

/// Sección "La hora" (para los grandes): leer un reloj de agujas. Las horas que salen
/// son fijas (de 1 a 12, con los minutos de cada nivel) para que cada frase venga grabada.

/// Una hora del reloj: [hour] de 1 a 12 y [minute] de 0 a 55.
typedef ClockTime = ({int hour, int minute});

/// "3:05", como en un reloj digital.
String digital(ClockTime t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

/// La hora siguiente (de 12 se pasa a 1).
int _nextHour(int h) => h % 12 + 1;

const _minutesEn = {
  5: 'oh five', 10: 'ten', 20: 'twenty', 25: 'twenty-five', 35: 'thirty-five', 40: 'forty', 50: 'fifty', 55: 'fifty-five',
};

/// Cómo se dice la hora: "las 3 y media", "la una en punto", "half past 3".
String timeName(ClockTime t) {
  final h = t.hour, m = t.minute;
  if (Lang.current == AppLang.es) {
    String las(int h) => h == 1 ? 'la una' : 'las $h';
    return switch (m) {
      0 => '${las(h)} en punto',
      15 => '${las(h)} y cuarto',
      30 => '${las(h)} y media',
      45 => '${las(_nextHour(h))} menos cuarto',
      _ => '${las(h)} y $m',
    };
  }
  return switch (m) {
    0 => "$h o'clock",
    15 => 'quarter past $h',
    30 => 'half past $h',
    45 => 'quarter to ${_nextHour(h)}',
    _ => '$h ${_minutesEn[m]}',
  };
}

// ---------- Frases ----------

String get whatTimeIsIt => tr('¿Qué hora es?', 'What time is it?');
String whichClockShows(ClockTime t) => tr('¿Qué reloj marca ${timeName(t)}?', 'Which clock shows ${timeName(t)}?');
String greatTime(ClockTime t) => tr('¡Muy bien! Son ${timeName(t)}.', 'Great! It is ${timeName(t)}.');
String itIsTouch(ClockTime t) => tr('Son ${timeName(t)}. ¡Tócalo!', 'It is ${timeName(t)}. Touch it!');

/// La aguja corta: en punto señala la hora; si no, ya pasó esa hora.
String shortHand(ClockTime t) => t.minute == 0
    ? tr('La aguja corta señala el ${t.hour}.', 'The short hand points to ${t.hour}.')
    : tr('La aguja corta ya pasó el ${t.hour}.', 'The short hand is past ${t.hour}.');

/// La aguja larga: dónde señala y qué quiere decir.
String longHand(int minute) {
  final at = minute == 0 ? 12 : minute ~/ 5;
  return switch (minute) {
    0 => tr('La aguja larga señala el 12: en punto.', "The long hand points to 12: o'clock."),
    15 => tr('La aguja larga señala el 3: y cuarto.', 'The long hand points to 3: quarter past.'),
    30 => tr('La aguja larga señala el 6: y media.', 'The long hand points to 6: half past.'),
    45 => tr('La aguja larga señala el 9: falta un cuarto para la hora.', 'The long hand points to 9: quarter to.'),
    _ => tr('La aguja larga señala el $at: son $minute minutos.', 'The long hand points to $at: $minute minutes.'),
  };
}

/// Lo que se ve y se dice en una pregunta de la hora.
class ClockQuestion {
  const ClockQuestion({required this.time, required this.optionTimes, required this.pickClock});

  /// La hora que marca el reloj (la respuesta).
  final ClockTime time;

  /// Las horas de las tres opciones.
  final List<ClockTime> optionTimes;

  /// Las opciones son relojes (se ve la hora escrita y hay que tocar el reloj).
  final bool pickClock;

  String get praise => greatTime(time);

  List<ExplainStep> get explain => [
        ExplainStep(shortHand(time), Lang.native),
        ExplainStep(longHand(time.minute), Lang.native),
        ExplainStep(itIsTouch(time), Lang.native, highlightAnswer: true),
      ];
}

/// Minutos que salen en cada nivel.
const clockMinutes = {
  'reloj-punto': [0],
  'reloj-media': [0, 30],
  'reloj-cuarto': [15, 30, 45],
  'reloj-5': [5, 10, 20, 25, 35, 40, 50, 55],
};

/// Todas las horas que pueden salir.
Iterable<ClockTime> get allClockTimes sync* {
  final minutes = {for (final m in clockMinutes.values) ...m};
  for (var h = 1; h <= 12; h++) {
    for (final m in minutes) {
      yield (hour: h, minute: m);
    }
  }
}

/// Una pregunta de la hora con los minutos de [minutes]: "¿Qué hora es?" (un reloj y tres horas
/// escritas) o, una de cada tres, "¿Qué reloj marca las 3?" (tres relojes).
Question clockQuestion(Random r, List<int> minutes) {
  final time = (hour: 1 + r.nextInt(12), minute: minutes[r.nextInt(minutes.length)]);
  // Errores típicos: confundir las agujas, equivocarse de hora por una, o leer mal la aguja larga.
  final wrong = <ClockTime>{
    if (time.minute % 5 == 0 && time.minute > 0 && time.hour * 5 < 60) (hour: time.minute ~/ 5, minute: time.hour * 5),
    (hour: _nextHour(time.hour), minute: time.minute),
    (hour: time.hour == 1 ? 12 : time.hour - 1, minute: time.minute),
    for (final m in minutes) if (m != time.minute) (hour: time.hour, minute: m),
    if (minutes.length == 1) (hour: time.hour, minute: 30),
  }..remove(time);
  final options = [time, ...(wrong.toList()..shuffle(r)).take(2)]..shuffle(r);
  final pickClock = r.nextInt(3) == 0;
  final clock = ClockQuestion(time: time, optionTimes: options, pickClock: pickClock);
  return Question(
    prompt: pickClock ? digital(time) : whatTimeIsIt,
    options: [for (final o in options) digital(o)],
    answerIndex: options.indexOf(time),
    speech: pickClock ? whichClockShows(time) : whatTimeIsIt,
    speechLang: Lang.native,
    clock: clock,
  );
}

/// Un juego de la sección La hora (se guarda su progreso con [key]).
class ClockLevel {
  const ClockLevel(this.key, this.icon, this.nameEs, this.nameEn);
  final String key;
  final String icon;
  final String nameEs;
  final String nameEn;

  String get label => '$icon ${tr(nameEs, nameEn)}';
  Question make(Random r) => clockQuestion(r, clockMinutes[key]!);
}

const clockLevels = [
  ClockLevel('reloj-punto', '🕒', 'En punto', "O'clock"),
  ClockLevel('reloj-media', '🕞', 'Y media', 'Half past'),
  ClockLevel('reloj-cuarto', '🕓', 'Y cuarto y menos cuarto', 'Quarter past and quarter to'),
  ClockLevel('reloj-5', '⏰', 'De 5 en 5 minutos', 'Every 5 minutes'),
];

/// Todas las frases de la sección La hora en el idioma actual (para grabarlas).
Iterable<String> get clockPhrases sync* {
  yield whatTimeIsIt;
  for (final t in allClockTimes) {
    yield whichClockShows(t);
    yield greatTime(t);
    yield itIsTouch(t);
    yield shortHand(t);
  }
  for (final m in {for (final m in clockMinutes.values) ...m}) {
    yield longHand(m);
  }
}
