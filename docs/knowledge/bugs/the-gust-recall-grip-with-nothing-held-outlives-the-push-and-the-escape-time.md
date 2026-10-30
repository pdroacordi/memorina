---
id: bugs/the-gust-recall-grip-with-nothing-held-outlives-the-push-and-the-escape-time
type: bug
title: After the autumn gust's wall-climb recall, Ivo with nothing held likely never grips the wall, because the gust stops pushing above 96 px and the escape time runs out before he falls back under it
status: resolved
severity: high
tags: [guardians, recall, wall-climb, gust, grd-04, physics]
related: [systems/guardians, systems/air, architecture/grd-04-autumn-and-summer-guardians, bugs/a-recall-forgot-its-source-so-a-directionless-escape-never-went-away, gotchas/a-body-beside-a-wall-is-not-on-it-unless-it-moves-into-it]
created: 2026-10-30
updated: 2026-10-30
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/guardians/guardian_gust.gd
  - resources/characters/guardians/guardian_attack.gd
  - scenes/characters/ivo/abilities/wall_mobility_component.gd
  - scenes/characters/guardians/guardian_gust.gd
  - resources/characters/guardians/autumn_guardian/autumn_gust.tres
  - tests/scenes/characters/ivo/player_recall_test.gd
---

## Summary

Found in review, not reproduced in a run. `systems/guardians` says that after the gust's recall press "he grips with
nothing held". Three numbers in the code work against that:

1. **The push stops above 96 px.** `GuardianGust.push_for` returns zero once Ivo's feet are more than
   `attack_height` above the guardian's feet. `autumn_gust.tres` leaves `attack_height` at its default, 96. Ivo's jump
   is 144 px (`ivo_jump_stats.tres`).
2. **Nothing else moves him into the wall.** The escape axis goes only to `WallMobilityComponent.update`
   (player.gd `_air_physics`). `LocomotionComponent.air_update` still gets `move_axis()`, which is 0. So above 96 px,
   `velocity.x` decays to the carry, which is 0. `move_and_slide` has already removed the into-wall part of the
   velocity on the last contact. With no motion into the wall, `is_on_wall()` is false and `_grip_normal()` returns
   ZERO (see the gotcha).
3. **The escape time starts too early.** A slide starts only when `velocity.y >= 0`, which is at or after the apex
   (about 0.67 s, slower at the top because of `apex_gravity_mult` 0.5). The first frame with both a wall contact and
   a falling body comes when he drops back below 96 px, roughly 0.9 to 1.1 s after the press. But
   `_recall_escape_left` (0.9 s) starts in `_open_recall`, when the window opens, not when the jump is pressed. It is
   counted in game time, and the window runs at `WorldFreeze.slow_scale` 0.2. A press 1 real second into the 2 s window
   has already used 0.2 s of the budget.

## Symptom (expected)

In `orchard_arena`, the gust carries Ivo to the wall, the recall opens, and the jump press unlocks WALL_CLIMB and jumps.
With no direction held he rises, does not catch the wall at the top, and falls back to the floor. There the gust's band
(2.0 to 2.4 s, 32 px high) can hit him. WALL_CLIMB is still saved, so the fight goes on, but the taught move fails the
first time it is used.

## Why the tests pass

`player_recall_test.test_a_wall_cued_recall_opens_at_the_wall_and_grips_it_with_nothing_held` calls
`_ivo.push(Vector2(600, 0))` on every frame at any height, and it presses jump on the frame the window opens. That
models neither the `attack_height` cut-off nor a player's reaction time. The GRD-04 playtest ran with `BOT_GOD=1` and
reports the hang "with the prompt over him", which was before the press. Neither run shows a grip after the press.

## Fix (proposed)

Choose one or combine, then pin it with a test that pushes through `GuardianGust.push_for` (height-gated) and presses
late in the window:

- Start the escape time at the press. Call `_remember_escape(source)` (or restart `_recall_escape_left`) in
  `_on_skill_recalled` as well as in `_open_recall`.
- Let the escape axis drive horizontal motion for the slide. Either feed `_escape_axis()` to `air_update` while
  `_recall_escape_left > 0`, or start the slide from `touches_wall()` in the frame contact happens, not only at the apex.
- Raise `autumn_gust.attack_height` above the jump apex (for example 160), so the push holds him to the wall at the
  top. This also widens who the gust carries.

## Fix (2026-10-30)

Two of the options, together: `GuardianAttack.push_height` (240 px, past the 144 px apex) gates the push instead of
`attack_height`, so the gust holds Ivo to the wall through the whole jump; and `_on_skill_recalled` restarts
`_recall_escape_left`, so the escape counts from the press. `player_recall_test.test_a_wall_cued_recall_opens_at_the_wall_and_grips_it_with_nothing_held`
now pushes only through `GuardianGust.push_for` with `autumn_gust.tres` and presses 50 frames into the window.

## Prevention

A grip that is meant to work "with nothing held" needs something moving the body into the wall in every frame where it
should hold. A test that pushes the body unconditionally hides any gate on the real pusher.
