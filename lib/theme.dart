import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'logic/lang.dart';

/// Colores que no cambian entre el día y la noche (acierto, pista, error).
class AppColors {
  static const green = Color(0xFF2FB36B);
  static const yellow = Color(0xFFFFC93C);
  static const red = Color(0xFFE5484D);
  static const orange = Color(0xFFFFA45C);
}

/// Estilo de la app: "Caramelo" de día y "Noche estrellada" de noche (de 19:00 a 6:59).
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.night,
    required this.font,
    required this.bg,
    required this.ink,
    required this.inkSoft,
    required this.card,
    required this.cardInk,
    required this.cardBorder,
    required this.math,
    required this.mathInk,
    required this.subtract,
    required this.subtractInk,
    required this.english,
    required this.englishInk,
    required this.memory,
    required this.memoryInk,
    required this.accent,
    required this.accentInk,
    required this.star,
    required this.track,
  });

  final bool night;
  final String font;
  final Color bg;
  final Color ink;
  final Color inkSoft;

  /// Botones y tarjetas normales.
  final Color card;
  final Color cardInk;
  final Color? cardBorder;

  /// Color de cada juego (Sumar, Inglés, Parejas) y de su texto encima.
  final Color math;
  final Color mathInk;
  final Color subtract;
  final Color subtractInk;
  final Color english;
  final Color englishInk;
  final Color memory;
  final Color memoryInk;

  /// Botones de escuchar, números al contar, cartas boca abajo.
  final Color accent;
  final Color accentInk;
  final Color star;

  /// Fondo de barras de progreso.
  final Color track;

  static const day = Palette(
    night: false,
    font: 'Fredoka',
    bg: Color(0xFFFDEBF3),
    ink: Color(0xFF3B2A55),
    inkSoft: Color(0xFF7A3A5E),
    card: Color(0xFFFFFFFF),
    cardInk: Color(0xFF3B2A55),
    cardBorder: null,
    math: Color(0xFFE5508E),
    mathInk: Color(0xFFFFFFFF),
    subtract: Color(0xFFFF9F45),
    subtractInk: Color(0xFF3B2A55),
    english: Color(0xFF2EC4A6),
    englishInk: Color(0xFF10372F),
    memory: Color(0xFF8162F0),
    memoryInk: Color(0xFFFFFFFF),
    accent: Color(0xFF8162F0),
    accentInk: Color(0xFFFFFFFF),
    star: Color(0xFFFFC93C),
    track: Color(0xFFFFFFFF),
  );

  static const nightStyle = Palette(
    night: true,
    font: 'Nunito',
    bg: Color(0xFF1B1F4B),
    ink: Color(0xFFFFFFFF),
    inkSoft: Color(0xFFC9CCF5),
    card: Color(0xFF2C3270),
    cardInk: Color(0xFFFFFFFF),
    cardBorder: Color(0xFF3D4494),
    math: Color(0xFFFFD45C),
    mathInk: Color(0xFF1B1F4B),
    subtract: Color(0xFFB9AFFF),
    subtractInk: Color(0xFF1B1F4B),
    english: Color(0xFF5EE1C9),
    englishInk: Color(0xFF1B1F4B),
    memory: Color(0xFFFF8A70),
    memoryInk: Color(0xFF1B1F4B),
    accent: Color(0xFF5EE1C9),
    accentInk: Color(0xFF1B1F4B),
    star: Color(0xFFFFD45C),
    track: Color(0xFF2C3270),
  );

  /// Para las pruebas: fuerza el día (false) o la noche (true).
  static bool? debugNight;

  static bool isNightAt(DateTime t) => t.hour >= 19 || t.hour < 7;

  static Palette at(DateTime t) => (debugNight ?? isNightAt(t)) ? nightStyle : day;

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) => t < 0.5 || other == null ? this : other;
}

extension PaletteOf on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>() ?? Palette.day;
}

/// Un color más oscuro, para el "relieve" de los botones.
Color shade(Color c, [double amount = 0.16]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness(math.max(0, hsl.lightness - amount)).toColor();
}

ThemeData buildTheme(Palette p) => ThemeData(
      useMaterial3: true,
      fontFamily: p.font,
      brightness: p.night ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: p.night ? Brightness.dark : Brightness.light,
        surface: p.bg,
      ),
      textTheme: ThemeData(brightness: p.night ? Brightness.dark : Brightness.light)
          .textTheme
          .apply(fontFamily: p.font, bodyColor: p.ink, displayColor: p.ink)
          .copyWith(bodyMedium: TextStyle(fontFamily: p.font, color: p.ink, fontWeight: FontWeight.w600)),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: p.font, fontSize: 24, fontWeight: FontWeight.w800, color: p.ink),
      ),
      dialogTheme: DialogThemeData(backgroundColor: p.night ? p.card : Colors.white),
      extensions: [p],
    );

/// Botón grande y redondeado, con relieve, fácil de tocar para un niño.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.fontSize = 26,
    this.locked = false,
    this.stars,
    this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
  });

  final String label;
  final VoidCallback? onTap;

  /// Sin color: el de las tarjetas del estilo actual (blanco de día, azul de noche).
  final Color? color;
  final Color? textColor;
  final double fontSize;
  final bool locked;

  /// Mejor resultado (0 a 3) que se muestra debajo del texto; null = no se muestra.
  final int? stars;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = color ?? p.card;
    final border = color == null ? p.cardBorder : null;
    final base = color == null && !p.night ? const Color(0xFFF3C6DA) : shade(bg);
    final radius = BorderRadius.circular(26);
    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          // Relieve: el botón "flota" sobre una base más oscura.
          boxShadow: [BoxShadow(color: border ?? base, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: border == null ? BorderSide.none : BorderSide(color: border, width: 2),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locked ? '$label 🔒' : label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: textColor ?? p.cardInk),
                  ),
                  if (stars != null) StarRating(stars: stars!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contador de estrellas: una pastilla con la estrella y el total.
class StarCounter extends StatelessWidget {
  const StarCounter({super.key, required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = p.night ? p.star : const Color(0xFF3B2A55);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 14, 4),
          decoration: BoxDecoration(
            color: p.night ? p.card : p.star,
            borderRadius: BorderRadius.circular(99),
            border: p.night ? Border.all(color: p.star, width: 2) : null,
            boxShadow: p.night ? null : [BoxShadow(color: shade(p.star, .12), offset: const Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 22, color: p.night ? p.star : Colors.white),
              const SizedBox(width: 4),
              Text('$stars', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mejor resultado de un nivel o tema: ★★☆.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.stars, this.size = 26});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      '★' * stars + '☆' * (3 - stars),
      semanticsLabel: tr('$stars de 3 estrellas', '$stars of 3 stars'),
      style: TextStyle(fontSize: size, color: p.night ? p.star : const Color(0xFFE0A51A), letterSpacing: 4),
    );
  }
}

/// Cara de Owlito: feliz con el reto de hoy hecho, triste si ayer no se hizo.
enum OwlMood { normal, happy, sad }

/// Owlito, el búho de la app. De día es café; de noche, morado.
class Owl extends StatelessWidget {
  const Owl({
    super.key,
    this.size = 100,
    this.night = false,
    this.wearing,
    this.feathers,
    this.mood = OwlMood.normal,
    this.blink = 0,
    this.tear = 0,
  });
  final double size;
  final bool night;
  final OwlMood mood;

  /// Cuánto tiene cerrados los ojos (0 abiertos, 1 cerrados), para parpadear.
  final double blink;

  /// Por dónde va la lágrima cuando está triste (0 recién sale, 1 ya cayó).
  final double tear;

  /// Lo que lleva puesto de la tienda (ver logic/shop.dart), o null.
  final String? wearing;

  /// Colores de plumas comprados (orejas, cuerpo, pecho), o null para los de siempre.
  final (int, int, int)? feathers;

  @override
  Widget build(BuildContext context) => Semantics(
        label: switch (mood) {
          OwlMood.happy => tr('Owlito, el búho, está feliz', 'Owlito the owl is happy'),
          OwlMood.sad => tr('Owlito, el búho, está triste', 'Owlito the owl is sad'),
          OwlMood.normal => tr('Owlito, el búho', 'Owlito the owl'),
        },
        child: CustomPaint(size: Size(size, size * 112 / 104), painter: _OwlPainter(night, wearing, feathers, mood, blink, tear)),
      );
}

class _OwlPainter extends CustomPainter {
  _OwlPainter(this.night, this.wearing, this.feathers, this.mood, this.blink, this.tear);
  final bool night;
  final String? wearing;
  final (int, int, int)? feathers;
  final OwlMood mood;
  final double blink;
  final double tear;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 104, size.height / 112);
    Paint fill(int c) => Paint()..color = Color(c);
    final ears = Path()
      ..moveTo(22, 26)..lineTo(30, 6)..lineTo(42, 22)..close()
      ..moveTo(82, 26)..lineTo(74, 6)..lineTo(62, 22)..close();
    final (earC, bodyC, bellyC) = feathers ?? (night ? (0xFF6E5BD8, 0xFF8270F0, 0xFFB9AFFF) : (0xFF8A5A3B, 0xFFA86B45, 0xFFF3D9B1));
    canvas.drawPath(ears, fill(earC));
    canvas.drawOval(Rect.fromCenter(center: const Offset(52, 64), width: 80, height: 88), fill(bodyC));
    canvas.drawOval(Rect.fromCenter(center: const Offset(52, 78), width: 52, height: 56), fill(bellyC));
    final eye = fill(night ? 0xFFFFE9A8 : 0xFFFFFFFF);
    canvas.drawCircle(const Offset(36, 46), 15, eye);
    canvas.drawCircle(const Offset(68, 46), 15, eye);
    final pupilC = night ? 0xFF1B1F4B : 0xFF1F3B2D;
    if (mood == OwlMood.happy) {
      // Ojos cerrados de felicidad (^ ^) y cachetes rosados.
      final smile = Paint()
        ..color = Color(pupilC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(Path()..moveTo(27, 50)..quadraticBezierTo(36, 36, 45, 50), smile);
      canvas.drawPath(Path()..moveTo(59, 50)..quadraticBezierTo(68, 36, 77, 50), smile);
      canvas.drawCircle(const Offset(24, 62), 5, fill(0x88FF7FA8));
      canvas.drawCircle(const Offset(80, 62), 5, fill(0x88FF7FA8));
    } else {
      final pupil = fill(pupilC);
      final dy = mood == OwlMood.sad ? 4.0 : 0.0; // triste: mira hacia abajo
      canvas.drawCircle(Offset(38, 47 + dy), 7, pupil);
      canvas.drawCircle(Offset(66, 47 + dy), 7, pupil);
      canvas.drawCircle(Offset(40, 44 + dy), 2.2, fill(0xFFFFFFFF));
      canvas.drawCircle(Offset(68, 44 + dy), 2.2, fill(0xFFFFFFFF));
      if (mood == OwlMood.sad) {
        // Párpados caídos, cejas tristes y una lágrima.
        final lid = fill(feathers?.$2 ?? (night ? 0xFF8270F0 : 0xFFA86B45));
        canvas.drawArc(Rect.fromCircle(center: const Offset(36, 46), radius: 15.5), math.pi, math.pi, false, lid);
        canvas.drawArc(Rect.fromCircle(center: const Offset(68, 46), radius: 15.5), math.pi, math.pi, false, lid);
        final brow = Paint()
          ..color = Color(pupilC)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(24, 30), const Offset(44, 25), brow);
        canvas.drawLine(const Offset(80, 30), const Offset(60, 25), brow);
        // La lágrima baja por la cara y se desvanece al final.
        final drop = tear * 16;
        canvas.drawPath(
          Path()
            ..moveTo(25, 58 + drop)
            ..quadraticBezierTo(19, 68 + drop, 25, 70 + drop)
            ..quadraticBezierTo(31, 68 + drop, 25, 58 + drop),
          Paint()..color = const Color(0xFF6EC6FF).withValues(alpha: tear < .7 ? 1 : (1 - tear) / .3),
        );
      }
      if (blink > 0) {
        // Párpados que bajan al parpadear.
        canvas.save();
        canvas.clipPath(Path()
          ..addOval(Rect.fromCircle(center: const Offset(36, 46), radius: 15.5))
          ..addOval(Rect.fromCircle(center: const Offset(68, 46), radius: 15.5)));
        canvas.drawRect(Rect.fromLTRB(0, 30, 104, 30 + 32 * blink), fill(feathers?.$2 ?? (night ? 0xFF8270F0 : 0xFFA86B45)));
        canvas.restore();
      }
    }
    canvas.drawPath(Path()..moveTo(46, 58)..lineTo(58, 58)..lineTo(52, 68)..close(), fill(0xFFF2A12B));
    if (!night) {
      final feet = Paint()
        ..color = const Color(0xFFF2A12B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(38, 108)..lineTo(44, 100)..lineTo(50, 108)
          ..moveTo(54, 108)..lineTo(60, 100)..lineTo(66, 108),
        feet,
      );
    }
    _paintAccessory(canvas);
  }

  void _paintAccessory(Canvas canvas) {
    Paint fill(int c) => Paint()..color = Color(c);
    switch (wearing) {
      case 'gorro':
        canvas.drawPath(Path()..moveTo(38, 24)..lineTo(66, 24)..lineTo(52, -6)..close(), fill(0xFFE5508E));
        canvas.drawCircle(const Offset(48, 14), 2.6, fill(0xFFFFC93C));
        canvas.drawCircle(const Offset(56, 18), 2.6, fill(0xFFFFC93C));
        canvas.drawCircle(const Offset(52, 5), 2.4, fill(0xFFFFFFFF));
        canvas.drawCircle(const Offset(52, -7), 5, fill(0xFFFFC93C));
      case 'lentes':
        final glass = fill(0xFF22223B);
        canvas.drawRRect(RRect.fromLTRBR(20, 36, 50, 56, const Radius.circular(8)), glass);
        canvas.drawRRect(RRect.fromLTRBR(54, 36, 84, 56, const Radius.circular(8)), glass);
        canvas.drawRect(const Rect.fromLTRB(48, 41, 56, 45), glass);
        canvas.drawLine(const Offset(25, 41), const Offset(31, 41), Paint()
          ..color = const Color(0x88FFFFFF)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
      case 'mono':
        final red = fill(0xFFE5484D);
        canvas.drawPath(Path()..moveTo(52, 84)..lineTo(36, 76)..lineTo(36, 92)..close(), red);
        canvas.drawPath(Path()..moveTo(52, 84)..lineTo(68, 76)..lineTo(68, 92)..close(), red);
        canvas.drawCircle(const Offset(52, 84), 5, fill(0xFFB8323A));
      case 'bufanda':
        final blue = fill(0xFF2EC4A6);
        canvas.drawRRect(RRect.fromLTRBR(22, 72, 82, 84, const Radius.circular(6)), blue);
        canvas.drawRRect(RRect.fromLTRBR(60, 76, 72, 104, const Radius.circular(5)), blue);
        final stripe = fill(0xFFFFFFFF);
        for (final x in [32.0, 44.0, 56.0, 68.0]) {
          canvas.drawRect(Rect.fromLTWH(x, 72, 4, 12), stripe);
        }
        canvas.drawRect(const Rect.fromLTWH(60, 94, 12, 4), stripe);
      case 'corona':
        canvas.drawPath(
          Path()
            ..moveTo(34, 26)..lineTo(34, 8)..lineTo(43, 17)..lineTo(52, 2)
            ..lineTo(61, 17)..lineTo(70, 8)..lineTo(70, 26)..close(),
          fill(0xFFFFC93C),
        );
        canvas.drawCircle(const Offset(52, 18), 3.2, fill(0xFFE5508E));
        canvas.drawCircle(const Offset(41, 21), 2.4, fill(0xFF2EC4A6));
        canvas.drawCircle(const Offset(63, 21), 2.4, fill(0xFF2EC4A6));
    }
  }

  @override
  bool shouldRepaint(_OwlPainter old) => old.night != night || old.wearing != wearing || old.feathers != feathers || old.mood != mood || old.blink != blink || old.tear != tear;
}

/// Owlito con vida en el menú, según su cara:
/// normal parpadea y se mece; feliz da saltitos con estrellitas; triste suspira y le cae una lágrima.
/// Con "reducir animaciones" del teléfono se queda quieto.
class LivelyOwl extends StatefulWidget {
  const LivelyOwl({super.key, this.size = 100, this.night = false, this.wearing, this.feathers, this.mood = OwlMood.normal});
  final double size;
  final bool night;
  final String? wearing;
  final (int, int, int)? feathers;
  final OwlMood mood;

  /// Las pruebas lo apagan para que `pumpAndSettle` no espere para siempre.
  static bool animate = true;

  @override
  State<LivelyOwl> createState() => _LivelyOwlState();
}

class _LivelyOwlState extends State<LivelyOwl> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = LivelyOwl.animate && !MediaQuery.disableAnimationsOf(context);
    if (on && !_c.isAnimating) {
      _c.repeat();
    } else if (!on) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final s = widget.size;
          var dx = 0.0, dy = 0.0, angle = 0.0, squash = 1.0, blink = 0.0;
          switch (widget.mood) {
            case OwlMood.normal:
              angle = math.sin(t * 2 * math.pi) * .05; // se mece
              blink = _blink(t, .46) + _blink(t, .52); // parpadea dos veces seguidas
            case OwlMood.happy:
              dy = -(math.sin(t * 6 * math.pi)).abs() * s * .08; // tres saltitos
              angle = math.sin(t * 6 * math.pi) * .04;
            case OwlMood.sad:
              final sigh = math.sin(t * 2 * math.pi).clamp(0, 1).toDouble(); // suspiro lento
              squash = 1 - sigh * .04;
              dy = sigh * s * .03;
              blink = _blink(t, .8) * .6;
          }
          final owl = Owl(
            size: s,
            night: widget.night,
            wearing: widget.wearing,
            feathers: widget.feathers,
            mood: widget.mood,
            blink: blink.clamp(0, 1).toDouble(),
            tear: widget.mood == OwlMood.sad ? (t * 2) % 1 : 0,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(dx, dy),
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(1, squash, 1)..rotateZ(angle),
                  child: owl,
                ),
              ),
              if (widget.mood == OwlMood.happy && _c.isAnimating)
                for (final (i, x) in [(0, -.12), (1, .92), (2, .4)])
                  _floatingStar(((t + i / 3) % 1), x, s),
            ],
          );
        },
      );

  /// Ojos cerrados un instante alrededor de [at] (0 a 1 del ciclo).
  static double _blink(double t, double at) {
    final d = (t - at).abs();
    return d > .025 ? 0 : 1 - d / .025;
  }

  /// Estrellita que sube desde Owlito y se desvanece.
  Widget _floatingStar(double k, double x, double s) => Positioned(
        left: s * x,
        top: s * (.25 - k * .6),
        child: IgnorePointer(
          child: Opacity(
            key: const Key('owl-star'),
            opacity: k < .2 ? k / .2 : 1 - (k - .2) / .8,
            child: CustomPaint(size: Size.square(s * .2), painter: const _StarPainter()),
          ),
        ),
      );
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final d = i.isEven ? r : r * .45;
      final pt = c + Offset(math.cos(a) * d, math.sin(a) * d);
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = AppColors.yellow);
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

/// Cielo de noche detrás del menú: estrellas y luna.
class NightSky extends StatelessWidget {
  const NightSky({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(child: CustomPaint(painter: _SkyPainter(), size: Size.infinite));
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final dot = Paint()..color = const Color(0xB3FFFFFF);
    for (final (x, y, r) in [(.10, 90.0, 2.0), (.30, 130.0, 1.6), (.54, 70.0, 2.2), (.9, 150.0, 1.8), (.2, 200.0, 1.4), (.72, 260.0, 1.5)]) {
      canvas.drawCircle(Offset(w * x, y), r, dot);
    }
    canvas.drawCircle(Offset(w - 60, 120), 30, Paint()..color = const Color(0xFFFFE9A8));
    canvas.drawCircle(Offset(w - 46, 110), 27, Paint()..color = const Color(0xFF1B1F4B));
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}
