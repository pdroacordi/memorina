---
id: bugs/root-bridge-strands-meet-at-a-step
type: bug
title: The far bank's root strand draws 4 px higher than the near bank's, so every joined root bridge shows a step where they meet
status: active
severity: low
tags: [enraizar, roots, root-bridge, art, sprite-rotation]
related: [playtests/2026-10-07-chuva-then-enraizar-wet-bridge, playtests/2026-09-30-enraizar-shaft-and-bridge, architecture/roots-join-earth-to-earth, systems/roots-and-climbing]
created: 2026-10-07
updated: 2026-10-08
source_files:
  - scenes/world/memory/song_effects/roots/root_span_view.gd
  - scenes/world/memory/song_effects/roots/root_catch.gd
  - assets/sprites/world/props/roots/root_strand.png
---

## Summary

A joined root bridge is drawn as two strands at different heights, with a 4 game-px step
where they meet. `RootSpanView._strand_sprite` centres the 10 px texture box on the line,
but the art in `root_strand.png` sits in rows 4-9 only. The far bank's strand is rotated by
PI, so its art falls in the other half of the box.

## Symptom

Play Chuva then Enraizar from the ledge of spring trial puzzle 5. Measured on the joined
bridge in the 1280x720 capture (`s_after_20.00`, the junction at about x 700, y 460):

- The near bank's strand (rotation 0) covers world y ~6005 to 6008.
- The far bank's strand (rotation PI) covers world y ~6001 to 6004.
- The walk surface (the one-way box top) and both bank tops are at y 6000.

The join shows a 4 px step
(`playtests/screenshots/2026-10-07-chuva-then-enraizar-wet-bridge/strand_step_at_the_join_4x.png`).
On the near half, Ivo's feet ride about 5 px above the strand he walks on. Every bridge
uses the same code, so puzzle 4's dry bridge shows the step as well. Shaft rungs are built
the same way (drop 0), so the same offset is expected there; that was not captured.

## Root cause

Alpha by row in `root_strand.png` (32x10): rows 0-3 are empty and rows 4-9 hold the art (1,
28, 31, 24, 32 and 16 opaque pixels). `sprite.offset = Vector2(0, -STRAND_THICKNESS * 0.5)`
centres the 10 px box on the line (root_span_view.gd:128), which centres the art only when
the art is symmetric in the box. With rotation 0 the art lands below the line. With rotation
PI the same rows land above it. The 2026-09-30 fix ("centred by local offset") cut the
earlier 15 px gap to this residual 4 px.

## Fix

Open. Either option makes both strands draw the same world rows whatever the art's padding:

- Set `flip_v` on a strand whose direction points left, so the rotation by PI does not
  turn the art upside down.
- Crop the texture to its art rows, setting `STRAND_THICKNESS` to match.

## Prevention

A test can build a `RootSpanView` for a bridge, then compare the global rects of
`sprite_a` and `sprite_b`, including the texture's opaque rows. Do not compare only the
`position` and `offset` values: those already match.

## Revision (2026-10-08)

PZL-04's `RootCatch` (scenes/world/memory/song_effects/roots/root_catch.gd:27-29) copies the same
centring for the two roots that seize a `LoweringPlatform`. The left root (rotation 0) and the
right root (rotation PI) are drawn on the line at the platform's mid-height (`catch_edges`, top
+ 5 px), so the right root meets the plank 4 px higher than the left. Not measured on screen. A
fix to `RootSpanView` should be applied to `RootCatch` too (or the strand built in one place).
