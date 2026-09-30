---
id: bugs/temporary-song-floors-are-remembered-as-safe-ground
type: bug
title: The bell jar's shell, a root bridge and other floors that go away are recorded as safe ground, so a fall respawns Ivo in mid-air
status: fixed
severity: high
tags: [safe-ground, respawn, hazard, redoma, enraizar, frost-shell, roots, moving-platforms, soltar]
related: [architecture/hazard-respawn-on-safe-ground, bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground, bugs/water-that-returns-leaves-its-dry-floor-as-safe-ground, architecture/the-bell-jar-closes-once, architecture/roots-join-earth-to-earth]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/characters/components/safe_ground_tracker.gd
  - scenes/world/memory/song_effects/shell/frost_shell.gd
  - scenes/world/memory/song_effects/roots/root_span_view.gd
  - scenes/world/interactables/freezable_water/ice_collider.gd
  - scenes/world/interactables/floater/floater.gd
  - scenes/world/interactables/drawbridge/drawbridge.gd
  - scenes/world/interactables/hanging_load/hanging_load.gd
---

## Summary

`SafeGroundTracker` refuses only colliders in the `unsafe_ground` group, and only
`IceCollider` joins it. The floors the song phases added also go away, but none of
them joins the group: the Redoma shell's ring, a root bridge's one-way floor, and the
moving planks and loads. If Ivo stood on one and then falls into water, he is
respawned where that floor used to be.

## Symptom

Found in review, not reproduced in engine. The mechanism is certain from the code.

- Ivo climbs onto a closed Redoma shell over the well ("whoever left can stand on it").
  The tracker records the top of the ring. The shell shrinks away and he drops into the
  well. `respawn()` puts him back at the recorded spot, which is now empty air above
  the water. He falls back in, and the teleport out and the fall back in fire a fresh
  `body_entered` on the hazard. So he sinks and is respawned at the same spot again,
  losing 1 HP per loop until he dies.
- A root bridge over water does the same thing once its strands wither.
- `Drawbridge` (hauled back up), `HangingLoad` (returns to its rope) and `Floater` or
  `Mechanism` (the floor has moved since) can all leave the recorded spot in the air or
  under the waterline.

## Root cause

- `safe_ground_tracker.gd:41-44`: firm ground means any collider hit on
  `_body.collision_mask` (layers 1, 2 and 4) unless it is in `UNSAFE`.
- `ice_collider.gd:21` is the only `add_to_group(SafeGroundTracker.UNSAFE)`.
- `frost_shell.gd:38` creates the ring's `StaticBody2D` on layer 4, which Ivo collides
  with. `root_span_view.gd:29` creates the bridge's `StaticBody2D` on the default layer
  1. Neither joins the group. Floater, HangingLoad and the Drawbridge/Seesaw/Mechanism
  planks are on Props (layer 2) or Terrain.

## Fix

Open. Add `add_to_group(SafeGroundTracker.UNSAFE)` to the shell's collider and the root
bridge's floor. For moving floors (Floater, Mechanism, Seesaw plank, Drawbridge plank,
HangingLoad), join the group as well. A spot on something that moves is not a spot to
come back to.

## Prevention

A new temporary or moving collider that Ivo can stand on has to answer "will it be
there on the way back?". Consider making the group opt-in the other way round: firm
ground means Terrain from a `RoomMapNode`, and everything else is unsafe by default.

## Resolution (2026-09-30)

Fixed: the Redoma collider, the root bridge floor, Floater, HangingLoad, Mechanism and the Drawbridge and Seesaw planks all join `SafeGroundTracker.UNSAFE`.
