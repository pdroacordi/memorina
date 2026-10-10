---
id: bugs/an-earth-cell-boxed-in-by-stone-grows-a-corner-tuft
type: bug
title: An earth cell with stone above, beside and diagonally above draws an inner-corner tile whose grass tuft shows under the stone's rounded corner (5 corners, trials only)
status: active
severity: low
tags: [world-07, dual-grid, tiles, underlay, corner-mask, aesthetics]
related: [playtests/2026-10-10-world07-legacy-tiles, architecture/biome-tilesets, bugs/stone-under-earth-draws-a-seasonal-lip-inside-the-ground]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/maps/ground_autotile.gd
---

## Summary

In a display tile with three stone corners and one earth corner below (for example NW, NE and
SW stone, SE earth), the underlay rule counts the two edge-adjacent stone corners for earth
but not the diagonal one. Earth draws m 14, the inner corner with a lip on its SW quadrant. The
legacy lip runs about 10 px into the SE quadrant. Stone draws m 7 and leaves SE open with a
rounded inner corner, so a bright grass tuft shows in a corner that has no exposed top.

## Symptom

On the water trial at world (15520, 6000) the earth block (cols 19-23, rows 16+) is boxed in by
stone, and a grass tuft shows at its top-left corner
(`playtests/screenshots/2026-10-10-world07-legacy-tiles/water_trial_enclosed_earth_corner_tuft.png`).
Re-checked 2026-10-10 after the stone-under-earth fix: unchanged, still present
(`fixed_caves_column_and_tuft_three_way.png`, bottom row). That fix tests the corner ABOVE a
look's own corner; here the earth corner's above is stone, a later look, so earth still draws m 14.
Static count of corners with one earth corner below and three stone corners: the_catch 2
(local cells (9,-15), (16,-15)) and water_trial 3 ((19,0), (10,6), (18,6)). No world room has one.

## Root cause

`GroundAutotile.corner_mask` counts a later look only beside one of the earlier look's
corners. The diagonal is skipped on purpose, so that a stone block in the air shows no earth.
The plan lists this as a risk ("Underlay artefacts", `architecture/biome-tilesets`).

## Fix

Resolved 2026-10-10; see Resolution. The proposal was: when a tile has no air corner, count every later-look corner for the earlier look (the
plan's one-line fallback, limited to air-free tiles). The tile then becomes earth 15 under
stone m 7, and the tuft is gone.

## Prevention

`WangSheet.preview` could include an earth cell nested in a stone L, both ways up.

## Resolution (2026-10-10)

`GroundAutotile.corner_mask` treats a tile with no air corner, where the look appears, as buried. There
every later-look corner counts for that look, so earth boxed in by stone fills its tile (earth 15 under
stone m 7).

Re-shot on the 04:53 tree, HEAD | fixed, at 3x
(`playtests/screenshots/2026-10-10-world07-legacy-tiles/fixed_tuft_five_corners.png`):
- No tuft at any of the 5 corners: water trial (15520, 6000), (15232, 6192) and (15488, 6192),
  and the_catch (17760, 5520) and (17984, 5520).
- The earth corner is square, with only the stone's dotted inner face around it.
- Collision: the logged positions are identical to HEAD.
- Stone on earth: the summer_trial c29 pillar foot has zero diff pixels against the first
  WORLD-07 run, so the rounded feet are unchanged.
