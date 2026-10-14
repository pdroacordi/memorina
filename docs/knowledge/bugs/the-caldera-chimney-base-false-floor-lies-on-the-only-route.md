---
id: bugs/the-caldera-chimney-base-false-floor-lies-on-the-only-route
type: bug
title: caldera_chimney_base's secret is a false floor on the only floor between its two openings, so every player walking through falls in
status: resolved
severity: medium
tags: [world-35, world-21, secret, false-wall, summer-caldera, rooms, level-design, reward-slot]
related: [architecture/secret-false-walls, architecture/reward-slots-reserve-their-place-in-the-room-text, playtests/2026-10-14-world35-step1, systems/rooms, systems/world]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/rooms/summer_caldera/contents/caldera_chimney_base.room
---

## Summary

WORLD-35 step 1 (uncommitted, on a10ba5c) made cols 6-9 of caldera_chimney_base's floor (rows 9-10) a `[secret]`.
That floor is the only way between the room's west opening (the cliff chimney) and its east opening (the long
corridor), and a secret never collides. Walking across the room drops every player into the hollow, so it is a pit
on the route, not a hidden place.

## Symptom

`tools/playtest/scripts/world35_secret_chimney_base.json` (`playtests/2026-10-14-world35-step1`): walking east from
col 2 drops Ivo 2 rows onto the slot at y 1888, and one jump climbs out east. The report says: "A false floor on the
only route east has no collision, so every player falls in at col 6 on the way through."

In a release build the slot draws nothing, so every player crossing between the Caldera and the cliff chimney falls
into an empty cracked pit. That is the "dead end I don't understand" WORLD-35 set out to remove.

## Root cause

The room has no solid mass at body height off the walking line. Rows 1-4 are enclosed, both openings are rows 5-8
over the floor at row 9, and the only other solids are a ceiling block (cols 8-11, rows 1-2), a ceiling pillar
(cols 26-28, rows 1-3), a 1-row bump (cols 20-23, row 8) and a 2-row post (cols 31-32, rows 7-8). The secret was put
in the floor because nothing else could hold a 2-row hollow. WORLD-21's contract ("Not impossible to find, but with
only subtle hints", user, 2026-10-10) assumes a secret is off the path and found by choice.

None of the audits can see this. `room_reach_test` and `room_kit_test` treat a secret as air, so the hollow is one
more dip Ivo jumps out of. `room_files_test` checks only for a hint and a unique id.

## Fix

Fixed 2026-10-14, before commit (orchestrator call, the reviewer's first option). Design 04 section 1's rule for secrets is "Not impossible to find, but with only subtle hints".

- **The floor is solid again** (cols 6-9, rows 9-10).
- **A double-jump nook in the ceiling block.**
  - Cols 5-11 of row 3 are a solid shelf under the block.
  - Cols 8-10, rows 1-2 are the `[secret]` hollow, cracked at 8,2, with col 11 left as its back.
  - A stone `[back]` wall (cols 8-11, rows 0-3) stands behind it, since an enclosed hollow shows rock (WORLD-31).
  - The slot `caldera_chimney_base_niche` moved to 9,2 and stays a CACHE.
- **Reach.** The shelf is 6 rows over the floor, so it takes the double jump.
  - The kit check reaches the slot first with the `both` kit (double jump, then Redoma through the cistern) and with `woods_orchards` (double jump and wall climb through the chimney).
  - All later kits reach it too. No kit without the double jump does.
  - The shelf top is a shelf (6 cells over air). It is anchored by the slot and the secret, so the audit raises nothing.
- **Checks.** `room_reach_test`, `room_kit_test`, `room_files_test` and `backdrop_seams_test` are green. A timeline in each direction across the room walks the floor with no fall (`tools/playtest/scripts/world35_chimney_base_cross.json`). `world35_secret_chimney_base.json` now double-jumps onto the shelf and walks into the hollow (`playtests/2026-10-14-world35-step1`).

## Prevention

- A secret goes behind a face the player has to walk into on purpose. It never goes in a floor or ceiling the route
  crosses.
- A check could catch it: run the union audit with the secret cells solid, and fail when the top of a secret cell is
  part of a surface some way between two anchors needs (a floor or ledge the route stands on).
