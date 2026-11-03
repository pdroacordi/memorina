"""Writes the final battle's sketches (tools/audio/midi/finale_*.mid): the fight loop with a separable spring layer,
the final call's underscore and the restoration cue.

Run: python -I tools/audio/make_finale_midis.py
Track names start with the AIVA patch id; one track per stem. Only the lead enters C4..G4, where the Memorina's
and the mentor's note voices sound. See docs/knowledge/music/final-battle.md.
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_miniature_midis import DRUMS, GM, PITCH, TPQ, chunk, vlq  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "midi")
PITCH = dict(PITCH, **{"A#" + str(o): 12 * (o + 1) + 10 for o in range(0, 8)})
BEATS_PER_BAR = 4


def line(notes, vel):
    return [([p], b, n, vel) for p, b, n in notes]


def bar(n, beat=0.0):
    return (n - 1) * BEATS_PER_BAR + beat


def octave_up(pitch):
    return pitch[:-1] + str(int(pitch[-1]) + 1)


def build(name, tempos, meter, key, tracks):
    conductor = [(0, 0, b"\xff\x58\x04" + bytes([meter[0], meter[1], 0x18, 0x08])),
                 (0, 0, b"\xff\x59\x02" + bytes([key[0] & 0xFF, key[1]]))]
    for beat, bpm in tempos:
        conductor.append((int(beat * TPQ), 1, b"\xff\x51\x03" + int(60e6 / bpm).to_bytes(3, "big")))
    out, pitched = [chunk(conductor)], 0
    for track, notes in tracks.items():
        # AIVA maps a track to a patch only when the name is the bare patch id; the stem stays in the dict key.
        patch = track.split(" ")[0]
        label = patch.encode()
        if patch.startswith("p."):
            ch, ev = DRUMS, [(0, 0, b"\xff\x03" + vlq(len(label)) + label)]
        else:
            ch, pitched = pitched, pitched + 1
            ev = [(0, 0, b"\xff\x03" + vlq(len(label)) + label), (0, 1, bytes([0xC0 | ch, GM[patch]]))]
        for pitches, beat, length, vel in notes:
            for p in pitches:
                ev.append((int(beat * TPQ), 3, bytes([0x90 | ch, PITCH[p], vel])))
                ev.append((int((beat + length) * TPQ) - 1, 2, bytes([0x80 | ch, PITCH[p], 0])))
        out.append(chunk(ev))
    path = os.path.join(OUT, name + ".mid")
    with open(path, "wb") as f:
        f.write(b"MThd" + struct.pack(">IHHH", 6, 1, len(out), TPQ) + b"".join(out))
    return path


# Fight loop: A minor, 80 BPM, 4/4, 16 bars (48 s), bar 16 loops to bar 1. Bars 1-2 open as the battle, not a song
# lesson: Am pedal (viola, piano), taiko ostinato, Congelar low in the basses; the flute first sings it at bar 13.
# The bed: Am Am | Am Am | F F | Dm Dm | Em Em | Am Am | F | G | Bb (bII, the crack) | Esus4. (bar, bass root, viola dyad, bars)
WINTER_CHORDS = [
    (3, "A1", ["E3", "A3"], 2), (5, "F1", ["F3", "A3"], 2), (7, "D2", ["F3", "A3"], 2), (9, "E1", ["E3", "B3"], 2),
    (11, "A1", ["E3", "A3"], 2), (13, "F1", ["F3", "A3"], 1), (14, "G1", ["G3", "B3"], 1),
    (15, "A#1", ["F3", "A#3"], 1), (16, "E1", ["E3", "A3"], 1)]
CONGELAR = ["G5", "E5", "D5", "C5", "C5", "C5"]
ENRAIZAR = ["C5", "D5", "C5", "E5", "C5", "G5"]


def fight():
    flute = [("A5", bar(9), 1.5), ("G5", bar(9, 1.5), 0.5), ("E5", bar(9, 2), 2), ("D5", bar(10), 1),
              ("E5", bar(10, 1), 3)]
    flute += [(p, bar(13, k), 1 if k < 5 else 2) for k, p in enumerate(CONGELAR)]
    flute += [("B4", bar(15), 2), ("A#4", bar(15, 2), 2), ("A4", bar(16), 3.5)]
    viola, basses, piano, taiko = [], [], [], []
    for n, root, dyad, length in WINTER_CHORDS:
        viola.append((dyad, bar(n), length * BEATS_PER_BAR - 0.25, 58))
        for half in range(length * 2):  # heavy half notes: the slow winter pattern
            basses.append(([root], bar(n, half * 2), 1.75, 70 if half % 2 == 0 else 60))
        piano.append(([root, octave_up(root)], bar(n), 0.5, 64))
    piano += [(["A5", "E6"], bar(n, 2), 0.5, 38) for n in (4, 8, 12)] + [(["B5", "E6"], bar(10, 2), 0.5, 38)]
    # Bars 1-2: Am pedal and Congelar two octaves down in the basses, under a driving eighth-note taiko ostinato.
    viola.append((["E3", "A3"], bar(1), 2 * BEATS_PER_BAR - 0.25, 58))
    piano += [(["A1", "A2"], bar(n, b), 0.5, 64 if b == 0 else 54) for n in (1, 2) for b in (0, 1.5, 3)]
    basses += [([p[0] + str(int(p[1]) - 3)], bar(1, k), 1 if k < 5 else 2.75, 76) for k, p in enumerate(CONGELAR)]
    for n in (1, 2):
        taiko += [(["B1"], bar(n, b), 0.1, v) for b, v in ((0, 80), (1, 52), (1.5, 60), (2, 72), (3, 56), (3.5, 64))]
    for n in range(3, 17):
        taiko += [(["B1"], bar(n), 0.1, 74), (["B1"], bar(n, 2), 0.1, 58)]
        if n % 2 == 0:
            taiko.append((["B1"], bar(n, 3.5), 0.1, 50))
    # Spring stem (revelation until the choice): G Mixolydian on a 1.5-beat grid (6/8 against the 4/4 bed); harp
    # G2-B3 and over A5; the clarinet sings Enraizar alone at bar 5 and half a beat behind the flute's Congelar at 13.
    harp, step, cells = [], 1.5, [["G2", "D3", "B3"], ["F2", "C3", "A3"]]
    for i in range(int(bar(3) / step), int(bar(17) / step)):
        cell = cells[(i // 4) % 2]
        harp.append(([cell[i % 3]], i * step, 0.5, 52))
        if i % 4 == 0:
            harp.append((["B5" if cell is cells[0] else "A5"], i * step + 0.75, 0.25, 40))
    clarinet = []
    for start in (bar(5), bar(13, 0.5)):
        clarinet += [([p], start + k * 1.5, 1.4 if k < 5 else 3, 66) for k, p in enumerate(ENRAIZAR)]
    return build("finale_luta", [(0, 80)], (4, 2), (0, 1), {
        "w.flute2.nat.slur (lead)": line(flute, 84),
        "s.solo-viola.nat.slur (inverno)": viola,
        "s.basses.vib.slur (inverno)": basses,
        "k.pop-piano.nat.stac (inverno)": piano,
        "p.taikos.nat.stac (inverno)": taiko,
        "s.harp2.pizz.stac (primavera)": harp,
        "w.clarinet1.nat.slur (primavera)": clarinet,
    })


def final_call():
    # Underscore under the two phrases: 60 BPM, 4 bars (16 s) looping, Am | Fmaj7 | Am(add9) | Fmaj7 on low basses and
    # high viola; phrase A ends on E and phrase B on C, both inside every chord. Nothing between C4 and G4.
    bass, viola, piano = [], [], []
    for n, (low, high) in enumerate([(["A1"], ["E5", "A5"]), (["F1", "A2"], ["E5", "A5"]),
                                     (["A1"], ["E5", "B5"]), (["F1", "A2"], ["E5", "A5"])]):
        bass.append((low, n * 4, 3.9, 50))
        viola.append((high, n * 4, 3.9, 40))
        piano.append((["E6"] if n % 2 == 0 else ["C6"], n * 4 + 2.5, 0.5, 30))
    return build("finale_chamado", [(0, 60)], (4, 2), (0, 1), {
        "s.basses.vib.slur": bass, "s.solo-viola.nat.slur": viola, "k.pop-piano.nat.stac": piano})


def restoration():
    # 100 BPM = mentor_winter.tres (beat 0.6 s). Beats 0-7.5 under his voice (not in this file): C pedal and high
    # violas, the fight's first C major. 7.5 the lamp: a harp run; 8 the flute plays phrase B (Ivo's E G E D D C)
    # over C Am F G C; the held C with A on top from 14 to 18.5 (~11.4 s with the ritardando).
    flute = [("E5", 8, 1), ("G5", 9, 1), ("E5", 10, 1.5), ("D5", 11.5, 0.5), ("D5", 12, 1), ("C5", 13, 5)]
    viola = [(["C5", "G5"], 0, 7.5, 34), (["E3", "G3"], 8, 2, 50), (["E3", "A3"], 10, 2, 50),
             (["F3", "A3"], 12, 1, 50), (["D3", "B3"], 13, 1, 50), (["E3", "G3"], 14, 4.5, 46)]
    basses = [(["C2"], 0, 7.5, 40), (["C2"], 8, 2, 56), (["A1"], 10, 2, 56), (["F1"], 12, 1, 56),
              (["G1"], 13, 1, 56), (["C2"], 14, 4.5, 50)]
    harp = line([("C3", 7.5, 0.25), ("G3", 7.75, 0.25), ("C4", 8, 0.25), ("E4", 8.25, 0.25), ("G4", 8.5, 0.25),
                 ("C5", 8.75, 0.5), ("G5", 14.5, 0.5), ("C6", 15.25, 0.5), ("A5", 16.25, 1.5)], 52)
    return build("finale_restauracao", [(0, 100), (14, 92), (16, 84)], (4, 2), (0, 0), {
        "w.flute2.nat.slur": line(flute, 78), "s.solo-viola.nat.slur": viola,
        "s.basses.vib.slur": basses, "s.harp2.pizz.stac": harp})


if __name__ == "__main__":
    for made in (fight(), final_call(), restoration()):
        print(made)
