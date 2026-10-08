# Aprende Jugando 🧒

App Android (Flutter) para que peques de 3 a 7 años practiquen **sumas** e **inglés**.
Modelo **freemium**: gratis con publicidad apta para niños, y Premium (pago único por Google Play) sin anuncios y con todo el contenido.

| Gratis | Premium |
|---|---|
| Sumas hasta 5 y hasta 10 | Sumas hasta 20 |
| Inglés: animales y frutas | Inglés: colores y números |
| Un anuncio en la pantalla final de cada partida | Sin publicidad |

- Voz del teléfono: español latino (`es-US`) e inglés (`en-US`).
- **Aprende de sus errores**: si se equivoca, no hay castigo. La voz le explica paso a paso
  (en sumas cuenta los dibujos con él uno a uno; en inglés le dice cómo se llama lo que tocó y cuál era),
  le señala la respuesta correcta y esa pregunta vuelve a salir unas rondas después como **repaso**.
- Control parental (multiplicación) antes de entrar a Premium o comprar.
- Anuncios AdMob en modo infantil: clasificación **G**, no personalizados, sin ID de publicidad y **nunca durante el juego**.

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

Cada vez que se sube código, GitHub Actions compila el APK
(pestaña **Actions → Android APK → aprende-jugando-apk**). Descárgalo e instálalo en un teléfono Android.

En tu ordenador (con Flutter y Android Studio instalados): `flutter run`.

## Publicar en Google Play (desde Ecuador)

1. **Cuenta de desarrollador** en [Play Console](https://play.google.com/console) (pago único de 25 USD).
2. **Perfil de pagos (comerciante)** en Play Console para cobrar. Los pagos llegan en USD a tu cuenta bancaria.
3. **Producto Premium**: en Play Console → *Monetizar → Productos → Productos únicos*, crea uno con el ID `premium_unlock` y su precio (p. ej. 2,99 USD).
4. **AdMob**: crea una cuenta en [admob.google.com](https://admob.google.com), registra la app y un bloque *Banner*.
   Cambia los IDs de prueba en `lib/config.dart` y `android/app/src/main/AndroidManifest.xml`.
   En AdMob marca la app como **dirigida a niños**.
5. **Firma de la app**: crea tu clave de subida y configúrala en `android/app/build.gradle.kts`
   (ahora usa la clave de depuración). Compila con `flutter build appbundle`.
6. **Ficha de la tienda**:
   - Público objetivo: menores de 13 → la app entra en el programa **Familias**.
   - Política de privacidad (URL pública, obligatoria).
   - Declarar que contiene anuncios y compras en la app.
7. Sube primero a **prueba interna** para probar la compra con cuentas de prueba (no se cobra) y luego a producción.
