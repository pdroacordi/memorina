---
id: gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it
type: gotcha
title: A CharacterBody2D standing on a one-way shape cannot be moved down into it by velocity; a body already inside it passes both ways
status: active
tags: [physics, one-way, characterbody2d, move-and-slide, tilemap, collision]
related: [bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn, systems/rooms, systems/helix-stair]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/maps/ground_collision.gd
  - scenes/characters/components/helix_rider_component.gd
---

## Summary

A one-way collision shape (our `-` ledges, `GroundCollision` alternative `ONE_WAY`, a full 32 px square) blocks downward motion of a body that rests on its top, however large the velocity, until one sweep is long enough to get past it. A body that is already inside the shape, deeper than the one-way margin, is ignored by it in both directions.

## Details

- Measured in the bell tower (Godot 4.7.2, 2026-10-11). With Ivo standing on the gallery planks at y 320, a velocity 5 to about 280 px per step downward left him at y 320 with `is_on_floor()` true for 2.8 s. A step of about 290 px passed through in one frame (`bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn`).
- Rising through the same plank from below works, and so does stopping with the feet 5-30 px inside it and then moving down again. At the start of each step the body overlaps the one-way, and Godot's motion test skips a one-way shape the body already overlaps. Recovery pushes a body out of a one-way only when the overlap is within the margin.
- So "one-ways pass" holds upward or from inside, not from on top. A mode that moves a body down through a ledge by velocity (a stair, a lift, a scripted drop) must first put the body inside the shape with a transform write (`Character.teleport_body`), or turn the collision off for that body.

## Gotchas / pitfalls

- A test that drives the body without physics (setting velocity and reading it back) cannot catch this. Only a real `move_and_slide` against the room's `Solid` layer shows it.
- A large enough step does pass through, so the failure looks like a stall followed by a fall, not a permanent block.
