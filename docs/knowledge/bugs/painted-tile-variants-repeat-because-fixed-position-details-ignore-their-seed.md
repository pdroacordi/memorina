---
id: bugs/painted-tile-variants-repeat-because-fixed-position-details-ignore-their-seed
type: bug
title: paint_tile_bodies.py draws some details at fixed positions, so the caldera ash's variant 4 is a copy of variant 1 and the lighthouse "chip" variant changes one art pixel
status: resolved
severity: low
tags: [tiles, tooling, world-07, variants, caldera, lighthouse, art-pipeline]
related: [systems/art-pipeline, architecture/biome-tilesets]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - tools/art/paint_tile_bodies.py
  - tools/art/tiles/bodies/summer_caldera_ash.json
  - tools/art/tiles/bodies/lighthouse_masonry.json
  - tools/art/tiles/sources/summer_caldera_ash_1.png
  - tools/art/tiles/sources/summer_caldera_ash_4.png
  - assets/sprites/world/tilesets/summer_caldera/ash.png
---

## Summary

`detail()` in `tools/art/paint_tile_bodies.py` takes a seeded rng per variant, but the `block`, `pumice`
and `carving` details ignore it for position (`groove` only picks one of two rows): `block` always paints at (6, 6). The caldera ash spec lists
`block` twice (seeds 1 and 4), so `summer_caldera_ash_4.png` is pixel-identical to `_1.png`. `summer_caldera_ash.tres`
declares `fill_variants` stone 4, but the sheet draws only 3 distinct variants.

## Symptom

Pairwise pixel differences between the painted bodies (2026-10-13 review):
- `summer_caldera_ash`: 1 vs 4: 0 px (identical). The big cinder shows in the same cell spot twice as often as
  the other variants.
- `lighthouse_masonry`: base vs variant 1 (`chip`): 1 px. The chip's candidate spots (7, 6) and (6, 6) sit on the
  block joint column x 7, so two of its three pixels are already joint colour.
- Also near-invisible: `threshold_road` 0 vs 3 (2 px), `threshold_earth` 0 vs 3 (3 px), `wind_orchards_drystone`
  0 vs 1 and 0 vs 3 (3 px).

The fill draws a variant in 4 cells of 10. A copy or a 1 px variant draws the base, so the base repeats as
wallpaper more than the variant count suggests.

## Root cause

The position-fixed details were written for one use per spec. Two specs reuse them, or place them where the base
already has that colour. Nothing checks that variants differ.

## Fix

Resolved 2026-10-13. Every detail in `paint_tile_bodies.py` now takes its position from the variant's seed. A detail that lands mostly on colours the body already has (a chip on a joint) is redrawn from the same rng, up to 40 times, until it differs from the base and from every earlier variant by `MIN_DIFFERENT` (6) art px. The tool exits without writing if any two bodies are still closer. All eight painted materials were repainted (the closest pair in each is now 6 px apart; the ash's variants 1 and 4 differ) and their sheets reassembled.

## Prevention

`paint_tile_bodies.py` prints the closest pair per material and refuses fewer than 6 art px. `biome_tileset_test.test_every_fill_variant_is_distinct` fails any biome look whose plain fill and fill variants, in band 0, differ pairwise by fewer than 3 art px (the village soil's pebble variant is 3).
