"""Aligns each miniature's first note with its track's, trims it, encodes OGG and prints the measured note_cues."""
import os, struct, subprocess, sys

S = sys.argv[1]
REPO = "D:/Projects/memorina"
SONGS = [  # song, track mp3, AIVA original MIDI, cut end (s, in the miniature's own time)
    ("congelar", "hymn_of_frost", "hymn_of_frost", 12.014),
    ("redoma", "lullaby_under_glass", "song_of_the_restless_wind", 9.788),
    ("soltar", "song_of_falling_leaves", "dirge_of_hollow_bark", 11.993),
    ("vendaval", "song_of_the_restless_wind", "song_of_bare_branches", 10.6),
    ("enraizar", "song_of_the_green_reaching", "song_of_the_green_reaching", 10.893),
    ("chuva", "song_of_the_first_rain", "song_of_the_cracking_shell", 10.172),
    ("solsticio", "song_of_the_longest_day", "call_of_the_lightning", 9.183),
]


def onset(path):
    out = subprocess.run(["ffmpeg", "-i", path, "-af", "silencedetect=n=-40dB:d=0.1", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    return float(out.split("silence_end: ")[1].split()[0])


def vlq(d, i):
    n = 0
    while True:
        b = d[i]; i += 1; n = (n << 7) | (b & 0x7F)
        if b < 0x80:
            return n, i


def flute_onsets(path):
    """Seconds of the first six flute note-ons, through the tempo map."""
    d = open(path, "rb").read()
    _, nt, tpq = struct.unpack(">HHH", d[8:14]); i = 14; tempos = []; ons = []
    for _ in range(nt):
        ln = struct.unpack(">I", d[i + 4:i + 8])[0]; j = i + 8; t = 0; st = 0; name = ""; notes = []
        while j < i + 8 + ln:
            dt, j = vlq(d, j); t += dt; s = d[j]
            if s == 0xFF:
                ty = d[j + 1]; l, k = vlq(d, j + 2)
                if ty == 0x51: tempos.append((t, int.from_bytes(d[k:k + l], "big")))
                if ty == 0x03: name = d[k:k + l].decode("latin1")
                j = k + l; continue
            if s in (0xF0, 0xF7):
                l, k = vlq(d, j + 1); j = k + l; continue
            if s & 0x80: st = s; j += 1
            hi = st & 0xF0
            if hi in (0x80, 0x90, 0xA0, 0xB0, 0xE0):
                if hi == 0x90 and d[j + 1]: notes.append(t)
                j += 2
            else:
                j += 1
        if "flute" in name: ons = sorted(notes)[:6]
        i = i + 8 + ln
    tempos.sort()

    def sec(tick):
        total, last_t, us = 0.0, 0, 500000
        for tt, u in tempos:
            if tt >= tick: break
            total += (tt - last_t) / tpq * us / 1e6; last_t, us = tt, u
        return total + (tick - last_t) / tpq * us / 1e6
    return [sec(x) for x in ons]


for song, track, orig, cut in SONGS:
    t_on = onset(f"{REPO}/assets/audios/soundtrack/{track}.mp3")
    mini = f"{S}/miniatura_{song}_v3.mid.mp3" if song == "vendaval" else f"{S}/miniatura_{song}_v2.mid.mp3"
    m_on = onset(mini)
    shift = t_on - m_on  # > 0: delay the miniature
    end = cut + shift
    pre = f"adelay={int(round(shift * 1000))}:all=1," if shift > 0 else f"atrim=start={-shift},asetpts=PTS-STARTPTS,"
    out = f"{REPO}/assets/audios/soundtrack/{track}_excerpt.ogg"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", mini, "-af",
                    f"{pre}atrim=0:{end:.3f},afade=t=out:st={end - 0.4:.3f}:d=0.4", "-c:a", "libvorbis", "-q:a", "6", out], check=True)
    fl = flute_onsets(f"{REPO}/tools/audio/aiva/existing/{orig}.mid")
    cues = [round(t_on + x - fl[0], 2) for x in fl]
    print(f"{song:10} track_on {t_on:.3f} mini_on {m_on:.3f} shift {shift:+.3f} excerpt_on {onset(out):.3f} len {end:.2f} cues {cues}")
