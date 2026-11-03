"""Writes the region themes' sketches (tools/audio/midi/regiao_<id>.mid): two stems per region, `base` (always) and
`memoria` (its level follows the region's memory), with rests written into the loop.

Run: python -I tools/audio/make_region_midis.py
Track names are the bare AIVA patch id (the stem is the dict key). Nothing but a quoting lead sounds in C4..G4, where
the Memorina's notes sound. See docs/knowledge/music/region-themes.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_finale_midis as fm  # noqa: E402
from make_finale_midis import build  # noqa: E402

FLUTE, VIOLA, BASS, HARP, PIANO, CLAR = ("w.flute2.nat.slur", "s.solo-viola.nat.slur", "s.basses.vib.slur",
                                         "s.harp2.pizz.stac", "k.pop-piano.nat.stac", "w.clarinet1.nat.slur")
MOTIFS = {"enraizar": ["C5", "D5", "C5", "E5", "C5", "G5"], "congelar": ["G5", "E5", "D5", "C5", "C5", "C5"],
          "soltar": ["G5", "C5", "D5", "C5", "E5", "C5"], "sombra": ["C5", "D5", "E5", "G5", "G5", "G5"]}


def at(bpb, n, beat=0.0):
    return (n - 1) * bpb + beat


def tones(bpb, items, vel):
    """items: (pitches, bar, beat, length in beats)."""
    return [(p if isinstance(p, list) else [p], at(bpb, n, b), length, vel) for p, n, b, length in items]


def quote(bpb, motif, n, step, vel, last=3.0):
    return [([p], at(bpb, n, k * step), step * 0.95 if k < 5 else last, vel) for k, p in enumerate(MOTIFS[motif])]


def write(name, bpm, meter, key, tracks):
    fm.BEATS_PER_BAR = meter[0] if meter[1] == 2 else meter[0] / 2
    return build(name, [(0, bpm)], meter, key, tracks)


def village():
    # G major, 66 BPM, 3/4, 24 bars (65 s); bars 23-24 rest. Home: harp lullaby cells, the fullest and still gentle.
    b, harp, bass = 3, [], []
    chords = [("G2", ["D3", "B3"]), ("C2", ["G2", "E3"]), ("E2", ["B2", "G3"]), ("D2", ["A2", "F#3"])]
    for i in range(22):
        root, cell = chords[(i // 2) % 4]
        bass.append(([root], at(b, i + 1), 2.9, 46))
        harp += [([cell[0]], at(b, i + 1, 1), 0.9, 40), ([cell[1]], at(b, i + 1, 2), 0.9, 36)]
    flute = tones(b, [("B5", 5, 0, 2), ("A5", 5, 2, 1), ("G5", 6, 0, 3), ("E5", 7, 0, 1.5), ("G5", 7, 1.5, 1.5),
                      ("A5", 8, 0, 3), ("D6", 13, 0, 2), ("B5", 13, 2, 1), ("A5", 14, 0, 3), ("G5", 15, 0, 2),
                      ("E5", 15, 2, 1), ("D5", 16, 0, 3), ("B5", 19, 0, 1.5), ("A5", 19, 1.5, 1.5),
                      ("G5", 20, 0, 6)], 60)
    viola = tones(b, [(["B4", "D5"], n, 0, 5.8) for n in (5, 9, 13, 17)], 34)
    return write("regiao_home_village", 66, (3, 2), (1, 0), {
        HARP + " (base)": harp, BASS + " (base)": bass, FLUTE + " (memoria)": flute, VIOLA + " (memoria)": viola})


def threshold():
    # A Aeolian, 54 BPM, 4/4, 16 bars (71 s). Phrases of 2 bars, then 2 bars of rest; an open fifth, no third below.
    b = 4
    bass = tones(b, [("A1", n, 0, 7.5) for n in (1, 9)] + [("F1", 5, 0, 7.5), ("E1", 13, 0, 6)], 40)
    viola = tones(b, [(["E3", "A3"], 1, 0, 7), (["F3", "C5"], 5, 0, 7), (["E3", "A3"], 9, 0, 7),
                      (["E3", "B3"], 13, 0, 6)], 32)
    piano = tones(b, [("E6", 3, 0, 2), ("C6", 3, 3, 1), ("A5", 7, 2, 2), ("B5", 11, 0, 2), ("E6", 15, 1, 3)], 30)
    return write("regiao_threshold", 54, (4, 2), (0, 1), {
        BASS + " (base)": bass, VIOLA + " (base)": viola, PIANO + " (memoria)": piano})


def frost_edge():
    # Near silence: A, 40 BPM, 4/4, 16 bars (96 s). Four isolated tones and one low breath; no harmony, no memory stem.
    b = 4
    piano = tones(b, [("E6", 1, 0, 4), ("A5", 6, 2, 4), ("B5", 11, 0, 4), ("E6", 14, 3, 4)], 26)
    bass = tones(b, [("A1", 8, 0, 12)], 24)
    return write("regiao_frost_edge", 40, (4, 2), (0, 1), {PIANO + " (base)": piano, BASS + " (base)": bass})


def spring_woods():
    # G Mixolydian, 72 BPM, 6/8, 16 bars (40 s). Harp in dotted cells G | F (the b7, growing, unresolved);
    # the clarinet quotes Enraizar once at bar 9, the green guardian's own voice, then 3 bars of rest.
    b, harp = 3, []
    for n in range(1, 15):
        cell = ["G2", "D3", "B3"] if (n - 1) // 2 % 2 == 0 else ["F2", "C3", "A3"]
        harp += [([cell[0]], at(b, n), 1.4, 38), ([cell[2]], at(b, n, 1.5), 1.4, 32)]
    bass = tones(b, [("G1" if (n - 1) // 2 % 2 == 0 else "F1", n, 0, 5.8) for n in range(1, 14, 2)], 40)
    clar = quote(b, "enraizar", 9, 1.5, 54, last=4.5)
    viola = tones(b, [(["B4", "D5"], 5, 0, 5.8), (["A4", "C5"], 7, 0, 5.8)], 30)
    return write("regiao_spring_woods", 72, (6, 3), (1, 0), {
        HARP + " (base)": harp, BASS + " (base)": bass, CLAR + " (memoria)": clar, VIOLA + " (memoria)": viola})


def frozen_lake():
    # A minor, 50 BPM, 4/4, 16 bars (77 s). Long low dyads and silence; the flute quotes Congelar once at bar 9,
    # slow as the hymn (one beat per note), then 4 bars of rest.
    b = 4
    bass = tones(b, [("A1", 1, 0, 7), ("F1", 5, 0, 7), ("A1", 9, 0, 7), ("E1", 13, 0, 4)], 36)
    viola = tones(b, [(["E3", "A3"], 1, 0, 7), (["F3", "A3"], 5, 0, 7)], 28)
    flute = quote(b, "congelar", 9, 1.0, 50, last=6.0)
    piano = tones(b, [("A5", 3, 2, 2), ("E6", 7, 0, 2)], 26)
    return write("regiao_frozen_lake", 50, (4, 2), (0, 1), {
        BASS + " (base)": bass, VIOLA + " (base)": viola, FLUTE + " (memoria)": flute, PIANO + " (memoria)": piano})


def wind_orchards():
    # E Phrygian, 60 BPM, 3/4, 24 bars (72 s). The base is the viola's falling F-E sigh (bII-i), let go and left;
    # the flute quotes Soltar at bar 13, then 4 bars of rest.
    b = 3
    viola = tones(b, [(["F3", "A3"], n, 0, 2) for n in (1, 5, 9, 17)] +
                  [(["E3", "B3"], n + 1, 0, 2.8) for n in (1, 5, 9, 17)], 32)
    bass = tones(b, [("E1", n, 0, 5.8) for n in (1, 9, 17)], 34)
    flute = quote(b, "soltar", 13, 1.0, 50, last=5.0)
    harp = tones(b, [("B5", 3, 1, 1), ("A5", 7, 2, 1), ("G5", 11, 0, 1), ("F5", 19, 1, 1), ("E5", 21, 0, 2)], 30)
    return write("regiao_wind_orchards", 60, (3, 2), (0, 1), {
        VIOLA + " (base)": viola, BASS + " (base)": bass, FLUTE + " (memoria)": flute, HARP + " (memoria)": harp})


def summer_caldera():
    # C Lydian on a G pedal, 58 BPM, 4/4, 16 bars (66 s). Underground noon: the low piano holds G (Sombra's pedal),
    # the viola leans on F# (the raised fourth) and does not resolve; the flute quotes Sombra once at bar 9.
    b = 4
    piano = tones(b, [(["G1", "G2"], n, 0, 7.8) for n in (1, 5, 9, 13)], 30)
    viola = tones(b, [(["F#3", "B3"], 3, 0, 7), (["E3", "A3"], 11, 0, 7)], 28)
    flute = quote(b, "sombra", 9, 1.0, 48, last=5.0)
    harp = tones(b, [("F#5", 6, 0, 1), ("B5", 6, 1.5, 1), ("A5", 14, 2, 2)], 30)
    return write("regiao_summer_caldera", 58, (4, 2), (0, 0), {
        PIANO + " (base)": piano, VIOLA + " (base)": viola, FLUTE + " (memoria)": flute, HARP + " (memoria)": harp})


if __name__ == "__main__":
    for make in (village, threshold, frost_edge, spring_woods, frozen_lake, wind_orchards, summer_caldera):
        print(make())
