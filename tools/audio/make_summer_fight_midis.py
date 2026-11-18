"""Writes the Sun Guardian's remade fight sketch (tools/audio/midi/luta_summer_epica.mid), proposal of 2026-11-18.

Run: python -I tools/audio/make_summer_fight_midis.py
C Lydian, 4/4 at 152 BPM, 96 bars of 60/38 s, one loop from beat 0 (151.58 s, loop_offset 0). Game cue: bpm 152,
beats_per_bar 4. Two stems, lead and bed. No F natural anywhere: the subdominant (the evening) never comes.
Track names are "<AIVA patch id> (<stem>)"; PATCHES names the AIVA patch each is set to. check() enforces the stem
rules before writing. See docs/knowledge/music/guardian-fights.md.
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_miniature_midis import TPQ, chunk, vlq  # noqa: E402
from make_finale_fight_midis import p  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "midi")
BPM = 152
BEATS_PER_BAR = 4
TOTAL_BARS = 96
DRUM_CHANNEL = 9

# AIVA patch id -> (GM program fallback, the AIVA patch to set, maps on import). Ids seen to map on their own:
# violas.nat.stac (Spiccato), solo-viola, basses, the kits; the rest are set by hand.
PATCHES = {
    "w.dizi.nat.slur": (72, "Dizi (Sustain)", False), "b.trumpets.nat.slur": (56, "Trumpets Legato", False),
    "b.trombones.nat.stac": (57, "3 Bass Trombones Sustain", False),
    "s.violins.nat.stac": (40, "Violins 1 Spiccato", False), "s.violas.nat.stac": (41, "Violas Spiccato", True),
    "s.cellos.nat.stac": (42, "Celli Spiccato", False),
    "p.taikos.nat.stac": (None, "Epic Taikos Kit (35 Kick, 38 Snare Center)", True),
    "p.orchestral-kit.nat.stac": (None, "Orchestral Kit (35 Kick, 38 Snare Center, 41 Crash Left)", True),
    "s.basses.vib.slur": (43, "Basses Vibrato Legato", True), "s.solo-viola.nat.slur": (41, "Solo Viola Legato", True),
    "s.violins.nat.slur": (48, "Violins 1 Sustain (arrives as Violas)", False),
}
DRUM_KITS = ("p.taikos.nat.stac", "p.orchestral-kit.nat.stac")
KICK, SNARE, CRASH = 35, 38, 41

SOMBRA = ["C", "D", "E", "G", "G", "G"]
SOLSTICIO = ["E", "C", "G", "E", "C", "G"]


def bar(m, beat=0.0):
    """Bar m (1..96), in beats."""
    return (m - 1) * BEATS_PER_BAR + beat


# One chord per two bars: I, II (D over the C, the Lydian F#), iii, vi, vii; never IV, never a fall to the evening.
UNITS = (["C", "D", "Em", "D", "C", "D", "Am", "D", "C", "Em", "D", "D"]          # A noon 1-24
         + ["Am", "Bm", "C", "D", "Am", "Bm", "Em", "D", "C", "Bm", "Am", "D"]    # B shadows 25-48
         + ["C", "D", "C", "D", "Em", "D", "C", "D", "Am", "Bm", "C", "D"]        # C the roar 49-72
         + ["C", "D", "C", "D", "Em", "D"]                                        # D sun overhead 73-84
         + ["Am", "Bm", "C", "D", "D", "D"])                                      # E the day is long 85-96
assert len(UNITS) * 2 == TOTAL_BARS


def chord(m):
    return UNITS[(m - 1) // 2]


def section(m):
    return "A" if m <= 24 else "B" if m <= 48 else "C" if m <= 72 else "D" if m <= 84 else "E"


SECTION_VEL = {"A": 92, "B": 98, "C": 112, "D": 76, "E": 100}
PEDAL = ("A", "C", "D")  # the basses hold G (the sun at the top) through these sections; they follow roots in B, E

# Bed: pitch classes C D E G A only (no semitone against G C D E; so no F#, the Lydian colour stays in the lead), B
# only as a root at MIDI 47 or under; never in 60..67 (Ivo's answer) or 72..79 (the Dizi's call, G5 C5 D5 E5).
#        root    solo viola     violins (bed)  cellos (lead)   violin cell (lead)          violas (lead)
VOICING = {
    "C":  ("C2", ["E3", "G3"],  ["C6", "G6"],  ["C2", "G2"],   ["E5", "F#5", "G5", "B5"],  ["C4", "G4"]),
    "D":  ("D2", ["D3", "A3"],  ["D6", "A6"],  ["D2", "A2"],   ["D5", "F#5", "A5", "C6"],  ["D4", "A4"]),
    "Em": ("E1", ["E3", "G3"],  ["E6", "G6"],  ["E2", "B2"],   ["E5", "G5", "B5", "D6"],   ["E4", "B4"]),
    "Am": ("A1", ["A3", "E3"],  ["A5", "E6"],  ["A2", "E3"],   ["E5", "A5", "C6", "E6"],   ["A3", "E4"]),
    "Bm": ("B1", ["D3"],        ["D6"],        ["B2", "F#3"],  ["D5", "F#5", "B5", "D6"],  ["B3", "F#4"]),
}


def bed():
    basses, viola, violins = [], [], []
    for m in range(1, TOTAL_BARS + 1, 2):
        sec, v = section(m), VOICING[chord(m)]
        vel, length = SECTION_VEL[sec], 2 * BEATS_PER_BAR - 0.05
        basses.append(([p("G1") if sec in PEDAL else p(v[0])], bar(m), length, min(vel, 100)))
        viola.append(([p(x) for x in v[1]], bar(m), length, max(vel - 18, 48)))
        violins.append(([p(x) for x in v[2]], bar(m), length, max(vel - 28, 40)))
    return {"s.basses.vib.slur (bed)": basses, "s.solo-viola.nat.slur (bed)": viola,
            "s.violins.nat.slur (bed)": violins}


# The violins' heat shimmer: sixteenths, indexes into the chord's cell. In the overhead sun they climb an octave.
FIGURES = {"A": [0, 1, 2, 1, 0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1], "B": [0, 2, 1, 3] * 4,
           "C": [3, 2, 3, 1, 3, 2, 3, 0, 3, 2, 3, 1, 3, 2, 1, 2], "D": [1, 2] * 8,
           "E": [0, 1, 2, 3, 1, 2, 3, 0, 2, 3, 0, 1, 3, 0, 1, 2]}


def violins():
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        cell = [p(x) + (12 if sec == "D" else 0) for x in VOICING[chord(m)][4]]
        vel = SECTION_VEL[sec] - 6
        out += [([cell[f]], bar(m, k * 0.25), 0.22, vel + (12 if k % 4 == 0 else 0))
                for k, f in enumerate(FIGURES[sec])]
    return out


def violas():
    """Eighths: the chord against the held G (root, G, fifth, G), the noon pedal in the middle voices."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        root, fifth = (p(x) for x in VOICING[chord(m)][5])
        g = p("G4") if root < p("G4") else p("G3")
        pattern = [root, g, fifth, g] * 2
        out += [([q], bar(m, k * 0.5), 0.4, SECTION_VEL[sec] - (26 if sec == "D" else 12) + (10 if k % 2 == 0 else 0))
                for k, q in enumerate(pattern)]
    return out


def cellos():
    """Eighths, a king's march: accents on 1 and 3."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        root, fifth = (p(x) for x in VOICING[chord(m)][3])
        for k, q in enumerate([root, root, fifth, root, root + 12, root, fifth, root]):
            out.append(([q], bar(m, k * 0.5), 0.4, min(SECTION_VEL[sec] + (18 if k in (0, 4) else 0), 120)))
    return out


SOMBRA_RHYTHM = [(0, 1), (1, 1), (2, 1), (3, 1), (4, 1), (5, 3)]  # C D E G | G G___
SOLSTICIO_RHYTHM = [(0, 1), (1, 1), (2, 2), (4, 1), (5, 1), (6, 6)]


def six(names, octave, start, vel, rhythm, octaves=None):
    return [([p(n + str(octaves[k] if octaves else octave))], start + o, ln - 0.05, vel)
            for k, (n, (o, ln)) in enumerate(zip(names, rhythm))]


def melodies():
    dizi, trumpets, trombones = [], [], []
    # The Dizi, the lion's own flute: Sombra, then an answer that climbs and holds at the top.
    quotes = ((5, 5, 94), (13, 5, 96), (29, 5, 100), (37, 5, 102), (53, 5, 112), (77, 5, 84), (89, 5, 104))
    for m, octave, vel in quotes:
        dizi += six(SOMBRA, octave, bar(m), vel, SOMBRA_RHYTHM)
        answer = [("A", 0, 1), ("B", 1, 1), ("D", 2, 2), ("E", 4, 4)]
        dizi += [([p(n + str(octave + (1 if n in ("D", "E") else 0)))], bar(m + 2, o), ln - 0.05, vel - 6)
                 for n, o, ln in answer]
    # The shadow keeps the shape: the bass trombones play each Sombra a beat late, two octaves down (B and C).
    for m, octave, vel in quotes:
        if section(m) in ("B", "C"):
            trombones += six(SOMBRA, octave - 2, bar(m, 1), vel - 4, SOMBRA_RHYTHM)
    # Trumpets: the sun's fanfare at each phrase of the noon; Solstício (the longest day) in the roar, then held high.
    for m in (1, 9, 17, 85, 93):
        trumpets += [([p("G4"), p("D5")], bar(m), 1.45, 104), ([p("A4"), p("E5")], bar(m, 1.5), 0.45, 100),
                     ([p("B4"), p("F#5")], bar(m, 2), 1.95, 108), ([p("G4"), p("D5")], bar(m + 1), 3.9, 104)]
    for m in (49, 57, 65):
        trumpets += six(SOLSTICIO, 5, bar(m), 114, SOLSTICIO_RHYTHM, octaves=[5, 5, 5, 5, 5, 5])
        trumpets.append(([p("A5"), p("D5")], bar(m + 3), 3.9, 116))  # the sun held at the top
        trombones += [([p("C3"), p("G3")], bar(m), 1.9, 108), ([p("D3"), p("A3")], bar(m + 2), 1.9, 108)]
    for m in (24, 48, 72, 96):  # the II held before each return, never resolved down
        trumpets.append(([p("D5"), p("F#5"), p("A5")], bar(m), 3.9, 112))
        trombones.append(([p("D2"), p("A2"), p("D3")], bar(m), 3.9, 110))
    return {"w.dizi.nat.slur (lead)": dizi, "b.trumpets.nat.slur (lead)": trumpets,
            "b.trombones.nat.stac (lead)": trombones}


def drums():
    taiko, kit = [], []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        loud = {"A": 112, "B": 112, "C": 120, "D": 96, "E": 114}[sec]
        if sec == "D":
            hits = [(0, KICK, loud), (2, KICK, loud - 10), (3.5, SNARE, 64)]
        else:
            hits = [(0, KICK, loud), (1.5, KICK, loud - 14), (2, KICK, loud - 6), (1, SNARE, 90), (3, SNARE, 94)]
            if sec in ("B", "C"):
                hits += [(0.75, SNARE, 60), (2.75, SNARE, 62), (3.5, SNARE, 80)]
        if sec != "D" and m % 8 == 0:
            hits = [h for h in hits if h[0] < 2] + [(2 + k * 0.25, SNARE if k % 2 else KICK, 74 + 5 * k) for k in range(8)]
        elif m % 4 == 0:
            hits = [h for h in hits if h[0] < 3] + [(3 + k * 0.25, SNARE, 78 + 9 * k) for k in range(4)]
        taiko += [([note], bar(m, b), 0.1, v) for b, note, v in hits]
        if sec in ("B", "C") or (sec == "E" and m >= 89):
            kit += [([SNARE], bar(m, k * 0.5), 0.1, 92 if k % 2 == 0 else 54) for k in range(8)]
        elif sec == "D":
            kit += [([SNARE], bar(m, k * 0.5), 0.1, 44) for k in range(8)]
        else:
            kit += [([SNARE], bar(m, b), 0.1, 86) for b in (1, 3)]
        if sec == "C":  # the blaze: the crash on every downbeat
            kit.append(([CRASH], bar(m), 0.1, 96))
    for m in (1, 9, 17, 25, 37, 73, 85):
        kit += [([CRASH], bar(m), 0.1, 112), ([KICK], bar(m), 0.1, 114)]
    for m in (24, 48, 72, 96):  # snare roll into the next section, replacing that bar's snare
        kit = [h for h in kit if not (h[0] == [SNARE] and bar(m) <= h[1] < bar(m + 1))]
        kit += [([SNARE], bar(m, k * 0.25), 0.1, 56 + 4 * k) for k in range(16)]
    return taiko, kit


def tracks():
    taiko, kit = drums()
    out = melodies()
    out.update({"s.violins.nat.stac (lead)": violins(), "s.violas.nat.stac (lead)": violas(),
                "s.cellos.nat.stac (lead)": cellos(), "p.taikos.nat.stac (lead)": taiko,
                "p.orchestral-kit.nat.stac (lead)": kit})
    out.update(bed())
    return out


SAFE = {0, 2, 4, 7, 9}             # C D E G A
LOW_ROOT_MAX = 47                  # B only as a root at or under B2
CALL_RANGES = ((60, 67), (72, 79))  # Ivo's answer (G4 C4 D4 E4) and the Dizi's call (G5 C5 D5 E5)


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
            for q in pitches:
                if q % 12 == 5:
                    problems.append(f"{name}: F natural ({q}) at beat {start}: the evening never comes")
                if stem != "bed":
                    continue
                if any(lo <= q <= hi for lo, hi in CALL_RANGES):
                    problems.append(f"{name}: {q} at beat {start} inside a call range")
                if q % 12 not in SAFE and not (q % 12 == 11 and q <= LOW_ROOT_MAX):
                    problems.append(f"{name}: pitch class {q % 12} ({q}) at beat {start}")
    return problems


SECTIONS = ((1, "A noon"), (25, "B shadows"), (49, "C the roar"), (73, "D sun overhead"), (85, "E the day is long"))


def build(name, all_tracks):
    to_tick = lambda beats: int(round(beats * TPQ))
    conductor = [(0, 0, b"\xff\x58\x04" + bytes([4, 2, 0x18, 0x08])),
                 (0, 0, b"\xff\x59\x02" + bytes([1, 0])),  # one sharp: C Lydian's F#
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
    print(build("luta_summer_epica", made))
    bar_s = 60 / BPM * BEATS_PER_BAR
    print(f"4/4 at {BPM}, bar {bar_s:.4f} s; loop {TOTAL_BARS} bars = {TOTAL_BARS * bar_s:.2f} s from beat 0 "
          f"(loop_offset 0)")
    for name, notes in made.items():
        ps = [q for ps_, *_ in notes for q in ps_]
        info = PATCHES[name.split(" ")[0]]
        print(f"  {name:34} {len(notes):4} notes, MIDI {min(ps)}..{max(ps)}  -> {info[1]}{'' if info[2] else ' (by hand)'}")
