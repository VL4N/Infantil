import 'package:aprende_jugando/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('de 19:00 a 6:59 la app usa el estilo de noche', () {
    expect(Palette.isNightAt(DateTime(2026, 1, 1, 18, 59)), isFalse);
    expect(Palette.isNightAt(DateTime(2026, 1, 1, 19)), isTrue);
    expect(Palette.isNightAt(DateTime(2026, 1, 1, 0, 30)), isTrue);
    expect(Palette.isNightAt(DateTime(2026, 1, 1, 6, 59)), isTrue);
    expect(Palette.isNightAt(DateTime(2026, 1, 1, 7)), isFalse);
    expect(Palette.at(DateTime(2026, 1, 1, 12)), Palette.day);
    expect(Palette.at(DateTime(2026, 1, 1, 21)), Palette.nightStyle);
  });
}
