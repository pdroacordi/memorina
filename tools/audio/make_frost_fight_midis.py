"""Writes the Frost Guardian's remade fight sketch (tools/audio/midi/luta_frost_epica.mid), proposal of 2026-11-18.

Run: python -I tools/audio/make_frost_fight_midis.py
D Dorian, 7/8 (2+2+3) at eighth = 360 (quarter 180), 120 bars of 7/6 s, one loop from beat 0 (140 s, loop_offset 0).
The game cue counts eighths: bpm 360, beats_per_bar 7. Two stems, lead and bed. Track names are
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
EIGHTH_BPM = 360
EIGHTHS_PER_BAR = 7
GROUPS = (0, 2, 4)           # 2+2+3: the eighth each group starts on
CRACK_GROUPS = (0, 3, 5)     # 3+2+2: the crack regroups the same bar
TOTAL_BARS = 120
DRUM_CHANNEL = 9

# AIVA patch id -> (GM program fallback, the AIVA patch to set). Drum kits have no program.
PATCHES = {
    "w.hulusi1.nat.slur": (79, "Hulusi 1 Sustain"), "s.violins.nat.stac": (40, "Violins 1 Spiccato"),
    "s.violas.nat.stac": (41, "Violas Spiccato"), "s.cellos.nat.stac": (42, "Celli Spiccato"),
    "k.celesta.nat.stac": (8, "Celesta Staccato"),
    "p.taikos.nat.stac": (None, "Epic Taikos Kit (35 Kick, 38 Snare Center)"),
    "p.orchestral-kit.nat.stac": (None, "Orchestral Kit (35 Kick, 38 Snare Center, 41 Crash Left)"),
    "s.basses.vib.slur": (43, "Basses Vibrato Legato"), "s.solo-cello.nat.slur": (42, "Solo Cello Legato"),
    "s.violins.trem.slur": (44, "Violins 1 Tremolo"), "s.harp2.pizz.stac": (46, "Harp 2 Pizzicato"),
}
DRUM_KITS = ("p.taikos.nat.stac", "p.orchestral-kit.nat.stac")
KICK, SNARE, CRASH = 35, 38, 41

CONGELAR = ["G", "E", "D", "C", "C", "C"]


def bar(m, eighth=0.0):
    """Bar m (1..120), in eighths."""
    return (m - 1) * EIGHTHS_PER_BAR + eighth


# One chord per two bars (Congelar spans two: G E D | C C C on the group starts).
UNITS = (["Dm", "G", "C", "Am", "Dm", "G", "F", "Am", "Dm", "G", "C", "Em", "F", "G", "Am", "Am"]   # A 1-32
         + ["Em", "F", "G", "Am", "C", "F", "Dm", "G", "C", "F", "G", "Am"]                       # B 33-56
         + ["Dm", "Dm", "C", "G", "Dm", "Dm", "F", "G", "Am", "F", "G", "Am"]                     # C 57-80
         + ["Dm", "Am", "G", "Dm", "Dm", "Am", "Em", "Am"]                                        # D 81-96
         + ["Dm", "G", "C", "F", "Dm", "G", "C", "Am", "F", "G", "Am", "Am"])                     # E 97-120
assert len(UNITS) * 2 == TOTAL_BARS


def chord(m):
    return UNITS[(m - 1) // 2]


def section(m):
    return "A" if m <= 32 else "B" if m <= 56 else "C" if m <= 80 else "D" if m <= 96 else "E"


SECTION_VEL = {"A": 92, "B": 100, "C": 110, "D": 70, "E": 96}
# The guardian's stop ("guardar que virou parar"): in the charge section every fourth bar is one tutti hit on its
# first eighth, then only the bed and the taiko kick on the group starts.
FROZEN = set(range(60, 81, 4))

# Bed: pitch classes C D E G A only (no semitone against G C D E), F and B only as roots at MIDI 47 or under; never in
# 48..55 (the Hulusi's call, G3 C3 D3 E3) or 60..67 (Ivo's answer, G4 C4 D4 E4).
#        basses  solo cello        violins tremolo   harp              cellos (lead)   violin cell (lead)
VOICING = {
    "Dm": ("D2", ["D2", "A2"],    ["D6", "A6"],     ["A5", "D6"],     ["D2", "A2"],   ["D5", "F5", "A5", "C6"]),
    "G":  ("G1", ["G2", "D2"],    ["D6", "G6"],     ["G5", "D6"],     ["G2", "D3"],   ["D5", "G5", "B5", "D6"]),
    "C":  ("C2", ["C2", "G2"],    ["E6", "G6"],     ["G5", "C6"],     ["C2", "G2"],   ["E5", "G5", "C6", "E6"]),
    "Am": ("A1", ["A2", "E2"],    ["A5", "E6"],     ["E6", "A6"],     ["A2", "E3"],   ["E5", "A5", "C6", "E6"]),
    "Em": ("E1", ["E2", "B2"],    ["E6", "G6"],     ["E6", "G6"],     ["E2", "B2"],   ["E5", "G5", "B5", "E6"]),
    "F":  ("F1", ["F2", "C2"],    ["A5", "C6"],     ["A5", "C6"],     ["F2", "C3"],   ["F5", "A5", "C6", "F6"]),
}
SCALE = ["D", "E", "F", "G", "A", "B", "C"]  # D Dorian


def bed():
    basses, cello, trem, harp = [], [], [], []
    for m in range(1, TOTAL_BARS + 1, 2):
        v, vel = VOICING[chord(m)], SECTION_VEL[section(m)]
        length = 2 * EIGHTHS_PER_BAR - 0.1
        basses.append(([p(v[0])], bar(m), length, min(vel, 100)))
        cello.append(([p(x) for x in v[1]], bar(m), length, max(vel - 16, 50)))
        trem.append(([p(x) for x in v[2]], bar(m), length, max(vel - 30, 40)))
        # Glass: a high pluck on each group start of the unit's first bar, once a bar in the breath.
        starts = (0,) if section(m) == "D" else GROUPS
        harp += [([p(v[3][k % 2])], bar(m, e), 1.5, max(vel - 34, 36)) for k, e in enumerate(starts)]
    return {"s.basses.vib.slur (bed)": basses, "s.solo-cello.nat.slur (bed)": cello,
            "s.violins.trem.slur (bed)": trem, "s.harp2.pizz.stac (bed)": harp}


# The violins' figure over seven eighths, indexes into the chord's cell (0..3). The bar is a mirror: it ends where it
# began, so nothing goes and nothing comes. "+n" is a semitone over cell[n] (the crack); the return runs up the
# Dorian scale instead (the water let run), then the loop mirrors again.
FIGURES = {"A": [0, 1, 2, 3, 2, 1, 0], "B": [3, "+2", 1, 0, 1, "+2", 3], "C": [0, 2, 1, 3, 1, 2, 0],
           "D": [2, 3, 2, 1, 2, 3, 2]}


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
        sec = section(m)
        cell = [p(x) for x in VOICING[chord(m)][5]]
        vel = SECTION_VEL[sec] - 4
        if m in FROZEN:
            out.append(([cell[3]], bar(m), 0.8, 118))
            continue
        if sec == "E":
            notes = scale_run(VOICING[chord(m)][5][0], 7)
        else:
            notes = [cell[int(f[1])] + 1 if isinstance(f, str) else cell[f] for f in FIGURES[sec]]
        for k, q in enumerate(notes):
            out.append(([q], bar(m, k), 0.8, vel + (12 if k in GROUPS else 0)))
    return out


def violas():
    """Repeated notes on the group pulse: root root | fifth fifth | root root fifth, an octave over the cellos."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        if sec == "D" or m in FROZEN:
            continue
        root, fifth = (p(x) + 12 for x in VOICING[chord(m)][4])
        pattern = [root, root, fifth, fifth, root, root, fifth]
        accents = CRACK_GROUPS if sec == "B" else GROUPS
        out += [([q], bar(m, k), 0.7, SECTION_VEL[sec] - 12 + (14 if k in accents else 0))
                for k, q in enumerate(pattern)]
    return out


def cellos():
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        root, fifth = (p(x) for x in VOICING[chord(m)][4])
        if m in FROZEN:
            out.append(([root, fifth], bar(m), 0.8, 120))
            continue
        accents = CRACK_GROUPS if sec == "B" else GROUPS
        for k in range(EIGHTHS_PER_BAR):
            q = root + 12 if k == 6 else fifth if k in (3, 5) else root
            out.append(([q], bar(m, k), 0.7, min(SECTION_VEL[sec] + (18 if k in accents else 0), 120)))
    return out


QUOTES = ((5, 4, 92), (21, 4, 96), (41, 4, 100), (57, 4, 110), (69, 4, 108), (85, 4, 76), (101, 4, 100),
          (113, 4, 104))
DOUBLED = (57, 101)


def congelar_at(m, octave, vel, shorten=0.1):
    return [([p(n + str(octave))], bar(m + k // 3, GROUPS[k % 3]), (2 if k % 3 < 2 else 3) - shorten, vel)
            for k, n in enumerate(CONGELAR)]


def hulusi():
    """The guardian's own flute: Congelar on the group starts (two bars), each answered in Dorian (its B).
    Kept in octave 4, the Hulusi's middle; the celesta doubles the climaxes two octaves up."""
    out = []
    for m, octave, vel in QUOTES:
        out += congelar_at(m, octave, vel)
        answer = [("A", 0, 2), ("C", 2, 2), ("B", 4, 3), ("A", 7, 7)]
        if m + 2 in FROZEN or m + 3 in FROZEN:  # over a stop the answer is one held note
            answer = [("A", 0, 14)]
        out += [([p(n + str(octave + (1 if n in ("C",) and octave == 4 else 0)))], bar(m + 2, e), ln - 0.1, vel - 6)
                for n, e, ln in answer]
    return out


def celesta():
    """Ice glints between the groups; denser in the breath, where they carry the line."""
    out, glints = [], ["A6", "E7", "D7", "G6", "C7"]
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        if m in FROZEN:
            out.append(([p("D7"), p("A7")], bar(m), 2, 100))
            continue
        spots = (1, 3, 5, 6) if sec == "D" else (1, 5) if sec in ("A", "E") else (3,)
        out += [([p(glints[(m + k) % 5])], bar(m, e), 0.5, SECTION_VEL[sec] - 20) for k, e in enumerate(spots)]
    for m in DOUBLED:
        out += congelar_at(m, 6, 96, shorten=1.5)
    return out


def drums():
    taiko, kit = [], []
    for m in range(1, TOTAL_BARS + 1):
        sec = section(m)
        if m in FROZEN:  # the low kick keeps the group pulse through the stop ("Bumbo continua", user, 2026-11-18)
            taiko += [([KICK], bar(m, g), 0.2, 124 if g == 0 else 96) for g in GROUPS]
            kit += [([CRASH], bar(m), 0.2, 112), ([KICK], bar(m), 0.2, 116)]
            continue
        groups = CRACK_GROUPS if sec == "B" else GROUPS
        loud = {"A": 110, "B": 112, "C": 118, "D": 90, "E": 110}[sec]
        hits = [(g, KICK, loud - (0 if g == 0 else 10)) for g in groups]
        if sec != "D":
            hits += [(e, SNARE, 64) for e in range(EIGHTHS_PER_BAR) if e not in groups]
        if m % 4 == 0 and sec != "D":  # fill: the last group in sixteenths
            hits = [h for h in hits if h[0] < 4] + [(4 + k * 0.5, SNARE, 70 + 7 * k) for k in range(6)]
        taiko += [([note], bar(m, e), 0.2, v) for e, note, v in hits]
        if sec in ("B", "C") or (sec == "E" and m >= 109):
            kit += [([SNARE], bar(m, e), 0.2, 92 if e in groups else 50) for e in range(EIGHTHS_PER_BAR)]
        elif sec == "D":
            kit += [([SNARE], bar(m, e), 0.2, 40) for e in range(EIGHTHS_PER_BAR)]
        else:
            kit += [([SNARE], bar(m, e), 0.2, 84) for e in (2, 4)]
    for m in (1, 17, 33, 57, 81, 97, 109):
        kit += [([CRASH], bar(m), 0.2, 110), ([KICK], bar(m), 0.2, 112)]
    for m in (32, 56, 96, 120):  # snare roll in sixteenths into the next section, replacing that bar's snare
        kit = [h for h in kit if not (h[0] == [SNARE] and bar(m) <= h[1] < bar(m + 1))]
        kit += [([SNARE], bar(m, k * 0.5), 0.2, 56 + 4 * k) for k in range(14)]
    return taiko, kit


def tracks():
    taiko, kit = drums()
    out = {"w.hulusi1.nat.slur (lead)": hulusi(), "s.violins.nat.stac (lead)": violins(),
           "s.violas.nat.stac (lead)": violas(), "s.cellos.nat.stac (lead)": cellos(),
           "k.celesta.nat.stac (lead)": celesta(), "p.taikos.nat.stac (lead)": taiko,
           "p.orchestral-kit.nat.stac (lead)": kit}
    out.update(bed())
    return out


SAFE = {0, 2, 4, 7, 9}         # C D E G A
LOW_ROOT_MAX = 47              # F and B only as roots at or under B2
CALL_RANGES = ((48, 55), (60, 67))  # the Hulusi's call (G3 C3 D3 E3) and Ivo's answer (G4 C4 D4 E4)


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
                if any(lo <= q <= hi for lo, hi in CALL_RANGES):
                    problems.append(f"{name}: {q} at eighth {start} inside a call range")
                if q % 12 not in SAFE and not (q % 12 in (5, 11) and q <= LOW_ROOT_MAX):
                    problems.append(f"{name}: pitch class {q % 12} ({q}) at eighth {start}")
    return problems


SECTIONS = ((1, "A the still lake"), (33, "B cracking"), (57, "C the charge"), (81, "D thin ice"),
            (97, "E let it run"))


def build(name, all_tracks):
    to_tick = lambda eighths: int(round(eighths * TPQ / 2))
    # AIVA's Import MIDI refuses 7/8 ("Invalid time signature"), so the file says 4/4; every note keeps its time.
    conductor = [(0, 0, b"\xff\x58\x04" + bytes([4, 2, 0x18, 0x08])),
                 (0, 0, b"\xff\x59\x02" + bytes([0, 1])),                        # no accidentals (D Dorian)
                 (0, 1, b"\xff\x51\x03" + int(60e6 / (EIGHTH_BPM / 2)).to_bytes(3, "big"))]
    for m, label in SECTIONS:
        text = label.encode()
        # At the nearest 4/4 bar line (8 eighths) of the file's meter.
        conductor.append((to_tick(round(bar(m) / 8) * 8), 2, b"\xff\x06" + vlq(len(text)) + text))
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
    print(build("luta_frost_epica", made))
    bar_s = 60 / EIGHTH_BPM * EIGHTHS_PER_BAR
    print(f"7/8 at eighth {EIGHTH_BPM}, bar {bar_s:.4f} s; loop {TOTAL_BARS} bars = {TOTAL_BARS * bar_s:.2f} s "
          f"from beat 0 (loop_offset 0)")
    for name, notes in made.items():
        ps = [q for ps_, *_ in notes for q in ps_]
        print(f"  {name:36} {len(notes):4} notes, MIDI {min(ps)}..{max(ps)}  -> {PATCHES[name.split(' ')[0]][1]}")
