#!/usr/bin/env bash
# Instala un APK, lo abre como un usuario y guarda captura + registro de errores.
# Imprime un resumen en el log de GitHub para poder leerlo sin descargar nada.
set -u
APK="$1"
PKG=com.owlitokids.aprendejugando
mkdir -p diagnostico
adb install -r "$APK" || { echo "::error::No se pudo instalar el APK"; exit 1; }
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 25
adb exec-out screencap -p > diagnostico/pantalla.png
adb logcat -d > diagnostico/logcat.txt
adb shell dumpsys activity top | head -40 > diagnostico/actividad.txt || true

echo "===== ¿Sigue viva la app? ====="
FALLO=0
adb shell pidof "$PKG" && echo "proceso vivo" || { echo "::error::la app no está corriendo (se cerró)"; FALLO=1; }

echo "===== Color de la pantalla ====="
python3 - <<'PY'
import struct, zlib
data = open("diagnostico/pantalla.png", "rb").read()
# Decodificador PNG mínimo (RGBA 8 bits, sin dependencias).
pos, chunks, w = 8, b"", 0
while pos < len(data):
    n = struct.unpack(">I", data[pos:pos+4])[0]; t = data[pos+4:pos+8]; body = data[pos+8:pos+8+n]
    if t == b"IHDR": w, h, depth, ctype = struct.unpack(">IIBB", body[:10])
    if t == b"IDAT": chunks += body
    pos += 12 + n
raw = zlib.decompress(chunks); bpp = 4 if ctype == 6 else 3; stride = w * bpp
rows, prev, i = [], bytearray(stride), 0
for _ in range(h):
    f = raw[i]; line = bytearray(raw[i+1:i+1+stride]); i += 1 + stride
    for x in range(stride):
        a = line[x-bpp] if x >= bpp else 0; b = prev[x]; c = prev[x-bpp] if x >= bpp else 0
        if f == 1: line[x] = (line[x] + a) & 255
        elif f == 2: line[x] = (line[x] + b) & 255
        elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
        elif f == 4:
            p = a + b - c; pa, pb, pc = abs(p-a), abs(p-b), abs(p-c)
            line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
    rows.append(line); prev = line
px = [(r[x], r[x+1], r[x+2]) for r in rows[::40] for x in range(0, stride, bpp*40)]
dark = sum(1 for p in px if sum(p) < 60) / len(px)
avg = tuple(sum(p[k] for p in px) // len(px) for k in range(3))
print(f"tamaño {w}x{h}, color medio {avg}, píxeles negros {dark:.0%}")
if dark > 0.9:
    print("::error::PANTALLA NEGRA en Android 16")
    open("diagnostico/negra", "w").close()
PY
[ -f diagnostico/negra ] && FALLO=1

echo "===== Errores en el registro ====="
grep -E "FATAL|AndroidRuntime|E flutter|flutter :|Flutter|Impeller|$PKG|UnsatisfiedLink|dlopen|libflutter|libapp" diagnostico/logcat.txt | head -150
exit $FALLO
