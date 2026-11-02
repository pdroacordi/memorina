"""Writes the reduced-version miniatures (tools/audio/midi/miniatura_<song>.mid): motif as in the full piece, an answer, a closing cadence and the season's gesture.

Run: python -I tools/audio/make_miniature_midis.py
The motif copies the full piece's notes, rhythm and tempo map, so Song.note_cues serves track and excerpt.
Last note-off stays under ~10.9 s: AIVA adds ~0.57 s before it and ~2.6 s of reverb after (rule: 10-14 s audible).
See docs/knowledge/music/reduced-versions.md.
"""
import os
import struct

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "midi")
TPQ = 480
DRUMS = 9
# AIVA patch id -> General MIDI program (0-based); AIVA maps by the track name, the program is a fallback.
GM = {"w.flute2.nat.slur": 73, "w.flute2.nat.stac": 73, "w.clarinet1.nat.slur": 71,
      "s.solo-viola.nat.slur": 41, "s.violas.nat.stac": 41, "s.solo-bass.nat.slur": 43,
      "s.basses.vib.slur": 43, "s.harp2.pizz.stac": 46, "k.pop-piano.nat.stac": 0}
PITCH = {n + str(o): 12 * (o + 1) + s for o in range(0, 8)
         for n, s in {"C": 0, "D": 2, "E": 4, "F": 5, "F#": 6, "G": 7, "A": 9, "B": 11}.items()}


def line(notes, vel):
    """[(pitch, beat, length)] -> [(pitches, beat, length, velocity)]."""
    return [([p], b, n, vel) for p, b, n in notes]


def hits(pitch, beats, vel):
    return [([pitch], b, 0.1, vel) for b in beats]


# song: (tempo map [(beat, bpm)], meter (num, denom power), key (sharps, minor), tracks {patch id: notes})
MINIATURES = {
    # A minor, 4/4. Hymn of Frost's motif and rubato (52 -> 62); F, Dm, Esus4 -> Em (minor v, no G#), Am under
    # a ritardando. Ice: high piano fifths A5 E6 after the arrival.
    "congelar": ([(0, 52), (0.5, 53), (2, 58), (3.5, 62), (5, 60), (6, 56), (7, 50), (8, 46)], (4, 2), (0, 1), {
        "w.flute2.nat.slur": line([
            ("G5", 0, 0.67), ("E5", 0.75, 0.5), ("D5", 1.25, 0.67), ("C5", 2, 0.42), ("C5", 2.5, 0.5),
            ("C5", 37 / 12, 0.42), ("A5", 3.5, 0.5), ("A5", 4, 1.5), ("G5", 5.5, 0.5), ("E5", 6, 1),
            ("D5", 7, 0.5), ("B4", 7.5, 0.5), ("A4", 8, 1.75)], 74),
        "s.solo-viola.nat.slur": [
            (["C4", "F4", "A4"], 4, 2, 64), (["D4", "F4", "A4"], 6, 1, 64),
            (["B3", "E4", "A4"], 7, 0.5, 62), (["B3", "E4", "G4"], 7.5, 0.5, 60),
            (["C4", "E4", "A4"], 8, 1.75, 58)],
        "k.pop-piano.nat.stac": [
            (["F1"], 4, 2, 70), (["D2"], 6, 1, 66), (["E1"], 7, 1, 66),
            (["A1", "E2", "A2"], 8, 1.75, 64), (["A5", "E6"], 8.5, 1.25, 40)],
    }),
    # A Dorian, 6/8 at 110. Restless Wind's staccato motif; Am, G, D (the Dorian major IV, violas borrow F#)
    # -> Am, a plagal close. Ice: two high violas taps on the held tonic, the taiko's pulse stops.
    "redoma": ([(0, 110), (9, 104), (10, 96), (11, 86), (12, 76)], (6, 3), (0, 1), {
        "w.flute2.nat.stac": line([
            ("D5", 0, 0.5), ("E5", 0.5, 0.5), ("D5", 1, 0.5), ("E5", 1.5, 0.5), ("G5", 2, 0.5), ("C5", 2.5, 0.5),
            ("B4", 3, 0.5), ("C5", 3.5, 0.5), ("D5", 4, 0.5), ("E5", 4.5, 0.5), ("D5", 5, 1),
            ("C5", 6, 0.5), ("B4", 6.5, 0.5), ("A4", 7, 0.5), ("B4", 7.5, 0.5), ("C5", 8, 1),
            ("D5", 9, 1), ("B4", 10, 0.5), ("C5", 10.5, 0.5), ("B4", 11, 1), ("A4", 12, 2.5)], 110),
        "s.violas.nat.stac": [
            (["A3", "C4", "E4"], 3, 3, 40), (["G3", "B3", "D4"], 6, 3, 42), (["A3", "D4", "F#4"], 9, 3, 44),
            (["A3", "C4", "E4"], 12, 2.5, 40), (["E5"], 12.75, 0.25, 36), (["A5"], 13.25, 0.25, 32)],
        "s.basses.vib.slur": [(["A1"], 3, 3, 64), (["G1"], 6, 3, 64), (["D2"], 9, 3, 64), (["A1"], 12, 2.5, 60)],
        "p.taikos.nat.stac": hits("B1", [3, 4.5, 6, 7.5, 9, 10.5, 12], 60),
        "p.orchestral-kit.nat.stac": hits("B1", [12], 50),
    }),
    # E Phrygian, 3/4 at 61. Hollow Bark's motif; Am, F (bII) -> Em, the Phrygian cadence with the flute's
    # F5 -> E5. Leaves: the viola falls B4 G4 E4 B3 in drifting rhythm under the held E5.
    "soltar": ([(0, 61), (8, 54), (9, 48), (10, 44)], (3, 2), (0, 1), {
        "w.flute2.nat.slur": line([
            ("G5", 0, 0.5), ("C5", 0.5, 0.5), ("D5", 1, 0.5), ("C5", 1.5, 0.5), ("E5", 2, 0.5), ("C5", 2.5, 0.5),
            ("C5", 3, 0.5), ("D5", 3.5, 0.5), ("E5", 4, 1), ("D5", 5, 0.5), ("C5", 5.5, 0.5),
            ("A4", 6, 1), ("C5", 7, 1), ("F5", 8, 1), ("E5", 9, 1.5)], 72),
        "s.solo-viola.nat.slur": [
            (["A3", "C4", "E4"], 3, 3, 64), (["F3", "A3", "C4"], 6, 3, 64),
            (["B4"], 9, 0.5, 56), (["G4"], 9.5, 0.5, 52), (["E4"], 9.875, 0.375, 48), (["B3"], 10.25, 0.25, 44)],
        "s.solo-bass.nat.slur": [(["A2"], 3, 3, 64), (["F2"], 6, 3, 64), (["E2"], 9, 1.5, 60)],
    }),
    # E minor, 4/4 at 72, no ritardando. Bare Branches' motif over its quiet piano E1 -> C2; a driving eighth-note
    # answer over Am (iv), Bm (v, minor, no D#); a rising sixteenth gust B4 C5 D5 E5 that stops on a short accented
    # Em at beat 10. Refused 2026-11-02 when the ending faded; see reduced-versions.md.
    "vendaval": ([(0, 72)], (4, 2), (1, 1), {
        "w.flute2.nat.slur": line([
            ("E5", 0, 1), ("E5", 1, 1), ("D5", 2, 1), ("D5", 3, 1), ("G5", 4, 1), ("E5", 5, 1),
            ("A5", 6, 0.5), ("G5", 6.5, 0.5), ("E5", 7, 0.5), ("C5", 7.5, 0.5),
            ("D5", 8, 0.5), ("F#5", 8.5, 0.5), ("B4", 9, 0.25), ("C5", 9.25, 0.25), ("D5", 9.5, 0.25),
            ("E5", 9.75, 0.25)], 80) + [(["E5", "B5"], 10, 0.75, 96)],
        "w.clarinet1.nat.slur": [
            (["C4", "E4", "G4"], 5, 1, 56), (["A3", "C4", "E4"], 6, 0.5, 66), (["A3", "C4", "E4"], 7, 0.5, 66),
            (["B3", "D4", "F#4"], 8, 0.5, 70), (["B3", "D4", "F#4"], 8.5, 0.5, 70),
            (["G3"], 9, 0.25, 70), (["B3"], 9.25, 0.25, 72), (["D4"], 9.5, 0.25, 76), (["F#4"], 9.75, 0.25, 80),
            (["E3", "G3", "B3", "E4"], 10, 0.75, 96)],
        "k.pop-piano.nat.stac": [(["E1"], 0, 4, 1), (["C2"], 4, 2, 30)]
        + [([n], 6 + 0.5 * i, 0.4, 58 + 2 * i) for i, n in enumerate(["A1", "A2", "A1", "A2", "B1", "B2", "B1", "B2"])]
        + [(["E1", "E2", "B2"], 10, 0.75, 100)],
    }),
    # G Mixolydian, 6/8 at 76. Green Reaching's motif; C, F (bVII) -> G, the Mixolydian cadence rising F5 -> G5.
    # Drops: three high harp plucks, unevenly spaced, on the held G.
    "enraizar": ([(0, 76), (7.5, 70), (8.5, 62), (9, 54)], (6, 3), (0, 0), {
        "w.flute2.nat.slur": line([
            ("C5", 0, 0.5), ("D5", 0.5, 0.5), ("C5", 1, 0.5), ("E5", 1.5, 0.5), ("C5", 2, 0.5), ("G5", 2.5, 1),
            ("F5", 3.5, 0.5), ("G5", 4, 1), ("E5", 5, 0.5), ("D5", 5.5, 0.5),
            ("A5", 6, 1), ("G5", 7, 0.5), ("F5", 7.5, 1.5), ("G5", 9, 2.25)], 72),
        "s.harp2.pizz.stac": line([
            ("G4", 3, 0.25), ("C5", 3.5, 0.25), ("E5", 4.5, 0.25), ("F4", 6, 0.25), ("A4", 6.5, 0.25),
            ("C5", 7.5, 0.25), ("D6", 9.5, 0.25), ("B5", 10.25, 0.25), ("G5", 10.75, 0.25)], 64),
        "s.solo-viola.nat.slur": [(["C4", "E4", "G4"], 3, 3, 60), (["F3", "A3", "C4"], 6, 3, 60),
                                  (["G3", "B3", "D4"], 9, 2.25, 58)],
        "s.basses.vib.slur": [(["C2"], 3, 3, 64), (["F1"], 6, 3, 64), (["G1"], 9, 2.25, 60)],
    }),
    # G major, 4/4 at 100. Cracking Shell's motif; F (its own bVII), C, D (viola borrows F#) -> G. Drops: four
    # high harp plucks, irregular, the rain beginning on the held G.
    "chuva": ([(0, 100), (10, 92), (11, 84), (12, 72)], (4, 2), (1, 0), {
        "w.flute2.nat.slur": line([
            ("E5", 0, 0.5), ("E5", 1, 0.5), ("E5", 2, 1), ("G5", 4, 1), ("C5", 5, 1), ("G5", 6, 1),
            ("C5", 8, 1), ("F5", 9, 0.5), ("E5", 9.5, 0.5), ("E5", 10, 1), ("A5", 11, 1), ("G5", 12, 2)], 72),
        "s.harp2.pizz.stac": line([
            ("F4", 8, 0.25), ("A4", 8.5, 0.25), ("C5", 9, 0.25), ("C4", 10, 0.25), ("G4", 10.5, 0.25),
            ("D4", 11, 0.25), ("A4", 11.5, 0.25),
            ("D6", 12.5, 0.25), ("B5", 13, 0.25), ("G6", 13.25, 0.25), ("D6", 13.75, 0.25)], 62),
        "s.solo-viola.nat.slur": [(["F4", "A4", "C5"], 8, 2, 62), (["E4", "G4", "C5"], 10, 1, 62),
                                  (["D4", "F#4", "A4"], 11, 1, 62), (["D4", "G4", "B4"], 12, 2, 58)],
        "s.basses.vib.slur": [(["F2"], 8, 2, 64), (["C2"], 10, 1, 64), (["D2"], 11, 1, 64), (["G1"], 12, 2, 60)],
    }),
    # C Lydian, 2/4 at 140. Lightning's motif over its bass walk and drums; C, D/C (the Lydian II over the
    # tonic) twice -> C. Heat: the violas shimmer F#5/E5 (the raised fourth) over the held C, drums gone.
    "solsticio": ([(0, 140), (10, 132), (12, 118), (13, 104), (14, 92)], (2, 2), (0, 0), {
        "w.flute2.nat.stac": line([
            ("E5", 0, 0.25), ("C5", 0.25, 0.25), ("G5", 0.5, 0.25), ("E5", 0.75, 0.25), ("C5", 1, 0.25),
            ("G5", 1.25, 0.25), ("A4", 1.5, 0.25), ("B4", 1.75, 0.25), ("C5", 2, 0.25), ("D5", 2.25, 0.25),
            ("E5", 2.5, 0.25), ("D5", 2.75, 0.25), ("C5", 3, 0.5), ("B4", 3.5, 0.5),
            ("G5", 4, 1), ("A5", 5, 0.5), ("G5", 5.5, 0.5), ("E5", 6, 0.5), ("D5", 6.5, 0.5), ("A5", 7, 1),
            ("E5", 8, 0.5), ("D5", 8.5, 0.5), ("C5", 9, 0.5), ("B4", 9.5, 0.5), ("A4", 10, 1), ("B4", 11, 1),
            ("D5", 12, 1), ("B4", 13, 1), ("C5", 14, 2.5)], 100),
        "s.violas.nat.stac": [
            (["C4", "E4", "G4"], 4, 2, 50), (["D4", "F#4", "A4"], 6, 2, 52), (["C4", "E4", "G4"], 8, 2, 50),
            (["D4", "F#4", "A4"], 10, 4, 54), (["C4", "E4", "G4"], 14, 2.5, 48)]
        + [([("F#5", "E5")[i % 2]], 14.5 + 0.25 * i, 0.25, 30 - i) for i in range(8)],
        "s.basses.vib.slur": [(["C2"], 0, 2, 72), (["A1"], 2, 2, 72), (["C2"], 4, 4, 70), (["C2"], 8, 6, 70),
                              (["C2"], 14, 2.5, 64)],
        "p.taikos.nat.stac": hits("F2", [b + o for b in (0, 4, 8) for o in (0, 0.75, 1, 1.5, 2.25, 2.5, 3.5)]
                                   + [12, 13, 14], 40),
        "p.orchestral-kit.nat.stac": hits("F2", [b + o for b in (0, 4, 8) for o in (0, 0.75, 1, 1.5, 2.25, 2.5, 3.5)]
                                          + [14], 28),
    }),
}


def vlq(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def chunk(events):
    body, last = bytearray(), 0
    for tick, _, data in sorted(events, key=lambda e: (e[0], e[1])):
        body += vlq(tick - last) + data
        last = tick
    body += vlq(0) + b"\xff\x2f\x00"
    return b"MTrk" + struct.pack(">I", len(body)) + body


def build(song, tempos, meter, key, tracks):
    conductor = [(0, 0, b"\xff\x58\x04" + bytes([meter[0], meter[1], 0x18, 0x08])),
                 (0, 0, b"\xff\x59\x02" + bytes([key[0] & 0xFF, key[1]]))]
    for beat, bpm in tempos:
        conductor.append((int(beat * TPQ), 1, b"\xff\x51\x03" + int(60e6 / bpm).to_bytes(3, "big")))
    out = [chunk(conductor)]
    pitched = 0
    for name, notes in tracks.items():
        if name.startswith("p."):
            ch = DRUMS
            ev = [(0, 0, b"\xff\x03" + vlq(len(name)) + name.encode())]
        else:
            ch, pitched = pitched, pitched + 1
            ev = [(0, 0, b"\xff\x03" + vlq(len(name)) + name.encode()), (0, 1, bytes([0xC0 | ch, GM[name]]))]
        for pitches, beat, length, vel in notes:
            for p in pitches:
                ev.append((int(beat * TPQ), 3, bytes([0x90 | ch, PITCH[p], vel])))
                ev.append((int((beat + length) * TPQ) - 1, 2, bytes([0x80 | ch, PITCH[p], 0])))
        out.append(chunk(ev))
    path = os.path.join(OUT, "miniatura_" + song + ".mid")
    with open(path, "wb") as f:
        f.write(b"MThd" + struct.pack(">IHHH", 6, 1, len(out), TPQ) + b"".join(out))
    return path


def main():
    for song, (tempos, meter, key, tracks) in MINIATURES.items():
        print(build(song, tempos, meter, key, tracks))


if __name__ == "__main__":
    main()
