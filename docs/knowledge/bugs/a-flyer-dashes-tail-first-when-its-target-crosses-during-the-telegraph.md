---
id: bugs/a-flyer-dashes-tail-first-when-its-target-crosses-during-the-telegraph
type: bug
title: A hornet or bat whose target crosses under it during the telegraph dashes or swoops tail-first
status: resolved
severity: low
tags: [core-13, creatures, enemy-ai, facing, flyer-ai, ceiling-ai]
related: [systems/creatures, architecture/corrupted-creatures, bugs/the-brute-swings-away-from-a-target-already-in-reach]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/enemies/enemy_ai.gd
  - scenes/characters/enemies/ai/flyer_ai.gd
  - scenes/characters/enemies/ai/ceiling_ai.gd
---

## Summary

A flyer's facing is locked at TELEGRAPH (`_move_side`) but its direction is locked at ACTIVE
(the hornet's `_aim`, the bat's `SwoopPath`). If the target crosses to the other side while the
telegraph runs, the creature flies one way and faces the other, so it dashes or swoops tail-first.
The hit still lands, so only the read is wrong.

## Details

- `EnemyAI._select_state` (`enemy_ai.gd:134`) sets `_move_side = _side.side` when the move
  starts. `_get_facing_direction` returns `_move_side` while `_clock.is_busy()`
  (`enemy_ai.gd:115`; `flyer_ai.gd:32` does the same).
- `FlyerAI._enter_phase(ACTIVE)` (`flyer_ai.gd:71`) recomputes `_aim = aim_at(position, target)`
  0.5 s later. `CeilingAI._enter_phase(ACTIVE)` (`ceiling_ai.gd:52`) builds the path through the
  target where it is 0.3 s later.
- Failing scenario (hornet): it hovers 128 px east of Ivo and starts its 0.5 s telegraph facing
  west. Ivo rolls under it to its east side. At ACTIVE `_aim` points east, but the sprite and
  `DashHitbox` still face west: it flies east tail-first. The bat does the same when Ivo
  walks or rolls from just ahead of it to just behind it during the drop. Its reach already allows
  a target up to 10 px behind (`x -24..128`, behind the `SideTracker` band).
- Gameplay barely changes: `DashHitbox` is 4 px off centre and `SwoopHitbox` is centred, so the
  box still passes through Ivo.

## Fix

Not applied. Re-take the move's side when the direction is locked: in each style's
`_enter_phase(ACTIVE)`, set `_move_side` to `signf(_aim.x)` (hornet) or
`signf(_path.end().x - _path.start.x)` (bat) when that is non-zero. The facing then turns once,
at the moment the dash starts, and holds until the move ends.

## Prevention

A style that locks a direction later than TELEGRAPH also owns the move's side from that point.
`flyer_ai_test` and `ceiling_ai_test` should cover a target that changes side during the
telegraph and assert that `facing_direction` matches the dash or swoop direction.

## Resolution (2026-10-29)

When the attack starts, `FlyerAI` sets `_move_side` from the dash aim and `CeilingAI` from the swoop's direction, so the sprite and hitbox face where the creature flies. `flyer_ai_test.test_the_dash_faces_where_it_flies` covers a target that crosses during the telegraph; the bat uses the same rule on its swoop path.
