import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFFFF8E7);
  static const ink = Color(0xFF2B2D42);
  static const yellow = Color(0xFFFFB703);
  static const blue = Color(0xFF219EBC);
  static const green = Color(0xFF52B788);
  static const red = Color(0xFFEF476F);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.yellow, surface: AppColors.bg),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink),
      ),
    );

/// Botón grande y redondeado, fácil de tocar para un niño.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.textColor = AppColors.ink,
    this.fontSize = 26,
    this.locked = false,
    this.stars,
    this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final double fontSize;
  final bool locked;

  /// Mejor resultado (0 a 3) que se muestra debajo del texto; null = no se muestra.
  final int? stars;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(24),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locked ? '$label 🔒' : label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                ),
                if (stars != null) StarRating(stars: stars!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contador de estrellas para la barra superior.
class StarCounter extends StatelessWidget {
  const StarCounter({super.key, required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Center(
          child: Text('⭐ $stars', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      );
}

/// Mejor resultado de un nivel o tema: ★★☆.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.stars, this.size = 26});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
        '★' * stars + '☆' * (3 - stars),
        semanticsLabel: '$stars de 3 estrellas',
        style: TextStyle(fontSize: size, color: AppColors.yellow, letterSpacing: 4),
      );
}
