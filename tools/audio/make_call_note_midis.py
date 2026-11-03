"""Writes each guardian's call-voice sketch (tools/audio/midi/chamado_<guardian>.mid): its four Memorina notes in
Enums.Note order (UP, DOWN, LEFT, RIGHT), one per 4/4 bar at 60 BPM: held 1.2 s from the bar's start, then silence,
so each note is cut to its own sample at 0, 4, 8, 12 s.

Run: python -I tools/audio/make_call_note_midis.py
Track names are the bare AIVA patch id. Pitch classes are always G C D E; only the octave differs per guardian.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_finale_midis as fm  # noqa: E402

# General MIDI programs for the proposed patches (AIVA ids to be checked in its patch search).
fm.GM.update({"w.alto-flute.nat.slur": 73, "w.pan-flute.nat.slur": 75, "w.piccolo.nat.slur": 72,
              "w.shakuhachi.nat.slur": 77})
GUARDIANS = {
    # guardian: (patch, octave shift from G4 C4 D4 E4, velocity)
    "frost": ("w.alto-flute.nat.slur", -1, 70),
    "bloom": ("w.pan-flute.nat.slur", 0, 74),
    "summer": ("w.piccolo.nat.slur", 1, 66),
    "autumn": ("w.shakuhachi.nat.slur", 0, 70),
}
NOTES = ["G4", "C4", "D4", "E4"]  # Enums.Note UP, DOWN, LEFT, RIGHT
HOLD = 1.2  # beats at 60 BPM = seconds


def shift(p, octaves):
    return p[:-1] + str(int(p[-1]) + octaves)


def main():
    fm.BEATS_PER_BAR = 4
    for name, (patch, octs, vel) in GUARDIANS.items():
        notes = [([shift(p, octs)], fm.bar(i + 1), HOLD, vel) for i, p in enumerate(NOTES)]
        print(fm.build("chamado_" + name, [(0, 60)], (4, 2), (0, 0), {patch: notes}))


if __name__ == "__main__":
    main()
