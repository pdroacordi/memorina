---
id: bugs/a-press-buffered-into-the-boarding-frame-acts-on-the-helix-stair
type: bug
title: A jump, roll or attack buffered into the frame Ivo boards a helix stair is performed on the stair
status: resolved
severity: medium
tags: [helix, stair, input-buffer, player, jump, roll, attack]
related: [systems/helix-stair, architecture/walkable-helix-stair, bugs/presses-made-while-sinking-fire-on-respawn]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/ivo/player.gd
---

## Summary

The stair refuses jump, roll and attack by dropping every buffer at the top of each step while
riding (player.gd:289-290). On the boarding frame that check has already run (he is not riding
yet). Then `_try_board` boards (player.gd:321), and `_try_jump`, `_try_roll` and `_try_attack`
(player.gd:328-330) still see the buffers. None of them is gated on `_rider.is_riding()`.

## Symptom

Found in review of WORLD-26 (2026-10-11). Reasoned from the code.

- Ivo hops onto the bell floor holding right and presses jump just before he lands in the foot's
  end zone. On the landing frame he boards, then `try_ground_jump(true)` launches him. He rises
  one frame's worth of jump velocity and `jumped` fires (dust, sound). The next step the rider
  sets `velocity = (feet - position) / delta` and pulls him back down. `_jump.is_jumping` stays
  true for the whole climb, because only `apply_gravity` clears it.
- A roll buffered the same way (ROLL unlocked): `try_roll` sets `velocity.x` to the roll speed
  for one frame. Then `is_rolling()` holds `move_axis()` at 0 through the roll and its recovery,
  so the steer latch resets. The ROLL clip plays on the stair, because the resolver checks
  `is_rolling` before `is_riding_stair`.
- An attack buffered the same way starts a swing on the stair, which the contract says is
  refused.

## Root cause

The refusal runs once, before boarding. `_try_board` does not drop the buffers itself, unlike
`_try_door` when it takes an open door (player.gd:592).

## Fix

In `_try_board`, after `_rider.board(...)`, call `_drop_buffers()`. Alternatively, gate
`_try_jump`, `_try_roll` and `_try_attack` on `not _rider.is_riding()`. Test: buffer a jump,
board, step once, then assert `not is_jumping()` and that the body stays on `feet_global(0)`.

## Prevention

A state that refuses actions by dropping buffers must also drop them on the frame it is
entered, not only on the frames when it is already active.

## Resolution

Fixed 2026-10-11 (WORLD-26). `Player._try_board` calls `_drop_buffers()` right after `_rider.board()`, as `_try_door` does on the way out. Test: `player_helix_test.test_a_jump_buffered_into_the_boarding_frame_is_dropped` (fails without the line).
