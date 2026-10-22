#!/usr/bin/env python3
"""Temporal: varias formas de decir "mono" con la voz en español, para elegir la que suena bien."""
import subprocess
import sys
import wave

from piper import PiperVoice, SynthesisConfig

model, out = sys.argv[1], sys.argv[2]
voice = PiperVoice.load(model)
variants = ["mono.", "Mono.", "¡Mono!", "móno.", "el mono.", "un mono.", "monito.", "Es un mono.", "mono mono."]
for i, text in enumerate(variants, 1):
    with wave.open("/tmp/v.wav", "wb") as w:
        voice.synthesize_wav(text, w, syn_config=SynthesisConfig(length_scale=1.1))
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", "/tmp/v.wav", "-af", "adelay=250:all=1,apad=pad_dur=0.15",
                    "-ac", "1", "-ar", "22050", "-codec:a", "libmp3lame", "-b:a", "64k", f"{out}/mono_{i}.mp3"], check=True)
    print(i, text)
