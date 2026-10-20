# Publicar «Aprende Jugando» en Google Play

## 1. Crear la clave de subida (una sola vez)

La clave firma la app para Google Play. **Guárdala muy bien** (copia en una memoria USB o en tu nube):
si la pierdes, Google Play te puede dar una nueva, pero tarda varios días.

En un ordenador con Java instalado (viene con Android Studio), abre una terminal y escribe:

```
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Te pedirá una contraseña (anótala) y tus datos (nombre, ciudad, país `EC`). Se crea el archivo `upload-keystore.jks`.

Después conviértelo a texto para guardarlo en GitHub:

- **Windows (PowerShell):** guarda el texto en un archivo y ábrelo con el Bloc de notas:
  ```
  [Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\Documents\upload-keystore.jks")) | Out-File -Encoding ascii "$HOME\Documents\clave.txt"
  notepad "$HOME\Documents\clave.txt"
  ```
  En el Bloc de notas: **Ctrl+A** y **Ctrl+C**. El texto empieza con `MII` y es una sola línea muy larga.
  Después de guardarlo en GitHub, borra `clave.txt`.
- **Mac:** `base64 -i upload-keystore.jks | pbcopy`
- **Linux:** `base64 -w0 upload-keystore.jks`

(En Windows y Mac el texto queda copiado; en Linux cópialo de la pantalla.)

## 2. Guardar la clave en GitHub

En el repositorio: **Settings → Secrets and variables → Actions → New repository secret**. Crea estos cuatro:

| Nombre | Valor |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | el texto largo del paso anterior |
| `ANDROID_KEYSTORE_PASSWORD` | la contraseña que pusiste |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | la misma contraseña |

Desde ese momento, cada versión nueva en
[Releases](https://github.com/VL4N/Infantil/releases/latest) trae también **AprendeJugando-GooglePlay.aab**:
ese es el archivo que se sube a Play Console (con los anuncios reales activados).
El APK de prueba sigue igual, con anuncios de prueba.

## 3. Activar la página de la política de privacidad

En el repositorio: **Settings → Pages → Build and deployment → Source: Deploy from a branch**,
rama `main`, carpeta `/docs`, y **Save**. A los pocos minutos queda en:

**https://vl4n.github.io/Infantil/privacidad.html** ← este enlace va en Play Console.

## 4. Ficha de la tienda (textos para copiar)

**Nombre de la app** (máx. 30 caracteres):

> Aprende Jugando: Sumas e Inglés

**Descripción breve** (máx. 80 caracteres):

> Sumas, restas e inglés para niños de 3 a 7 años, con voz y sin castigos.

**Descripción completa:**

> Aprende Jugando es una app para que niñas y niños de 3 a 7 años practiquen sumas, restas e inglés jugando, con Owlito, un búho que los acompaña.
>
> ➕ SUMAS Y ➖ RESTAS
> • "2 + 3 = ?", "2 + ? = 5", "5 − 2 = ?" y contar dibujos.
> • Niveles hasta 5, hasta 10 y hasta 20.
>
> 🇬🇧 INGLÉS
> • Escucha y toca el dibujo, o mira el dibujo y elige la palabra.
> • "How many?": cuenta y elige el número en inglés.
> • Parejas: juego de memoria para juntar cada dibujo con su palabra.
> • 13 temas: animales, frutas, colores, números, cuerpo, ropa, familia, saludos, comida, casa, escuela, clima y acciones.
>
> 💡 APRENDE DE SUS ERRORES
> Si se equivoca no hay castigo: una voz natural le explica paso a paso, le muestra la respuesta correcta y esa pregunta vuelve a salir más tarde como repaso.
>
> ⭐ ESTRELLAS Y TIENDA DE OWLITO
> Cada respuesta correcta da una estrella para vestir a Owlito: gorros, lentes, corona y plumas de colores.
>
> 🌙 DE DÍA Y DE NOCHE
> De día la app es colorida y de noche cambia sola a colores suaves para cansar menos la vista.
>
> 👨‍👩‍👧 PARA PAPÁS Y MAMÁS
> • Varios niños en el mismo teléfono, cada uno con su progreso.
> • Resumen con los días jugados, los resultados y las palabras que más le cuestan.
> • Recordatorio diario opcional.
> • Control parental antes de comprar o entrar a la zona de papás.
> • Sin cuentas, sin chat y sin pedir datos personales. Funciona sin internet.
>
> GRATIS Y PREMIUM
> Gratis: sumas y restas hasta 5 y hasta 10, inglés con animales y frutas, y un anuncio apto para niños solo al terminar cada partida (nunca durante el juego).
> Premium (pago único): todos los niveles y temas, y sin publicidad.

**Gráficos que pide la ficha:**
- Icono 512×512: `assets/icon/play_store_512.png` (ya está).
- Imagen destacada 1024×500: falta.
- Capturas del teléfono: mínimo 2 (menú de día, menú de noche, una resta, una pregunta de inglés, la tienda de Owlito).

## 5. Respuestas para los cuestionarios de Play Console

**Público objetivo y contenido:** edades 5 y menos, 6 a 8. La app es para niños → programa Familias.

**Anuncios:** Sí, la app contiene anuncios (AdMob, certificado para Familias).

**Compras en la app:** Sí (Premium, pago único, ID `premium_unlock`).

**Seguridad de los datos** (lo que declaramos):
- ¿Recopila o comparte datos? **Sí**, solo por los anuncios de AdMob en la versión gratuita
  (lo que Google indica para su SDK de anuncios):
  *Ubicación aproximada* (por la IP), *Actividad en la app → Interacciones con la app*,
  *Información y rendimiento de la app → Registros de fallos y Diagnóstico* e
  *Identificadores del dispositivo u otros* (no el ID de publicidad, que está desactivado).
  Finalidad: **Publicidad o marketing** y **Prevención de fraudes, seguridad**. No es opcional. No se vende.
- ¿Los datos se cifran en tránsito? **Sí** (AdMob usa HTTPS).
- ¿Se pueden borrar? El progreso del juego vive solo en el teléfono y se borra al desinstalar la app.
- Compras: las procesa Google Play; la app no recibe datos de pago.

**Clasificación de contenido (IARC):** categoría "Juegos" o "Educación"; sin violencia, sin lenguaje,
sin contenido sexual, sin apuestas, sin interacción entre usuarios, sin compartir ubicación.
Resultado esperado: apto para todos (PEGI 3 / Everyone).

## 6. Prueba cerrada (cuentas personales nuevas)

Si tu cuenta de desarrollador es **personal** y se creó después de noviembre de 2023, Google pide
una **prueba cerrada con al menos 12 personas durante 14 días seguidos** antes de publicar en producción.
Sube el `.aab` a *Pruebas → Prueba cerrada*, agrega los correos de Gmail de familiares o amigos
y pídeles que la instalen desde el enlace de prueba y la abran de vez en cuando.
