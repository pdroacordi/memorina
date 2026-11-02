"""Writes the MIDI sketches AIVA takes as influence: songs, their reduced versions, the final song.

Run: python -I tools/audio/make_aiva_midis.py   (no dependencies; writes tools/audio/midi/, see its README.md)
Notes follow Enums.Note: 0 UP G4, 1 DOWN C4, 2 LEFT D4, 3 RIGHT E4 (assets/audios/sfx/memorina/).
"""
import os
import struct

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "midi")
TPQ = 480
NOTE = {0: 67, 1: 60, 2: 62, 3: 64}

# Pitch names for hand-written melodies.
P = {"C3": 48, "D3": 50, "E3": 52, "F3": 53, "G3": 55, "A3": 57, "B3": 59,
     "C4": 60, "D4": 62, "E4": 64, "F4": 65, "G4": 67, "A4": 69, "B4": 71, "C5": 72, "D5": 74, "E5": 76, "G5": 79}

# Chords as (bass root, three tones), all inside C major.
CHORD = {
    "C": (48, [60, 64, 67]),
    "Am": (45, [57, 60, 64]),
    "G": (43, [55, 59, 62]),
    "Em": (40, [55, 59, 64]),
    "Dm": (50, [57, 62, 65]),
    "F": (41, [57, 60, 65]),
}
# Chords tried, in order, to harmonise a pair of motif notes.
PREFERENCE = ["C", "Am", "G", "Em"]

# General MIDI programs (0-based).
FLUTE, CLARINET, OBOE, HARP, CELESTA, MARIMBA = 73, 71, 68, 46, 8, 12
STRINGS, SLOW_STRINGS, PIZZICATO, CELLO, CONTRABASS = 48, 49, 45, 42, 43
NYLON, PIANO, VOICE, CHOIR, WARM_PAD = 24, 0, 53, 52, 89

SEASON = {
    "inverno": {"lead": FLUTE, "double": CELESTA, "chords": STRINGS, "bass": CONTRABASS, "style": "hold"},
    "outono": {"lead": CLARINET, "double": None, "chords": NYLON, "bass": CELLO, "style": "arpeggio"},
    "primavera": {"lead": HARP, "double": FLUTE, "chords": PIZZICATO, "bass": CELLO, "style": "pulse"},
    "verao": {"lead": OBOE, "double": None, "chords": WARM_PAD, "bass": CELLO, "style": "drone"},
}

SONGS = [
    # file name, notes, season, game track
    ("congelar", [0, 3, 2, 1, 1, 1], "inverno", "hymn_of_frost"),
    ("redoma", [2, 3, 2, 3, 0, 1], "inverno", "lullaby_under_glass"),
    ("soltar", [0, 1, 2, 1, 3, 1], "outono", "song_of_falling_leaves"),
    ("vendaval", [3, 3, 2, 2, 0, 3], "outono", "song_of_the_restless_wind"),
    ("enraizar", [1, 2, 1, 3, 1, 0], "primavera", "song_of_the_green_reaching"),
    ("chuva", [3, 3, 3, 0, 1, 0], "primavera", "song_of_the_first_rain"),
    ("sombra", [1, 2, 3, 0, 0, 0], "verao", "chant_of_the_noon_sun"),
    ("solsticio", [3, 1, 0, 3, 1, 0], "verao", "song_of_the_longest_day"),
]


class Track:
    def __init__(self, name, program, channel):
        self.name, self.program, self.channel = name, program, channel
        self.events = []  # (tick, order, bytes); note-offs sort before note-ons at one tick

    def note(self, pitch, start, length, velocity=80):
        t0, t1 = int(start * TPQ), int((start + length) * TPQ)
        self.events.append((t0, 1, bytes([0x90 | self.channel, pitch, velocity])))
        self.events.append((t1 - 1, 0, bytes([0x80 | self.channel, pitch, 0])))

    def chunk(self):
        body = bytearray()
        name = self.name.encode()
        body += vlq(0) + b"\xff\x03" + vlq(len(name)) + name
        body += vlq(0) + bytes([0xC0 | self.channel, self.program])
        last = 0
        for tick, _, data in sorted(self.events):
            body += vlq(tick - last) + data
            last = tick
        body += vlq(0) + b"\xff\x2f\x00"
        return b"MTrk" + struct.pack(">I", len(body)) + body


def vlq(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def save(name, bpm, tracks, meter=(4, 4)):
    head = bytearray()
    head += vlq(0) + b"\xff\x51\x03" + (60_000_000 // bpm).to_bytes(3, "big")
    head += vlq(0) + b"\xff\x58\x04" + bytes([meter[0], {2: 1, 4: 2, 8: 3}[meter[1]], 24, 8])
    head += vlq(0) + b"\xff\x59\x02\x00\x00"  # C major
    head += vlq(0) + b"\xff\x2f\x00"
    conductor = b"MTrk" + struct.pack(">I", len(head)) + head
    used = [t for t in tracks if t.events]
    data = b"MThd" + struct.pack(">IHHH", 6, 1, len(used) + 1, TPQ) + conductor + b"".join(t.chunk() for t in used)
    with open(os.path.join(OUT, name + ".mid"), "wb") as f:
        f.write(data)
    return name + ".mid"


def chord_for(pitches, last=False):
    classes = {p % 12 for p in pitches}
    if last:
        # A motif closes on its tonic: C under C, E or G; G under D.
        return "G" if classes == {62 % 12} else "C"
    for name in PREFERENCE:
        if classes <= {t % 12 for t in CHORD[name][1]}:
            return name
    first = pitches[0] % 12
    return next(n for n in PREFERENCE if first in {t % 12 for t in CHORD[n][1]})


def harmonise(notes, beats):
    """Chords over pairs of motif notes; the last note gets the closing chord. Returns [(start, length, chord)]."""
    plan, start, i = [], 0.0, 0
    while i < len(notes):
        group = notes[i:i + 2] if i + 2 < len(notes) else notes[i:i + 1]
        last = i + len(group) >= len(notes)
        length = sum(beats[i:i + len(group)])
        plan.append((start, length, chord_for([NOTE[n] for n in group], last)))
        start += length
        i += len(group)
    return plan


def accompany(look, chords, bass, plan, tail):
    """Lays the season's accompaniment under a chord plan; tail beats extend the last chord."""
    plan = plan[:-1] + [(plan[-1][0], plan[-1][1] + tail, plan[-1][2])]
    style = look["style"]
    for start, length, name in plan:
        root, tones = CHORD[name]
        if style != "drone":
            bass.note(root, start, length, 70)
        if style == "hold":
            for t in tones:
                chords.note(t - 12, start, length, 55)
        elif style == "arpeggio":
            pattern = [tones[0] - 12, tones[1] - 12, tones[2] - 12, tones[1] - 12]
            steps = max(1, int(length * 2))
            for k in range(steps):
                chords.note(pattern[k % 4], start + k * 0.5, 0.5 if k < steps - 1 else length - k * 0.5, 60)
        elif style == "pulse":
            for k in range(max(1, int(length))):
                for t in tones:
                    chords.note(t - 12, start + k, 0.5, 58)
        elif style == "drone":
            for t in tones:
                chords.note(t - 12, start, length, 45)
    if style == "drone":
        total = plan[-1][0] + plan[-1][1]
        bass.note(36, 0, total, 60)  # C2 and G2 under the whole motif
        bass.note(43, 0, total, 50)


def motif_piece(name, notes, season, beats, tail, bpm, double_octave=True):
    look = SEASON[season]
    lead = Track("Melodia (motivo)", look["lead"], 0)
    double = Track("Dobra", look["double"] or look["lead"], 1)
    chords = Track("Acordes", look["chords"], 2)
    bass = Track("Baixo", look["bass"], 3)
    start = 0.0
    for n, b in zip(notes, beats):
        lead.note(NOTE[n], start, b, 92)
        if look["double"] is not None and double_octave:
            double.note(NOTE[n] + 12, start, b, 55)
        start += b
    accompany(look, chords, bass, harmonise(notes, beats), tail)
    return save(name, bpm, [lead, double, chords, bass])


def cues(beats, bpm):
    out, t = [], 0.0
    for b in beats:
        out.append(round(t * 60 / bpm, 2))
        t += b
    return out


def melody_track(name, program, channel, line, velocity=85):
    track = Track(name, program, channel)
    t = 0.0
    for pitch, length in line:
        if pitch is not None:
            track.note(P[pitch], t, length, velocity)
        t += length
    return track, t


def chord_tracks(changes, program_chords, program_bass, style):
    chords = Track("Acordes", program_chords, 2)
    bass = Track("Baixo", program_bass, 3)
    plan, t = [], 0.0
    for name, length in changes:
        plan.append((t, length, name))
        t += length
    accompany({"style": style}, chords, bass, plan, 0)
    return chords, bass


def final_song():
    made = []
    a = [("G4", 1), ("E4", 1), ("D4", 1), ("C4", 1), ("D4", 1), ("E4", 2), (None, 1)]
    b = [("E4", 1), ("G4", 1), ("E4", 1.5), ("D4", 0.5), ("D4", 1), ("C4", 3)]
    a_chords = [("C", 2), ("G", 2), ("G", 1), ("C", 3)]
    b_chords = [("C", 2), ("Am", 2), ("G", 1), ("C", 3)]
    flute, _ = melody_track("Flauta (frase A, o mentor; frase B, Ivo)", FLUTE, 0, a + b, 92)
    strings, bass = chord_tracks(a_chords + b_chords, STRINGS, CONTRABASS, "hold")
    made.append(save("cancao_final_12", 72, [flute, strings, bass]))
    # The battle sketch: winter (Freeze) twice, the two tracks at once, then the final call.
    winter = [("G4", 1), ("E4", 1), ("D4", 1), ("C4", 1), ("C4", 1), ("C4", 3)]
    spring = [("C5", 1), ("D5", 1), ("C5", 1), ("E5", 1), ("C5", 1), ("G5", 3)]  # Enraizar an octave up
    lead, _ = melody_track("Flauta (inverno, depois o chamado final)", FLUTE, 0, winter * 3 + a + b, 92)
    second, _ = melody_track("Harpa (primavera, só na revelação)", HARP, 1, [(None, 16)] + spring, 70)
    changes = [("C", 2), ("G", 2), ("C", 4)] * 3 + a_chords + b_chords
    strings, bass = chord_tracks(changes, STRINGS, CONTRABASS, "hold")
    made.append(save("batalha_final_esboco", 72, [lead, second, strings, bass]))
    # The restoration (the lamp scene, about 14 s): phrase B slowly over piano, opening on C.
    piano, _ = melody_track("Piano (frase B)", PIANO, 0, [(None, 2)] + b + [(None, 2)], 80)
    strings, bass = chord_tracks([("Am", 2)] + b_chords + [("C", 2)], SLOW_STRINGS, CELLO, "hold")
    made.append(save("restauracao", 60, [piano, strings, bass]))
    return made


def main():
    os.makedirs(OUT, exist_ok=True)
    made = []
    for name, notes, season, track in SONGS:
        # Melody alone: the cleanest influence for AIVA.
        lone = Track("Motivo", SEASON[season]["lead"], 0)
        for i, n in enumerate(notes):
            lone.note(NOTE[n], i, 1, 90)
        made.append(save("motivo_" + name, 100, [lone]))
        # Reduced versions are miniatures: make_miniature_midis.py.
    # The wife's song: make_wife_song_midis.py.
    made += final_song()
    print("\n".join(sorted(made)))


if __name__ == "__main__":
    main()
