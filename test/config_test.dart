import 'package:aprende_jugando/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los APK de prueba usan el anuncio de prueba y Play Store el real', () {
    const testBanner = 'ca-app-pub-3940256099942544/6300978111';
    if (Config.playRelease) {
      expect(Config.bannerAdUnitId, isNot(testBanner));
      expect(Config.bannerAdUnitId, startsWith('ca-app-pub-4226625652685681/'));
    } else {
      expect(Config.bannerAdUnitId, testBanner);
    }
  });
}
