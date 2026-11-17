"""EBU R128 loudness of a mono float signal (ITU-R BS.1770 K-weighting), shared by the sound tools.

momentary_max is the loudest 400 ms window, the level a sound effect is set by (systems/sound-effects, Levels). It
matches ffmpeg's ebur128 M within 0.2 LU on the game's files.
"""
import numpy as np
from scipy.signal import lfilter

WINDOW = 0.4  # s, the momentary window
HOP = 0.1  # s
PAD = 0.5  # s of silence after the sound, so a short hit fills a window (as measure_levels.py pads ffmpeg)


def _k_weighting(rate):
	"""The two BS.1770 biquads (high shelf, then high-pass) designed for `rate`."""
	g, q, fc = 3.999843853973347, 0.7071752369554196, 1681.974450955533
	a = 10 ** (g / 40)
	w = 2 * np.pi * fc / rate
	alpha = np.sin(w) / (2 * q)
	shelf_b = [a * ((a + 1) + (a - 1) * np.cos(w) + 2 * np.sqrt(a) * alpha), -2 * a * ((a - 1) + (a + 1) * np.cos(w)),
			   a * ((a + 1) + (a - 1) * np.cos(w) - 2 * np.sqrt(a) * alpha)]
	shelf_a = [(a + 1) - (a - 1) * np.cos(w) + 2 * np.sqrt(a) * alpha, 2 * ((a - 1) - (a + 1) * np.cos(w)),
			   (a + 1) - (a - 1) * np.cos(w) - 2 * np.sqrt(a) * alpha]
	q, fc = 0.5003270373238773, 38.13547087602444
	w = 2 * np.pi * fc / rate
	alpha = np.sin(w) / (2 * q)
	pass_b = [(1 + np.cos(w)) / 2, -(1 + np.cos(w)), (1 + np.cos(w)) / 2]
	pass_a = [1 + alpha, -2 * np.cos(w), 1 - alpha]
	return (shelf_b, shelf_a), (pass_b, pass_a)


def momentary_max(x, rate):
	"""Loudest momentary loudness of `x`, LUFS; -inf for silence."""
	y = np.concatenate([np.asarray(x, dtype=np.float64), np.zeros(int(PAD * rate))])
	for b, a in _k_weighting(rate):
		y = lfilter(b, a, y)
	n, hop = int(WINDOW * rate), int(HOP * rate)
	if len(y) < n:
		y = np.concatenate([y, np.zeros(n - len(y))])
	power = np.cumsum(np.concatenate([[0.0], y ** 2]))
	starts = np.arange(0, len(y) - n + 1, hop)
	loudest = np.max((power[starts + n] - power[starts]) / n)
	return -0.691 + 10 * np.log10(loudest) if loudest > 0 else float("-inf")
