---
id: playtests/2026-09-30-rain-gale-shell-look
type: playtest
title: Rain that lands, a one-way gale in pixel-art gusts, and water standing against the Redoma's curve
status: active
tags: [chuva, rain, vendaval, gale, redoma, water, visuals, sprite-bursts]
related: [architecture/the-bell-jar-closes-once]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/memory/song_effects/rain/rain_fall.gd
  - scenes/world/memory/song_effects/rain/rain_sky.gdshader
  - scenes/world/memory/song_effects/gale/gale_field.gd
  - scenes/world/memory/song_effects/bursts/sprite_bursts.gd
  - scenes/world/environment/water/water_body.gd
---

## Summary

A visual pass after the user's feedback: the rain was thin streaks with no
splashes, the gale's radial streaks read as noise, and Redoma cut water as a
square column (and made a lake vanish). All three were replayed with the real
timelines (`song_rain_basin_log`, `song_gale_chasm`, `song_release_gale_cocoon`,
`song_bell_jar_well`), and every other song timeline was rerun for regressions.

## What was seen

- Rain: a storm ceiling over the pulse, many more drops, crowns on the ground and
  the water. First run: drops aimed while the basin was low fell under the rising
  water and splashed on its bed; drops born inside an overhang were drawn over it.
  Both fixed (the live waterline stops a drop; a drop born in rock is not born).
- Gale: the first gust pass was invisible - bursts were spawning (about 17 alive)
  but pale peach one-pixel strokes on brown at those rates read as nothing. More,
  brighter, longer-lived gusts read as curling pixel-art wind.
- The one-way gale broke the cocoon timeline: it walked left, then played facing
  away from the plate. The puzzle is right (face where the load must go); the
  timeline now turns first.
- The seesaw timeline had been failing since Sombra's pulse was shortened (it
  climbed after the shadow faded); it now walks 5 s sooner.
- Redoma: the water stands against the curve with its lighter line. With a
  curved cut the old six-deep well kept its bottom corner wet, so it is five deep.

## What this cannot judge

Whether the storm multiply is too dark for a long rainy puzzle, and whether the
gusts' density feels busy over minutes rather than one crossing. A lake under a
shell was checked in a unit test only.
