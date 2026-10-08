# Aprende Jugando 🧒

App web sencilla para que peques de 3 a 7 años practiquen:

- **Sumar** con dibujos para contar (niveles hasta 5, 10 y 20).
- **Inglés**: escuchan una palabra y tocan el dibujo correcto (animales, frutas, colores y números).

Cada acierto a la primera da una ⭐ (se guardan en el dispositivo). Sin anuncios, sin registro, sin internet una vez cargada.

## Cómo usarla

Abre `index.html` en el navegador del móvil, tablet u ordenador. No hace falta instalar nada.
La voz usa el sintetizador del propio dispositivo, así que suena mejor si tiene voces en español e inglés instaladas.

## Modelo freemium

Todo se ajusta en `config.js`.

| Gratis | Premium (pago único) |
|---|---|
| Sumas hasta 5 y hasta 10 | Sumas hasta 20 |
| Inglés: animales y frutas | Inglés: colores y números |
| Con publicidad (1 anuncio cada 2 partidas, solo en la pantalla final) | Sin publicidad |

- **Control parental**: para comprar o entrar en Premium hay que resolver una multiplicación (`monetization.js`).
- **Publicidad**: hoy es un espacio de prueba. Para publicar en tiendas hay que usar una red certificada para apps familiares (p. ej. AdMob con `tagForChildDirectedTreatment`) y anuncios **no personalizados** (COPPA / RGPD).
- **Compra**: hoy desbloquea directamente para probar. Falta conectar Google Play Billing / StoreKit.

### Pendiente para publicar en Google Play / App Store
1. Empaquetar la web como app nativa (p. ej. con Capacitor).
2. Conectar AdMob (modo infantil) y la compra dentro de la app.
3. Política de privacidad y formulario de "Familias" (Google) o categoría "Niños" (Apple).
