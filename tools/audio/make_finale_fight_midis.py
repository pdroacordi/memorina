"""Writes the final battle's remade fight sketch (tools/audio/midi/finale_luta_epica.mid), v2 of 2026-11-18.

Run: python -I tools/audio/make_finale_fight_midis.py
A minor (with Bb, the crack), 200 BPM, 4/4, 128 bars of 1.2 s, one loop from beat 0 (153.6 s, loop_offset 0): the
fight is at full drive on its first beat. Harmony and sung lines are written on a plan of 64 two-bar units in
half-time (bar(), doubled by half_time()); the drive (strings, taikos, snare, harp, timpani) at 200 (fbar()).
Track names are "<AIVA patch id> (<stem>)"; INTENDED names the AIVA patch each is set to. check() enforces the stem
rules before writing. See docs/knowledge/music/final-battle.md.
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_miniature_midis import TPQ, chunk, vlq  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "midi")
BPM = 200
BEATS_PER_BAR = 4
HALF = 2                     # fight bars (and beats) per plan bar (and plan beat)
PLAN_BARS = 64
TOTAL_BARS = PLAN_BARS * HALF
DRUM_CHANNEL = 9

# AIVA patch id -> (GM program fallback, the AIVA patch to set). Drum kits have no program.
PATCHES = {
    "w.flute2.nat.slur": (73, "Flute 2 Legato"), "b.horns.nat.slur": (60, "9 Horns Legato"),
    "b.trombones.nat.stac": (57, "3 Bass Trombones Sustain"), "s.cellos.nat.stac": (42, "Celli Spiccato"),
    "s.violins.nat.stac": (40, "Violins 1 Spiccato"), "s.violas.nat.stac": (41, "Violas Staccato"),
    "p.taikos.nat.stac": (None, "Epic Taikos Kit (35 Kick, 38 Snare Center)"),
    "p.orchestral-kit.nat.stac": (None, "Orchestral Kit (35 Kick, 38 Snare Center, 41 Crash Left)"),
    "s.basses.vib.slur": (43, "Basses Vibrato Legato"), "v.choir.nat.slur": (52, "Male Choir Sustain"),
    "s.solo-viola.nat.slur": (41, "Solo Viola Legato"), "s.violins.nat.slur": (48, "Violins 1 Sustain"),
    "p.timpani.nat.stac": (47, "Timpani Hits"), "s.harp2.pizz.stac": (46, "Harp 2 Pizzicato"),
    "w.clarinet1.nat.slur": (71, "Clarinet 1 Legato"), "k.celesta.nat.stac": (8, "Celesta Staccato"),
}
DRUM_KITS = ("p.taikos.nat.stac", "p.orchestral-kit.nat.stac")
KICK, SNARE, CRASH = 35, 38, 41  # the kit channels mapped in AIVA; the taikos have only KICK and SNARE

NAMES = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8,
         "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def p(name):
    return 12 * (int(name[-1]) + 1) + NAMES[name[:-1]]


def bar(n, beat=0.0):
    """Plan bar n (1..64), plan beat: in plan beats; half_time() turns them into fight beats."""
    return (n - 1) * BEATS_PER_BAR + beat


def fbar(m, beat=0.0):
    """Fight bar m (1..128) at 200 BPM, in fight beats."""
    return (m - 1) * BEATS_PER_BAR + beat


def plan_of(m):
    return (m + 1) // HALF


def first_fight_bar(n):
    return (n - 1) * HALF + 1


def half_time(notes):
    return [(ps, b * HALF, ln * HALF, v) for ps, b, ln, v in notes]


# The motifs, exact (systems/music): Congelar, Enraizar, and the mentor's phrase A of the final call, the fight's theme
# ("Tema da luta (Recommended)", user, 2026-11-18).
CONGELAR = ["G", "E", "D", "C", "C", "C"]
ENRAIZAR = ["C", "D", "C", "E", "C", "G"]
PHRASE_A = ["G", "E", "D", "C", "D", "E"]


def motif(names, octave, start, rhythm, vel, octaves=None):
    """Six notes at `start` with `rhythm` [(offset, length)]; `octaves` overrides per note."""
    return [([p(n + str(octaves[k] if octaves else octave))], start + o, ln, vel)
            for k, (n, (o, ln)) in enumerate(zip(names, rhythm))]


# One chord per plan bar (two fight bars). Bed voicings use only A C D E G Bb (no semitone against the call notes
# G C D E); F and B only as low roots (MIDI 47 or under), never in MIDI 60..67. Lead and spring carry the rest.
CHORDS = {}
for n, c in enumerate(
        ["Am", "Am", "F", "F", "Dm", "Dm", "Esus", "E"]                        # plan 1-8 A, winter
        + ["Am", "Am", "F", "G", "Am", "F", "Bb", "E"]                         # 9-16
        + ["Am", "Bb", "Am", "Bb", "Gm", "Am", "Bb", "E"]                      # 17-24 B, the crack
        + ["Dm", "Bb", "C", "Bb", "Am", "Bb", "Bb", "E"]                       # 25-32
        + ["Am", "F", "C", "G", "Am", "F", "Dm", "E"]                          # 33-40 C, keeping
        + ["Am", "Am", "Bb", "Bb", "Am", "Am", "Bb", "E"]                      # 41-48 the hammered C
        + ["Am", "Fmaj7", "Am", "Fmaj7", "Dm", "Bb", "Esus", "E"]              # 49-56 D, breath
        + ["Am", "Am", "F", "F", "Dm", "Bb", "Esus", "E"], start=1):           # 57-64 E, return
    CHORDS[n] = c

# The male choir sings only under C4 (bed rule), so it takes the low voicing and the solo viola's top note.
#          basses   choir low          solo viola       violins (bed)   timpani  cellos           violin cell
VOICING = {
    "Am":    ("A1", ["A2", "E3"],     ["C3", "E3"],    ["A5", "E6"],  "A2", ["A2", "E3"],  ["E5", "A5", "C6", "E6"]),
    "F":     ("F1", ["F2", "C3"],     ["A3", "C3"],    ["C6", "A5"],  "F2", ["F2", "C3"],  ["F5", "A5", "C6", "F6"]),
    "Fmaj7": ("F1", ["F2", "C3"],     ["A3", "E3"],    ["E6", "A5"],  "F2", ["F2", "C3"],  ["E5", "A5", "C6", "E6"]),
    "Dm":    ("D2", ["D3", "A3"],     ["A3", "D3"],    ["A5", "D6"],  "D2", ["D2", "A2"],  ["D5", "F5", "A5", "D6"]),
    "Esus":  ("E1", ["E2", "B2"],     ["A3", "E3"],    ["E6", "A6"],  "E2", ["E2", "B2"],  ["E5", "A5", "B5", "E6"]),
    "E":     ("E1", ["E2", "B2"],     ["D3", "E3"],    ["E6", "D6"],  "E2", ["E2", "B2"],  ["E5", "G#5", "B5", "E6"]),
    "G":     ("G1", ["G2", "D3"],     ["G3", "D3"],    ["G5", "D6"],  "G2", ["G2", "D3"],  ["D5", "G5", "B5", "D6"]),
    "C":     ("C2", ["C3", "G3"],     ["E3", "G3"],    ["E6", "G6"],  "C3", ["C3", "G3"],  ["E5", "G5", "C6", "E6"]),
    "Bb":    ("Bb1", ["Bb2", "D3"],   ["D3", "Bb3"],   ["D6", "E6"],  "Bb2", ["Bb2", "F3"], ["D5", "F5", "Bb5", "D6"]),
    "Gm":    ("G1", ["G2", "D3"],     ["Bb3", "D3"],   ["G5", "D6"],  "G2", ["G2", "D3"],  ["D5", "G5", "Bb5", "D6"]),
}


def section(n):
    """Section of plan bar n."""
    return "A" if n <= 16 else "B" if n <= 32 else "C" if n <= 48 else "D" if n <= 56 else "E"


def fsection(m):
    return section(plan_of(m))


SECTION_VEL = {"A": 90, "B": 98, "C": 110, "D": 72, "E": 92}
HAMMER_FROM = first_fight_bar(41)  # fight bar 81: Congelar's C hammered


def fchord(m):
    return VOICING[CHORDS[plan_of(m)]]


def runs():
    """Plan bars grouped into runs of one chord inside a section: [(first bar, bars)]."""
    out, n = [], 1
    while n <= PLAN_BARS:
        m = n
        while m + 1 <= PLAN_BARS and CHORDS[m + 1] == CHORDS[n] and section(m + 1) == section(n):
            m += 1
        out.append((n, m - n + 1))
        n = m + 1
    return out


def bed_sustain():
    """Held harmony, in plan beats."""
    basses, choir, viola, violins = [], [], [], []
    for n, length in runs():
        sec, v = section(n), VOICING[CHORDS[n]]
        vel = SECTION_VEL[sec]
        beats = length * BEATS_PER_BAR - 0.05
        basses.append(([p(v[0])], bar(n), beats, min(vel, 100)))
        choir.append(([p(x) for x in sorted(set(v[1] + v[2]), key=p)], bar(n), beats, max(vel - 14, 50)))
        viola.append(([p(x) for x in v[2]], bar(n), beats, max(vel - 20, 46)))
        if sec != "A" or n >= 9:
            violins.append(([p(x) for x in v[3]], bar(n), beats, max(vel - 26, 40)))
    return {"s.basses.vib.slur (bed)": basses, "v.choir.nat.slur (bed)": choir,
            "s.solo-viola.nat.slur (bed)": viola, "s.violins.nat.slur (bed)": violins}


def timpani():
    """At 200: a stroke on every downbeat (the pulse stays under a call), two in the climax, a roll into the loop."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec, root = fsection(m), fchord(m)[4]
        if m == TOTAL_BARS:
            out += [([p("E2")], fbar(m, k / 4), 0.24, 64 + 3 * k) for k in range(16)]
            continue
        out.append(([p(root)], fbar(m), 0.5, 118 if m == 1 else 70 if sec == "D" else 92))
        if sec == "C" or m % 8 == 0:
            out.append(([p(root)], fbar(m, 2), 0.5, 82))
    return out


# Eighths per bar at 200 for the cellos: R root, F fifth, O root an octave up.
OSTINATO = "RRFRORFR"


def cellos():
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = fsection(m)
        root, fifth = (p(x) for x in fchord(m)[5])
        accents = (0, 3, 6) if sec in ("B", "C") else (0, 4)
        for k in range(8):
            pitch = {"R": root, "F": fifth, "O": root + 12}[OSTINATO[k]]
            vel = SECTION_VEL[sec] + (18 if k in accents else 0)
            out.append(([pitch], fbar(m, k * 0.5), 0.4, min(vel, 120)))
    return out


# The violins' restless figure, eighths at 200 over the chord's cell (indexes 0..3, low to high). "+" is the note a
# semitone above the previous index (E-F, A-Bb: the crack). Every fourth bar ends on a sixteenth burst.
FIGURES = {"A": [0, 1, 2, 1, 3, 2, 1, 2], "B": [0, "+0", 1, "+1", 0, "+0", 2, 1], "C": [3, 2, 3, 1, 3, 2, 3, 0],
           "D": [1, 2, 1, 2, 1, 2, 1, 2], "E": [0, 1, 2, 3, 0, 1, 2, 3]}


def violins_fast():
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec, cell = fsection(m), [p(x) for x in fchord(m)[6]]
        lift = 12 if sec == "E" and m >= 121 else 0
        vel = SECTION_VEL[sec] - 6
        figure = FIGURES[sec]
        burst = m % 4 == 0 and sec != "D"
        for k in range(6 if burst else 8):
            f = figure[k]
            pitch = cell[int(f[1])] + 1 if isinstance(f, str) else cell[f]
            out.append(([pitch + lift], fbar(m, k * 0.5), 0.4, vel + (10 if k % 4 == 0 else 0)))
        if burst:  # four sixteenths falling from the top of the cell
            out += [([cell[3 - k] + lift], fbar(m, 3 + k * 0.25), 0.22, vel + 6) for k in range(4)]
    return out


def violas_gallop():
    """Eighth-two-sixteenths on root, root, fifth (an octave over the cellos); syncopated off-beats in the crack;
    silent in the breath, which thins to cellos, violins and drums."""
    out = []
    for m in range(1, TOTAL_BARS + 1):
        sec = fsection(m)
        root, fifth = (p(x) + 12 for x in fchord(m)[5])
        vel = SECTION_VEL[sec] - 10
        if sec == "D":
            continue
        if sec == "B":
            out += [([root, fifth], fbar(m, b), 0.4, vel + 8) for b in (0.5, 1.5, 2.5, 3.5)]
            continue
        for b in range(4):
            out += [([root], fbar(m, b), 0.45, vel + 8), ([root], fbar(m, b + 0.5), 0.22, vel),
                    ([fifth], fbar(m, b + 0.75), 0.22, vel)]
    return out


def trombone_stabs():
    """At 200: the opening hit, the 3+3+2 stabs of the crack, the cadence stabs on each V."""
    out = [([p("A1"), p("E2"), p("A2")], fbar(1), 1.5, 116)]
    for m in range(first_fight_bar(17), first_fight_bar(33) - 1):  # bar 64 takes the cadence stab
        chord = fchord(m)[5]
        stab = [p(chord[0]), p(chord[1]), p(chord[0]) + 12]
        out += [(stab, fbar(m, b), 0.4, 104 if b == 0 else 92) for b in (0, 1.5, 3)]
    for m, vel in ((16, 100), (32, 104), (64, 112), (96, 116)):
        out += [([p("E2"), p("B2"), p("G#3")], fbar(m, b), 0.4 if b < 3 else 0.9, vel) for b in (0, 1.5, 3)]
    return out


def sung_lines():
    """Brass and flute, in plan beats (half-time at 200)."""
    horns, flute, trombones = [], [], []
    q = [(0, 1.5), (1.5, 0.5), (2, 2), (4, 2), (6, 1), (7, 1)]  # Congelar: G. E D | C C C
    a = [(0, 1.5), (1.5, 0.5), (2, 1), (3, 1), (4, 1), (5, 3)]  # Phrase A: G. E D C | D E___
    # A, winter: horns Congelar from beat 0 over the full drive, its answer; phrase A with the flute an octave up,
    # its E over the Bb (the crack).
    horns += motif(CONGELAR, 4, bar(1), q, 96)
    horns += [([p("A4")], bar(3), 3, 90), ([p("G4")], bar(3, 3), 1, 88), ([p("F4")], bar(4), 2, 90),
              ([p("E4")], bar(4, 2), 2, 88)]
    horns += [([p("D4")], bar(5), 2, 90), ([p("E4")], bar(5, 2), 1, 90), ([p("F4")], bar(5, 3), 1, 92),
              ([p("E4")], bar(6), 4, 90), ([p("A4")], bar(7), 2, 94), ([p("G4")], bar(7, 2), 1, 92),
              ([p("F4")], bar(7, 3), 1, 92), ([p("E4")], bar(8), 4, 96)]
    horns += motif(PHRASE_A, 4, bar(9), a, 98)
    flute += motif(PHRASE_A, 5, bar(9), a, 88)
    horns += [([p("A4")], bar(11), 2, 96), ([p("C5")], bar(11, 2), 2, 98), ([p("B4")], bar(12), 2, 98),
              ([p("D5")], bar(12, 2), 2, 100), ([p("C5")], bar(13), 2, 100), ([p("B4")], bar(13, 2), 1, 96),
              ([p("A4")], bar(13, 3), 1, 96)]
    horns += motif(PHRASE_A, 4, bar(14), a, 100)  # its E lands on the Bb (plan 15)
    flute += motif(PHRASE_A, 5, bar(14), a, 90)
    horns += [([p("E4")], bar(16), 4, 104)]
    # B, the crack: Congelar over Am-Bb; phrase A twice; the flute's E-F shards.
    horns += motif(CONGELAR, 4, bar(17), q, 100)
    horns += [([p("C4")], bar(19), 4, 98), ([p("D4")], bar(20), 2, 98), ([p("E4")], bar(20, 2), 2, 100)]
    horns += motif(PHRASE_A, 4, bar(21), a, 100)  # over Gm and Am
    horns += motif(PHRASE_A, 4, bar(23), a, 104)  # begun over the Bb, its E lands on the E
    for n in (18, 20, 23, 26, 28, 30):
        for b in (1, 3):
            flute += [([p("E6")], bar(n, b), 0.25, 92), ([p("F6")], bar(n, b + 0.25), 0.25, 98)]
    # Plan 25-32: a line in octaves that sinks by step onto the leading tone, G# over the E.
    for n, beat, top, beats in ((25, 0, "D5", 4), (26, 0, "C5", 4), (27, 0, "E5", 4), (28, 0, "D5", 4),
                                (29, 0, "C5", 2), (29, 2, "B4", 2), (30, 0, "Bb4", 4), (31, 0, "A4", 4),
                                (32, 0, "G#4", 4)):
        horns.append(([p(top), p(top) - 12], bar(n, beat), beats - 0.05, 104))
    # C, keeping: tutti Congelar broad, phrase A, then Congelar's C hammered (eighths at 200), given up a semitone,
    # C to B, into the breath.
    broad = [(0, 2), (2, 2), (4, 2), (6, 2), (8, 4), (12, 4)]
    horns += motif(CONGELAR, 4, bar(33), broad, 112)
    flute += motif(CONGELAR, 5, bar(33), broad, 100)
    even = [(0, 1), (1, 1), (2, 1), (3, 1), (4, 1), (5, 3)]
    horns += motif(PHRASE_A, 4, bar(37), even, 112)
    flute += motif(PHRASE_A, 5, bar(37), even, 100)
    horns += [([p("F4"), p("A4")], bar(39), 2, 110), ([p("E4"), p("G4")], bar(39, 2), 1, 108),
              ([p("D4"), p("F4")], bar(39, 3), 1, 108), ([p("E4"), p("G#4")], bar(40), 4, 116)]
    flute += [([p("A5")], bar(39), 2, 100), ([p("G5")], bar(39, 2), 1, 98), ([p("F5")], bar(39, 3), 1, 98),
              ([p("E5")], bar(40), 4, 104)]
    for n in range(41, 49):
        last = n == 48
        for k in range(8 if not last else 4):
            horns.append(([p("C5"), p("C4")], bar(n, k * 0.5), 0.45, 108 + (8 if k % 4 == 0 else 0)))
        flute.append(([p("C6")], bar(n), 4 if not last else 2, 96))
    horns.append(([p("B4"), p("B3")], bar(48, 2), 2, 112))
    flute.append(([p("B5")], bar(48, 2), 2, 100))
    # D, breath (thinner, still driven): one horn sings phrase A broad, then the flute, its E over the Bb.
    horns += motif(PHRASE_A, 4, bar(49), broad, 80)
    flute += motif(PHRASE_A, 5, bar(53), [(0, 1.5), (1.5, 0.5), (2, 1), (3, 1), (4, 1), (5, 11)], 76)
    # E, return: phrase A in the horns, then the held E fortissimo over the V, into beat 0.
    horns += motif(PHRASE_A, 4, bar(61), [(0, 1.5), (1.5, 0.5), (2, 1), (3, 1), (4, 2), (6, 2)], 100)
    horns += [([p("E4"), p("E5")], bar(63), 8, 112)]
    trombones += [([p("E2"), p("B2"), p("G#3")], bar(63), 7.5, 110)]
    flute += [([p("E6")], bar(63), 7.5, 96)]
    return horns, flute, trombones


def drums():
    """At 200, from beat 0. Taikos (kick, snare): a driving bar in winter, 3+3+2 in the crack, every beat in the
    hammered C, kick on 1 and 3 in the breath; a fill each four bars, a longer one each eight. Snare: backbeat in
    winter, running eighths in the crack, the climax and the return, soft eighths in the breath."""
    taiko, kit = [], []
    for m in range(1, TOTAL_BARS + 1):
        sec = fsection(m)
        if sec == "B":
            hits = [(0, KICK, 114), (1.5, KICK, 104), (3, KICK, 108), (0.5, SNARE, 62), (2.5, SNARE, 64),
                    (3.5, SNARE, 88)]
        elif sec == "C" and m >= HAMMER_FROM:
            hits = [(b, KICK, 118 if b % 2 == 0 else 104) for b in range(4)] + [(b + 0.5, SNARE, 76) for b in range(4)]
        elif sec == "D":
            hits = [(0, KICK, 96), (2, KICK, 86), (3.5, SNARE, 60)]
        else:
            loud = 116 if sec == "C" else 110
            hits = [(0, KICK, loud), (1.5, SNARE, 76), (2, KICK, loud - 8), (3, SNARE, 80), (3.5, SNARE, 88)]
            if sec == "C":
                hits += [(1, SNARE, 70), (2.5, SNARE, 72)]
        if sec != "D" and m % 8 == 0:
            hits = [h for h in hits if h[0] < 1] + [(1 + k * 0.25, SNARE if k % 2 else KICK, 70 + 4 * k)
                                                   for k in range(12)]
        elif m % 4 == 0:
            hits = [h for h in hits if h[0] < 3] + [(3 + k * 0.25, SNARE, 76 + 8 * k) for k in range(4)]
        taiko += [([note], fbar(m, b), 0.1, v) for b, note, v in hits]
        if sec in ("B", "C") or (sec == "E" and m >= 117):
            kit += [([SNARE], fbar(m, k * 0.5), 0.1, (94 if k in (0, 3, 6) else 56)) for k in range(8)]
        elif sec == "D":
            kit += [([SNARE], fbar(m, k * 0.5), 0.1, 40 + (14 if k % 4 == 0 else 0)) for k in range(8)]
        else:
            kit += [([SNARE], fbar(m, b), 0.1, 86) for b in (1, 3)]
    for m in (1, 17, 33, 49, 65, 81, 113):  # crash and kick at each section and phrase start
        kit += [([CRASH], fbar(m), 0.1, 110), ([KICK], fbar(m), 0.1, 112)]
    kit += [([CRASH], fbar(97), 0.1, 80)]
    for m in (16, 32, 64, 80, 128):  # snare roll into the next section (16ths at 200), replacing that bar's snare
        kit = [h for h in kit if not (h[0] == [SNARE] and fbar(m) <= h[1] < fbar(m + 1))]
        kit += [([SNARE], fbar(m, k / 4), 0.1, 56 + 4 * k) for k in range(16)]
    return taiko, kit


def spring():
    """G Mixolydian against the A-minor winter. The harp runs at 200 on a dotted-quarter grid (1.5 beats: 6/8
    across the 4/4); the clarinet's Enraizar is in plan beats (half-time). Held notes only G A C D E."""
    harp, celesta = [], []
    cells = [["G2", "D3", "A3"], ["C3", "G3", "D3"]]
    for i in range(int(fbar(TOTAL_BARS + 1) / 1.5)):
        beat = i * 1.5
        sec = fsection(int(beat // BEATS_PER_BAR) + 1)
        cell = cells[(i // 8) % 2]
        vel = {"A": 58, "B": 64, "C": 72, "D": 54, "E": 60}[sec]
        harp.append(([p(cell[i % 3])], beat, 0.75, vel))
        if i % 4 == 0:
            harp.append(([p("B5") if cell is cells[0] else p("A5")], beat + 0.5, 0.25, vel - 12))
        if sec in ("C", "D", "E") and i % 3 == 1:
            celesta.append(([p(["G6", "D6", "E6", "A6", "C7"][i % 5])], beat + 0.5, 0.5, vel - 12))
    clarinet = []
    dotted = [(k * 1.5, 1.4 if k < 5 else 3) for k in range(6)]
    for start, octave, vel in ((bar(5), 5, 70), (bar(13), 5, 72), (bar(17, 0.5), 5, 78), (bar(25), 5, 80),
                               (bar(33, 0.5), 5, 88), (bar(37), 6, 86), (bar(57), 5, 72), (bar(61, 0.5), 5, 80)):
        clarinet += motif(ENRAIZAR, octave, start, dotted, vel)
    # The breath: Enraizar broad, answering the horn's phrase A (the two he held, one bar apart).
    clarinet += motif(ENRAIZAR, 5, bar(50), [(0, 2), (2, 2), (4, 2), (6, 2), (8, 2), (10, 6)], 68)
    return {"s.harp2.pizz.stac (spring)": harp, "w.clarinet1.nat.slur (spring)": half_time(clarinet),
            "k.celesta.nat.stac (spring)": celesta}


def tracks():
    horns, flute, trombones = sung_lines()
    taiko, kit = drums()
    out = {"w.flute2.nat.slur (lead)": half_time(flute), "b.horns.nat.slur (lead)": half_time(horns),
           "b.trombones.nat.stac (lead)": half_time(trombones) + trombone_stabs(),
           "s.violins.nat.stac (lead)": violins_fast(), "s.violas.nat.stac (lead)": violas_gallop(),
           "s.cellos.nat.stac (lead)": cellos(), "p.taikos.nat.stac (lead)": taiko,
           "p.orchestral-kit.nat.stac (lead)": kit}
    out.update({k: half_time(v) for k, v in bed_sustain().items()})
    out["p.timpani.nat.stac (bed)"] = timpani()
    out.update(spring())
    return out


SAFE = {0, 2, 4, 7, 9}        # C D E G A: consonant with every call note
BED_EXTRA = {10}              # Bb: a whole tone from C, a tritone from E; no semitone against G C D E
LOW_ROOT_MAX = 47             # F and B may sound in the bed only as roots at or under B2
CALL_LOW, CALL_HIGH = 60, 67  # C4..G4, where the call notes sound
SPRING_HELD = 1.0             # fight beats (0.3 s at 200): a spring colour note (B, F) may last no longer


def check(all_tracks):
    """Returns a list of rule violations (empty when the sketch keeps the stem contract). Beats are fight beats."""
    problems, end = [], fbar(TOTAL_BARS + 1)
    for name, notes in all_tracks.items():
        stem = name.split("(")[1].rstrip(")")
        patch = name.split(" ")[0]
        for pitches, beat, length, vel in notes:
            if beat < 0 or beat + length > end + 1e-6:
                problems.append(f"{name}: note at {beat} + {length} outside the {TOTAL_BARS} bars")
            if not 1 <= vel <= 127:
                problems.append(f"{name}: velocity {vel}")
            if patch in DRUM_KITS:
                allowed = (KICK, SNARE) if patch == "p.taikos.nat.stac" else (KICK, SNARE, CRASH)
                problems += [f"{name}: unmapped drum {q}" for q in pitches if q not in allowed]
                continue
            for q in pitches:
                if stem != "lead" and CALL_LOW <= q <= CALL_HIGH:
                    problems.append(f"{name}: {q} at beat {beat} inside C4..G4")
                pc = q % 12
                if stem == "bed" and pc not in SAFE | BED_EXTRA and not (pc in (5, 11) and q <= LOW_ROOT_MAX):
                    problems.append(f"{name}: pitch class {pc} ({q}) at beat {beat} in the bed")
                if stem == "spring" and pc not in SAFE and length > SPRING_HELD:
                    problems.append(f"{name}: held colour note {q} ({length} beats) at beat {beat} in spring")
    return problems


SECTIONS = ((1, "A winter"), (33, "B the crack"), (65, "C keeping"), (81, "C the hammered C"), (97, "D breath"),
            (113, "E return"))


def build(name, all_tracks):
    conductor = [(0, 0, b"\xff\x58\x04" + bytes([4, 2, 0x18, 0x08])),
                 (0, 0, b"\xff\x59\x02" + bytes([0, 1])),  # A minor
                 (0, 1, b"\xff\x51\x03" + int(60e6 / BPM).to_bytes(3, "big"))]
    for m, label in SECTIONS:  # a marker at each section, for the editor
        text = label.encode()
        conductor.append((int(fbar(m) * TPQ), 2, b"\xff\x06" + vlq(len(text)) + text))
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
        for pitches, beat, length, vel in notes:
            for q in pitches:
                ev.append((int(round(beat * TPQ)), 3, bytes([0x90 | ch, q, vel])))
                ev.append((int(round((beat + length) * TPQ)) - 1, 2, bytes([0x80 | ch, q, 0])))
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
    print(build("finale_luta_epica", made))
    bar_s = 60 / BPM * BEATS_PER_BAR
    print(f"{BPM} BPM, bar {bar_s:.2f} s; loop {TOTAL_BARS} bars = {TOTAL_BARS * bar_s:.2f} s from beat 0 "
          f"(loop_offset 0)")
    for name, notes in made.items():
        ps = [q for ps_, *_ in notes for q in ps_]
        print(f"  {name:38} {len(notes):4} notes, MIDI {min(ps)}..{max(ps)}  -> {PATCHES[name.split(' ')[0]][1]}")
