"""Writes the restoration's remade sketches (tools/audio/midi/restauracao_epica*.mid), proposal of 2026-11-18.

Run: python -I tools/audio/make_restoration_midis.py
One stem ("all"), one-shot, 100 BPM (mentor_winter's beat, 0.6 s), C major: the resolution of the fight's A minor.
Beat 0 is the first note of his song (G E D C C C, beats 1 1 1 1 1 2.5, his note samples, not in this file); under
it nothing sounds in MIDI 60..67 and only C D E G A. The lamp lights at beat 7.5 (4.5 s).
- restauracao_epica.mid fits the scene as it is (11.1 s; last note-off 10.7 s).
- restauracao_epica_longa.mid needs the scene 6 s longer (17.1 s; last note-off 15.9 s): the fight's theme (phrase A)
  healed into C major, then Ivo's phrase B on the first perfect cadence of the score.
Track names are "<AIVA patch id> (all)"; PATCHES names the AIVA patch each is set to. See
docs/knowledge/music/final-battle.md.
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_miniature_midis import TPQ, chunk, vlq  # noqa: E402
from make_finale_fight_midis import p  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "midi")
DRUM_CHANNEL = 9
VOICE_END = 7.5     # beats: his last C ends here (4.5 s); the lamp lights
SAFE = {0, 2, 4, 7, 9}

PATCHES = {
    "w.flute2.nat.slur": (73, "Flute 2 Legato", True), "b.horns.nat.slur": (60, "9 Horns Legato", False),
    "v.choir.nat.slur": (52, "Male Choir Sustain", False), "s.violins.nat.slur": (48, "Violins 1 Sustain", False),
    "s.cellos.nat.slur": (42, "Celli Legato", False), "s.basses.vib.slur": (43, "Basses Vibrato Legato", True),
    "s.harp2.pizz.stac": (46, "Harp 2 Pizzicato", True), "k.celesta.nat.stac": (8, "Celesta Staccato", False),
    "p.timpani.nat.stac": (47, "Timpani Hits", False),
    "p.orchestral-kit.nat.stac": (None, "Orchestral Kit (41 Crash Left)", True),
}
DRUM_KITS = ("p.orchestral-kit.nat.stac",)
CRASH = 41

PHRASE_A = ["G", "E", "D", "C", "D", "E"]
PHRASE_B = ["E", "G", "E", "D", "D", "C"]


def n(*names):
    return [p(x) for x in names]


def under_his_song():
    """Beats 0-7.5: the fight's A minor one last time, then C as his C C C holds: Am7 | G (no B) | C."""
    return {
        "s.basses.vib.slur": [(n("A1"), 0, 2, 52), (n("G1"), 2, 2, 54), (n("C2"), 4, 3.5, 60)],
        "s.cellos.nat.slur": [(n("A2", "E3"), 0, 2, 48), (n("G2", "D3"), 2, 2, 50), (n("C3", "G3"), 4, 3.5, 58)],
        "v.choir.nat.slur": [(n("A2", "E3"), 0, 2, 40), (n("G2", "D3"), 2, 2, 44), (n("C3", "G3", "E3"), 4, 3.5, 54)],
        "s.violins.nat.slur": [(n("E5", "A5"), 0, 2, 36), (n("D5", "G5"), 2, 2, 40), (n("E5", "G5", "C6"), 4, 3.5, 52)],
        "b.horns.nat.slur": [(n("C3", "G3"), 4, 3.5, 50)],
        # A roll under the held C into the lamp, then the stroke.
        "p.timpani.nat.stac": [(n("G2"), 5.5 + k * 0.125, 0.12, 36 + 3 * k) for k in range(16)],
    }


def lamp(at):
    """The lamp lights at beat `at`: crash, timpani, a harp sweep up C major, celesta sparks."""
    sweep = ["C3", "E3", "G3", "C4", "E4", "G4", "C5", "E5", "G5", "C6"]
    return {
        "p.orchestral-kit.nat.stac": [([CRASH], at, 0.1, 104)],
        "p.timpani.nat.stac": [(n("C3"), at, 0.5, 108)],
        "s.harp2.pizz.stac": [(n(x), at + k * 0.125, 0.5, 70 + 2 * k) for k, x in enumerate(sweep)],
        "k.celesta.nat.stac": [(n(x), at + 0.5 + k * 0.5, 0.5, 64) for k, x in enumerate(["C7", "G6", "E6", "G6", "C7"])],
    }


def merge(*parts):
    out = {}
    for part in parts:
        for k, v in part.items():
            out.setdefault(k, []).extend(v)
    return out


def six(names, octave, start, rhythm, vel):
    return [(n(x + str(octave)), start + o, ln - 0.05, vel) for x, (o, ln) in zip(names, rhythm)]


def short():
    """Fits 11.1 s: the lamp at 7.5, Ivo's phrase B from beat 8 over C Am F G, C with A on top from 15."""
    b = [(0, 1), (1, 1), (2, 1.5), (3.5, 0.5), (4, 1), (5, 4.6)]  # E G E. D | D C___
    tracks = merge(under_his_song(), lamp(VOICE_END), {
        "w.flute2.nat.slur": six(PHRASE_B, 5, 8, b, 88),
        "b.horns.nat.slur": [(n("C4", "E4", "G4"), 7.5, 0.5, 96)] + six(PHRASE_B, 4, 8, b, 82),
        "v.choir.nat.slur": [(n("C3", "G3", "E4"), 7.5, 2.5, 78), (n("A2", "E3", "C4"), 10, 1.5, 76),
                             (n("F2", "C3", "A3"), 11.5, 0.5, 74), (n("G2", "D3", "B3"), 12, 1, 78),
                             (n("C3", "G3", "E4"), 13, 1, 82), (n("F2", "C3", "A3"), 14, 1, 76),
                             (n("C3", "G3", "E4"), 15, 2.6, 80)],
        "s.violins.nat.slur": [(n("E6", "G6"), 7.5, 2.5, 70), (n("E6", "A6"), 10, 1.5, 68), (n("C6", "A6"), 11.5, 0.5, 66),
                               (n("B5", "G6"), 12, 1, 70), (n("C6", "G6"), 13, 2, 74), (n("G5", "A5", "E6"), 15, 2.6, 72)],
        "s.cellos.nat.slur": [(n("C3", "G3"), 7.5, 2.5, 72), (n("A2", "E3"), 10, 1.5, 70), (n("F2", "C3"), 11.5, 0.5, 70),
                              (n("G2", "D3"), 12, 1, 74), (n("C3", "G3"), 13, 1, 76), (n("F2", "A2"), 14, 1, 70),
                              (n("C3", "G3"), 15, 2.6, 72)],
        "s.basses.vib.slur": [(n("C2"), 7.5, 2.5, 80), (n("A1"), 10, 1.5, 76), (n("F1"), 11.5, 0.5, 76),
                              (n("G1"), 12, 1, 80), (n("C2"), 13, 4.6, 78)],
        "k.celesta.nat.stac": [(n("A6"), 15.5, 2, 58)],  # the A over the last C: her song's lost note
    })
    return tracks, [(0, 100), (15, 92)]


def long():
    """Needs 17.1 s: the lamp at 7.5; the horns and choir sing phrase A (the fight's theme) in C, its E now on C (the
    tritone healed into a major third); Ivo's phrase B from 15, its D D over G and its C on the first V-I; F/C, then C
    with A on top."""
    a = [(0, 1), (1, 1), (2, 1), (3, 1), (4, 1), (5, 2)]
    b = [(0, 1), (1, 1), (2, 1.5), (3.5, 0.5), (4, 1), (5, 6)]
    tracks = merge(under_his_song(), lamp(VOICE_END), {
        "b.horns.nat.slur": [(n("C4", "E4", "G4"), 7.5, 0.5, 96)] + six(PHRASE_A, 4, 8, a, 96)
                            + six(PHRASE_B, 4, 15, b, 80),
        "v.choir.nat.slur": six(PHRASE_A, 3, 8, a, 84)
                            + [(n("C3", "G3", "E4"), 15, 2, 74), (n("A2", "E3", "C4"), 17, 1.5, 74),
                               (n("F2", "C3", "A3"), 18.5, 0.5, 72), (n("G2", "D3", "B3"), 19, 1, 80),
                               (n("C3", "G3", "E4"), 20, 2, 86), (n("F2", "C3", "A3"), 22, 1, 76),
                               (n("C3", "G3", "E4"), 23, 3, 80)],
        "w.flute2.nat.slur": six(PHRASE_B, 5, 15, b, 90),
        "s.violins.nat.slur": [(n("E6", "G6"), 7.5, 1.5, 70), (n("E6", "A6"), 9, 1, 70), (n("D6", "A6"), 10, 1, 70),
                               (n("E6", "G6"), 11, 1, 72), (n("D6", "B6"), 12, 1, 74), (n("E6", "G6", "C7"), 13, 2, 80),
                               (n("E6", "G6"), 15, 2, 70), (n("E6", "A6"), 17, 1.5, 68), (n("C6", "A6"), 18.5, 0.5, 66),
                               (n("B5", "G6"), 19, 1, 74), (n("C6", "G6"), 20, 3, 78), (n("G5", "A5", "E6"), 23, 3, 72)],
        "s.cellos.nat.slur": [(n("C3", "G3"), 7.5, 1.5, 74), (n("A2", "E3"), 9, 1, 72), (n("F2", "C3"), 10, 1, 72),
                              (n("C3", "G3"), 11, 1, 74), (n("G2", "D3"), 12, 1, 76), (n("C3", "G3"), 13, 2, 80),
                              (n("C3", "G3"), 15, 2, 70), (n("A2", "E3"), 17, 1.5, 70), (n("F2", "C3"), 18.5, 0.5, 70),
                              (n("G2", "D3"), 19, 1, 78), (n("C3", "G3"), 20, 2, 80), (n("F2", "A2"), 22, 1, 70),
                              (n("C3", "G3"), 23, 3, 72)],
        "s.basses.vib.slur": [(n("C2"), 7.5, 1.5, 80), (n("A1"), 9, 1, 78), (n("F1"), 10, 1, 78), (n("C2"), 11, 1, 78),
                              (n("G1"), 12, 1, 82), (n("C2"), 13, 2, 84), (n("C2"), 15, 2, 74), (n("A1"), 17, 1.5, 74),
                              (n("F1"), 18.5, 0.5, 74), (n("G1"), 19, 1, 82), (n("C2"), 20, 6, 82)],
        "p.timpani.nat.stac": [(n("G2"), 19, 0.5, 90), (n("C3"), 20, 0.5, 100)],
        "s.harp2.pizz.stac": [(n(x), 20 + k * 0.25, 0.5, 62) for k, x in enumerate(["C4", "E4", "G4", "C5", "E5", "G5"])],
        "k.celesta.nat.stac": [(n("A6"), 23.5, 2.5, 58)],
    })
    return tracks, [(0, 100), (22, 90)]


def seconds(beat, tempos):
    out, (b0, bpm) = 0.0, tempos[0]
    for b1, bpm1 in tempos[1:]:
        if beat <= b1:
            break
        out += (b1 - b0) * 60 / bpm
        b0, bpm = b1, bpm1
    return out + (beat - b0) * 60 / bpm


def check(tracks, tempos, limit_s):
    problems, last = [], 0.0
    for name, notes in tracks.items():
        drum = name in DRUM_KITS
        for pitches, start, length, vel in notes:
            last = max(last, seconds(start + length, tempos))
            if not 1 <= vel <= 127:
                problems.append(f"{name}: velocity {vel}")
            if drum:
                problems += [f"{name}: unmapped drum {q}" for q in pitches if q != CRASH]
                continue
            if start < VOICE_END - 1e-6 and not name.startswith("p.timpani"):
                for q in pitches:
                    if 60 <= q <= 67 or q % 12 not in SAFE:
                        problems.append(f"{name}: {q} at beat {start} under his song")
            if start < VOICE_END - 1e-6 and name.startswith("p.timpani") and any(q % 12 not in SAFE for q in pitches):
                problems.append(f"{name}: unsafe timpani under his song")
    if last > limit_s:
        problems.append(f"last note-off {last:.2f} s past {limit_s} s")
    flute = sorted(tracks["w.flute2.nat.slur"], key=lambda e: e[1])
    if [q % 12 for ps, *_ in flute for q in ps] != [4, 7, 4, 2, 2, 0]:
        problems.append("the flute is not exactly phrase B")
    return problems, last


def build(name, tracks, tempos):
    conductor = [(0, 0, b"\xff\x58\x04" + bytes([4, 2, 0x18, 0x08])), (0, 0, b"\xff\x59\x02" + bytes([0, 0]))]
    conductor += [(int(b * TPQ), 1, b"\xff\x51\x03" + int(60e6 / bpm).to_bytes(3, "big")) for b, bpm in tempos]
    out, channels = [chunk(conductor)], iter([c for c in range(16) if c != DRUM_CHANNEL])
    for patch, notes in tracks.items():
        label = patch.encode()  # the bare patch id; the single stem is "all"
        ev = [(0, 0, b"\xff\x03" + vlq(len(label)) + label)]
        if patch in DRUM_KITS:
            ch = DRUM_CHANNEL
        else:
            ch = next(channels)
            ev.append((0, 1, bytes([0xC0 | ch, PATCHES[patch][0]])))
        for pitches, start, length, vel in notes:
            for q in pitches:
                ev.append((int(round(start * TPQ)), 3, bytes([0x90 | ch, q, vel])))
                ev.append((int(round((start + length) * TPQ)) - 1, 2, bytes([0x80 | ch, q, 0])))
        out.append(chunk(ev))
    path = os.path.join(OUT, name + ".mid")
    with open(path, "wb") as f:
        f.write(b"MThd" + struct.pack(">IHHH", 6, 1, len(out), TPQ) + b"".join(out))
    return path


if __name__ == "__main__":
    failed = False
    for name, (tracks, tempos), limit in (("restauracao_epica", short(), 10.9), ("restauracao_epica_longa", long(), 16.0)):
        problems, last = check(tracks, tempos, limit)
        if problems:
            print(name, "\n".join(problems))
            failed = True
            continue
        print(build(name, tracks, tempos), f"last note-off {last:.2f} s")
        for patch, notes in tracks.items():
            info = PATCHES[patch]
            ps = [q for ps_, *_ in notes for q in ps_]
            print(f"  {patch:28} {len(notes):3} notes, MIDI {min(ps)}..{max(ps)} -> {info[1]}{'' if info[2] else ' (by hand)'}")
    sys.exit(1 if failed else 0)
