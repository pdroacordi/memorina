---
id: bugs/the-farmhouse-props-node-has-no-z-index
type: bug
title: threshold_farmhouse's Props node has no z_index -10, so its props draw at z 0 with the ground and the entities
status: fixed
severity: low
tags: [props, interiors, z-index, draw-order, farmhouse, story-02]
related: [systems/props, systems/pickups, systems/rooms]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/rooms/threshold/contents/threshold_farmhouse_contents.tscn
  - tests/scenes/world/environment/props/prop_scenes_test.gd
---

## Summary

FIXED 2026-10-15 (STORY-02 review, before commit). The farmhouse contents add a `Props` Node2D with no `z_index`. Every other `Props` node under `scenes/world/rooms/*/contents/` sets `z_index = -10`, and `systems/props` (Placement) fixes the order: backdrop -30, `[back]` walls -20, props -10, ground and entities 0, water 50.

## Symptom

None visible today. The meal table, chair, stool, broom, basket, bucket, shelf and window draw at z 0. The sword `ItemPickup` and the door still draw in front of them, but only because `RoomMap` comes after `Props` in the tree, not because of z. `systems/pickups` says the item draws "in front of the contents' Props (z -10)". That is false in the one room that holds a pickup.

The break shows once something at z 0 outside this `Contents` draws before it in the tree, or once a prop is moved after `RoomMap`. A prop would then cover an entity or the ground.

## Root cause

`threshold_farmhouse_contents.tscn`, the line `[node name="Props" type="Node2D" parent="."]` with no `z_index = -10`. The scene is written by hand, and no test checks the `Props` z.

## Fix

Fixed 2026-10-15. `threshold_farmhouse_contents.tscn`'s `Props` has `z_index = -10` (the orchestrator, with the art). `prop_scenes_test.test_every_rooms_props_node_draws_at_minus_ten` reads every `scenes/world/rooms/*/contents/*_contents.tscn` from its `SceneState` and fails on a `Props` node whose z is not -10 (a missing line reads as 0).

## Prevention

Add a case to `prop_scenes_test`: every `Props` child of a contents scene under `scenes/world/rooms` has `z_index == -10`. Today a hand-written contents scene can leave it out without failing any check.
