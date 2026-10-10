---
id: bugs/a-bent-grass-blade-draws-doubled-corners
type: bug
title: A bent grass blade draws 2-3 art px wide at each step of its lean, because the row fill includes the row below's column
status: resolved
severity: low
tags: [grass, shader, pixel-art, world-23, review]
related: [systems/grass, architecture/generated-grass]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/environment/grass/grass_blades.gdshader
---

## Summary

`grass_blades.gdshader` fills each blade row from the row below's offset to its own, both
ends included. Wherever the offset changes, both rows hold the shared column, so a leaning
blade is a 4-connected staircase with doubled corners. The contract is a one-art-pixel,
8-connected line (`architecture/generated-grass`, "Drawing a blade"; the shader's own comment).

## Symptom

Found in the WORLD-23 review (2026-10-10) by running the shader's row logic in a scratch
script. Bend 1, height 7 (shortened to 4.55 art px), lean 0.9, rows top to bottom:

```
..##....
.##.....
##......
#.......
#.......
```

An 8-connected line is one pixel per row here (`..#`, `.#`, `#`, `#`, `#`). A row whose
offset jumps by 2 draws 3 pixels. It shows wherever a blade leans: on contact, and on tall
blades at the sway's extremes.

## Root cause

`grass_blades.gdshader:104-106`. `below` is the previous row's offset, and the test
`dx >= min(here, below) && dx <= max(here, below)` includes `below`'s column, which that row
already drew.

## Fix

Not fixed. When `here != below`, start the span one column past `below`, toward `here`:
`int from = here == below ? here : below + int(sign(float(here - below)));`, then test
`dx` between `min(from, here)` and `max(from, here)`.

## Prevention

A line drawn as one span per row is 8-connected only if each span excludes the previous
row's end column. Check this with a 2-3 row hand trace when reviewing any rasterised line in
a shader. Nothing renders the blade in a test today; a CPU twin is out of scope by design
(`gotchas/glsl-gdscript-math-must-be-duplicated`), so the trace is the safeguard.

## Fix (2026-10-10)

A row's span starts one column past the last row's offset (`below + sign(here - below)`), so the blade is one 8-connected line.
