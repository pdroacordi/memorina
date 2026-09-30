---
id: bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground
type: bug
title: A roll (or a flinch) into a pool hides Ivo from the water long enough for SafeGroundTracker to record the pool floor as safe ground
status: fixed
severity: high
tags: [water, hazard, respawn, safe-ground, hurtbox, i-frames, monitorable, animation-reset]
related: [gotchas/monitorable-false-hides-an-area-from-every-monitor, gotchas/animationtree-reset-track-overwrites-script-writes, bugs/a-second-fall-during-the-respawn-clear-sinks-forever]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/combat/hazard/hazard_zone.gd
  - scenes/combat/hurtbox/hurtbox.gd
  - scenes/characters/components/safe_ground_tracker.gd
  - scenes/characters/ivo/ivo.tscn
---

## Summary

`HazardZone` detects a body through its Hurtbox's `area_entered`. Ivo's i-frames are
`Hurtbox:monitorable` keys in his clips, and a monitoring area cannot see an area that is
not monitorable. So the water, which is documented to ignore i-frames
(hurtbox.gd:23-26), does not see him while he rolls (`roll` keys `false` for the whole
0.583 s, ivo.tscn:1303) or flinches (`hurt` keys `false` for 0.333 s, ivo.tscn:662).

During that window he falls to the floor of the pool. `SafeGroundTracker` records the
floor as firm ground: he is on the floor, both probes hit Terrain, and the floor is not
`unsafe_ground`. When the clip lets go, the water takes him, and `respawn()` puts him
back on the pool floor.

## Symptom

Found in review of 84ada2e. Reasoned from the code and the clip data, not captured in
the engine.

- Roll off the bank into the Downtown pool. At project gravity he falls well over 100 px
  in 0.58 s, so he reaches the bottom of any painted basin before the roll ends.
- The roll ends and RESET makes the hurtbox monitorable again. The Hazard sees him, he
  sinks, `Game` fades out, and `respawn()` sends him to the last safe position: the pool
  floor.
- On the pool floor he is still inside the Hazard, but a teleport produces no new
  `area_entered`. He now walks underwater with full control, and the tracker keeps
  recording the pool floor as his checkpoint until he climbs out.
- The same happens when an enemy's hit knocks him into a shallow pool (0.333 s hidden).
- The same mechanism makes the water report Ivo twice when it takes him: `hurt` switches
  monitorable off and on again. Only the `_sinking` guard (player.gd:839) absorbs the
  second report. `Character._on_hazard_touched` has no such guard, so an enemy whose
  hurt clip keys monitorable would lose 1 HP on every flinch until it died.

## Root cause

- hazard_zone.gd:13-17 detects through `area_entered` on the hurtbox layer. Whether a
  hurtbox is monitorable is animation-owned state, and it means "cannot be hit", not
  "is not here".
- safe_ground_tracker.gd:33-37 judges ground as firm by the collider underfoot alone. It
  never checks whether the body is standing inside a hazard.

## Fix

Not fixed. Recommended:

1. Detect the BODY, not the hurtbox. Use `body_entered`, with the mask on the Player (256)
   and Enemy (65536) body layers, and call `(body as Character).hurtbox.receive_hazard(self)`.
   The contract with the hurtbox stays the same, and no clip key can hide a body from
   water. This also removes the exit/re-enter caused by the hurt clip.
2. As a second guard, make the tracker refuse any position inside a hazard. Either the
   body pushes an "in hazard" count into it, the same way `enabled` is pushed, or the
   Hazard gets a layer that the tracker can query with `intersect_point` and
   `collide_with_areas`.

## Prevention

Add a test that rolls Ivo into a pool and asserts that `last_safe_position()` is still on
the bank. Review rule: a trigger that means "the body is here" must never detect through
an area that a clip toggles.

## Resolution (2026-09-23)

`HazardZone` detects BODIES (`body_entered`, mask Player 256 + Enemy 65536) and calls `Character.receive_hazard()`; the Hurtbox no longer takes part (it means "can be hit", and i-frames key it). The zone sits on a new `Hazard` physics layer (11, 1024) and `SafeGroundTracker` refuses any spot inside one (`_in_hazard()`), so a pool floor can never be remembered even if something else reaches it.
