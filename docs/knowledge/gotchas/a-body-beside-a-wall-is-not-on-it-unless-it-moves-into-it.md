---
id: gotchas/a-body-beside-a-wall-is-not-on-it-unless-it-moves-into-it
type: gotcha
title: A CharacterBody2D beside a wall reports is_on_wall() only in a step whose motion pushes into the wall, and move_and_slide removes that part of the velocity on contact
status: active
tags: [physics, characterbody2d, move-and-slide, wall, wall-slide]
related: [bugs/the-gust-recall-grip-with-nothing-held-outlives-the-push-and-the-escape-time, systems/guardians]
created: 2026-10-30
updated: 2026-10-30
source_files:
  - scenes/characters/ivo/abilities/wall_mobility_component.gd
---

## Summary

`move_and_slide()` changes `velocity` when it slides along a collision: the part pointing into a wall is removed. On
the next step, if nothing (input, air carry, knockback) puts horizontal speed back toward the wall, the body moves
only vertically. That step has no wall collision, so `is_on_wall()` is false and `get_slide_collision_count()` lists
no wall, even though the body is still touching it.

## Consequence here

`WallMobilityComponent._grip_normal()`, and so `touches_wall()` and the wall slide, depend on that collision. A grip
"with nothing held" holds only while some velocity pushes Ivo into the wall every frame. Feeding a direction only to
the slide's `axis` is not enough, because `axis` decides whether to grip and does not move the body. In Ivo's case the
push comes from `LocomotionComponent.air_update` steering toward the move axis plus the carry.

## Prevention

Before relying on wall contact, find out what moves the body into the wall in every frame the contact should last.
When a test fakes that push (for example `push()` on every frame), make it as gated as the real pusher.
