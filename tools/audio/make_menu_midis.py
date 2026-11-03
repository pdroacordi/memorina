"""Writes the title-screen theme's sketch (tools/audio/midi/menu_titulo.mid): one stem, a solo flute over a bass
pedal and a viola dyad, four 4-bar sections in the four seasons' modes (winter, spring, summer, autumn); each flute
phrase lands on one Memorina note (G, C, D, E) and is followed by silence. No song motif, no wife's song.

Run: python -I tools/audio/make_menu_midis.py
Track names are the bare AIVA patch id. See docs/knowledge/music/menu-theme.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_region_midis import FLUTE, VIOLA, BASS, tones, write  # noqa: E402


def title():
    # 56 BPM, 4/4, 16 bars (68.6 s), loops. Per section: phrase over bars 1-3, bar 4 near silence.
    b = 4
    # (season, bass, viola dyad, flute phrase landing on the Memorina note)
    sections = [
        ("A1", ["E3", "A3"], [("E6", 0, 2), ("D6", 2, 1), ("C6", 3, 1), ("B5", 4, 2), ("G5", 6, 5)]),     # winter, A Aeolian -> G
        ("G1", ["F3", "B3"], [("B5", 0, 1), ("D6", 1, 1), ("F6", 2, 2), ("E6", 4, 2), ("C6", 6, 5)]),     # spring, G Mixolydian -> C
        ("C2", ["F#3", "B3"], [("G5", 0, 1), ("A5", 1, 1), ("B5", 2, 2), ("A5", 4, 2), ("D6", 6, 5)]),    # summer, C Lydian -> D
        ("E1", ["F3", "A3"], [("A5", 0, 1), ("G5", 1, 1), ("F5", 2, 2), ("G5", 4, 2), ("E5", 6, 5)]),     # autumn, E Phrygian -> E
    ]
    flute, viola, bass = [], [], []
    for i, (root, dyad, phrase) in enumerate(sections):
        n = 4 * i + 1
        bass.append(([root], (n - 1) * b, 14.0, 34))
        viola.append((dyad, (n - 1) * b + 2, 10.0, 26))
        flute += [([p], (n - 1) * b + beat, length * 0.97, 50) for p, beat, length in phrase]
    return write("menu_titulo", 56, (4, 2), (0, 0), {FLUTE: flute, VIOLA: viola, BASS: bass})


if __name__ == "__main__":
    print(title())
