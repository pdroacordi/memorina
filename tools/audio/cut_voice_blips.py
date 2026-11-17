"""Cuts the dialogue voice blips from the Memorina's four note samples (SND-05, systems/dialogue).

    python -I tools/audio/cut_voice_blips.py

Each blip is a note's attack, BLIP_SECONDS long with a fast fade, leveled with cut_sfx.level() as one group, so the four
play alike and the voice cue's volume_db alone sets the level.
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_sfx import RATE, decode, finish, level, write_wav  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NOTES = os.path.join(ROOT, "assets", "audios", "sfx", "memorina")
OUT = os.path.join(ROOT, "assets", "audios", "sfx", "dialogue")
BLIP_SECONDS = 0.07  # s, long enough to hear the pitch, short enough for 13 blips a second
SOURCES = {
	"voice_01.wav": "note_down_c4.mp3",
	"voice_02.wav": "note_low_mid_d4.mp3",
	"voice_03.wav": "note_high_mid_e4.mp3",
	"voice_04.wav": "note_up_g4.mp3",
}


def main():
	rendered = {out: finish(decode(os.path.join(NOTES, src)), BLIP_SECONDS, fade_out=0.03) for out, src in SOURCES.items()}
	for out, x in level(rendered).items():
		write_wav(os.path.join(OUT, out), x)
		print(f"{out}: {len(x) / RATE:.3f} s")
	return 0


if __name__ == "__main__":
	sys.exit(main())
