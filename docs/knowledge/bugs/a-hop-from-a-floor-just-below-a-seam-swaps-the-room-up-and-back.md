---
id: bugs/a-hop-from-a-floor-just-below-a-seam-swaps-the-room-up-and-back
type: bug
title: On a floor 64-128 px below a horizontal seam, a hop lifts Ivo's whole body into the room above and the landing brings it back - two glides (mill loft, inn gallery, terraces crown) or two region cuts (canopy launch branch) per hop
status: resolved
severity: medium
tags: [rooms, seam, camera, glide, cut, region, world-05, feel, wind-orchards]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/a-hop-below-a-seam-flips-the-room-twice, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/game.gd
  - scenes/world/camera.gd
  - scenes/world/rooms/wind_orchards/contents/orchard_mill_town.room
  - scenes/world/rooms/wind_orchards/contents/orchard_terraces.room
  - scenes/world/rooms/spring_woods/contents/woods_canopy.room
---

## Summary

`bugs/a-hop-below-a-seam-flips-the-room-twice` was resolved with whole-body hysteresis: Ivo leaves a room
only when his whole body (54 px) is out of it. That fixed floors that put the body across a seam (32 px
under). Floors a bit further down now behave the other way. Standing, the body is wholly in the lower room. A
hop carries it wholly into the upper room, and the landing carries it wholly back. Each hop is therefore two
real room changes:
- inside a region, two 0.45 s camera glides (one up, one back);
- across a region seam, two one-frame cuts with a palette change.

Four such floors are on the Orchard routes, and two of them are launch points the player stands on before the
jump up.

## Symptom

HEAD 5062946, imported 00:23:06. `tools/playtest/scripts/traverse_orchards_caldera_h{1..4}_*.json`. Each run
stands Ivo on the floor and hops with presses of 0.05, 0.1, 0.2, 0.45 and 0.45 s, logging every 0.05 s.

| Floor | Below the seam | Room above | Hops that switch | Per switching hop |
|---|---|---|---|---|
| orchard_mill_town loft (S46-51, y -1472) | 64 px | orchard_counterweights (in region) | 0.1, 0.2, 0.45, 0.45 (all but the 0.05 tap) | 2 glides. For a 0.45 s hop the camera centre goes y -1400 → -1716 in 0.45 s, then back to -1428 after landing (t 6.00-7.20). |
| orchard_mill_town inn gallery (one-way cols 23-28, y -1472) | 64 px | orchard_windy_gap (in region) | 0.1, 0.2, 0.45, 0.45 | 2 glides |
| orchard_terraces crown (one-way cols 43-52, y -1792) | 128 px | orchard_chasm_bridge (in region) | 0.45, 0.45 | 2 glides (switch at feet -1924, back at -1848) |
| woods_canopy launch branch (one-way cols 9-14, y -1024) | 128 px | orchard_terraces (another region) | 0.45, 0.45 | 2 cuts: camera centre (-4054, -972) → (-4160, -1328) at t 6.20, back at t 6.90. The palette switches woods ↔ orchards both times. |

Frames: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/hop_below_seam_swaps_rooms.png`. The
mill-loft peak shows the counterweights' frame and the landing the mill town's. The canopy-branch peak shows
the orchard's frame (grey) and the landing the woods' (green).

Ivo stays fully in frame throughout (visible 1.00 on every sample); this is about the camera moving, not
losing him.

## Impact

- **Feel** (inferred from the logged camera motion, not observed at 60 fps):
  - On the loft and gallery, every hop, even a 0.1 s tap, swings the view ~300 px up and back within ~1.2 s.
  - On the canopy branch, the obvious "test hop" before the double jump into the Orchards flashes the whole
    screen to the next region and back.
- Nothing breaks: the rooms, Ivo and the landing are all correct.

## Fix

Options for the implementer:
- Defer an upward room change made in the air until Ivo lands in the new room or rises past a margin. Today
  the camera's `_keep_subject_in_view` already keeps him framed without the switch.
- Or require the body to be a margin past the seam (e.g. one body height) before entering the room above.
- Or author such floors at least ~200 px (hop peak 143 + body 54) below a horizontal seam, or across it, and
  add a `room_files_test` rule. The loft and gallery are meant as launch points into the room above, so the
  first two options fit them better.

## Prevention

A `game_test` case: a body standing 64 px and 128 px below a seam hops in place, and no `room_changed` fires
unless it lands in the upper room.

## Resolution (2026-10-10, re-verified)

`RoomExit.has_left`: Ivo leaves sideways once his body is out. Up or down, he leaves only once his body is
`SEAM_MARGIN` (64 px) past the edge, or when he stands. Working tree on 5062946 with the coordinator's fixes, `--import` at 01:27:51; nothing changed after it.

`traverse_orchards_caldera_rv_h{1..4}_*.json`: taps of 0.05/0.1/0.2 s and jumps of 0.45 s, 0.45 s.
- **No room change at all** on the terraces crown (peak feet -1935.7), the mill loft at row 0 (-1679.7), the
  new windy-gap launch ledge, row 3 (-1583.7), or the canopy launch branch (-1167.7).
- **Normal crossings still switch once:**
  - re-runs of `o1` (canopy → terraces, region cut at feet -1246.9);
  - `o5` (crown → chasm bridge at feet -1996.2);
  - `o5b` (chasm bridge ↔ lake_chasm cut both ways, drop to the crown);
  - `o2a`, `c3a` and `o4` (chimney → caldera_chimney_base cut).
  No fade in any of them.
