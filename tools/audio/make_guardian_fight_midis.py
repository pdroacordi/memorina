"""Writes the four guardians' fight-loop sketches (tools/audio/midi/luta_<guardian>.mid), stems `bed` and `lead`.

Run: python -I tools/audio/make_guardian_fight_midis.py
Track names are the bare AIVA patch id (the stem is the dict key suffix). `lead` carries the drive (taiko, ostinato,
the flute and every modal colour note); GuardianMusic mutes it while a call is open. `bed` is what is left under the
call: sustained, built only from C D E G A (the pentatonic that holds the Memorina's four notes), never in C4..G4.
See docs/knowledge/music/guardian-fights.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_finale_midis as fm  # noqa: E402
from make_finale_midis import build  # noqa: E402

FLUTE, FLUTE_ST, VIOLA, VIOLAS, BASS, SOLO_BASS, HARP, PIANO, CLAR, TAIKO = (
    "w.flute2.nat.slur", "w.flute2.nat.stac", "s.solo-viola.nat.slur", "s.violas.nat.stac", "s.basses.vib.slur",
    "s.solo-bass.nat.slur", "s.harp2.pizz.stac", "k.pop-piano.nat.stac", "w.clarinet1.nat.slur", "p.taikos.nat.stac")
MOTIFS = {"congelar": ["G5", "E5", "D5", "C5", "C5", "C5"], "enraizar": ["C5", "D5", "C5", "E5", "C5", "G5"],
          "sombra": ["C5", "D5", "E5", "G5", "G5", "G5"], "soltar": ["G5", "C5", "D5", "C5", "E5", "C5"]}
BED_CLASSES = {"C", "D", "E", "G", "A"}


def at(n, beat=0.0):
    return (n - 1) * fm.BEATS_PER_BAR + beat


def quote(motif, n, step, vel, last):
    return [([p], at(n, k * step), step * 0.95 if k < 5 else last, vel) for k, p in enumerate(MOTIFS[motif])]


def held(chords, vel):
    """chords: (bar, pitches, bars held)."""
    return [(ps, at(n), bars * fm.BEATS_PER_BAR - 0.1, vel) for n, ps, bars in chords]


def set_meter(meter):
    # Must run before any at(): bars are counted in quarter beats of this meter.
    fm.BEATS_PER_BAR = meter[0] if meter[1] == 2 else meter[0] / 2


def write(name, bpm, meter, key, tracks):
    set_meter(meter)
    return build(name, [(0, bpm)], meter, key, tracks)


def frost():
    set_meter((4, 2))
    # A Aeolian, 120 BPM, 4/4, 16 bars (32 s); arena frozen lake (A minor, 50): same key, the lake's stillness at
    # 2.4x. Lead: taiko eighths, flute staccato ostinato on A-B-C-E (B and F are lead-only), Congelar at bar 9.
    plan = [(1, "A1", ["E3", "A3"]), (5, "C2", ["G3", "C3"]), (9, "A1", ["E3", "A3"]), (13, "G1", ["D3", "G3"])]
    bed = {f"{BASS} (bed)": held([(n, [r], 4) for n, r, _ in plan], 54),
           f"{VIOLA} (bed)": held([(n, d, 4) for n, _, d in plan], 44),
           f"{HARP} (bed)": [(["A5" if n < 13 else "G5"], at(n + k), 0.5, 36) for n, _, _ in plan for k in (0, 2)]}
    taiko, ost, flute = [], [], []
    for n in range(1, 17):
        taiko += [(["B1"], at(n, b * 0.5), 0.1, v) for b, v in enumerate((88, 50, 62, 50, 78, 50, 66, 70))]
        if n not in range(9, 11):
            ost += [([p], at(n, k * 0.5), 0.3, 62) for k, p in enumerate(["A5", "B5", "C6", "E6"] * 2)]
    flute += quote("congelar", 9, 1, 84, 4)
    flute += [(["F5"], at(15), 2, 80), (["E5"], at(15, 2), 2, 80), (["B4"], at(16), 2, 78), (["E5"], at(16, 2), 2, 78)]
    bass_drive = [(["A1"] if n < 13 else ["E1"], at(n, b), 0.4, 70) for n in range(1, 17) for b in (0, 1.5, 3)]
    return write("luta_frost", 120, (4, 2), (0, 1), {
        **bed, f"{TAIKO} (lead)": taiko, f"{FLUTE_ST} (lead)": ost, f"{FLUTE} (lead)": flute,
        f"{SOLO_BASS} (lead)": bass_drive})


def bloom():
    set_meter((6, 3))
    # G Mixolydian, 6/8 at dotted quarter 96 (quarter 144), 16 bars (20 s); arena spring woods (G Mixolydian, 6/8,
    # 72): same mode and meter, doubled. Lead: taiko in two dotted groups, violas staccato on G-A-B-D / F-G-A-C
    # (B and F lead-only), the clarinet (spring's voice in the finale) sings Enraizar at bar 9 in dotted quarters.
    bed = {f"{BASS} (bed)": held([(n, ["G1"] if (n - 1) % 8 < 4 else ["C2"], 4) for n in (1, 5, 9, 13)], 52),
           f"{HARP} (bed)": [([p], at(n, k * 1.5), 1.4, 40) for n in range(1, 17)
                             for k, p in enumerate(["G2", "D3"] if (n - 1) % 8 < 4 else ["C3", "G3"])],
           f"{VIOLA} (bed)": held([(1, ["A5", "D6"], 4), (5, ["G5", "C6"], 4), (9, ["A5", "D6"], 4),
                                   (13, ["G5", "E6"], 4)], 34)}
    taiko, violas = [], []
    for n in range(1, 17):
        taiko += [(["B1"], at(n, b), 0.1, v) for b, v in ((0, 86), (1, 56), (1.5, 76), (2.5, 60))]
        cell = ["G5", "A5", "B5", "D6", "B5", "A5"] if (n - 1) % 8 < 4 else ["F5", "G5", "A5", "C6", "A5", "G5"]
        if n not in range(9, 13):
            violas += [([p], at(n, k * 0.5), 0.3, 60) for k, p in enumerate(cell)]
    clar = quote("enraizar", 9, 1.5, 80, 3) + [(["F5"], at(13, 0), 1.4, 72), (["D5"], at(13, 1.5), 1.4, 72),
                                                (["G5"], at(14, 0), 3, 74)]
    return write("luta_bloom", 144, (6, 3), (1, 0), {
        **bed, f"{TAIKO} (lead)": taiko, f"{VIOLAS} (lead)": violas, f"{CLAR} (lead)": clar})


def summer():
    set_meter((4, 2))
    # C Lydian over a G pedal, 132 BPM, 4/4, 16 bars (29 s); arena summer caldera (C Lydian on a G pedal, 58): same
    # pedal, the noon that does not move. Lead: taiko, flute staccato with F# (lead-only), Sombra at bar 9 with the
    # solo viola a beat late an octave under as its shadow, as in Sombra's own piece (viola C4..G4: lead only).
    bed = {f"{PIANO} (bed)": [(["G1", "G2"], at(n, b), 0.5, 56) for n in range(1, 17) for b in (0, 2)],
           f"{BASS} (bed)": held([(n, ["G1"], 4) for n in (1, 5, 9, 13)], 48),
           f"{HARP} (bed)": [([p], at(n, k), 0.5, 38) for n in range(1, 17) for k, p in
                             enumerate(["A5", "C6", "E6", "D6"] if n % 2 else ["G5", "A5", "D6", "C6"])]}
    taiko = [(["B1"], at(n, b), 0.1, v) for n in range(1, 17)
             for b, v in ((0, 90), (0.75, 54), (1.5, 66), (2, 80), (2.75, 54), (3.5, 70))]
    ost = [([p], at(n, k * 0.5), 0.3, 60) for n in range(1, 17) if n not in (9, 10)
           for k, p in enumerate(["G5", "A5", "F#5", "G5", "E5", "F#5", "G5", "D6"])]
    flute = quote("sombra", 9, 1, 86, 6) + [(["F#5"], at(13), 2, 78), (["E5"], at(13, 2), 2, 78), (["D5"], at(14), 4, 76)]
    shadow = [([p[0] + str(int(p[1]) - 1)], at(9, k + 1), 0.95 if k < 5 else 5, 60)
              for k, p in enumerate(MOTIFS["sombra"])]
    return write("luta_summer", 132, (4, 2), (0, 0), {
        **bed, f"{TAIKO} (lead)": taiko, f"{FLUTE_ST} (lead)": ost, f"{FLUTE} (lead)": flute,
        f"{VIOLA} (lead)": shadow})


def autumn():
    set_meter((3, 2))
    # E Phrygian, 3/4 at 156, 24 bars (28 s); arena wind orchards (E Phrygian, 3/4, 60): same mode and meter, the
    # orchard's sigh made gusts. Lead: taiko hemiola (2 against 3), violas staccato falling F-E (the bII, lead-only),
    # flute Soltar at bar 13. The bed lets go: E, then C, then A, each held, never resolved upward.
    bed = {f"{BASS} (bed)": held([(1, ["E1"], 8), (9, ["C2"], 4), (13, ["A1"], 4), (17, ["E1"], 8)], 52),
           f"{VIOLA} (bed)": held([(1, ["E3", "G3"], 8), (9, ["E3", "G3"], 4), (13, ["E3", "A3"], 4),
                                   (17, ["D3", "G3"], 4), (21, ["E3", "G3"], 4)], 42),
           f"{HARP} (bed)": [(["E5" if n < 17 else "D5"], at(n), 1, 34) for n in range(1, 25, 2)]}
    taiko = [(["B1"], at(n, b), 0.1, v) for n in range(1, 25) for b, v in
             (((0, 88), (1, 52), (2, 68)) if n % 2 else ((0, 74), (1.0, 60), (2, 52)))]
    taiko += [(["B1"], at(n, 0) + 1.5, 0.1, 64) for n in range(2, 25, 2)]  # hemiola accent
    violas = [([p], at(n, k * 0.5), 0.35, 62) for n in range(1, 25) if n not in range(13, 17)
              for k, p in enumerate(["F5", "E5", "C5", "F5", "E5", "B4"] if n % 4 else ["F5", "E5", "D5", "C5", "B4", "A4"])]
    flute = quote("soltar", 13, 1, 84, 4) + [(["F5"], at(17, 1), 2, 76), (["E5"], at(18), 3, 74)]
    return write("luta_autumn", 156, (3, 2), (0, 1), {
        **bed, f"{TAIKO} (lead)": taiko, f"{VIOLAS} (lead)": violas, f"{FLUTE} (lead)": flute})


if __name__ == "__main__":
    for made in (frost(), bloom(), summer(), autumn()):
        print(made)
