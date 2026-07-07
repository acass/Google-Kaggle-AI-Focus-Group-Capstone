#!/usr/bin/env python3
"""Generate narration WAVs with Gemini TTS (voice Charon) for the video/ composition.

Run with the backend venv (has google-genai):
    backend/.venv/bin/python scripts/gemini_tts.py

Reads GEMINI_API_KEY from the environment, falling back to backend/.env.
Gemini TTS returns raw PCM (16-bit, 24 kHz, mono); we wrap it into a .wav with the
stdlib wave module. Narration text is read verbatim from video/assets/audio/*.txt.

Never hardcode the key; never print it.
"""
import os
import sys
import wave
from pathlib import Path

from google import genai
from google.genai import types

REPO = Path(__file__).resolve().parent.parent
AUDIO_DIR = REPO / "video" / "assets" / "audio"
VOICE = "Charon"
# Gemini TTS model. gemini-2.5-flash-preview-tts is the known-good default; a
# TTS-capable model id is required (plain text models reject response_modalities=["AUDIO"]).
MODEL = os.environ.get("GEMINI_TTS_MODEL", "gemini-2.5-flash-preview-tts")

# Segments to (re)generate: the 6 existing ones + the new eval scene.
SEGMENTS = ["seg1", "seg2", "seg3", "seg4", "seg5", "seg6", "seg-eval"]


def load_api_key() -> str:
    key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if not key:
        env = REPO / "backend" / ".env"
        if env.exists():
            for line in env.read_text().splitlines():
                line = line.strip()
                if line.startswith("GEMINI_API_KEY=") or line.startswith("GOOGLE_API_KEY="):
                    key = line.split("=", 1)[1].strip().strip('"').strip("'")
                    if key:
                        break
    if not key:
        sys.exit("ERROR: GEMINI_API_KEY not set in env or backend/.env")
    return key


def synth(client: genai.Client, text: str, out: Path) -> None:
    resp = client.models.generate_content(
        model=MODEL,
        contents=text,
        config=types.GenerateContentConfig(
            response_modalities=["AUDIO"],
            speech_config=types.SpeechConfig(
                voice_config=types.VoiceConfig(
                    prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=VOICE)
                )
            ),
        ),
    )
    pcm = resp.candidates[0].content.parts[0].inline_data.data
    with wave.open(str(out), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(24000)
        w.writeframes(pcm)


def main() -> None:
    client = genai.Client(api_key=load_api_key())
    print(f"Model: {MODEL}  Voice: {VOICE}")
    for seg in SEGMENTS:
        txt = AUDIO_DIR / f"{seg}.txt"
        wav = AUDIO_DIR / f"{seg}.wav"
        if not txt.exists():
            sys.exit(f"ERROR: missing narration text {txt}")
        text = txt.read_text().strip()
        print(f"  {seg}: {len(text)} chars -> {wav.name}", flush=True)
        synth(client, text, wav)

    # Self-check: all files exist and are non-empty PCM.
    for seg in SEGMENTS:
        wav = AUDIO_DIR / f"{seg}.wav"
        assert wav.exists() and wav.stat().st_size > 44, f"bad wav: {wav}"
    print("OK: all WAVs generated.")


if __name__ == "__main__":
    main()
