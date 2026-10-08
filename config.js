// Ajustes del modelo freemium. Cambia aquí qué es gratis, el precio y la publicidad.
const CONFIG = {
  // Contenido gratuito; todo lo demás requiere Premium.
  free: {
    mathMax: [5, 10],
    englishTopics: ['animales', 'frutas'],
  },

  premium: {
    price: '2,99 €',
    // Al publicar en Google Play / App Store, aquí va el ID del producto de la tienda.
    productId: 'premium_unlock',
  },

  ads: {
    enabled: true,
    // Mostrar un anuncio cada N partidas terminadas (nunca durante el juego).
    everyNGames: 2,
    // null = espacio de prueba. Al integrar una red de anuncios apta para niños
    // (p. ej. AdMob con "tagForChildDirectedTreatment"), se conecta en monetization.js.
    provider: null,
  },
};
