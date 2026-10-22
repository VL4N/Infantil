#!/usr/bin/env python3
"""Temporal: graba las mismas frases con varias voces en inglés de Piper para compararlas."""
import os
import subprocess
import sys
import wave

from piper import PiperVoice, SynthesisConfig

PHRASES = [
    "What number comes next?",
    "Great job! You are a star!",
    "Let's count together: one, two, three, four, five.",
    "You won a new sticker!",
    "Oops! Let's try again. Touch the seven.",
]
ES = ["¿Qué número sigue?", "¡Muy bien! ¡Eres una estrella!", "Contamos juntos: uno, dos, tres, cuatro, cinco."]

models, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
for f in sorted(os.listdir(models)):
    if not f.endswith(".onnx"):
        continue
    name = f[:-5]
    voice = PiperVoice.load(os.path.join(models, f))
    phrases = ES if name.startswith("es_") else PHRASES
    wav = "/tmp/m.wav"
    with wave.open(wav, "wb") as w:
        for i, text in enumerate(phrases):
            voice.synthesize_wav(text, w, syn_config=SynthesisConfig(length_scale=1.15), set_wav_format=(i == 0))
    for kbps in (["32"] + (["64"] if "ljspeech" in name else [])):
        suffix = "" if kbps == "32" else f"_{kbps}k"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-af", "apad=pad_dur=0.2", "-ac", "1",
                        "-ar", "22050", "-codec:a", "libmp3lame", "-b:a", f"{kbps}k", f"{out}/{name}{suffix}.mp3"], check=True)
    print("ok", name)
