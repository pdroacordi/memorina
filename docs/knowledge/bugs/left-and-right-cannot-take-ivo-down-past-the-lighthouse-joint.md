---
id: bugs/left-and-right-cannot-take-ivo-down-past-the-lighthouse-joint
type: bug
title: In the lighthouse, the other side drops Ivo off at the mentor's floor, and walking back to the axis boards the upper flight, so left and right never reach the lower flight
status: resolved
severity: medium
tags: [helix, stair, lighthouse, joint, steering, navigation, stuck, world-26]
related: [systems/helix-stair, architecture/walkable-helix-stair, playtests/2026-10-11-lighthouse-helix, bugs/an-outward-press-at-the-helix-foot-does-not-step-off, architecture/room-reachability-audit]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/components/helix_rider_component.gd
  - scenes/world/interactables/helix_stair/helix_stair.gd
  - scenes/world/rooms/frost_edge/contents/lighthouse_interior.room
---

## Summary

In `lighthouse_interior` (two joined flights, hand 1), left and right alone cannot get Ivo from the mentor's floor
or the attic down to the ground floor. Holding left down the upper flight sets him off on the mentor's floor. From
there, walking right toward the stair boards the upper flight and carries him back up. Only Down, or Down plus
right held while walking into the axis, rides through the joint. The bell tower teaches that left goes all the way
down.

## Symptom

Found in review (2026-10-11), from the code and the passing rider tests. Not run in game.

1. On the upper flight, hold left (the other side; the way down on the bell tower). At u 0,
   `helix_rider_component.gd:104-107` takes `absf(axis.y) < VERTICAL` and calls `_leave`, which returns `OFF_FOOT`
   on the mentor's floor at the axis (x 24320, y 12800). `test_the_other_side_at_a_joined_foot_walks_onto_its_floor`
   pins this.
2. He walks on left into the mentor's room (`_held_at_leave` and `regrab_delay` stop him reboarding the lower head).
3. To go on down he walks right toward the stair. When he comes within `board_reach` (6 px) of x 24320, the sensor
   overlaps both end zones: the lower flight's `Head` (onto -1) and the upper flight's `Foot` (onto +1).
   `end_pressed_into` (`helix_rider_component.gd:42-57`) gets direction +1 for right, which matches the `Foot`. He
   boards the upper flight and climbs.
4. If he turns back with left, he rides down to step 1 again. Left and right loop him between the mentor's floor and
   the upper flight.

The lower head boards only on Down, or on left from the right half of the mentor's floor (x > 24326). Nothing ever
leaves Ivo on the right half:
- On the lower flight, the hand side at the head rides on up (`helix_rider_component.gd:92-95`), so `OFF_HEAD` never
  fires there.
- The upper foot lets him off on the left only.

So he reaches the right half only by jumping over the axis, or by reversing within 0.3 s of a left dismount.

## Root cause

The decision in `systems/helix-stair` ("the mentor's room entered by the other side at the joint; the builder's
call, not asked of the user") makes a joined foot behave like a floor for the other side and like a stair for Down.
On an unjoined stair, the other side and Down are the same command. At the joint they become two different
commands, and nothing on screen tells the player.

Two other rules make it worse:
- Walking across an end on a floor boards the end that matches the held side.
- Both ends share one x.

Together they mean that walking from the mentor's room toward the stair always picks the flight that goes up.

The reach audit does not catch it. `HelixStair.reach_ends` gives the lower head the hand-side cell (10, 24), and the
audit lets him walk along the mentor's floor from (9, 24) to (10, 24). In the game, crossing the axis on that floor
boards a stair.

## Fix

Options considered before the user's choice:
- At a joined foot, the other side rides on down when the press was held from above (`_held_at_leave`-style). Only
  a fresh press at u 0, after a stop, walks off onto the mentor's floor.
- Or the joint's two ends board only on Up or Down, never on a horizontal walk. Left and right then cross the
  mentor's floor freely, and the other side at the upper foot can ride on down like Down. The mentor's floor is
  then left by a fresh press at u 0.
- Mirroring the hand does not help: the trap only changes side.

Whichever is chosen, add a rider test that goes from the upper head to the lowest foot on horizontal input only, and
a timeline that goes from the mentor's room back to the door.

## Prevention

- When a gesture means one thing on a single stair, check whether the joint changes its meaning. Test every
  end-to-end route on horizontal input alone, as well as with Up and Down.
- The reach audit treats a floor across a helix axis as walkable. It cannot see an end that boards whoever walks
  through it.

## Resolution (2026-10-11)

The user chose "Walk left into it" (2026-10-11): "Make the mentor floor's stair end mirror the bell tower: walking left into the stair from the right side goes down, so left/right alone can do everything (the right half of the floor becomes reachable)."

- `HelixRiderComponent.update`: at a head with a stair above, only Up rides on; the hand side walks off onto the floor's hand side (`OFF_HEAD`), as at any head. The upper foot is unchanged: Down rides on down, the other side walks off onto the other side.
- Walking left into the axis from the right half boards the lower flight going down; walking right in from the mentor's room (left half) boards the upper flight going up. Up and Down at the axis climb and descend.
- The reach audit's lower-head edge (the hand-side cell (10, 24)) is now where the game lets Ivo off.
- Tests: `helix_rider_component_test` (the hand side walks off a joined head; walking left in from the hand side boards the flight below; walking right in from the other side boards the flight above; left and right alone go up to the joint and back down to the lowest foot; Up and Down ride through). Timeline `tools/playtest/scripts/lighthouse_helix_climb.json` takes every route, re-run in game (`playtests/2026-10-11-lighthouse-helix`).
- Left and right alone still cannot cross from the mentor's room to the right half: that needs Up or Down at the axis, or the upper flight's head. The user's option accepts it: each half is a bell tower end.
