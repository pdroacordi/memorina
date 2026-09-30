---
id: architecture/hazard-respawn-on-safe-ground
type: architecture
title: Hazards reach bodies through the Hurtbox, and Ivo is sent back to the last firm ground under a fade the composition root drives
status: active
tags: [hazard, water, respawn, player, combat, hurtbox, camera, fade]
related: [architecture/water-two-projections, architecture/character-controller-input-split, gotchas/sprite-frame-out-of-bounds-on-clip-switch]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/combat/hazard/hazard_zone.gd
  - scenes/combat/hurtbox/hurtbox.gd
  - scenes/characters/character.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/safe_ground_tracker.gd
  - scenes/world/game.gd
  - scenes/world/camera.gd
---

## Context

The user: Ivo must not swim; falling into water costs health (1 HP, user decision) and puts him back
on the most recent land he stood on. There was no respawn of any kind (death has no bench yet).

## Options considered

- **The water volume teleports whatever enters it.** Water would have to know the player, the camera
  and the fade.
- **A method on Player that the water calls by duck typing.** Couples every future hazard to Ivo.
- **First chosen, then replaced: `HazardZone` -> `Hurtbox.receive_hazard()`**, the Hitbox contract.
  The hurtbox means "can be hit", and a roll's i-frames key it unmonitorable: the water could not see
  Ivo and the pool floor became his safe ground (bugs/roll-iframes-hide-the-water-...).
- **Chosen: `HazardZone` detects the BODY and calls `Character.receive_hazard()`** - a typed method
  on the base every body has, so nothing couples to Ivo, and a spike pit later is the same node.

## Decision

- No i-frames hold anyone above water. `Guardian` overrides `receive_hazard` to ignore it (inert health).
- `Character.receive_hazard`: `_wound` (damage and flash), no knockback. `Player` overrides it: hurt, cancel
  attack / Memorina / recall, then (if alive) sink out of control and emit `fell_into_hazard`.
- **The composition root (`Game`) drives the beat** with the existing `Fade`, as it does room
  transitions: hold the sink a beat, fade out, `Player.respawn()`, swap to the room of the new ground
  itself (`_enter_room`) if it differs, `GameCamera.snap()`, fade in. Every fall is its own beat
  (`_hazard_beat`) - control returns while the screen clears, so a second fall mid-clear is normal -
  and fades are awaited on `Fade.faded`, because a killed tween never emits `finished`.
- **`SafeGroundTracker`** (a component, a child of the body so it reads this frame's floor) records the
  position only with firm floor under BOTH foot corners and neither collider in `unsafe_ground`
  (FREEZE's `IceCollider`). The body switches it off while sinking - in the first run it recorded the
  bottom of the pool as firm, and Ivo respawned underwater.

## Consequences

- A fall on the last HP is the ordinary death (a corpse sinking); there is still no bench respawn.
- Enemies take hazard damage but nothing respawns them or steers them away from water yet.
- Ivo's 4-frame hurt clip straight into idle exposed `gotchas/sprite-frame-out-of-bounds-on-clip-switch`
  on him; fixed for Ivo by keying hframes before frame.
