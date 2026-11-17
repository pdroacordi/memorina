---
id: bugs/eight-step-and-landing-files-start-mid-impact-with-a-click
type: bug
title: Eight step and landing WAVs start at up to 98% of their peak, a click on every play
status: fixed
severity: medium
tags: [audio, footsteps, sfx-pipeline, cut-sfx, click, snd-07]
related: [systems/sound-effects, bugs/ivo-steps-and-soft-landings-are-silent-on-room-ground]
created: 2026-11-16
updated: 2026-11-16
source_files:
  - tools/audio/cut_sfx.py
  - assets/audios/sfx/ivo/
---

## Summary

The SND-07 attack cut (`finish(..., attack_db=STEP_ATTACK_DB)`) turns off the 3 ms anti-click fade
for steps and landings. A source slice that already starts loud has no fade-in at all, so the file's
first sample is a step from silence to near the peak.

## Symptom

Measured on the re-cut files (first sample over the file's peak): `step_stone_01` 0.98,
`step_earth_03` 0.78, `land_mud_02` 0.58, `step_stone_02` 0.49, `step_earth_05` 0.49,
`land_earth_02` 0.38, `step_stone_03` 0.29, `step_earth_06` 0.24. At HEAD every one of them started
at 0 (the 3 ms ramp). Each play starts on a discontinuity: a click on top of the step, and the
head of the impact is missing.

## Root cause

`tools/audio/cut_sfx.py:96-101`: the cut point `i` is the first sample 14 dB under the peak, and the
fade covers only `[start, i)` with `start = max(0, i - ATTACK_PREROLL * RATE)`. When the slice
(`walk_picks` or the landing window) begins inside the impact, `i` is 0, `start` is 0 and the ramp is
empty. Line 107 then skips the 3 ms fade that used to catch exactly this case
(`elif attack_db is None and abs(x[0]) > 0.03 * peak`).

## Fix

Not fixed. Either keep a minimum ramp in the attack branch (fade `max(i - start, 3 ms)` samples),
or widen the source window left by `ATTACK_PREROLL` so the impact's start is inside the slice
(the better cut: the attack itself is kept). Re-run `cut_sfx.py` and check every step and landing
file's first sample.

## Prevention

A cut that replaces the onset logic keeps its click guard. A check over the output (first sample
under 3% of the peak) belongs in the script's run, next to the attack-offset figures
`systems/sound-effects` quotes.

## Fix (2026-11-16, before the SND-07 commit)

`cut_sfx.py` reads an attack cut from `ATTACK_LEAD` (30 ms) before the picked slice, so the impact's start is inside it, and always fades in at least `ATTACK_PREROLL` (4 ms). Re-cut: no step or landing file starts above 2% of its peak; the slowest reaches a quarter of its peak at 47 ms (`land_earth_01`).
