---
id: playtests/2026-10-10-generated-grass
type: playtest
title: Generated grass - a dense verge on the east gate's dirt road, blades over Ivo's feet, a bent trail where he ran; the cobbles keep a short moss fringe
status: active
tags: [world-23, grass, playtest]
related: [systems/grass, architecture/generated-grass]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - tools/playtest/scripts/grass_walk_gate.json
  - tools/playtest/scripts/grass_walk_lane.json
---

## Summary

WORLD-23 in the real game (windowed, `tools/playtest`), at the village's memory 0.8.

- **The verge** (`01_gate_verge_standing.png`): the east gate's new dirt road grows dense blades in 2x art pixels, shaded dark to lit, with front-row blades standing over Ivo's feet.
- **Contact** (`02_running_trail_zoom.png`): the blades Ivo has just run through lean and lie bent behind him, then spring back.
- **Cobbles** (`03_lane_moss_fringe_zoom.png`): the street keeps a sparse moss fringe of 1-3 art px. That fringe is too short to show a bend, which is why the dirt verges were added.

## What screenshots cannot show

- The sway runs on the cell clocks at 0.8 memory and reads as a slow breathing, not a wind.
- Not measured: frame time. The village view has two or three grass runs on screen.

## Not covered

- The grey hold (bend frozen below 0.2): covered by `grass_springs_test`, not played. No village grass stands in a forgotten spot.
- Autumn and winter pulses across bent grass.
