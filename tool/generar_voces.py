#!/usr/bin/env python3
"""Graba con Piper todas las frases de la app (ver lib/logic/phrases.dart).

Uso: generar_voces.py frases.tsv voz_es.onnx voz_en.onnx carpeta_salida

frases.tsv viene de `dart run tool/export_phrases.dart` (archivo<TAB>idioma<TAB>texto).
Cada frase se guarda como MP3 mono en carpeta_salida/<archivo>. Las que ya existen
se saltan (la carpeta se guarda en caché entre compilaciones de GitHub).
"""
import os
import subprocess
import sys
import tempfile
import wave


def clip_name(text: str, lang: str) -> str:
    """Igual que clipName() en lib/logic/phrases.dart (FNV-1a de 64 bits)."""
    h = 0xCBF29CE484222325
    for byte in f"{lang}|{text}".encode("utf-8"):
        h = ((h ^ byte) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return f"{h:016x}.mp3"


def synthesize(voice, text: str, wav_path: str, length_scale: float) -> None:
    with wave.open(wav_path, "wb") as wav:
        try:  # piper-tts >= 1.3
            from piper import SynthesisConfig

            voice.synthesize_wav(text, wav, syn_config=SynthesisConfig(length_scale=length_scale))
        except ImportError:  # versiones anteriores
            voice.synthesize(text, wav, length_scale=length_scale)


def main() -> None:
    tsv, model_es, model_en, out_dir = sys.argv[1:5]
    from piper import PiperVoice

    voices = {"es": PiperVoice.load(model_es), "en": PiperVoice.load(model_en)}
    # Un poco más despacio que lo normal, para niños pequeños.
    speed = {"es": 1.1, "en": 1.15}
    # La voz en inglés (LJSpeech) pierde claridad a 32 kbps: se guarda con más calidad.
    bitrate = {"es": "32k", "en": "64k"}
    os.makedirs(out_dir, exist_ok=True)
    done = skipped = 0
    with open(tsv, encoding="utf-8") as f, tempfile.TemporaryDirectory() as tmp:
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            name, lang, text = line.split("\t", 2)
            assert clip_name(text, lang) == name, f"hash distinto para {text!r}"
            out = os.path.join(out_dir, name)
            if os.path.exists(out):
                skipped += 1
                continue
            wav = os.path.join(tmp, "frase.wav")
            # Con punto final la voz pronuncia entera una palabra suelta ("4" -> "cuatro.").
            spoken = text if text[-1] in ".!?" else text + "."
            synthesize(voices[lang], spoken, wav, speed[lang])
            # Silencio al principio y al final: algunos teléfonos se comen el comienzo
            # del audio al empezar a sonar (la "c" de "cuatro").
            subprocess.run(
                ["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-af", "adelay=250:all=1,apad=pad_dur=0.15",
                 "-ac", "1", "-ar", "22050", "-codec:a", "libmp3lame", "-b:a", bitrate[lang], out],
                check=True,
            )
            done += 1
    # Borra audios de frases que ya no existen (por ejemplo, de una versión anterior).
    wanted = {line.split("\t", 1)[0] for line in open(tsv, encoding="utf-8") if line.strip()}
    removed = 0
    for name in os.listdir(out_dir):
        if name.endswith(".mp3") and name not in wanted:
            os.remove(os.path.join(out_dir, name))
            removed += 1
    print(f"Frases grabadas: {done}, ya existían: {skipped}, borradas: {removed}")


if __name__ == "__main__":
    main()
