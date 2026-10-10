---
id: bugs/the-raised-mill-drawbridge-stands-through-the-windy-gap
type: bug
title: The mill town's 18-cell drawbridge, held up, is a solid 576 px pole through orchard_windy_gap's chasm - it stops the Vendaval crossing whenever the bridge is not lowered
status: resolved
severity: low
tags: [world-05, wind-orchards, drawbridge, soltar, vendaval, windy-gap, collision, level-design]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/the-mill-loft-is-reached-by-double-jump-without-soltar, bugs/a-lowered-drawbridge-is-a-10-px-curb-on-its-own-bank]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_mill_town.room
  - scenes/world/rooms/wind_orchards/contents/orchard_windy_gap.room
  - scenes/world/interactables/drawbridge/
---

## Summary

`mill_bridge` (`D` at mill town col 28 row 1, `length_cells` 18) is hinged at (-6768, -1472) and held upright
until Soltar drops it. Upright, it is 576 px tall: from the inn gallery up to y -2048. That goes through
the mill town's top, the whole of orchard_windy_gap (y -1920..-1536) and past its top. In the windy gap it stands in
the middle of the 20-cell chasm (x -7168..-6528), between the east ledge and the west floor, and it is solid.

## Symptom

HEAD 5062946, imported 00:23:06.
- **Gale crossing, bridge up**
  (`tools/playtest/scripts/traverse_orchards_caldera_g4a_windy_gap_gale_crossing_bridge_raised.json`). Ivo
  plays Vendaval on the east ledge facing west and makes a running double jump. He flies west at up to 460 px/s
  and stops dead at x -6745.9 (y -1772.8, t 7.05). He slides down the pole into the mill town.
- **Without the gale** (`..._g3_windy_gap_chasm_double_jump_no_gale_*.json`): stopped at x -6746 the same way.
- **From the gallery** (`..._g2_gallery_double_jump_to_windy_gap_ledge_*.json`): every jump east is stopped at
  x -6778.1 by the pole's other face.
- **With the bridge lowered** (`..._g4c_*`, `..._g5*`), the flight passes x -6768 freely.

Frame: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/raised_drawbridge_stands_in_the_windy_gap.png`
(the pole runs the full height of the windy gap's view). It also shows in the mill town as a dark bar rising
out of the top of the frame above the inn.

## Impact

- The intended route lowers the bridge before the windy gap, so the pole is gone while the player is there.
  In `g4c` the bridge was still down ~11 s after the pulse.
- If the bridge rises while the player is in the windy gap (a slow or failed attempt), the pole cuts the
  chasm. No crossing works until they drop to the mill town and lower the bridge again.
- **Visually:** a mill-town object stands in another room's sky.

## Fix

Options:
- Make the raised bridge not collide (a held-up plank is scenery), or give it collision only while lowered or
  falling.
- Or shorten the raised visual and collider to the mill town's bounds (fold the plank, or raise it as a
  shorter lifted section).
- Or move the hinge so that the raised bridge stands under a ceiling.

## Prevention

Room authoring: an entity's extent in every state (raised, lowered, swung) must stay inside its own room, or
must be intended for the neighbour. A `room_files_test` bound check per entity state would catch it.

## Resolution (2026-10-10, re-verified)

The bridge is now 6 cells, hinged at mill (36, 5) on the inn roof's east end. Raised, it spans y -1536..-1344,
inside the mill town. Working tree on 5062946 with the coordinator's fixes, `--import` at 01:27:51; nothing changed after it.
- **Crossings pass the old pole line.** The windy gap crossings with Vendaval
  (`traverse_orchards_caldera_rv_w3_late12_windy_gap_gale_crossing{,_r2,_r3}.json`) fly past x -6768 freely,
  with the bridge raised, and land on the west floor (x -7239..-7247).
- **Soltar still lowers it.** `rv_l2_soltar_bridge_to_loft`: Ivo walks it to its end (-6343.7, -1344).
