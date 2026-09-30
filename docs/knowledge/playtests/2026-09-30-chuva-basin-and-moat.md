---
id: playtests/2026-09-30-chuva-basin-and-moat
type: playtest
title: Chuva lifts the log to the passage; Chuva then Congelar crosses the dry moat
status: active
tags: [chuva, rain-basin, floater, congelar, combinado-1, trials]
related: [architecture/the-water-level-moves, gotchas/playtest-clock-pauses-with-the-tree]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - tools/playtest/scripts/song_rain_basin_log.json
  - tools/playtest/scripts/song_rain_freeze_moat.json
---

## Summary

Both spring puzzles solve with real input. The rain reads: streaks only inside the pulse,
the basin fills over ~3 s with its reflection, the log rises with Ivo on it. One real
layout fault found and fixed: the passage was 64 px tall and 114 px from the log, so a
full jump hit the wall above it - it is now three cells tall and the log lies by it.

## What was seen

- Dry basin: rain, rising water, the log carrying Ivo, a short hop into the passage.
- Dry moat: Chuva fills it; Congelar from the edge grows ice across; Ivo crosses ahead of
  the thaw (which chases from the origin 1.5 s after the ice forms, at 48 px/s).

## What this cannot judge

The moat is a race against the thaw that a script times exactly; a first-time player
waiting to watch the ice finish will find it melting behind them - by design ("travessia
contra o tempo"), but untested on a person. Falling into the moat's water respawns on the
last safe ground as for any pool.
