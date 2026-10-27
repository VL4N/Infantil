#!/usr/bin/env python3
"""Graba con Piper todas las frases de la app (ver lib/logic/phrases.dart).

Uso: generar_voces.py frases.tsv voz_es.onnx voz_en.onnx carpeta_salida

frases.tsv viene de `dart run tool/export_phrases.dart` (archivo<TAB>idioma<TAB>texto).
Cada frase se guarda como Opus (.ogg) mono en carpeta_salida/<archivo>. Las que ya existen
se saltan (la carpeta se guarda en caché entre compilaciones de GitHub).
"""
import os
import subprocess
import sys
import tempfile
import wave


# Palabras que la voz pronuncia mal tal cual: se graban con otro texto (en la app se ven igual).
# Elegidas escuchando muestras: "mono" sola sonaba rara y "fresa" sonaba "flesa".
PRONUNCIATION = {
    ("es", "mono"): "el mono.",
    ("es", "fresa"): "fressa.",
}


# Palabras que suenan mal dentro de una frase: se graban escritas de otra forma.
WORD_FIXES = {"es": {"fresa": "fressa"}}


def fix_words(text: str, lang: str) -> str:
    import re

    for word, spoken in WORD_FIXES.get(lang, {}).items():
        text = re.sub(rf"\b{word}\b", spoken, text, flags=re.IGNORECASE)
    return text


def clip_name(text: str, lang: str) -> str:
    """Igual que clipName() en lib/logic/phrases.dart (FNV-1a de 64 bits)."""
    h = 0xCBF29CE484222325
    for byte in f"{lang}|{text}".encode("utf-8"):
        h = ((h ^ byte) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return f"{h:016x}.ogg"


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
    # Opus (hecho para voz) suena igual que el MP3 anterior ocupando menos de la mitad.
    # La voz en inglés (LJSpeech) pierde claridad con menos calidad: se guarda con un poco más.
    bitrate = {"es": "20k", "en": "24k"}
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
            fixed = PRONUNCIATION.get((lang, text))
            # Las de PRONUNCIATION se graban siempre (son pocas), por si la caché tiene la versión anterior.
            if os.path.exists(out) and fixed is None:
                skipped += 1
                continue
            wav = os.path.join(tmp, "frase.wav")
            # Con punto final la voz pronuncia entera una palabra suelta ("4" -> "cuatro.").
            spoken = fixed or fix_words(text if text[-1] in ".!?" else text + ".", lang)
            synthesize(voices[lang], spoken, wav, speed[lang])
            # Silencio al principio y al final: algunos teléfonos se comen el comienzo
            # del audio al empezar a sonar (la "c" de "cuatro").
            subprocess.run(
                ["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-af", "adelay=250:all=1,apad=pad_dur=0.15",
                 "-ac", "1", "-ar", "24000", "-codec:a", "libopus", "-application", "voip", "-b:a", bitrate[lang], out],
                check=True,
            )
            done += 1
    # Borra audios de frases que ya no existen (por ejemplo, de una versión anterior).
    wanted = {line.split("\t", 1)[0] for line in open(tsv, encoding="utf-8") if line.strip()}
    removed = 0
    for name in os.listdir(out_dir):
        if name not in wanted:
            os.remove(os.path.join(out_dir, name))
            removed += 1
    print(f"Frases grabadas: {done}, ya existían: {skipped}, borradas: {removed}")


if __name__ == "__main__":
    main()
