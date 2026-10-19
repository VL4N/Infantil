# Aprende Jugando 🧒

App Android (Flutter) para que peques de 3 a 7 años practiquen **sumas** e **inglés**.
Modelo **freemium**: gratis con publicidad apta para niños, y Premium (pago único por Google Play) sin anuncios y con todo el contenido.

| Gratis | Premium |
|---|---|
| Sumas hasta 5 y hasta 10 | Sumas hasta 20 |
| Inglés: animales y frutas | Inglés: colores, números, cuerpo, ropa, familia y saludos |
| Un anuncio en la pantalla final de cada partida | Sin publicidad |

- Sumas en tres formatos que se mezclan en cada partida: "2 + 3 = ?", "2 + ? = 5" (cuánto falta)
  y, en el nivel "Hasta 5", "¿Cuántos hay?" para contar dibujos.
- Inglés en dos formatos que se mezclan: "escucha y toca el dibujo" y "mira el dibujo y elige la palabra"
  (cada palabra tiene un 🔊 para escucharla antes de elegir). También "How many?": contar dibujos
  y elegir el número en inglés (hasta 5; hasta 10 en el tema Números).
- **Parejas en inglés**: juego de memoria con 8 cartas para juntar cada dibujo con su palabra
  (la palabra se lee en voz alta al destaparla). Usa los mismos temas y candados que Inglés.
- Cada partida da de 0 a 3 estrellas; el mejor resultado de cada nivel y tema se ve en el menú.
- Voz del teléfono: español latino (`es-US`) e inglés (`en-US`).
- **Aprende de sus errores**: si se equivoca, no hay castigo. La voz le explica paso a paso
  (en sumas cuenta los dibujos con él uno a uno; en inglés le dice cómo se llama lo que tocó y cuál era),
  le señala la respuesta correcta y esa pregunta vuelve a salir unas rondas después como **repaso**.
- **Resumen para papás** (detrás del control parental): días jugados, partidas y mejor resultado
  de cada nivel o tema, y las palabras en inglés que más le cuestan.
- Control parental (multiplicación) antes de entrar a Premium, comprar o ver el resumen.
- Anuncios AdMob en modo infantil: clasificación **G**, no personalizados, sin ID de publicidad y **nunca durante el juego**.

## Icono

Búho generado con Higgsfield y centrado sobre fondo crema. Archivos en `assets/icon/`:
`icon_full.png` (icono completo), `icon_foreground.png` (capa del icono adaptable de Android)
y `play_store_512.png` (el de 512×512 que pide la ficha de Google Play).
Para regenerar los iconos de Android: `dart run flutter_launcher_icons`.

## Voz

La app trae su propia voz grabada (suena igual en todos los teléfonos, sin internet).
`lib/logic/phrases.dart` lista todas las frases; al compilar, GitHub Actions las graba con
[Piper](https://github.com/rhasspy/piper) (`tool/generar_voces.py`) y las incluye en `assets/voz/`.
Si falta alguna frase, la app usa la voz del teléfono. `test/phrases_test.dart` comprueba que no falte ninguna.

Voces (permiten uso comercial):
- Español: **es_MX "claude" (high)**, licencia Apache-2.0 ([HirCoir/Piper-TTS-Spanish](https://huggingface.co/spaces/HirCoir/Piper-TTS-Spanish)).
- Inglés: **en_US "ljspeech" (high)**, dataset LJ Speech de dominio público.

## Diseño

De día (7:00 a 18:59) la app usa el estilo "Caramelo" (rosa, menta y lila, letra Fredoka) y de
noche (19:00 a 6:59) el estilo "Noche estrellada" (azul oscuro con luna y estrellas, letra Nunito).
Los colores están en `lib/theme.dart` (`Palette.day` y `Palette.nightStyle`). Las letras están en
`assets/fonts/` con su licencia SIL Open Font License.

## Estructura

```
lib/
  config.dart            ← qué es gratis, ID del producto, IDs de anuncios
  logic/                 ← contenido y generación de preguntas
  services/billing.dart  ← compra con Google Play Billing
  services/ads.dart      ← AdMob (modo infantil)
  screens/               ← pantallas
test/                    ← pruebas automáticas
```

## Probar la app

El APK de la última versión está siempre en
**[Releases → última versión](https://github.com/VL4N/Infantil/releases/latest)** → `AprendeJugando.apk`.
Descárgalo en el teléfono Android y ábrelo (permite "instalar apps de origen desconocido").

Cada vez que se sube código a `main`, GitHub Actions comprueba la app, compila el APK y publica una versión nueva.

En tu ordenador (con Flutter y Android Studio instalados): `flutter run`.

## Publicar en Google Play (desde Ecuador)

Guía paso a paso, textos de la ficha y respuestas de los cuestionarios:
**[docs/publicar-en-google-play.md](docs/publicar-en-google-play.md)**.
Política de privacidad: `docs/privacidad.html` (publicada con GitHub Pages).

1. **Cuenta de desarrollador** en [Play Console](https://play.google.com/console) (pago único de 25 USD).
2. **Perfil de pagos (comerciante)** en Play Console para cobrar. Los pagos llegan en USD a tu cuenta bancaria.
3. **Producto Premium**: en Play Console → *Monetizar → Productos → Productos únicos*, crea uno con el ID `premium_unlock` y su precio (p. ej. 2,99 USD).
4. **AdMob** ✅: la app y el bloque *Banner* ya están creados y sus IDs puestos en `lib/config.dart`
   y `android/app/src/main/AndroidManifest.xml`. Los APK de prueba muestran anuncios de **prueba**;
   solo la versión para Google Play (compilada con `--dart-define=PLAY_RELEASE=true`) muestra los reales.
   **No toques nunca tus propios anuncios reales**: AdMob lo considera fraude.
5. **Firma de la app**: crea tu clave de subida y guárdala en los secretos de GitHub (ver la guía).
   Con eso, cada versión en Releases trae `AprendeJugando-GooglePlay.aab` listo para subir.
6. **Ficha de la tienda**:
   - Público objetivo: menores de 13 → la app entra en el programa **Familias**.
   - Política de privacidad (URL pública, obligatoria).
   - Declarar que contiene anuncios y compras en la app.
7. Sube primero a **prueba interna** para probar la compra con cuentas de prueba (no se cobra) y luego a producción.
