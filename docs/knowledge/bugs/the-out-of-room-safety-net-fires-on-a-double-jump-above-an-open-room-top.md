---
id: bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top
type: bug
title: The new out-of-every-room safety net runs the hazard beat (fade to black, put back on firm ground) when a plain double jump lifts Ivo 64 px above an open room top
status: resolved
severity: medium
tags: [world-05, rooms, room-exit, safety-net, hazard, fade, double-jump, regression]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/wall-climb-leaves-the-world-over-the-cliff-chimneys-west-wall, bugs/a-hop-from-a-floor-just-below-a-seam-swaps-the-room-up-and-back, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/game.gd
  - scenes/world/rooms/room_exit.gd
---

## Summary

The fix for `bugs/wall-climb-leaves-the-world-over-the-cliff-chimneys-west-wall` added a safety net to
`Game._physics_process`: once `RoomExit.has_left` says Ivo has left the current room, and no room lies under his
body's centre, `_lost` is set and `_on_player_fell_into_hazard()` runs. In the air, `has_left` is true when the
body is 64 px past a top edge. Most rooms with no room above have an open top. A double jump (270 px) from any
floor less than ~206 px below such a top therefore triggers the hazard beat at the peak: the screen fades to
black and Ivo is put back on the last firm ground.

## Symptom

Working tree on 5062946, `--import` 01:27:51. A double jump straight up (0.45 s, then 0.4 s at +0.55 s):

| Timeline (`traverse_orchards_caldera_...`) | Floor | Room top | Peak feet | Result |
|---|---|---|---|---|
| `rv_n1_leaf_path_hill_double_jump` | leaf path hill (-8300, -1408) | -1536 | -1677.6 | `fade` rises from t 2.20 (0.13) to 0.93 at 2.60; put back at (-8300, -1408) |
| `rv_n2_orchard_well_oneway_double_jump` | orchard_well one-way (-3700, -1344) | -1536 | -1613.6 | same: 19 samples with `fade` > 0.05 |
| `rv_n3_threshold_bridge_deck_double_jump` | threshold_bridge deck (6880, 160) | 0 | -109.6 | `fade` 0.18 at t 2.30 → 0.98 at 2.70; put back on the deck at 2.80 |

hp stays 3 in all three runs.

Frames: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/rv_safety_net_on_a_plain_double_jump.png`.

## Impact

- **Wherever an open-topped room has a floor or ledge within ~206 px of its top, a double jump there is
  punished as if it were a fall into water.**
  - Threshold bridge deck: a running double jump over the gap is pulled back to the deck.
  - Leaf path hill, orchard_well one-way, windy gap shelf (top -1760, room top -1920).
  - Likely also high ledges in other regions.
- There is no damage, but the fade and teleport read as a death.

## Fix

Suggested: do not treat "above an open room top" as out of the world.
- Count a room as containing the body when the body is above its top and inside its x range, if no room lies
  above. Equivalently, give rooms with nothing above an unbounded top for this test only.
- Or fire the net only when the body is below every room in reach, or outside them horizontally and falling,
  or after N s outside every room.

The chimney's new ceiling already closes the gap that motivated the net.

## Prevention

A `game_test` case: a body 100 px above an open room top, airborne, with no room above. No `_lost`, no hazard
beat.

## Resolution (2026-10-10, re-verified)

`Game` now ignores a body that is wholly above the current room's top (`body.end.y <= top`). The camera's yield
is limited to the current room and the rooms touching it (`_reach_of`). Working tree on 5062946 with the coordinator's second round of fixes, `--import` at 02:37:17; nothing changed after it.
- **No fade, no pull-back:** the same double jumps (`traverse_orchards_caldera_rv_n1/n2/n3_*.json`) have zero
  samples with `fade` > 0.05. Leaf path hill: peak -1677.6. orchard_well one-way: -1613.6. Threshold bridge
  deck: -109.6. Each lands back where it took off.
- **The void case still respawns**
  (`..._rv2_v2_wall_climb_over_bloom_hollow_west_wall.json`). Wall climb over bloom_hollow's west wall (the
  world's west edge, open top) drops Ivo west of every room. The hazard beat fades in (0.91) at feet y ~650
  and puts him back on firm ground at (-6931.9, 288). It worked twice in one run, hp 3.
  - Teleporting straight into the void at load (`..._rv2_v1_*`) is not a valid test: no room ever becomes
    current, the boot fade stays at 1.0 and he falls forever. This is a runner artefact, not reachable in play.
- **Camera yield** (the coordinator asked how it looks).
  - Where a room above or beside touches the current one (leaf path: the windy gap at its corner; orchard_well:
    lake_chasm), the frame still follows: visible 1.00 throughout.
  - Over the threshold bridge (nothing above), the frame stays in the room. Ivo is partly out of frame from
    t 1.51 and wholly out of the top of the frame from t 1.81 to 2.85, about 1.05 s of a 1.6 s double jump.
    Only the HUD shows while the screen holds still.
  - Frame: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/rv2_double_jump_leaves_the_frame_top_on_the_threshold_bridge.png`.
  - Whether that reads as a deliberate "he went off the top" or as losing the character needs a human. It is
    the same shape as the opening report's bridge-jump note.

## Regression timeline re-pointed (2026-10-11, WORLD-25)

The orchard_well one-way that `rv_n2` stood on was removed, and orchard_well has no floor within 206 px of an open top any more. The check is now `traverse_woods_lake_rv_n2_pond_shelf_double_jump.json`: woods_pond's rock shelf (-5264, 64), open top y 0, peak feet -205.6, `fade` 0.00 throughout (`bugs/world-25-re-pointed-timelines-no-longer-test-their-scenario`).
