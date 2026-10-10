---
id: bugs/ivo-stays-live-through-the-out-of-room-hazard-beat
type: bug
title: The out-of-every-room hazard beat leaves Ivo controllable for its 0.75 s, so a door, a bench or F10 can run inside it and the respawn then yanks him away
status: resolved
severity: low
tags: [world-05, rooms, safety-net, hazard, door, bench, race, fade]
related: [bugs/the-safety-net-fires-when-ivo-drops-across-a-seam-above-two-open-tops, gotchas/a-killed-tween-never-emits-finished, systems/life-benches-death]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/game.gd
  - scenes/characters/ivo/player.gd
---

## Summary

A real hazard enters the beat through `Player.receive_hazard`, which sets `_sinking`. That stops input, the
door buffer, sitting and `SafeGroundTracker`, and `DebugTrials` refuses to move a sinking player. The `_lost`
path (game.gd:75-76) calls `_on_player_fell_into_hazard()` directly, so none of that happens. For the sink hold
plus the fade to black (0.25 + 0.5 s), Ivo keeps moving and acting.

## Symptom

Found in review. If Ivo is back in a room before the black (always so in
`bugs/the-safety-net-fires-when-ivo-drops-across-a-seam-above-two-open-tops`), he can:
- **Take a door.** `_on_player_entered_door` starts its own `to_black()`. Both coroutines resume on the
  shared `Fade.faded` signal. The beat resumes first: it teleports Ivo to safe ground, enters that room and
  starts `to_clear()`. Then the door's `_land_in` places him at the door while the screen is already clearing.
  If the contents are not ready, the room pops in visibly.
- **Sit on a bench.** It saves, then the respawn pulls him off the seat.
- **Press F10** (debug). He moves to a trial, then is pulled back.

## Root cause

The beat assumes the body is already held by whoever emitted `fell_into_hazard`. The new caller does not hold
it.

## Fix

Suggested: hold the body through a Player method, e.g. `Player.fall_out_of_world()`. It would set `_sinking`
(or an equivalent hold), disable safe ground and emit `fell_into_hazard`. `Game` would then connect as for any
hazard, and `_lost` could stay purely a Game guard. This also keeps hold logic in `Player`
(one responsibility per script).

## Prevention

A game-level test: trigger the lost path, then press into a door within 0.75 s. No `door_entered` handling
starts until the beat has cleared.

## Resolution (2026-10-10)

`Player.fall_out_of_world()` holds him like a sink (`_sinking`, safe ground off, knockback cleared) and emits `fell_into_hazard`; `Game` calls it instead of starting the beat itself. Playtest (2026-10-10, working tree on 5062946, `--import` at 03:35:59, real save untouched): `..._rv4_v1_void_beat_ignores_input.json`. Wall climb over bloom_hollow's west wall (the world's edge) takes Ivo
out of every room at t 3.15 (-7063, -160).
- **From t 3.15 to 3.75 he is held like a sink.** The velocity is (x decaying -98 → -9, y +40), although left is held
  throughout, and the jump press at t 3.40 does nothing.
- At `fade` 1.0 he is put back on firm ground (-6931.9, 288) at t 3.80, hp 3.
- Input returns during the fade-in: a jump at t 4.0, `fade` 0.51. That matches the water hazard's beat.
- No door is within reach of that spot. The jump press was the input tested during the beat.
