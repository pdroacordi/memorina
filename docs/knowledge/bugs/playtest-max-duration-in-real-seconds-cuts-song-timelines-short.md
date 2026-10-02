---
id: bugs/playtest-max-duration-in-real-seconds-cuts-song-timelines-short
type: bug
title: The playtest runner now measures max_duration in real seconds, so every song timeline quits before its post-performance steps
status: fixed
severity: medium
tags: [playtest, harness, pause, performance, timeline, max-duration]
related: [gotchas/playtest-clock-pauses-with-the-tree, architecture/pause-menu-worldfreeze-reuse]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - tools/playtest/playtest_runner.gd
  - tools/playtest/scripts/
---

## Summary

The UI-02 change to `PlaytestRunner._process` (`tools/playtest/playtest_runner.gd`, the
`real_elapsed >= _max_duration` quit test) compares `max_duration` with real seconds, but
the default timeline clock `t` still skips paused time. No existing timeline was retuned.
A performance freezes the tree for its excerpt (7 s, `Song.excerpt_duration` default), so
every timeline that plays a song reaches its last `t` about 7 s per song AFTER its
`max_duration` and is cut short.

## Symptom

Reasoned from the code and the committed timelines; not yet run. `max_duration - last t`
for the song timelines in `tools/playtest/scripts/`:

| timeline | songs | margin |
|---|---|---|
| `song_bell_jar_well.json` | 1 | 0.5 s |
| `song_rain_freeze_moat.json` | 2 | 0.4 s |
| `song_release_gale_cocoon.json` | 2 | 0.5 s |
| `song_solstice_corridor.json` | 2 | 0.5 s |
| `water_freeze_crossing.json` | 1 | 1.2 s |
| `bloom_guardian_full.json` | call + whole-track lesson | 4.0 s |

All are well below 7 s per performance. `quit_now()` fires with steps left. The run
exits normally and the late screenshots (the pulse and its effect) are simply missing.

## Root cause

The runner change was made so that a paused tree cannot hang a run: a pause-menu timeline
on the default clock never fires the press that closes the menu. The fix moved the cap to
real time for every timeline, including the ones whose `t` is meant to skip pauses.

## Fix

Fixed 2026-10-02 with the first option (`tools/playtest/playtest_runner.gd`):
- `max_duration` is measured on the timeline's own clock again: `_elapsed`, unpaused time by default, real time with `"clock": "real"`.
- A separate watchdog ends a hung run when real time passes `max_duration * WATCHDOG_FACTOR + WATCHDOG_SLACK` (3 and 30 s). It calls `push_error` with the steps left and exits with code 1.

Measured: `song_bell_jar_well.json` (max 15, default clock) wrote all 12 screenshots again, including the post-pulse `pass_09.20` to `pass_14.50`. No timeline was retuned.

## Prevention

Changing what a harness field means requires retuning every file that sets it in the same
change. Grep `tools/playtest/scripts/` for the field first.
