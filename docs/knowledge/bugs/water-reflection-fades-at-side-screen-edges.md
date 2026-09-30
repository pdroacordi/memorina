---
id: bugs/water-reflection-fades-at-side-screen-edges
type: bug
title: The water reflection fades to the body colour within 12 px of the LEFT/RIGHT screen edges, a navy seam on the reflection strip, although a vertical mirror never reads off the sides
status: fixed
severity: low
tags: [water, reflection, shader, pixel-art, screen-edge]
related: [playtests/2026-09-23-generated-water, architecture/water-is-world-art-reflecting-two-passes]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/environment/water/water_surface.gdshader
  - resources/world/water/reflection_strip_look.tres   # renamed to lake_look.tres in 1c5117f
  - scenes/world/environment/water/water_reflection.gdshaderinc   # the edge fade lives here since b0fbbd4
---

## Summary

`edge_fade_px` dissolves the reflection near every edge of the screen, the left and
right edges included. The mirror only flips Y and shifts each band sideways by
`band_shift_max` (1 px), so the mirrored sample never leaves the screen horizontally.
Where the water reaches the side of the screen, the outermost 12 game px therefore stipple
from the reflected colour into the bare body colour. On the Woods reflection strip that is
green-grey into navy: a visible dark, blue, dithered seam at the screen edge.

## Symptom

`tools/playtest/scripts/water_reflection.json`, frames `02_zooming` and `03_zoom_1_5`, on
224d721 and on 20597f0. The strip runs off the right edge of the screen. Sampled at row
640: (34, 42, 38) at x 1262, then (21, 25, 33) at x 1278. See
`playtests/screenshots/2026-09-23-generated-water/03_reflection_edge_seam_400.png`.
The same seam appears at the left edge whenever the strip crosses it. This follows from
the code; it was not captured, because in no frame did the strip reach the left edge.

## Root cause

`water_surface.gdshader:110-111`:
`inside = min(uv_m, 1.0 - uv_m) * game_size; edge = clamp(min(inside.x, inside.y) / edge_fade_px, 0, 1)`.
`inside.x` is at most about `band_shift_max` px different from the fragment's own
distance to the side of the screen, so the fade fires on the sides for no reason. The
strip's look shows the whole fade, because `reflection_strength` 1.0 with ramp alpha 255
makes the reflection replace the body completely everywhere else.

## Fix

Not fixed. Fade on `inside.y` only. The source is out of bounds only vertically, above
the top of the screen. Handle the sides by clamping `uv_m.x` into the screen, or by
fading over `band_shift_max` px rather than `edge_fade_px`.

## Prevention

When a fade guards against sampling outside a texture, derive its extent from how far the
sample can actually move on that axis.

## Fix

Fixed in fae1438 (2026-09-23): the edge fade uses the vertical distance only, and the mirrored x is clamped inside the screen.
