/// Ajustes del modelo freemium. Cambia aquí qué es gratis, el producto y la publicidad.
class Config {
  // ---------- Contenido gratuito (lo demás requiere Premium) ----------
  static const freeMathMax = [5, 10];
  static const freeEnglishTopics = ['animales', 'frutas'];

  // ---------- Compra en Google Play ----------
  /// ID del producto "único" (no consumible) creado en Play Console.
  static const premiumProductId = 'premium_unlock';

  /// Código para que los revisores de Google Play (y verificadores) abran Premium sin pagar.
  /// Es largo (16 letras al azar) para que no se pueda adivinar a partir de esta huella.
  /// Aquí solo está su huella SHA-256; el código se da solo en Play Console.
  static const reviewCodeSha256 = 'cb8d36169eb9658810cd8c0d04c6a6180637f243c0f4963b06ad1f93812d6bbc';

  /// Precio que se muestra si la tienda aún no respondió. El real lo pone Google Play.
  static const fallbackPrice = 'US\$ 2,99';

  // ---------- Publicidad (AdMob) ----------
  static const adsEnabled = true;

  /// Solo la versión para Google Play usa anuncios reales; se compila con
  /// `--dart-define=PLAY_RELEASE=true`. Los APK de prueba muestran anuncios de
  /// prueba: tocar tus propios anuncios reales puede hacer que AdMob cierre la cuenta.
  static const playRelease = bool.fromEnvironment('PLAY_RELEASE');

  static const _realBannerAdUnitId = 'ca-app-pub-4226625652685681/7459328744';
  static const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const bannerAdUnitId = playRelease ? _realBannerAdUnitId : _testBannerAdUnitId;

  // ---------- Juego ----------
  static const roundsPerGame = 10;
}
