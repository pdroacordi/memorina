---
id: bugs/lake-glints-shear-at-column-seams
type: bug
title: Lake glints drift on the per-column clock, so once neighbouring clocks diverge the glint lanes shear at every 16 px column seam
status: fixed
severity: low
tags: [water, lake, shader, clock, greyhush, phase-scar]
related: [bugs/lake-clock-runs-at-the-fastest-memory-across-the-room, architecture/memory-gated-height-field]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/environment/water/water_lake.gdshader
  - scenes/world/environment/water/water_body.gd
---

## Summary

7cfe1fe moved the glints onto the column clock (`here_time`). The reason given was that
they are "discrete re-rolls, where columns drifting out of step is invisible". That holds
for `roll`, but not for `drift`. At water_lake.gdshader:125, `drift` is a continuous
sideways slide of each lane (`floor(here_time * (h - 0.5) * 6)`). Where two neighbouring
columns have run at different rates, their drifts differ. A glint cell is 10 px and not
aligned to the 16 px columns, so the seam splits it: part of the dash is drawn in one
place and the rest somewhere else. The offset is permanent. It is the "phase scar" that
kept the bands on the shared clock.

## Symptom

Found in review of 7cfe1fe. Reasoned from the shader, not captured.

`_refresh_rates` interpolates rates linearly between samples taken every 4 columns. So
inside any gradient (a well's feather, a pulse's edge), each column runs at a slightly
different rate from its neighbours. That is also where glints show, because they are
gated by `awake` in the stippled band. After a pulse has covered part of a lake for a few
seconds, the glint lanes crossing its old edge stay broken at the column seams, even once
memory is uniform again.

## Root cause

A per-column clock drives a continuous per-lane slide.

## Fix

Not fixed. Options:

- Drive `drift` from the shared `water_time` and keep only `roll` on `here_time`. Drift
  then runs at the wrong speed in partial memory, but it is slow and gated by `awake`.
- Quantise the glint cells to columns: make `glint_length` divide `column_width`, and
  apply `drift` only in whole columns.

## Prevention

Before putting an effect on a per-column clock, ask whether it is a re-roll or a slide.
A phase offset is invisible in a re-roll and becomes a seam in a slide. Only re-rolls may
read `here_time`.

## Revision (2026-09-23)

Added in the design review of b0fbbd4..7cfe1fe. The first fix option (drift on
`water_time`, roll left on `here_time`) is not enough by itself. `roll` is evaluated per
PIXEL column, not once per glint. A glint cell that straddles a column seam
(`glint_length` up to 24 px, columns 16 px) gets an independent lit/unlit decision on
each side once the two clocks differ by more than about `1 / glint_rate` seconds. The
result is a dash cut off exactly on the column line, with its two halves re-rolling at
different moments. A glint has to read ONE clock. Sample it at the column where its cell
starts, e.g. `wc_data(wc_column(cell * length_px - drift + 0.5)).r` once `drift` is on the
shared clock. Otherwise take the second option (cells quantised to columns).

The shore line's dashes rely on the same invariant, and it is currently held only by
coincidence. `LINE_DASH = 16.0` (water_lake.gdshader:57) repeats
`WaterBody.PLANE_COLUMN_WIDTH` instead of reading the `column_width` uniform the shader
already has. It is also evaluated on the WORLD grid (`texel.x / LINE_DASH`), while columns
are on the BODY grid (`body_left + k * column_width`). The two agree only because every
room and layer origin today is a multiple of 16 (Woods at x 1952). Use the column index
itself as the dash id (`float dash = float(wc_column(centre.x))`). Then "one dash is one
column, so one clock" holds by construction.

## Resolution (2026-09-23)

Everything that SLIDES reads the shared clock again (the glints' `drift`, as the bands); only the discrete re-rolls (which dashes are open, which glints are lit) read the column clock, now in the data texture's g. The shore dash id is the column index (`wc_column`), not world x / 16, so it never depends on a room sitting on a multiple of 16.
