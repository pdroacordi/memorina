"""Writes the Bloom Guardian's remade fight sketch (tools/audio/midi/luta_bloom_epica.mid), proposal of 2026-11-18.

Run: python -I tools/audio/make_bloom_fight_midis.py
G Mixolydian, 6/8 at dotted quarter = 132 (quarter 198, eighth 396), 160 bars of 10/11 s, one loop from beat 0
(145.45 s, loop_offset 0). The game cue: bpm 198, beats_per_bar 3. Two stems, lead and bed. Track names are
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
EIGHTH_BPM = 396
EIGHTHS_PER_BAR = 6
TOTAL_BARS = 160
DRUM_CHANNEL = 9

# AIVA patch id -> (GM program fallback, the AIVA patch to set). Ids known to map on import: flute2, clarinet1,
# solo-viola, basses, harp2, taikos, orchestral-kit; the rest are set by hand.
PATCHES = {
    "w.recorder.nat.slur": (74, "Recorder Legato"), "w.clarinet1.nat.slur": (71, "Clarinet 1 Legato"),
    "w.flute2.nat.stac": (73, "Flute 2 Staccato"), "s.violins.nat.stac": (40, "Violins 1 Spiccato"),
    "s.violas.nat.stac": (41, "Violas Spiccato"), "s.cellos.nat.stac": (42, "Celli Spiccato"),
    "s.harp2.pizz.stac": (46, "Harp 2 Pizzicato"),
    "p.taikos.nat.stac": (None, "Epic Taikos Kit (35 Kick, 38 Snare Center)"),
    "p.orchestral-kit.nat.stac": (None, "Orchestral Kit (35 Kick, 38 Snare Center, 41 Crash Left)"),
    "s.basses.vib.slur": (43, "Basses Vibrato Legato"), "s.solo-viola.nat.slur": (41, "Solo Viola Legato"),
    "s.violins.nat.slur": (48, "Violins 1 Sustain"),
}
DRUM_KITS = ("p.taikos.nat.stac", "p.orchestral-kit.nat.stac")
KICK, SNARE, CRASH = 35, 38, 41

ENRAIZAR = ["C", "D", "C", "E", "C", "G"]
CHUVA = ["E", "E", "E", "G", "C", "G"]
SCALE = ["G", "A", "B", "C", "D", "E", "F"]  # G Mixolydian: no F#, so no leading tone pulls into G


def bar(m, eighth=0.0):
    """Bar m (1..160), in eighths."""
    return (m - 1) * EIGHTHS_PER_BAR + eighth


# One chord per two bars. The climb in C rises by step to F (bVII) and falls back to C: it begins and never arrives.
# The loop's last chord is F, so G arrives only as the loop starts again.
UNITS = (["G", "F", "C", "G", "G", "F", "Am", "C", "G", "Em", "F", "C", "G", "F", "Dm", "C", "Am", "F", "C", "F"]
         + ["Am", "F", "C", "G", "Dm", "Am", "F", "G", "Am", "F", "C", "Em", "Dm", "F", "C", "G"]
         + ["G", "Am", "C", "Dm", "Em", "F", "F", "C", "G", "Am", "C", "Dm", "Em", "F", "G", "F", "C", "Am", "F", "F"]
         + ["C", "G", "Am", "F", "C", "G", "F", "C", "Am", "Em", "F", "G"]
         + ["G", "F", "C", "G", "Am", "F", "C", "Dm", "Em", "F", "F", "F"])
assert len(UNITS) * 2 == TOTAL_BARS


def chord(m):
    return UNITS[(m - 1) // 2]


def section(m):
    return "A" if m <= 40 else "B" if m <= 72 else "C" if m <= 112 else "D" if m <= 136 else "E"


SECTION_VEL = {"A": 90, "B": 96, "C": 110, "D": 74, "E": 98}

# Bed: pitch classes C D E G A only (no semitone against the Recorder's call G C D E), F and B only as roots at MIDI
# 47 or under; never in 60..67, where both the Recorder's call and Ivo's answer sound.
#        basses  solo viola        violins (bed)     cellos (lead)   violin cell (lead)          harp (lead)
VOICING = {
    "G":  ("G1", ["G3", "D3"],    ["D6", "G6"],     ["G2", "D3"],   ["G5", "B5", "D6", "G6"],   ["G2", "D3", "B3", "D4", "G4", "B4"]),
    "F":  ("F1", ["A3", "C3"],    ["C6", "A5"],     ["F2", "C3"],   ["F5", "A5", "C6", "F6"],   ["F2", "C3", "A3", "C4", "F4", "A4"]),
    "C":  ("C2", ["G3", "E3"],    ["E6", "G6"],     ["C2", "G2"],   ["E5", "G5", "C6", "E6"],   ["C3", "G3", "C4", "E4", "G4", "C5"]),
    "Am": ("A1", ["A3", "E3"],    ["A5", "E6"],     ["A2", "E3"],   ["E5", "A5", "C6", "E6"],   ["A2", "E3", "A3", "C4", "E4", "A4"]),
    "Dm": ("D2", ["A3", "D3"],    ["A5", "D6"],     ["D2", "A2"],   ["D5", "F5", "A5", "D6"],   ["D2", "A2", "D3", "F3", "A3", "D4"]),
    "Em": ("E1", ["G3", "E3"],    ["E6", "G6"],     ["E2", "B2"],   ["E5", "G5", "B5", "E6"],   ["E2", "B2", "E3", "G3", "B3", "E4"]),
}


def bed():
    basses, viola, violins = [], [], []
    for m in range(1, TOTAL_BARS + 1, 2):
        v, vel = VOICING[chord(m)], SECTION_VEL[section(m)]
        length = 2 * EIGHTHS_PER_BAR - 0.1
        basses.append(([p(v[0])], bar(m), length, min(vel, 100)))
        viola.append(([p(x) for x in v[1]], bar(m), length, max(vel - 18, 48)))
        violins.append(([p(x) for x in v[2]], bar(m), length, max(vel - 28, 40)))
    return {"s.basses.vib.slur (bed)": basses, "s.solo-viola.nat.slur (bed)": viola,
            "s.violins.nat.slur (bed)": violins}


# The violins over six eighths, indexes into the chord's cell: every figure ends higher than it starts (growth).
FIGURES = {"A": [0, 1, 2, 1, 2, 3], "B": [0, 2, 1, 3, 2, 3], "C": [1, 2, 3, 2, 3, 3], "D": [2, 3, 2, 3, 2, 3],
           "E": [0, 1, 2, 3, 2, 3]}


def scale_run(start, n):
    name, octave = start[:-1], int(start[-1])
    i, out = SCALE.index(name), []
    for _ in range(n):
        out.append(p(SCALE[i % 7] + str(octave)))
        i += 1
        if SCALE[i % 7] == "C":
            octave += 1
    return out


def violins():
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec, cells = section(m), VOICING[chord(m)][4]
        cell = [p(x) for x in cells]
        vel = SECTION_VEL[sec] - 4
        if sec in ("C", "E") and m % 4 == 0:  # sap: a bar of sixteenths up the scale
            out += [([q], bar(m, k * 0.5), 0.4, vel + (10 if k % 6 == 0 else 0))
                    for k, q in enumerate(scale_run(cells[0], 12))]
            continue
        for k, f in enumerate(FIGURES[sec]):
            if k == 5 and m % 2 == 0 and sec != "D":  # a turn on the last eighth: two sixteenths
                out += [([cell[3]], bar(m, 5), 0.4, vel + 4), ([cell[3] + 2], bar(m, 5.5), 0.4, vel + 4)]
                continue
            out.append(([cell[f]], bar(m, k), 0.8, vel + (12 if k in (0, 3) else 0)))
    return out


def violas():
    """Off-beat dyads (eighths 1, 2, 4, 5), the spring of the 6/8; in the roots, the 3/4 against it (2, 4)."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        root, fifth = (p(x) + 12 for x in VOICING[chord(m)][3])
        spots = (2, 4) if sec == "B" else (1, 2, 4, 5)
        out += [([root, fifth], bar(m, e), 0.7, SECTION_VEL[sec] - (24 if sec == "D" else 12)) for e in spots]
    return out


def cellos():
    """A gallop (quarter, eighth, quarter, eighth); in the roots, three quarters across the bar (hemiola)."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        root, fifth = (p(x) for x in VOICING[chord(m)][3])
        vel = SECTION_VEL[sec]
        if sec == "B":
            out += [([q], bar(m, e), 1.8, min(vel + (16 if e == 0 else 6), 120))
                    for e, q in ((0, root), (2, fifth), (4, root + 12))]
        else:
            out += [([q], bar(m, e), ln, min(vel + (16 if e in (0, 3) else 0), 120))
                    for e, q, ln in ((0, root, 1.8), (2, fifth, 0.8), (3, root, 1.8), (5, root + 12, 0.8))]
    return out


def harp():
    """Eighth arpeggios rising through the chord, one octave span a bar; it leads the thinner rain section."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        notes = [p(x) for x in VOICING[chord(m)][5]]
        vel = SECTION_VEL[sec] - (4 if sec == "D" else 20)
        out += [([q + (12 if sec == "D" else 0)], bar(m, k), 0.9, vel) for k, q in enumerate(notes)]
    return out


def six(names, octave, m, vel, rhythm):
    """A six-note motif from bar m; rhythm [(eighth, length)] from the bar's start."""
    return [([p(n + str(octave))], bar(m, e), ln - 0.1, vel) for n, (e, ln) in zip(names, rhythm)]


# Enraizar in 6/8: C D | C E (quarter-eighth pairs), then C and the long G that reaches (a bar and a half).
ROOT_RHYTHM = [(0, 2), (2, 1), (3, 2), (5, 1), (6, 2), (8, 10)]
# Chuva, the bird's tune ("Escuta quando chover"): E E E in eighths, G, then C G.
RAIN_RHYTHM = [(0, 1), (1, 1), (2, 1), (3, 3), (6, 3), (9, 3)]


def woodwinds():
    recorder, clarinet, flute = [], [], []
    for m, vel in ((9, 96), (25, 98), (89, 112), (101, 112), (145, 104)):
        recorder += six(ENRAIZAR, 5, m, vel, ROOT_RHYTHM)
    # The roots find each other: Enraizar in canon, clarinet then recorder a bar behind.
    for m in (41, 57):
        clarinet += six(ENRAIZAR, 5, m, 98, ROOT_RHYTHM)
        recorder += six(ENRAIZAR, 5, m + 1, 100, ROOT_RHYTHM)
    clarinet += six(ENRAIZAR, 4, 89, 104, ROOT_RHYTHM)  # the climax: an octave under the recorder
    # Answers between the quotes: a phrase that climbs to F and stops there (the bVII, never the G).
    for m in (13, 29, 93, 105, 149):
        recorder += [([p(n)], bar(m + k // 6, k % 6), 0.9, 90) for k, n in enumerate(["D5", "E5", "F5", "G5", "A5", "C6"])]
        recorder.append(([p("F6")], bar(m + 1), 11.8, 94))
    for m in (17, 33, 121, 137):  # the clarinet's own line: rising thirds in the low register
        clarinet += [([p(n)], bar(m, e), 2.8, 84) for n, e in (("G3", 0), ("B3", 3))]
        clarinet += [([p(n)], bar(m + 1, e), 2.8, 86) for n, e in (("D4", 0), ("F4", 3))]
        clarinet.append(([p("A4")], bar(m + 2), 11.8, 88))
    for m in (117, 129):  # the bird
        flute += six(CHUVA, 6, m, 92, RAIN_RHYTHM)
    for m in range(113, 137):  # birdsong between, off the beat
        if m in range(117, 120) or m in range(129, 132):
            continue
        flute += [([p(["G6", "A6", "E6", "D7"][(m + k) % 4])], bar(m, e), 0.5, 70) for k, e in enumerate((1, 4))]
    return {"w.recorder.nat.slur (lead)": recorder, "w.clarinet1.nat.slur (lead)": clarinet,
            "w.flute2.nat.stac (lead)": flute}


def drums():
    taiko, kit = [], []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        loud = {"A": 110, "B": 112, "C": 118, "D": 94, "E": 112}[sec]
        if sec == "B":
            hits = [(0, KICK, loud), (2, KICK, loud - 10), (4, KICK, loud - 6), (1, SNARE, 60), (3, SNARE, 62),
                    (5, SNARE, 80)]
        elif sec == "D":
            hits = [(0, KICK, loud), (3, KICK, loud - 10)]
        else:
            hits = [(0, KICK, loud), (3, KICK, loud - 8), (2, SNARE, 74), (5, SNARE, 82)]
            if sec == "C":
                hits += [(1, SNARE, 64), (4, SNARE, 66)]
        if sec != "D" and m % 8 == 0:  # a long fill: the bar in sixteenths
            hits = [h for h in hits if h[0] < 1] + [(1 + k * 0.5, SNARE if k % 2 else KICK, 70 + 4 * k)
                                                   for k in range(10)]
        elif m % 4 == 0:
            hits = [h for h in hits if h[0] < 3] + [(3 + k * 0.5, SNARE, 76 + 7 * k) for k in range(6)]
        taiko += [([note], bar(m, e), 0.2, v) for e, note, v in hits]
        if sec in ("B", "C") or (sec == "E" and m >= 149):
            kit += [([SNARE], bar(m, e), 0.2, 92 if e in (0, 3) else 52) for e in range(EIGHTHS_PER_BAR)]
        elif sec == "D":
            kit += [([SNARE], bar(m, e), 0.2, 42) for e in range(EIGHTHS_PER_BAR)]
        else:
            kit += [([SNARE], bar(m, 3), 0.2, 86)]
    for m in (1, 21, 41, 73, 89, 113, 137):
        kit += [([CRASH], bar(m), 0.2, 110), ([KICK], bar(m), 0.2, 112)]
    for m in (40, 72, 112, 160):  # snare roll in sixteenths into the next section, replacing that bar's snare
        kit = [h for h in kit if not (h[0] == [SNARE] and bar(m) <= h[1] < bar(m + 1))]
        kit += [([SNARE], bar(m, k * 0.5), 0.2, 56 + 5 * k) for k in range(12)]
    return taiko, kit


def tracks():
    taiko, kit = drums()
    out = woodwinds()
    out.update({"s.violins.nat.stac (lead)": violins(), "s.violas.nat.stac (lead)": violas(),
                "s.cellos.nat.stac (lead)": cellos(), "s.harp2.pizz.stac (lead)": harp(),
                "p.taikos.nat.stac (lead)": taiko, "p.orchestral-kit.nat.stac (lead)": kit})
    out.update(bed())
    return out


SAFE = {0, 2, 4, 7, 9}         # C D E G A
LOW_ROOT_MAX = 47              # F and B only as roots at or under B2
CALL_RANGE = (60, 67)          # the Recorder's call and Ivo's answer, both G4 C4 D4 E4


def check(all_tracks):
    """Returns the rule violations (empty when the sketch keeps the stem contract). Units are eighths."""
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
                    problems.append(f"{name}: {q} at eighth {start} inside the call range")
                if q % 12 not in SAFE and not (q % 12 in (5, 11) and q <= LOW_ROOT_MAX):
                    problems.append(f"{name}: pitch class {q % 12} ({q}) at eighth {start}")
    return problems


SECTIONS = ((1, "A sprouting"), (41, "B roots"), (73, "C sap"), (113, "D rain"), (137, "E almost"))


def build(name, all_tracks):
    to_tick = lambda eighths: int(round(eighths * TPQ / 2))
    conductor = [(0, 0, b"\xff\x58\x04" + bytes([6, 3, 0x24, 0x08])),          # 6/8, which AIVA imports
                 (0, 0, b"\xff\x59\x02" + bytes([0, 0])),                        # no accidentals (G Mixolydian)
                 (0, 1, b"\xff\x51\x03" + int(60e6 / (EIGHTH_BPM / 2)).to_bytes(3, "big"))]
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
    print(build("luta_bloom_epica", made))
    bar_s = 60 / EIGHTH_BPM * EIGHTHS_PER_BAR
    print(f"6/8 at eighth {EIGHTH_BPM}, bar {bar_s:.4f} s; loop {TOTAL_BARS} bars = {TOTAL_BARS * bar_s:.2f} s "
          f"from beat 0 (loop_offset 0)")
    for name, notes in made.items():
        ps = [q for ps_, *_ in notes for q in ps_]
        print(f"  {name:36} {len(notes):4} notes, MIDI {min(ps)}..{max(ps)}  -> {PATCHES[name.split(' ')[0]][1]}")
