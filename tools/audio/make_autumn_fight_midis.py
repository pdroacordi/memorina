"""Writes the Leaf Guardian's remade fight sketch (tools/audio/midi/luta_autumn_epica.mid), proposal of 2026-11-18.

Run: python -I tools/audio/make_autumn_fight_midis.py
E Phrygian, 3/4 at 192 BPM (one-in-a-bar, 64 to the minute), 160 bars of 0.9375 s, one loop from beat 0 (150.0 s,
loop_offset 0). Game cue: bpm 192, beats_per_bar 3. Two stems, lead and bed. Track names are
"<AIVA patch id> (<stem>)"; PATCHES names the AIVA patch each is set to. check() enforces the stem rules before
writing. See docs/knowledge/music/guardian-fights.md.
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_miniature_midis import TPQ, chunk, vlq  # noqa: E402
from make_finale_fight_midis import p  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "midi")
BPM = 192
BEATS_PER_BAR = 3
TOTAL_BARS = 160
DRUM_CHANNEL = 9

# AIVA patch id -> (GM program fallback, the AIVA patch to set, maps on import).
PATCHES = {
    "w.xiao.nat.slur": (77, "Xiao (Sustain)", False), "w.bassoon.nat.stac": (70, "Bassoon Staccato", False),
    "s.violins.nat.stac": (40, "Violins 1 Spiccato", False), "s.violas.nat.stac": (41, "Violas Spiccato", True),
    "s.cellos.nat.stac": (42, "Celli Spiccato", False),
    "p.taikos.nat.stac": (None, "Epic Taikos Kit (35 Kick, 38 Snare Center)", True),
    "p.orchestral-kit.nat.stac": (None, "Orchestral Kit (35 Kick, 38 Snare Center, 41 Crash Left)", True),
    "s.basses.vib.slur": (43, "Basses Vibrato Legato", True), "s.solo-viola.nat.slur": (41, "Solo Viola Legato", True),
    "s.violins.nat.slur": (48, "Violins 1 Sustain (arrives as Violas)", False),
}
DRUM_KITS = ("p.taikos.nat.stac", "p.orchestral-kit.nat.stac")
KICK, SNARE, CRASH = 35, 38, 41

SOLTAR = ["G", "C", "D", "C", "E", "C"]
VENDAVAL = ["E", "E", "D", "D", "G", "E"]
SCALE = ["E", "F", "G", "A", "B", "C", "D"]  # E Phrygian: its F, a semitone over the home, is the decay


def bar(m, beat=0.0):
    """Bar m (1..160), in beats."""
    return (m - 1) * BEATS_PER_BAR + beat


# One chord per two bars. The loop ends on F (bII), so the Phrygian cadence F -> Em lands on the loop's first beat.
UNITS = (["Em", "F", "Em", "Dm", "C", "F", "Em", "Em", "Am", "Dm", "Em", "F", "C", "Dm", "Em", "F", "Am", "G", "F", "Em"]
         + ["Am", "Dm", "Am", "Em", "F", "G", "Am", "Am", "Dm", "Am", "F", "Em", "Am", "Dm", "F", "Em"]
         + ["Em", "F", "G", "Am", "Em", "F", "Dm", "Em", "Am", "G", "F", "Em", "Em", "F", "G", "Am", "Dm", "C", "F", "Em"]
         + ["Em", "Em", "Am", "Am", "Dm", "Em", "F", "Em", "Am", "Dm", "F", "Em"]
         + ["Am", "G", "F", "Em", "Am", "G", "F", "Em", "Dm", "C", "F", "F"])
assert len(UNITS) * 2 == TOTAL_BARS


def chord(m):
    return UNITS[(m - 1) // 2]


def section(m):
    return "A" if m <= 40 else "B" if m <= 72 else "C" if m <= 112 else "D" if m <= 136 else "E"


SECTION_VEL = {"A": 92, "B": 98, "C": 112, "D": 74, "E": 100}

# Bed: pitch classes C D E G A only (no semitone against the Xiao's call G C D E), F and B only as roots at MIDI 47
# or under; never in 60..67, where the Xiao's call and Ivo's answer both sound.
#        root    solo viola     violins (bed)  cellos (lead)   violin cell (lead)
VOICING = {
    "Em": ("E1", ["E3", "G3"],  ["E6", "G6"],  ["E2", "B2"],   ["E5", "G5", "B5", "E6"]),
    "F":  ("F1", ["A3", "C3"],  ["A5", "C6"],  ["F2", "C3"],   ["F5", "A5", "C6", "F6"]),
    "G":  ("G1", ["G3", "D3"],  ["D6", "G6"],  ["G2", "D3"],   ["D5", "G5", "B5", "D6"]),
    "Am": ("A1", ["A3", "E3"],  ["A5", "E6"],  ["A2", "E3"],   ["E5", "A5", "C6", "E6"]),
    "Dm": ("D2", ["A3", "D3"],  ["A5", "D6"],  ["D2", "A2"],   ["D5", "F5", "A5", "D6"]),
    "C":  ("C2", ["G3", "E3"],  ["E6", "G6"],  ["C2", "G2"],   ["E5", "G5", "C6", "E6"]),
}


def bed():
    basses, viola, violins = [], [], []
    for m in range(1, TOTAL_BARS + 1, 2):
        sec, v = section(m), VOICING[chord(m)]
        vel, length = SECTION_VEL[sec], 2 * BEATS_PER_BAR - 0.05
        basses.append(([p(v[0])], bar(m), length, min(vel, 100)))
        viola.append(([p(x) for x in v[1]], bar(m), length, max(vel - 18, 48)))
        violins.append(([p(x) for x in v[2]], bar(m), length, max(vel - 28, 40)))
    return {"s.basses.vib.slur (bed)": basses, "s.solo-viola.nat.slur (bed)": viola,
            "s.violins.nat.slur (bed)": violins}


def scale_down(start, n):
    name, octave = start[:-1], int(start[-1])
    i, out = SCALE.index(name), []
    for _ in range(n):
        out.append(p(SCALE[i % 7] + str(octave)))
        if SCALE[i % 7] == "C":
            octave -= 1
        i -= 1
    return out


def violins():
    """Eighths. The whirl (up and back) in the wind; pairs across the 3/4 (2+2+2) while he counts; leaves falling
    (scales down the mode, a new leaf each bar from the top) in the gust and the last leaf; in the release the fall
    reaches the bottom and lets go."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        cells = VOICING[chord(m)][4]
        cell = [p(x) for x in cells]
        vel = SECTION_VEL[sec] - 6
        if sec == "A":
            notes, accents = [cell[i] for i in (0, 1, 2, 3, 2, 1)], (0,)
        elif sec == "B":
            notes, accents = [cell[i] for i in (3, 3, 1, 1, 2, 2)], (0, 2, 4)
        elif sec in ("C", "E"):
            notes, accents = scale_down(cells[3], 6), (0,)
        else:  # the last leaf: one falling pair a beat, softer
            notes, accents = [cell[i] for i in (3, 2, 2, 1, 1, 0)], (0,)
        out += [([q], bar(m, k * 0.5), 0.4, vel + (12 if k in accents else 0) - (18 if sec == "D" else 0))
                for k, q in enumerate(notes)]
    return out


def violas():
    """The waltz's after-beats (beats 2 and 3 as eighth pairs); in the counting, the hemiola: three half notes over
    two bars."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        root, fifth = (p(x) + 12 for x in VOICING[chord(m)][3])
        vel = SECTION_VEL[sec] - (26 if sec == "D" else 12)
        if sec == "B":
            spots = (0, 2) if m % 2 == 1 else (1,)
            out += [([root, fifth], bar(m, b), 1.9 if b != 2 else 0.9, vel + 8) for b in spots]
        else:
            out += [([root, fifth], bar(m, b), 0.4, vel + (6 if b in (1, 2) else 0)) for b in (1, 1.5, 2, 2.5)]
    return out


def cellos():
    """Eighths under the whirl, the downbeat leaned on; the hemiola's accents while he counts."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        root, fifth = (p(x) for x in VOICING[chord(m)][3])
        accents = ((0, 4) if m % 2 == 1 else (2,)) if sec == "B" else (0,)
        for k, q in enumerate([root, root, fifth, root, root + 12, fifth]):
            out.append(([q], bar(m, k * 0.5), 0.4, min(SECTION_VEL[sec] + (18 if k in accents else 0), 120)))
    return out


SOLTAR_RHYTHM = [(0, 2), (2, 1), (3, 2), (5, 1), (6, 2), (8, 4)]       # G. C | D. C | E. C__ (waltz pairs)
VENDAVAL_RHYTHM = [(0, 1), (1, 1), (2, 1), (3, 1), (4, 1), (5, 4)]     # the gust: quarters, the last E long


def six(names, octave, start, vel, rhythm):
    return [([p(n + str(octave))], start + o, ln - 0.05, vel) for n, (o, ln) in zip(names, rhythm)]


def woodwinds():
    xiao, bassoon = [], []
    # The Xiao, his own breath: Soltar, then an answer that will not let go: each note tied over the bar line and
    # resolved a beat late; in the release the answer falls on time.
    for m, vel in ((5, 90), (21, 94), (45, 98), (77, 110), (93, 110), (117, 80), (141, 104)):
        xiao += six(SOLTAR, 4, bar(m), vel, SOLTAR_RHYTHM)
        if section(m) == "E":
            answer = [("A4", 0, 3), ("G4", 3, 3), ("F4", 6, 3), ("E4", 9, 6)]
        else:
            answer = [("A4", 0, 4), ("G4", 4, 3), ("F4", 7, 4), ("E4", 11, 4)]  # held past each bar line
        xiao += [([p(n)], bar(m + 4, o), ln - 0.05, vel - 6) for n, o, ln in answer]
    # The bassoon, bone on wood: the downbeat in the wind and the gust; while he counts, staccato quarters on the
    # root, and every eighth bar he loses the count and stops a beat early ("Trinta e... uma?").
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        root = p(VOICING[chord(m)][3][0]) + 12
        if sec == "B":
            beats = (0, 1) if m % 8 == 0 else (0, 1, 2)
            bassoon += [([root], bar(m, b), 0.4, 84 + (12 if b == 0 else 0)) for b in beats]
        elif sec in ("A", "C", "E") and not (85 <= m <= 88 or 101 <= m <= 104):
            bassoon.append(([root], bar(m), 0.45, 90))
    # The gust (Vendaval) in the bassoon, twice.
    for m in (85, 101):
        bassoon += six(VENDAVAL, 3, bar(m), 106, VENDAVAL_RHYTHM)
    return {"w.xiao.nat.slur (lead)": xiao, "w.bassoon.nat.stac (lead)": bassoon}


def drums():
    taiko, kit = [], []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        loud = {"A": 112, "B": 112, "C": 120, "D": 96, "E": 114}[sec]
        if sec == "B":  # the hemiola: kicks every half note across two bars
            hits = [(0, KICK, loud), (2, KICK, loud - 8)] if m % 2 == 1 else [(1, KICK, loud - 4)]
            hits += [(0.5, SNARE, 60), (1.5, SNARE, 62), (2.5, SNARE, 80)]
        elif sec == "C":
            hits = [(0, KICK, loud), (1, KICK, loud - 12), (2, KICK, loud - 8), (1.5, SNARE, 80), (2.5, SNARE, 90)]
        elif sec == "D":
            hits = [(0, KICK, loud), (2.5, SNARE, 60)]
        else:
            hits = [(0, KICK, loud), (1, SNARE, 84), (2, SNARE, 78), (2.5, KICK, loud - 20)]
        if sec != "D" and m % 8 == 0:
            hits = [h for h in hits if h[0] < 1] + [(1 + k * 0.25, SNARE if k % 2 else KICK, 74 + 6 * k) for k in range(8)]
        elif m % 4 == 0:
            hits = [h for h in hits if h[0] < 2] + [(2 + k * 0.25, SNARE, 78 + 9 * k) for k in range(4)]
        taiko += [([note], bar(m, b), 0.1, v) for b, note, v in hits]
        if sec in ("B", "C") or (sec == "E" and m >= 149):
            kit += [([SNARE], bar(m, k * 0.5), 0.1, 92 if k == 0 else 54) for k in range(6)]
        elif sec == "D":
            kit += [([SNARE], bar(m, k * 0.5), 0.1, 42) for k in range(6)]
        else:
            kit += [([SNARE], bar(m, b), 0.1, 80) for b in (1, 2)]
    for m in (1, 21, 41, 73, 85, 101, 113, 137):
        kit += [([CRASH], bar(m), 0.1, 112), ([KICK], bar(m), 0.1, 114)]
    for m in (40, 72, 112, 160):  # snare roll into the next section, replacing that bar's snare
        kit = [h for h in kit if not (h[0] == [SNARE] and bar(m) <= h[1] < bar(m + 1))]
        kit += [([SNARE], bar(m, k * 0.25), 0.1, 56 + 5 * k) for k in range(12)]
    return taiko, kit


def tracks():
    taiko, kit = drums()
    out = woodwinds()
    out.update({"s.violins.nat.stac (lead)": violins(), "s.violas.nat.stac (lead)": violas(),
                "s.cellos.nat.stac (lead)": cellos(), "p.taikos.nat.stac (lead)": taiko,
                "p.orchestral-kit.nat.stac (lead)": kit})
    out.update(bed())
    return out


SAFE = {0, 2, 4, 7, 9}         # C D E G A
LOW_ROOT_MAX = 47              # F and B only as roots at or under B2
CALL_RANGE = (60, 67)          # the Xiao's call and Ivo's answer, both G4 C4 D4 E4


def check(all_tracks):
    """Returns the rule violations (empty when the sketch keeps the stem contract). Units are beats."""
    problems, end = [], bar(TOTAL_BARS + 1)
    for name, notes in all_tracks.items():
        stem, patch = name.split("(")[1].rstrip(")"), name.split(" ")[0]
        for pitches, start, length, vel in notes:
            if start < 0 or start + length > end + 1e-6:
                problems.append(f"{name}: note at {start} + {length} outside the {TOTAL_BARS} bars")
            if not 1 <= vel <= 127:
                problems.append(f"{name}: velocity {vel}")
            if patch in DRUM_KITS:
                allowed = (KICK, SNARE) if patch == "p.taikos.nat.stac" else (KICK, SNARE, CRASH)
                problems += [f"{name}: unmapped drum {q}" for q in pitches if q not in allowed]
                continue
            if stem != "bed":
                continue
            for q in pitches:
                if CALL_RANGE[0] <= q <= CALL_RANGE[1]:
                    problems.append(f"{name}: {q} at beat {start} inside the call range")
                if q % 12 not in SAFE and not (q % 12 in (5, 11) and q <= LOW_ROOT_MAX):
                    problems.append(f"{name}: pitch class {q % 12} ({q}) at beat {start}")
    return problems


SECTIONS = ((1, "A wind"), (41, "B counting"), (73, "C the gust"), (113, "D the last leaf"), (137, "E letting go"))


def build(name, all_tracks):
    to_tick = lambda beats: int(round(beats * TPQ))
    conductor = [(0, 0, b"\xff\x58\x04" + bytes([3, 2, 0x18, 0x08])),          # 3/4
                 (0, 0, b"\xff\x59\x02" + bytes([0, 1])),                        # no accidentals (E Phrygian)
                 (0, 1, b"\xff\x51\x03" + int(60e6 / BPM).to_bytes(3, "big"))]
    for m, label in SECTIONS:
        text = label.encode()
        conductor.append((to_tick(bar(m)), 2, b"\xff\x06" + vlq(len(text)) + text))
    out, channels = [chunk(conductor)], iter([c for c in range(16) if c != DRUM_CHANNEL])
    for track, notes in all_tracks.items():
        # AIVA maps a track to a patch only when the name is the bare patch id; the stem stays in the dict key.
        patch = track.split(" ")[0]
        label = patch.encode()
        ev = [(0, 0, b"\xff\x03" + vlq(len(label)) + label)]
        if patch in DRUM_KITS:
            ch = DRUM_CHANNEL
        else:
            ch = next(channels)
            ev.append((0, 1, bytes([0xC0 | ch, PATCHES[patch][0]])))
        for pitches, start, length, vel in notes:
            for q in pitches:
                ev.append((to_tick(start), 3, bytes([0x90 | ch, q, vel])))
                ev.append((to_tick(start + length) - 1, 2, bytes([0x80 | ch, q, 0])))
        out.append(chunk(ev))
    path = os.path.join(OUT, name + ".mid")
    with open(path, "wb") as f:
        f.write(b"MThd" + struct.pack(">IHHH", 6, 1, len(out), TPQ) + b"".join(out))
    return path


if __name__ == "__main__":
    made = tracks()
    found = check(made)
    if found:
        print("\n".join(found[:40]))
        sys.exit(1)
    print(build("luta_autumn_epica", made))
    bar_s = 60 / BPM * BEATS_PER_BAR
    print(f"3/4 at {BPM}, bar {bar_s:.4f} s; loop {TOTAL_BARS} bars = {TOTAL_BARS * bar_s:.2f} s from beat 0 "
          f"(loop_offset 0)")
    for name, notes in made.items():
        ps = [q for ps_, *_ in notes for q in ps_]
        info = PATCHES[name.split(" ")[0]]
        print(f"  {name:34} {len(notes):4} notes, MIDI {min(ps)}..{max(ps)}  -> {info[1]}{'' if info[2] else ' (by hand)'}")
