---
id: bugs/a-wall-climb-over-the-seam-pillar-shows-the-wall-up-cut-in-the-sky
type: bug
title: A wall climb over the pillar at the lake_fishing_village / lake_waterfall_path seam shows the WALL_UP cut (valley sky against ice-cave rock) in open sky; the allowance's reason does not hold
status: resolved
tags: [backdrop, room-ring, seam, hard-cut, world-28, allowlist, wall-climb]
related: [bugs/a-ring-corner-diagonal-shows-a-rock-wall-in-the-mills-sky-on-a-jump, architecture/backdrop-seams, systems/backdrops, systems/rooms]
created: 2026-10-13
updated: 2026-10-14
source_files:
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/environment/backdrop/backdrop_seams.gd
  - tests/scenes/world/environment/backdrop/backdrop_seams_test.gd
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/rooms/frozen_lake/contents/lake_fishing_village.room
  - scenes/world/rooms/frozen_lake/contents/lake_waterfall_path.room
---

## Summary

RESOLVED 2026-10-13 (WORLD-28 re-review, played; was medium). `backdrop_seams_test.ALLOWED` accepts
`lake_fishing_village|lake_waterfall_path ring: x 2560, y -2080..-1920` as `WALL_UP`: "a jump raises the frame
over the open room, but its side stays at the seam ... so the line is the frame's own edge". With `WALL_CLIMB`, Ivo
climbs the hanging wall at the seam (village col 59 / waterfall col 0, rows 0-4) and goes over its top into the ring.
The frame then yields past x 2560, and a hard vertical line of ice-cave rock against the valley sky stands in open air
above the pillar, beside Ivo.

## Symptom

Timeline (scratchpad `rev/timelines/wu_d_wallclimb_shots.json`): start (2440, -1633) in the passage, skills
`[DOUBLE_JUMP, WALL_CLIMB]`, hold right, and press jump for 0.3 s every 0.5 s from t 2.3. The wall slide refreshes
coyote time, so each press is a ground jump up the wall face. At t 3.72 Ivo is at (2561, -1981), and the current room is
still `lake_fishing_village` (his centre is in the void, over the waterfall path's columns). The camera centre is
(2261, -1863), at t 4.22 (2357, -1900). Stills `wu_d_1` and `wu_d_2` show the cut from the frame's top down to the
pillar's snow cap at y -1920. It sits about 100 px inside the frame's right edge: flat valley sky on the left, the dark
ice-cave wall on the right. Ivo walks over the pillar top and lands in the waterfall path. Nothing out of the ordinary is
needed: the climb takes three presses with a basic ability.

## Root cause

- `void_owner` gives the void over each room's columns to that room (`ABOVE`), so the two rooms' sky-vs-rock boundary is
  x 2560 continued straight up through the ring. That is correct ownership. The problem is the allowance's premise that
  no frame shows the line away from its edge.
- `GameCamera._keep_subject_in_view` yields sideways whenever Ivo's body plus `subject_margin` passes the clamp. Ivo
  does not need to change rooms for that. Above the two rooms' tops `RoomExit` keeps the current room (`_room_at` of a
  centre in the void returns null, and `is_lost` finds the waterfall path below), so the village's reach
  (x up to 2720) lets the frame follow him over the seam.
- `WALL_UP` was checked with stills `f5`-`f8`: double jumps from the floor beside the wall, which never reach the top.
  A wall climb was not tried.

## Fix

Not fixed. Options:
- A `[back]` wall or solid cells over the top of the pillar do not help: the ring is void and draws only backdrops. The
  cut can only be hidden by changing whose picture fills the void there. For example, give the void above the pillar
  (x 2528..2592) to one room, or make the two rooms share a picture above their tops.
- Or raise the waterfall path's west wall above its top row, so the seam ends in a wall reaching the ring limit. Rooms
  cannot extend past their 384 px grid, so this means making the pillar unclimbable (no wall face to slide on, e.g. a
  slope or spikes) and re-running the `reach_audit`.
- Or ask the user whether a straight rock edge in the sky above a climbable pillar is acceptable, and record the answer
  verbatim. Then `WALL_UP`'s reason must say that a climb shows it.

Check the other three `WALL_UP` entries the same way (`lake_chasm|orchard_chasm_bridge x -3200`,
`orchard_arena|orchard_cliff_chimney x -10240`, `the_catch|water_trial x 17472`): each is a seam between two wall tops,
so a wall climb may reach it too.

## Prevention

- A ring allowance whose reason depends on what a frame can reach must be checked with every traversal ability the
  player can have there (double jump, wall climb), not only a jump from the floor.
- `room_ring_test` could sweep the body over the top of every seam wall that has a wall face to climb. Today it sweeps
  only lines across edges and over the top at fixed heights.

## Resolution (2026-10-13)

- **Over its top a room shows its region's open set.** A `Backdrop` whose set overrides its region's (a cave, rock or
  interior wall) builds the override's layers with `Backdrop.Part.UNDER_TOP` and the region's set with `OVER_TOP`
  (`Sky0..`). The shader's `part` discards by `BackdropMath.over_top` (the pixel centre above the room's top edge), the
  same test in both languages. Ownership is unchanged, so every pixel keeps one owner and every line stays straight.
  Rock fills only the room and the void beside or under it; over the wall tops the sky goes on. Over the seam pillar the
  village and the waterfall path both show `village_valley` at the frozen lake's horizon: the same pixels, no cut.
  `backdrop_seams_test` takes the set per cell (`BackdropSeamRoom.over_top`).
- **The four former `WALL_UP` cuts.** Played with `[DOUBLE_JUMP, WALL_CLIMB]` (scratchpad/w28 `timelines/h1`-`h4`):
  - fishing village / waterfall path (x 2560): gone. Stills `h1_*_1`, `_2` (the moments of `wu_d_1`, `wu_d_2`): sky
    over both, the pillar's stone below.
  - orchard_arena / orchard_cliff_chimney (x -10240): gone. The arena's hanging block has a lip at row 0, so the climb
    stops under it (`h3_*`).
  - water_trial / the_catch (x 17472): gone; the climb over the trial's east wall onto the catch's roof shows sky
    (`h4_*`).
  - orchard_chasm_bridge / lake_chasm (x -3200): remains, at a region border. Over the wall tops both show
    `village_valley`, but at the orchards' and the lake's horizons (-1301, -1685), so the sky bands step on a straight
    line. A climb over the bridge's east wall onto the chasm's roof shows it (`h2_*`, `crop_h2_sky.png`). Listed as
    `REGION_SKY` with the user's "OK until skies match (Recommended)" (2026-10-13). Gone the same day (WORLD-33): every
    surface set's sky has a vertical scroll of 0, so it stands at eye level on any horizon, and a border cairn covers
    the lake's far peaks over the tops; the cut is now `REGION_TOPS` with a cover (`systems/backdrops`).
- Cuts that the rule removed elsewhere: crater/seesaw y 1376, cistern bottom/crater y 992. New ring limits it made
  (all facing solid walls): chasm/high wall y -2464, chimney base/cliff chimney y 1376, cistern bottom/temple gate y 1376.

**WORLD-34 (2026-10-14):** Ivo can no longer get over a first-row seam pillar through the sky (the band's side is an ungrippable edge wall, the pillar's top a flush slab), so this view no longer arises in play (by construction, `architecture/world-edges-from-the-room-list`; not re-shot).
