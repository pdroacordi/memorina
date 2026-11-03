"""Builds looping stems from an AIVA "Render Stems" zip: groups the per-instrument WAVs, cuts one loop, folds the tail.

Run: python -I tools/audio/build_stems.py <stems.zip> <out_dir> <name> <loop_seconds> group=track,track ...
Each group becomes <out_dir>/<name>_<group>.ogg. The loop starts at the mix's first onset (AIVA's lead-in) and lasts
exactly loop_seconds; what rings past the loop end is added onto its start, so the seam has no gap (systems/music).
"""
import io
import os
import subprocess
import sys
import wave
import zipfile

import numpy as np

ONSET_DB = -40.0


def read(zf, name):
    with wave.open(io.BytesIO(zf.read(name))) as w:
        rate, channels = w.getframerate(), w.getnchannels()
        data = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768.0
    return rate, data.reshape(-1, channels)


def main():
    zpath, out, name, loop = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4])
    groups = {g.split("=")[0]: g.split("=")[1].split(",") for g in sys.argv[5:]}
    zf = zipfile.ZipFile(zpath)
    wavs = {n: read(zf, n) for n in zf.namelist() if n.endswith(".wav")}
    rate = next(iter(wavs.values()))[0]
    length = max(d.shape[0] for _, d in wavs.values())
    pad = lambda d: np.pad(d, ((0, length - d.shape[0]), (0, 0)))
    mixed = {g: sum(pad(wavs[t + ".wav"][1]) for t in tracks) for g, tracks in groups.items()}
    whole = sum(mixed.values())
    env = np.abs(whole).max(axis=1)
    start = int(np.argmax(env > 10 ** (ONSET_DB / 20)))
    frames = int(round(loop * rate))
    os.makedirs(out, exist_ok=True)
    for group, data in mixed.items():
        # AIVA ends the render at the last sound, so trailing rest bars come back as padding.
        body = np.pad(data[start:start + frames], ((0, max(0, start + frames - len(data))), (0, 0)))
        tail = data[start + frames:]
        body[:min(len(tail), frames)] += tail[:frames]
        path = os.path.join(out, f"{name}_{group}.ogg")
        raw = (np.clip(body, -1, 1) * 32767).astype(np.int16).tobytes()
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(rate), "-ac", str(body.shape[1]),
                        "-i", "-", "-c:a", "libvorbis", "-q:a", "6", path], input=raw, check=True)
        print(path, f"{body.shape[0] / rate:.3f} s")
    print(f"lead-in cut: {start / rate:.3f} s, tail folded: {max(0, length - start - frames) / rate:.2f} s")


main()
