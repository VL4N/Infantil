/// Ajustes del modelo freemium. Cambia aquí qué es gratis, el producto y la publicidad.
class Config {
  // ---------- Contenido gratuito (lo demás requiere Premium) ----------
  static const freeMathMax = [5, 10];
  static const freeEnglishTopics = ['animales', 'frutas'];

  // ---------- Compra en Google Play ----------
  /// ID del producto "único" (no consumible) creado en Play Console.
  static const premiumProductId = 'premium_unlock';

  /// Precio que se muestra si la tienda aún no respondió. El real lo pone Google Play.
  static const fallbackPrice = 'US\$ 2,99';

  // ---------- Publicidad (AdMob) ----------
  static const adsEnabled = true;

  /// ID de bloque de anuncios de PRUEBA de Google. Antes de publicar, sustitúyelo
  /// por el tuyo de AdMob (y el App ID en android/app/src/main/AndroidManifest.xml).
  static const bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  // ---------- Juego ----------
  static const roundsPerGame = 10;
}
