#!/usr/bin/env python3
"""Temporal: varias formas de decir "mono" y "fresa" con la voz en español, para elegir la que suena bien."""
import subprocess
import sys
import wave

from piper import PiperVoice, SynthesisConfig

model, out = sys.argv[1], sys.argv[2]
voice = PiperVoice.load(model)
variants = {
    "mono": ["mono.", "Mono.", "¡Mono!", "móno.", "el mono.", "un mono.", "monito.", "Es un mono."],
    "fresa": ["fresa.", "Fresa.", "¡Fresa!", "fressa.", "frresa.", "frrresa.", "f-resa.", "la fresa.", "una fresa."],
}
for word, texts in variants.items():
  for i, text in enumerate(texts, 1):
    with wave.open("/tmp/v.wav", "wb") as w:
        voice.synthesize_wav(text, w, syn_config=SynthesisConfig(length_scale=1.1))
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", "/tmp/v.wav", "-af", "adelay=250:all=1,apad=pad_dur=0.15",
                    "-ac", "1", "-ar", "22050", "-codec:a", "libmp3lame", "-b:a", "64k", f"{out}/{word}_{i}.mp3"], check=True)
    print(word, i, text)
