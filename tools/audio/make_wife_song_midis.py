"""Writes the wife's song sketches (tools/audio/midi/esposa_<version>.mid) for import into AIVA.

Run: python -I tools/audio/make_wife_song_midis.py
The first eight notes and their rhythm are resources/story/morning_song.tres at its beat_seconds (0.42 s),
so the voice matches the guitar scene. Her lost ending passes through A4, a note the Memorina lacks.
Voice and guitar track names are unverified AIVA patch ids: set them by patch search after import.
See docs/knowledge/music/wifes-song.md.
"""
import os
import struct

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "midi")
TPQ = 480
BEAT_SECONDS = 0.42  # morning_song.tres
VOICE, GUITAR = "v.solo-soprano.nat.slur", "g.nylon-guitar.nat.stac"
FLUTE, VIOLA, BASS = "w.flute2.nat.slur", "s.solo-viola.nat.slur", "s.solo-bass.nat.slur"
GM = {VOICE: 53, GUITAR: 24, FLUTE: 73, VIOLA: 41, BASS: 43}
PITCH = {n + str(o): 12 * (o + 1) + s for o in range(0, 8)
         for n, s in {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}.items()}

# morning_song.tres: E G E D C D E C, beats 1 1 1.5 .5 1 1 1 2.5.
MORNING = [("E4", 1), ("G4", 1), ("E4", 1.5), ("D4", 0.5), ("C4", 1), ("D4", 1), ("E4", 1), ("C4", 2.5)]
# The song, bar = 4 beats: A (bars 1-3) the morning phrase; A' (4-6) open on G; B (7-10) rises to A;
# A'' (11-15) the lost ending: ...E G | A G E | D. E C. Ivo's phrase B ends E G E D D C instead.
SECOND = [("E4", 1), ("G4", 1), ("E4", 1.5), ("D4", 0.5), ("C4", 1), ("D4", 1), ("E4", 1), ("G4", 2.5)]
BRIDGE = [("A4", 1), ("A4", 1), ("G4", 1), ("E4", 1), ("G4", 1), ("A4", 1), ("G4", 1), ("E4", 1),
          ("D4", 1), ("E4", 1), ("G4", 1), ("E4", 1), ("D4", 3)]
LAST = [("E4", 1), ("G4", 1), ("E4", 1.5), ("D4", 0.5), ("C4", 1), ("D4", 1), ("E4", 1), ("G4", 1)]
LOST_ENDING = [("A4", 2), ("G4", 1), ("E4", 1), ("D4", 1.5), ("E4", 0.5), ("C4", 4)]
SONG = [(MORNING, 0), (SECOND, 12), (BRIDGE, 24), (LAST, 40), (LOST_ENDING, 48)]


def phrase(notes, start, vel, octave=0, skip=()):
    out, t = [], start
    for name, length in notes:
        if name not in skip:
            out.append(([PITCH[name] + 12 * octave], t, length, vel))
        t += length
    return out


def song_voice(vel):
    return [n for notes, start in SONG for n in phrase(notes, start, vel)]


def arpeggio(chord, start, length, vel, late=0.0):
    """Ivo's guitar: eighths up and back over a first-position chord; `late` beats behind the change."""
    tones = {"C": ["C3", "G3", "C4", "E4"], "Am": ["A2", "E3", "A3", "C4"], "G": ["G2", "D3", "G3", "B3"],
             "F": ["F2", "C3", "F3", "A3"]}[chord]
    order = [0, 1, 2, 3, 2, 1, 2, 3]
    out, t, i = [], start + late, 0
    while t < start + length - 0.01:
        out.append(([PITCH[tones[order[i % 8]]]], t, 0.5, vel - (6 if i % 2 else 0)))
        t += 0.5
        i += 1
    return out


def held(chords, vel, octave_shift=0):
    voicing = {"C": ["C3", "G3", "E4"], "Am": ["A2", "E3", "C4"], "G": ["G2", "D3", "B3"],
               "F": ["F2", "C3", "A3"]}
    return [([PITCH[p] + 12 * octave_shift for p in voicing[c]], s, n, vel) for c, s, n in chords]


def complete():
    """Flashback 1 (Estabelecimento): she sings, Ivo follows on the guitar, a bar late, unsure of the end."""
    guitar = []
    plan = [("C", 4), ("C", 8), ("C", 12), ("Am", 16), ("G", 20), ("F", 24), ("Am", 28), ("G", 32), ("G", 36),
            ("C", 40), ("Am", 44), ("F", 48)]
    for chord, start in plan:
        guitar += arpeggio(chord, start, 4, 58)
    guitar += arpeggio("G", 52, 2.5, 54)  # still on G when she lands on C at 54: he never knew the end
    guitar += arpeggio("C", 54, 6, 56, late=0.5)
    guitar += [([PITCH["B2"]], 60, 0.5, 44), ([PITCH["C3"], PITCH["G3"], PITCH["E4"]], 60.5, 3.5, 50)]  # tag
    return [(0, 60 / BEAT_SECONDS)], {VOICE: song_voice(84), GUITAR: guitar}


def lullaby():
    """Flashback 5: the whole song at half speed, voice alone, slowing at the end."""
    return [(0, 30 / BEAT_SECONDS), (52, 66), (54, 58), (56, 50)], {VOICE: song_voice(66)}


def hum():
    """The mentor's flicker (wife_hum_opening.wav): the first four notes in one breath, ending open on D."""
    return [(0, 60 / BEAT_SECONDS)], {VOICE: phrase(MORNING[:4], 0, 70)}


def epilogue():
    """STORY-07: the Memorina (flute, octave up) plays to the gap and his wrong D; her voice enters there,
    he follows her a beat behind, they sing the lost ending; at her A he holds G; she leaves before the last C."""
    flute = phrase(MORNING[:4], 0, 78, 1)
    flute += [([PITCH["D5"]], 4, 1, 72)]  # his note (phrase B), against her C
    flute += phrase([("C4", 1), ("D4", 1), ("E4", 1), ("C4", 1.5)], 5, 70, 1)
    flute += phrase(LAST, 12, 72, 1) + [([PITCH["G5"]], 20, 2, 66)]  # no A on the Memorina
    flute += phrase([("G4", 1), ("E4", 1), ("D4", 1.5), ("E4", 0.5), ("C4", 4)], 22, 70, 1)
    voice = phrase(MORNING[4:], 4, 80)
    voice += phrase(LAST, 12, 82) + phrase([("A4", 2), ("G4", 1), ("E4", 1), ("D4", 1.5), ("E4", 0.5), ("C4", 1.5)], 20, 84)
    chords = [("C", 4, 4), ("Am", 8, 2), ("G", 10, 2), ("C", 12, 4), ("Am", 16, 4), ("F", 20, 4), ("G", 24, 2),
              ("C", 26, 6)]
    viola = held(chords, 46)
    bass = [([PITCH[{"C": "C2", "Am": "A1", "G": "G1", "F": "F1"}[c]]], s, n, 52) for c, s, n in chords]
    tempo = [(0, 60 / BEAT_SECONDS), (24, 130), (26, 112), (28, 96)]
    return tempo, {FLUTE: flute, VOICE: voice, VIOLA: viola, BASS: bass}


def vlq(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def track_chunk(events):
    body, last = bytearray(), 0
    for tick, _, data in sorted(events, key=lambda e: (e[0], e[1])):
        body += vlq(tick - last) + data
        last = tick
    body += vlq(0) + b"\xff\x2f\x00"
    return b"MTrk" + struct.pack(">I", len(body)) + bytes(body)


def save(name, tempo, tracks):
    conductor = [(int(b * TPQ), 1, b"\xff\x51\x03" + round(60_000_000 / bpm).to_bytes(3, "big")) for b, bpm in tempo]
    conductor += [(0, 0, b"\xff\x58\x04\x04\x02\x18\x08"), (0, 0, b"\xff\x59\x02\x00\x00")]
    chunks = [track_chunk(conductor)]
    for channel, (patch, notes) in enumerate(tracks.items()):
        ev = [(0, 0, b"\xff\x03" + vlq(len(patch)) + patch.encode()), (0, 0, bytes([0xC0 | channel, GM[patch]]))]
        for pitches, beat, length, vel in notes:
            t0, t1 = int(round(beat * TPQ)), int(round((beat + length) * TPQ)) - 1
            for p in pitches:
                ev.append((t0, 2, bytes([0x90 | channel, p, vel])))
                ev.append((t1, 1, bytes([0x80 | channel, p, 0])))
        chunks.append(track_chunk(ev))
    path = os.path.join(OUT, name + ".mid")
    with open(path, "wb") as f:
        f.write(b"MThd" + struct.pack(">IHHH", 6, 1, len(chunks), TPQ) + b"".join(chunks))
    return path


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, make in [("esposa_inteira", complete), ("esposa_ninar", lullaby), ("esposa_sopro", hum),
                       ("esposa_epilogo", epilogue)]:
        print(save(name, *make()))


if __name__ == "__main__":
    main()
