---
id: bugs/wind-piles-water-above-its-own-bank
type: bug
title: A wind crest rises above the bank it piles against, so a gale stands pool water in mid-air
status: fixed
severity: medium
tags: [water, wind, crest, gale, pzl-03]
related: [architecture/wind-piles-a-bounded-crest, systems/air, systems/water, bugs/a-crest-built-off-screen-springs-in-overshooting, playtests/2026-10-08-frozen-wave]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/environment/water/wind_crest.gd
  - scenes/world/environment/water/water_body.gd
  - resources/world/water/water_profile.gd
  - resources/world/water/still_pool_profile.tres
---

## Summary

`WindCrest` caps the crest at `min(crest_height, crest_per_fetch * width)` and never at the
height of the bank it piles against. `still_pool_profile.tres` (every pool's profile) takes the
default `crest_height` 160, so any Vendaval over any pool stands up to 160 px of water above a
bank that may be 8 px high.

## Symptom

Found in review of the PZL-03 diff (2026-10-08). Not run in the engine. Derived from the code
and the shader:

- `water_surface.gdshader` draws every texel from `rest_y - round(r)` down to the floor, and the
  quad's rect now reaches `cap + 4` px above the rest line (`water_body.gd:553`). Nothing clips the
  water against the ground beside the pit.
- Autumn trial chasm, the designed solution (Vendaval from col 17, facing right): the pool's
  columns sit 96..576 px from the origin, so the mean gale is about 140 px/s and the drive is about
  0.9. The crest climbs toward about 145 px against a far bank only 40 px above the rest line
  (water row 17, inset 8). A wall of water about 100 px tall stands in the air over the bank Ivo
  lands on.
- Water trial, section 2, with Vendaval played on the shore facing left (the pool is on his right;
  `GaleShape` blows one way across the whole disc): the crest piles at the left bank, which is
  the shore, 8 px above the rest line. Congelar then makes a 152 px ice face at x 960 with no
  collider on its side (`IceCollider` lays segments along the band tops only). Ivo walks into
  the ice and falls into the water beneath it.
- The winter well (9 cells, cap 144) has banks 8 px above its rest line.

The natural `W` currents do not cause it. Each `WindZone` box rises from its cell's floor, and
`_refresh_winds` samples 4 px above a rest line that lies 8 px or more below that floor.

## Root cause

`wind_crest.gd:12` (`_cap`) knows the pool's width but not its banks. `water_body.gd:97` builds a
crest for every body with a profile, and `crest_height` defaults to 160 in
`water_profile.gd:56`, so the one puzzle pool's tuning reaches every pool in the game.

## Fix

Fixed before commit (2026-10-08): `WindCrest.set_banks(left, right)` caps each direction by its downwind bank, which `WaterBody` reads once from the room's map (`RoomMapNode.ground_at`, scanning up from the rest line beside each end); no room map leaves it uncapped. `wind_crest_test.test_water_never_piles_over_its_bank`.

Verified in the engine on the fixed code (playtest `2026-10-08-frozen-wave`). The autumn chasm's designed solution: the crest climbs to the far bank's lip (about 35 px against a 40 px bank, t 16.8) and settles, with no water above the bank. Water trial, Vendaval on the shore facing left: Congelar's ice by the shore stands 8 px above flat ice (y 6000 against 6008) and Ivo walks onto it with no face. The same gale tilts section 1's tank, whose banks are tall, and its log tilts with it.

Not fixed. Either or both:
- Cap each sign separately by the downwind bank's height above the rest line.
  `WaterBasins`/`WaterLayer` know the ground beside each basin and can hand it in like
  `set_floor`.
- Make the crest opt-in. Set the default `crest_height` to 0 and give A Onda Parada's pool its own
  profile and layer preset (the plan already calls "a still pond is a profile with
  `crest_height` 0" the open/closed path).

## Prevention

A shape added to the water's target must stay inside the basin that holds it. When a new
offset or level source is added, check it against the lowest bank of every painted pool, not
only the puzzle it was made for.
