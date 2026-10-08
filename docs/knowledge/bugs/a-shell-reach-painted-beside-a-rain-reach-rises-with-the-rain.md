---
id: bugs/a-shell-reach-painted-beside-a-rain-reach-rises-with-the-rain
type: bug
title: A shell reach (`u`) painted on the same water as a rain reach (`r`) is silently made a rain reach
status: fixed
severity: low
tags: [water, rooms, parser, reach, shell-reach, redoma, chuva, pzl-06]
related: [architecture/the-shell-displaces-water-into-the-reach, architecture/a-pool-rests-below-its-painted-reach, systems/water, systems/rooms, systems/bell-jar]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/rooms/maps/room_map_parser.gd
  - scenes/world/environment/water/water_basins.gd
  - scenes/world/environment/water/water_layer.gd
---

## Summary

The legend says of `u` "The rain never raises it", but nothing refuses a map that paints `u`
and `r` over the same pool. The parser accepts it, `WaterBasins` marks the basin `rains`, and
`WaterLayer` builds a `RainBasin`: Chuva raises the water through the `u` rows and Redoma
raises nothing. Latent: no map paints both today.

## Symptom

Found in review of the PZL-06 diff (2026-10-08). Derived from the code; not run.

- `u` and `r` both touching the same `f`/`~` water: `_resolve_reach` puts the `r` group in
  `RoomMap.reach[host]` and the `u` group in `RoomMap.shell_reach[host]`
  (`room_map_parser.gd:169-170`). No error.
- `RoomMapNode` paints both on the host's layer (alternatives 1 and 2). In
  `WaterBasins._pour` one `r` cell in the basin sets `basin.rains = true`
  (`water_basins.gd:63`). `WaterLayer._pour` then picks `rising_body_scene` and sets
  `displaces = false` (`water_layer.gd:50,55`). `RainBasin` raises to `level_range().x`, the
  painted top, which is the top `u` row when `u` is painted highest.
- `r` painted on top of `u` (touching only `u`, not the water): the `r` group has no host, so it
  becomes a lone dry rain basin (`map.reach["r"]`) on its own layer, stacked above the pool.

## Root cause

The two reach kinds are resolved independently. `_resolve_reach` only checks each group against
water cells, never against the other reach kind, and `WaterBasins` lets any rain cell decide the
whole basin.

## Fix

Not fixed. In `_resolve_reach`, report an error when a reach group touches a cell of the other
reach kind, or when a host already has the other kind (`map.reach` vs `map.shell_reach`). Add a
parser test for each case and a line in the `u` legend description ("never with r").

## Prevention

A legend rule stated as "never" needs a parser error, not only a description. Test the
combinations of reach kinds as well as each kind alone.

## Resolution

Fixed before commit (2026-10-08): the parser rejects a shell reach touching a rain reach (`room_map_parser_test.test_a_pool_rises_with_the_rain_or_a_shell_not_both`).
