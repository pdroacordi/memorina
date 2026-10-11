---
id: bugs/the-cistern-stairwell-shows-through-the-closed-secret-wall
type: bug
title: The caldera cistern's stairwell art shows below and beside its secret chamber before the chamber is found
status: resolved
severity: medium
tags: [doors, door-look, stairwell, secret, rooms, caldera-cistern, world-24, world-21]
related: [systems/rooms, architecture/secret-false-walls, architecture/doors-and-interiors, bugs/well-water-stands-in-the-air-at-a-passage-mouth]
created: 2026-10-10
updated: 2026-10-11
source_files:
  - scenes/world/interactables/door/door.gd
  - scenes/world/rooms/summer_caldera/contents/caldera_cistern.room
  - assets/sprites/world/props/door/door_stairwell.png
  - scenes/world/rooms/maps/room_map_node.gd
---

## Summary

WORLD-24 gave the caldera cistern's chamber door the `stairwell` look. Its art is 120x88 px, opaque to every edge, and
sinks 67 px below the floor. The chamber (cols 8-11, rows 9-10) is a `[secret]`, and the closed wall covers only those
cells. Before the player finds the secret, the stairwell's steps and kerbs show inside the solid floor under it, which
gives the hidden chamber away.

## Symptom

Seen in the running game (review, 2026-10-10; timelines `rv_cis_hidden` and `rv_cis_found` in the review
scratchpad):
- Ivo stands outside the chamber at (1100, 640), so the secret is still closed. The closed wall draws the chamber as
  stone. Under it, a dark stair opening with railings and a post draws over rows 11-13 (world y ~736-803, x ~852-972).
  That area is solid stone in the map.
- After the secret opens, the art's left 12 px still hang past the west wall (col 7) into the left pool's col 6
  (local x 212-224). They show as a pale column under the water.

## Root cause

- `Door._dress` (`door.gd:90-95`) sets `_sprite.position.y = SINKS["stairwell"] - height / 2`, so the 88 px frame
  spans 21 px above the floor and 67 px below it (`door.gd:22`). It is 120 px wide, centred on the door cell.
- The door is at col 8 (`caldera_cistern.room:91`), centre x 272. The art therefore covers x 212-332 and floor-21 to
  floor+67: cols 6.6-10.4 and rows 10.3-13.1.
- The closed secret draws its world twin at `SECRET_Z` 40 (`room_map_node.gd:14`, `:147`), but only over the
  `[secret]` cells (rows 9-10, cols 8-11, `caldera_cistern.room:74-75`). It covers the art's 21 px above the floor and
  nothing else.
- Entities are added after the ground layers (`room_map_node.gd:89`), so the parts below the floor and over col 7
  draw on top of the solid stone tiles.

The door moved from col 9 to col 8 so the art would not cross the flooded passage at col 11. That only moved the
overhang onto the west wall and pool.

## Fix

Not fixed (review only). Possible fixes:
- Hide a door whose cell lies in a closed secret group until `found_secrets` holds that group. `SecretWall` knows
  when the group opens.
- Or clip or redraw the stairwell art so nothing below the floor line shows outside the chamber, and give the
  chamber a stairwell no wider than its 4 cells (the frame is 120 px; the chamber is 128 px with walls on both
  sides).
- Either way, keep the art off col 6 and col 7.

## Prevention

- Nothing checks that a door's art stays inside its own surroundings. `facade_doors_test` checks only the look's
  name and whether a facade is present.
- A test could require, for every door whose cell is in a `[secret]` group, that the look's art rect (from
  `Door.LOOKS`/`SINKS`) lies inside that group's cells plus the floor row. Not added.
- The art was approved in the running game with the chamber already open. Board shots of a secret's contents
  should include the closed state.

## Resolution (2026-10-11)

A door inside a `[secret]` now hides its art until that secret is found: `RoomMapNode._build` passes the door the `SecretWall` of its cell's group (`Door.hide_until`), and the door shows its sprite on the wall's `found` (or at once if `SaveSystem` already remembers it). The stairwell art was trimmed to 96 px (`--keep-x=19:67`) so it sits over cols 7-9 and no longer hangs into the col 6 pool. Test: `room_map_node_test.test_a_door_inside_a_closed_secret_is_hidden`.
