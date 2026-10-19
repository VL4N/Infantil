#!/usr/bin/env python3
"""Genera los efectos de sonido de la app (assets/sonidos/*.mp3) con síntesis simple.

Uso: python3 tool/generar_sonidos.py  (necesita ffmpeg). Son sonidos propios, sin licencias de terceros.
"""
import math
import os
import struct
import subprocess
import tempfile
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sonidos")


def tone(freq, dur, vol=0.5, bright=0.25):
    """Una nota tipo campanita: armónicos suaves y caída rápida."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / 0.008) * math.exp(-5.5 * t / dur)
        s = math.sin(2 * math.pi * freq * t) + bright * math.sin(2 * math.pi * 2 * freq * t) + 0.08 * math.sin(2 * math.pi * 3 * freq * t)
        out.append(vol * env * s / (1 + bright + 0.08))
    return out


def mix(*parts):
    """Suma pistas que empiezan en distintos momentos: (inicio en segundos, muestras)."""
    total = max(int(start * RATE) + len(s) for start, s in parts)
    buf = [0.0] * total
    for start, s in parts:
        o = int(start * RATE)
        for i, v in enumerate(s):
            buf[o + i] += v
    peak = max(abs(v) for v in buf) or 1
    return [v / peak * 0.8 for v in buf]


def save(name, samples):
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "s.wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(struct.pack("<h", int(v * 32767)) for v in samples))
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-af", "adelay=60:all=1",
                        "-ac", "1", "-ar", str(RATE), "-codec:a", "libmp3lame", "-b:a", "64k",
                        os.path.join(OUT, name + ".mp3")], check=True)


C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0

# Acierto: arpegio corto y alegre (do-mi-sol-do).
save("acierto", mix((0, tone(C5, .25)), (.07, tone(E5, .25)), (.14, tone(G5, .25)), (.21, tone(C6, .45))))

# Fin de partida: fanfarria con brillo.
save("celebracion", mix(
    (0, tone(G5, .3)), (.12, tone(C6, .3)), (.24, tone(E6, .3)), (.36, tone(G6, .7)),
    (.36, tone(C6, .7, .35)), (.55, tone(E6 * 2, .25, .15)), (.68, tone(G6 * 2, .25, .12)),
))

# Voltear una carta o tocar algo: "pop" suave.
save("toque", mix((0, tone(880, .12, .6, .1)), (.03, tone(1320, .1, .3, .05))))
