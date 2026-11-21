---
id: playtests/2026-11-20-world15-17-guardian-regions-dressing
type: playtest
title: WORLD-15/16/17 guardian-region dressing at real memory - props read in the grey, movers stop below 0.2 and speed up in a pulse, fights stay readable; one decal floats (orchard_arena claw marks), the innkeeper is mostly hidden, the street windmills read as toys
status: active
build: 1c01ab6b + uncommitted WORLD-15/16/17 dressing; a sibling regenerated 191 dressing files at 20:19-20:22, so every judged run is from after the second --import (20:27:51; nothing under scenes/ resources/ assets/ globals/ tools/art changed after it). The mover run (20:24) saw the new scenes before that import.
area_tested: "every dressed room of frozen_lake, wind_orchards and summer_caldera at authored memory (0.3 / 0.25 / 0.15, no world_restored), the five ambient movers, the Frost and Sun fights walked in from the west doorway"
ratings: { readability: 4, aesthetics: 3 }
tags: [props, world-15, world-16, world-17, frozen-lake, wind-orchards, summer-caldera, greyhush, ambient-motion, inhabitants, guardians, playtest]
related: [systems/props, bugs/orchard-arena-claw-marks-hang-in-the-air-west-of-the-east-face, bugs/guardian-region-props-placed-inside-ground-cells-draw-nowhere, bugs/the-long-corridor-column-stands-on-its-pressure-plate, bugs/the-mill-town-well-head-floats-over-the-shaft, playtests/2026-11-20-grd18-leaf-sun-mentor-art]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/world/rooms/frozen_lake/contents/
  - scenes/world/rooms/wind_orchards/contents/
  - scenes/world/rooms/summer_caldera/contents/
  - scenes/world/environment/props/ambient_motion.gd
  - scenes/world/environment/inhabitants/fisherman.tscn
  - scenes/world/environment/inhabitants/innkeeper.tscn
  - scenes/world/environment/inhabitants/miller.tscn
---

## Summary

The user had already toured these regions in full colour. This session covers the authored grey. The dressing reads
well in the grey: stone, ice and timber props keep clear silhouettes and values, and nothing covers a door, plate,
gate, fruit or teacher. Movers behave per the contract. At 0.25-0.3 they run slowly (they never "hold still" in these
two regions, because both sit above 0.2), they freeze at a forced 0.15, and they run at full speed inside a pulse.
Both guardians and every telegraph and spawn stay readable over the arena dressing. Defects: the orchard_arena claw
marks float in the air (bug filed); the innkeeper is mostly hidden behind the counter; the two street windmills in
the mill town read as toy-sized.

## What was tested

- **Tours:** a teleport tour per region through every prop cluster of every dressed room (94 frames), run twice
  because the dressing was regenerated mid-session. A `-s` probe (`dress_probe.gd`, scratch) kept Ivo's hp topped up
  and logged every on-screen `AmbientMotion` every 100-250 ms (sprite frame, memory sampled at the prop).
- **Movers:** at baseline for ~5 s, then FREEZE played beside them (mill town lower street, the fishing village
  nets, the fisher hut, the inn, the summit). A second run forced the field baseline to 0.15 at the same spots.
- **Fights:** `guardian_fight_player_driver.gd` (`PL_GOD=1 PL_LEARNED=1`). Ivo walked in from the west doorway:
  Frost from (4420, -1640), Sun from (2500, 1814), with `move_right` held for 3.0-3.4 s. The Frost fight showed swipe,
  slam (ice rows) and charge; the Sun fight showed claw, roar, charge and ember spit (pods and patches), then lucidity.
  Neither fight drew the icicle fall or the sun shafts, so `guardian_art_check_driver.gd` forced them:
  `frost_icicle_fall`, `frost_body_drop` with Ivo at x 4620 (under the west corner icicles), and `summer_sun_shafts`,
  `summer_ember_spit` with Ivo at x 3220 (in front of the crouched shadow and the sun disk).
- `prop_grounding_test` passes (4/4).

## Findings

**Defects**

- **orchard_arena claw marks hang in the air** (`bugs/orchard-arena-claw-marks-hang-in-the-air-west-of-the-east-face`).
  `ClawMarks` at local (1230, 180) covers x 1212..1248. The east face is column 39 (x 1248+, rows 0-5), so all three
  slashes are drawn on open sky beside the wall. `prop_grounding_test` has no rule for decals cut into a face.
  `screenshots/2026-11-20-world15-17-guardian-regions-dressing/orchard_arena_claw_marks_in_the_air.png`.
- **The innkeeper barely reads.** In orchard_inn the innkeeper stands at local (350, 288), inside the 4-cell `SSSS`
  counter block (cols 9-12, top y 256). Props draw behind ground, so only ~20 px of head and shoulders show above
  the counter, pale among the mugs and jug. In the grey it reads as one more object on the counter.
  `orchard_inn_innkeeper_behind_counter.png`. The probe confirms it animates.

**Judgement calls (low confidence, for the user)**

- **The two small windmills in orchard_mill_town read as models.** The one that remains after the regeneration is
  on the lower street (local 1720, 352): its body is 84 px tall, about 1.6 times Ivo, and shorter than the scarecrow
  beside it. The windmills in the backdrop behind it are building-sized. Board: "two small windmills on the sky band
  behind the street". (Before the 20:20 regeneration, a second one stood at local 1150, body hidden behind the inn and
  sails drawn over the inn's wall; it is gone now.)
  `orchard_mill_town_lower_street_grey.png`, `orchard_mill_town_lower_street_pulse.png`.
- **Frost moss patches** (lake_waterfall_path, lake_high_wall, lake_icefall shaft) are flat white blobs stuck to wall
  faces mid-height. They read as frost, but as the brightest marks in a grey cave they draw the eye more than a
  backdrop detail should. `lake_frost_moss_on_wall_faces.png`.
- **The Sun arena's char silhouettes** (alpha 136) are clearly lion-shaped in the grey. When the lion stands over
  one (roar at x ~2900, the rearing pose at x ~3500), its own shadow sits right behind it like a dark double. The
  mane, the embers and the shafts stay clear on top of the char, but the lion's dark legs lose edge contrast where
  they overlap it. Inferred from stills, not from play; a human fight is needed to say whether it distracts.
  `caldera_arena_roar_over_burned_shadows.png`.
- orchard_terraces: the ladder (local 228) stands 108 px from the apple tree (120), upright with nothing to lean on.
- Board items not built (scope notes, not defects): no frozen boat under the fishing village deck, no hut smoke, the
  inn fireplace is unlit, no brazier embers, no ice columns on the Frost arena's shoulders.

**Memory and motion** (probe numbers, not frames)

| Mover | Baseline | Frame changes at baseline | Forced 0.15 | Inside a FREEZE pulse (memory 1) |
|---|---|---|---|---|
| FishRack, FishRack2, NetPoles (fishing village, 3 fps) | 0.30 | ~1 per s | 0 in 5 s | ~3 per s |
| Fisherman (fisher hut, 6 fps) | 0.30 | ~1.7 per s | 0 | ~5.5 per s |
| Innkeeper (inn, 6 fps) | 0.25 | ~1.5 per s | 0 | ~5.5 per s |
| Miller, Windmill2Sails (mill town, 6 / 7.2 fps) | 0.25 | ~1.5 per s | 0 | ~6 per s |
| GreatWindmillSails (summit, 3.84 fps) | 0.25 | ~1 per s | 0 | ~3.5 per s |

- At the authored memory, nothing "holds still": `AmbientMath.advance` stops only below 0.2, and the lake (0.3) and
  the orchards (0.25) are above it, so every mover runs at 25-30 % speed. Interiors take their region's memory
  (fisher hut 0.3, inn 0.25). The caldera (0.15) has no movers. This matches `systems/props`. If the user expected
  the lake and orchard movers frozen until a pulse, the region memory or the threshold has to change.
- With the baseline forced to 0.15, every mover held its frame for the whole 5 s. FREEZE raised the sampled
  memory to 1.0 within ~1 s, and each mover ran at full speed until the pulse ended.
- The first summit song was dropped (no pulse; the summit fly was harassing Ivo); the second worked.
- `interiors_base_vs_pulse_sheet.png`: both interiors in the grey and in the pulse. Every prop reads in both.

**Grey readability** (`lake_fishing_village_grey.png`, `caldera_long_corridor_grey.png`)

- Lake: timber (racks, nets, hut, traps) stays mid-dark against a pale sky, and ice crystals, columns and icicles
  are the brightest whites. The fisherman is a dim grey figure, but his silhouette holds.
- Orchards: the trees, carts and hay go muddy brown-grey but keep their shapes. The scarecrow is the palest object
  in the mill town. It is plain straw, with no bone mask, so it is not confused with the guardian.
- Caldera: columns, broken columns, statues and the sun reliefs are pale sandstone and read strongly at 0.15. Ash
  heaps read as pale mounds (similar to snow). Burned roots and thorn shrubs are dark and faint, as intended.

**Floating, clipping, covering**

- A script checked every prop rect against every door, plate, gate, fruit, bench, talk, item and teacher cell. The
  only overlaps are intended: the hut and inn facades carry their doors, the pear limb and pear tree hold their
  fruit, and the existing leaf piles mark the soft-landing snow zones.
- The windy gap's weather vane (-6512, -1632) stands behind Ivo's usual spot, 64 px west of the kestrel teacher,
  without covering it. The mill town well head sits over the Hollow Tree well with the drop still visible.
- Nothing else floated or clipped in 94 frames, apart from the claw marks above. The 20:19-20:22 regeneration was the
  reviewer's fixes for three bugs (props inside ground cells, the corridor column on its plate, the floating well head).
  The post-import frames confirm all three: the shards, rubble and young tree are visible, the column clears the plate,
  and the well drum rests on both lips.

**Fights**

- **Frost** (`frost_arena_slam_beside_corner_icicles.png`, `frost_arena_falling_icicle_vs_static_icicles_forced.png`):
  the arena's own icicles are pale grey and small, at the corners and on the ceiling edge. A falling icicle is
  saturated blue with a dark outline and a floor glint under Ivo, so it cannot be confused with the dressing. Near the
  west wall the guardian's raised slam fist overlaps the corner icicle cluster: minor clutter, and the fist still reads.
- **Sun** (`caldera_arena_embers_over_brazier.png`, `caldera_arena_sun_shafts_over_relief_forced.png`): the ember pods
  (orange) and patch markers (yellow bars) stand out over the grey braziers, which sit under the west patch spot.
  A sun shaft's thin warning line crosses the sun disk and stays visible. The burning shaft is the brightest thing on
  screen. The columns stand at the walls (x 2672, 3728) and never hide the lion or Ivo, who draw in front.

## Ratings rationale

Readability 4: in every frame, each guardian, telegraph and spawn and every interactable reads over the dressing.
The deductions are the hidden innkeeper and the char double behind the lion. Aesthetics 3: the grey keeps the props'
shapes, but the floating claw marks, the toy-scale street windmill and the bright frost blobs look off. Fun and
fluidity are not rated: this session judged stills and probe numbers, not play feel.
