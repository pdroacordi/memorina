"""Writes the Sombra (summer, shadow) sketches: the full piece and its reduced version (systems/music).

Run: python -I tools/audio/make_sombra_midis.py   (writes tools/audio/midi/sombra_*.mid)
The flute states C5 D5 E5 G5 G5 G5 alone at beat 0; a solo cello answers with the motif mirrored around D
(E D C A A A, two octaves down) one beat behind: the shadow on the ground.
Bars 1-2 of the full piece equal the reduced version, so one note_cues serves both.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_aiva_midis import Track, save  # noqa: E402

# The shadow is a solo cello: the mirror reaches A2, below a cello's C3.
FLUTE, CELLO, HARP, CONTRABASS = 73, 42, 46, 43
BPM = 90
N = {"A2": 45, "C2": 36, "D2": 38, "E2": 40, "F2": 41, "G2": 43, "A3": 57, "B3": 59, "C3": 48, "D3": 50,
     "E3": 52, "F3": 53, "G3": 55, "C4": 60, "D4": 62, "E4": 64, "F4": 65, "G4": 67, "A4": 69, "B4": 71,
     "C5": 72, "D5": 74, "E5": 76, "F5": 77, "G5": 79, "A5": 81, "B5": 83, "C6": 84}
MOTIF = ["C5", "D5", "E5", "G5", "G5", "G5"]
SHADOW = ["E3", "D3", "C3", "A2", "A2", "A2"]  # the motif mirrored around D (white keys map to white keys)
BEATS = [1, 1, 1, 1, 1, 3]  # bars 1-2; the last G holds through bar 2
# Harp chord shapes, low to high, all white keys.
SHAPE = {"C/G": ["G2", "C3", "E3", "G3", "C4", "E4"], "Am": ["A2", "E3", "A3", "C4", "E4", "A4"],
         "F": ["F2", "C3", "F3", "A3", "C4", "F4"], "Dm/G": ["G2", "D3", "F3", "A3", "D4", "F4"],
         "Em": ["E2", "B3", "E3", "G3", "B3", "E4"]}


def line(track, notes, beats, start, vel):
    t = start
    for n, b in zip(notes, beats):
        if n is not None:
            track.note(N[n], t, b, vel)
        t += b
    return t


def split(pairs):
    return [n for n, _ in pairs], [b for _, b in pairs]


def tracks():
    return (Track("Flauta (motivo)", FLUTE, 0), Track("Violoncelo solo (sombra)", CELLO, 1),
            Track("Harpa", HARP, 2), Track("Contrabaixo", CONTRABASS, 3))


def opening(flute, cello):
    """Bars 1-2: the motif alone at beat 0, its mirrored shadow one beat behind."""
    line(flute, MOTIF, BEATS, 0, 92)
    line(cello, SHADOW, [1, 1, 1, 1, 1, 2], 1, 62)


def harp_bar(harp, shape, bar, vel=58):
    tones = SHAPE[shape]
    pat = tones + [tones[4], tones[3]]
    for k in range(8):
        harp.note(N[pat[k]], bar * 4 + k * 0.5, 0.5 if k < 7 else 1.5, vel)


def reduced():
    flute, cello, harp, bass = tracks()
    opening(flute, cello)
    # Beat 8: C over a G pedal with the shadow's A under it (C6/G), held to 10.5 beats = 7.0 s.
    for n in SHAPE["C/G"]:
        harp.note(N[n], 8, 2.5, 60)
    bass.note(N["G2"], 8, 2.5, 66)
    cello.note(N["A2"], 8, 2.5, 50)
    return save("sombra_reduzida", BPM, [flute, cello, harp, bass])


def full():
    flute, cello, harp, bass = tracks()
    opening(flute, cello)
    # Bars 3-10 (A): the noon. Harp enters, G pedal, the flute grows the motif, the cello trails it.
    for i, c in enumerate(["C/G", "C/G", "F", "C/G", "Am", "F", "Dm/G", "C/G"]):
        harp_bar(harp, c, 2 + i)
        bass.note(N["G2"] if "/G" in c else N[SHAPE[c][0]], (2 + i) * 4, 4, 64)
    line(flute, *split([("C5", 1), ("D5", 1), ("E5", 1), ("G5", 1), ("A5", 2), ("G5", 2),
                        ("E5", 1), ("G5", 1), ("G5", 1), ("G5", 1), ("C6", 4),
                        ("A5", 1), ("G5", 1), ("E5", 1), ("D5", 1), ("C5", 2), ("E5", 2),
                        ("D5", 2), ("E5", 1), ("D5", 1), ("G5", 4)]), 8, 82)
    line(cello, *split([("E3", 2), ("C3", 2), ("C3", 4), ("A2", 4), ("C3", 4), ("A2", 4), ("A2", 4),
                        ("F3", 4), ("E3", 3)]), 9, 58)
    # Bars 11-18 (B): the shadow leads. The cello sings the mirror up an octave; the flute only answers G G.
    for i, c in enumerate(["Am", "Am", "F", "C/G", "Am", "Em", "F", "Dm/G"]):
        harp_bar(harp, c, 10 + i, 50)
        bass.note(N[SHAPE[c][0]], (10 + i) * 4, 4, 60)
    line(cello, *split([("E4", 1), ("D4", 1), ("C4", 1), ("A3", 1), ("A3", 1), ("A3", 3),
                        ("C4", 2), ("E4", 2), ("D4", 4),
                        ("E4", 1), ("D4", 1), ("C4", 1), ("A3", 1), ("A3", 1), ("A3", 3),
                        ("F3", 2), ("A3", 2), ("G3", 4)]), 40, 74)
    line(flute, *split([(None, 9), ("E5", 1), ("G5", 1), ("G5", 1), (None, 13), ("D5", 1), ("G5", 1), ("G5", 1)]),
         40, 64)
    # Bars 19-26 (A'): hero and shadow as one, the motif in flute with the cello in thirds below.
    t = 72
    for rep, chords in enumerate([["C/G", "C/G"], ["F", "C/G"], ["Am", "F"], ["Dm/G", "C/G"]]):
        line(flute, MOTIF, BEATS, t, 88 if rep % 2 == 0 else 80)
        line(cello, ["A4", "B4", "C5", "E5", "E5", "D5"] if rep % 2 else ["A4", "B4", "C5", "E5", "E5", "E5"],
             BEATS, t, 62)
        for i, c in enumerate(chords):
            harp_bar(harp, c, t // 4 + i, 62)
            bass.note(N["G2"] if "/G" in c else N[SHAPE[c][0]], t + i * 4, 4, 66)
        t += 8
    # Bars 27-34 (coda): the motif in halves, its shadow behind; the last G stays over C/G, unresolved.
    line(flute, MOTIF, [2, 2, 2, 2, 2, 10], 104, 78)
    line(cello, SHADOW, [2, 2, 2, 2, 2, 8], 106, 56)
    for i, c in enumerate(["C/G", "F", "C/G", "Am"]):
        harp_bar(harp, c, 26 + i, 48)
    for n in SHAPE["C/G"]:
        harp.note(N[n], 120, 12, 44)
    bass.note(N["G2"], 104, 28, 58)  # the pedal never falls to C
    return save("sombra_completa", BPM, [flute, cello, harp, bass])


if __name__ == "__main__":
    print(reduced(), full())
