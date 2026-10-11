---
id: bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn
type: bug
title: Down or the other side at the helix head runs Ivo in place on the one-way gallery while the tower turns, then drops him about 290 px in one frame
status: resolved
severity: high
tags: [helix, stair, one-way, gallery, physics, camera, player]
related: [systems/helix-stair, architecture/walkable-helix-stair, gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it, playtests/2026-10-11-bell-tower-helix]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/components/helix_rider_component.gd
  - scenes/world/interactables/helix_stair/helix_stair.gd
  - scenes/world/rooms/home_village/contents/village_bell_tower.room
  - tests/scenes/characters/components/helix_rider_component_test.gd
  - tools/playtest/scripts/bell_tower_helix_climb.json
---

## Summary

Every descent of the bell tower stair from its head sticks for about 2.8 s and then drops a turn at once. The rider moves `_u` down whether or not the body follows. The body stands on the one-way gallery planks, and a body standing on a one-way cannot move down into it.

## Symptom

Found in review of WORLD-26 (2026-10-11) and reproduced in the windowed game (logs every 0.1 s). Timeline: Up at the square's bell tower door; right held into the foot (boards at t 4.2); Up held to the head (Up holds there, feet y 12320, `floor=true`); Down from t 16.6.

- t 16.65 to 19.36: `pos=(9920,12320) floor=true state=run`. Ivo runs in place on top of the gallery. The tower turns under him and the tread he should stand on moves away (screenshot: he runs on the planks with nothing below).
- t 19.46: `pos=(9920,12614.9) vel=(0,17700)`. He drops 295 px in one physics step, and the camera, which follows the feet, drops with him.
- After that the descent is normal, 10 px a riser.

The committed timeline `bell_tower_helix_climb.json` (left at the head) hits the same thing. Its own log at t 17.61 reads `pos=(9920.0,12319.9) floor=true state=run`, a second after it pressed left. `playtests/2026-10-11-bell-tower-helix` reports "boards the head and descends" because its still `a06_descending` (t 20.0) was taken after the drop.

## Root cause

- `HelixRiderComponent.update` (helix_rider_component.gd:87-93) moves `_u` down at ω and writes `velocity = (stand_global(_u) - position) / delta`. It never checks whether the body reached the last target.
- At the head the feet rest on the gallery (`-`, one-way, row 10, top y 320). The first descending step targets tread 111 at y 325, 5 px into the plank. `move_and_slide` treats the 5 px down as motion into a one-way the body is touching, so the floor stops it (`gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it`). Every later target is deeper and is blocked the same way, until the sweep of a step about 290 px long gets past the plank.
- Rising works for the opposite reason: from below, the body is already inside the plank, deeper than the one-way margin, so the plank ignores it both ways.
- `HelixStair.check` (helix_stair.gd:53-58) and the contract ("the capsule along the column meets no solid cell (one-ways pass)") count one-ways as passable both ways. That holds only upward.

## Fix

Fixed 2026-10-11 in WORLD-26, in `HelixRiderComponent`:

- `_step_to(point, delta)` sends the body to every stand target. If the target is more than `MISS` (1 px) below the body and the body is on the floor, it calls `Character.teleport_body` onto the target first. On the first descending step from the head, that moves the feet 5 px into the plank, onto tread 111. From inside the plank he passes through it, as he does on the way up. `check()` keeps solids out of the column, so a floor under the body in the column can only be a one-way.
- At the top of `update`: if the body ended the last step more than `MISS` from its target, `_u` does not advance; the body is sent to that target again. The tower can no longer turn away from the body. `board` and `release` clear the target.

Tests:
- `helix_rider_component_test.test_down_at_the_head_descends_through_the_gallery_tread_by_tread` uses a real one-way plank. It boards at the head with Down and rides 240 frames. Every frame the feet are on `stand_global(u)` ±0.5 px and move down at most one riser. With the teleport disabled, the guard holds `u` and the test fails 242 times.
- `test_a_body_short_of_its_step_holds_the_progress` covers the guard.

The windowed `bell_tower_helix_climb.json` now traces every physics frame of the descent. Left at the head boards at 17.14 s, the feet step 5 px into the plank, and the descent takes 659 frames to the foot (28.10 s). The largest step down is 10.0 px, and `u` is never held (`playtests/2026-10-11-bell-tower-helix`).

## Prevention

- The rider owns `_u` and the body owns its position. Any system that drives a body by velocity toward a computed target must check that the body arrived, or the two diverge without a sound.
- `check` should say "one-ways pass upward"; a one-way in the column needs a stated plan for coming down through it.
- A playtest claim of movement needs a logged position after the input, not only a still taken seconds later.
