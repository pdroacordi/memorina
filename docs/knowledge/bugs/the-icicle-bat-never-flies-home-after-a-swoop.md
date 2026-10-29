---
id: bugs/the-icicle-bat-never-flies-home-after-a-swoop
type: bug
title: The icicle bat never reaches its anchor after a swoop. It pins on a block corner or wall it meets nearly head-on, and a swoop from the east carries it out of lake_ice_caves into lake_frost_arena
status: resolved
severity: medium
tags: [core-13, creatures, bat, ceiling-ai, swoop-path, flight-component, floating, lake-ice-caves, lake-frost-arena]
related: [systems/creatures, architecture/corrupted-creatures, playtests/2026-10-29-core13-round2, bugs/a-flyer-dashes-tail-first-when-its-target-crosses-during-the-telegraph]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/enemies/ai/ceiling_ai.gd
  - scenes/characters/enemies/ai/swoop_path.gd
  - scenes/characters/components/flight_component.gd
  - scenes/characters/creatures/bat/bat.tscn
  - scenes/world/rooms/frozen_lake/contents/lake_ice_caves.room
  - tools/playtest/scripts/core13_bat.json
---

## Summary

After its first swoop, `lake_ice_caves_bat_2` (anchor (4304, -1808)) never hangs again. It stops
in mid-air, still in the fly pose, and swoops again from wherever it stopped. This happened in
every run (6 of 6, on the build before and after the 13:14 `ceiling_ai.gd` facing fix). It
happens in two ways, depending on where Ivo stands when the swoop locks.

1. **Ivo at x ~4369 (inside the room):** the swoop ends near (4436, -1787). The bat climbs to
   (4426, -1867), flies west toward its anchor and stops for good at **(4364, -1824)**. That is
   the lower right corner of the ceiling block it hangs from (cols 33-35, rows 1-2, bottom y
   -1824).
2. **Ivo at x ~4417 (the right part of the reach, where a player coming from the arena door
   enters it):** `SwoopPath` ends at the mirror of the start, x ~4530. That is past the room's
   east edge (x 4480). The bat flies out through the open rows 5-8 of col 39 into
   `lake_frost_arena`. It stops for good at **(4524, -1766)**, under the arena's col-0 block
   (rows 3-4). The camera is clamped to `lake_ice_caves`, so the bat is out of frame. About 1.5 s
   later it swoops back in from off-frame and hits Ivo.

## Evidence

- Runs `bat1`/`bat1n` (Ivo stops at 4417-4452) and `bat2`/`bat2n`/`fin_bat` (Ivo stops at 4369-4426),
  `trace` every physics frame. The bat's position comes from `foes=` dx/dy plus Ivo's position:
  - case 1: `3.71 (4426,-1867) recover` -> `4.36 (4364,-1830)` -> `4.49..5.49 (4364,-1824..-1823) -`
    -> `5.61 telegraph` from that point.
  - case 2: `3.46 (4512,-1750) recover` -> `3.71..5.46 (4524,-1766..-1767)` -> `5.60 telegraph`
    -> swoops west through Ivo, who is hit (hp 2 -> 1 at 6.42-6.44 in both builds).
- Frames: `playtests/screenshots/2026-10-29-core13-round2/bat_swoop_then_pinned_on_the_block_corner.png`
  (frames 4.0-5.5 show the bat spread-winged at the block corner) and
  `bat_swoop_leaves_the_room_and_returns_from_off_frame.png` (frames 3.0-6.0: the bat is gone from
  the room, then a wingtip comes in at the right edge at 6.1-6.2).

## Likely cause (inferred, not verified in code)

- `CeilingAI._recover_tick`/`_home_tick` steer straight at `_home`, with no detour.
  `FlightComponent` turns that into a velocity, and the body (`motion_mode` FLOATING) slides along
  what it hits.
- In FLOATING mode, `CharacterBody2D.move_and_slide` does not slide on a contact whose angle to
  the surface normal is under `wall_min_slide_angle` (default 15 degrees). The two pinned
  headings are 14.9 degrees (case 1: offset (-60, +16) into the block's side) and 10.8 degrees
  (case 2: offset (-220, -42) into the arena block's side). Both are under that limit, so the
  bat stops dead against the face instead of sliding off the corner.
- Case 2 also needs the swoop to leave the room. `SwoopPath` mirrors the start across the target
  without regard to the room. With the anchor 176 px from the east wall and a reach of 128 px
  east, any target past x ~4392 puts the path's end beyond x 4480. Nothing keeps a flyer inside
  its room: `WorldEdges` masks only Ivo.

## Suggested fix (for the implementer to choose)

- Let the homing slide. Set `wall_min_slide_angle = 0` on the flyers' bodies, or project the steer
  onto the contact's tangent while it is against a surface. Then add a test that flies the
  bat home from both pinned points through `FlightComponent.steered` with collision.
- Keep the swoop inside the room. Clamp the path's end x to the room's bounds minus the body's
  half width, or end the swoop early at the room edge. Then a bat placed near a wall cannot
  carry itself into the next room (here an arena, where `room_files_test` forbids creatures).
- Check the hornet as well: `FlyerAI` homes with the same straight steer on the same FLOATING
  body. The hornets in `orchard_chasm_bridge` were not seen pinned in this session, but they hover
  in open air.

## Prevention

`ceiling_ai_test` checks the swoop and the steer without collision. A flyer's way home must be
tested against the room it is placed in, from every point a swoop can end.

## Resolution (2026-10-29)

`CeilingAI` flies home back along the swoop it just flew (`_homeward`: the path reversed, then onto the anchor), so it never steers straight at the anchor through a wall; the flyers' bodies also slide along any wall (`wall_min_slide_angle = 0`). `ceiling_ai_test.test_it_flies_home_back_along_its_swoop`; in `core13_bat.json` the bat hangs at its anchor again 2 s after the swoop. A swoop that ends past the room's edge still leaves the room briefly and retraces back.
