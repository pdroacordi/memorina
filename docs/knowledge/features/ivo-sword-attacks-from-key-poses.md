---
id: features/ivo-sword-attacks-from-key-poses
type: feature
title: Ivo's sword attacks are key poses with drawn smears, and they hit only on the strike and smear frames
status: active
tags: [ivo, combat, attack, animation, art-pipeline, hitbox, smear]
related: [systems/animation, architecture/ivo-at-2x, systems/guardians, systems/art-pipeline, playtests/2026-10-11-ivo-at-2x, playtests/2026-10-11-core09-retune]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - tools/art/build_ivo_attacks.py
  - tools/art/sources/ivo/attack_poses/guard.png
  - assets/sprites/characters/ivo/ivo_attack_ground.png
  - assets/sprites/characters/ivo/ivo_attack_run.png
  - assets/sprites/characters/ivo/ivo_attack_air.png
  - assets/sprites/characters/ivo/ivo_attack_down.png
  - scenes/characters/ivo/ivo.tscn
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/player_animation_resolver.gd
  - tests/scenes/characters/ivo/ivo_sheet_test.gd
  - tests/scenes/combat/combat_reach_test.gd
---

## Summary

Ivo has four sword attacks: a standing two-swing combo (a slash, then an overhead chop), a running two-swing attack whose legs keep the run stride, an air slash, and a downward pogo stab. Each reads as wind-up, strike, smear and follow-through, and the sword hits only on the strike and smear frames, with a box that covers the drawn steel and smear. CORE-08 (fourth and fifth art rounds, `architecture/ivo-at-2x`); contract in `systems/animation` ("Ivo's sheets").

## Details

- **Build.** `python -I tools/art/build_ivo_attacks.py [--preview=<dir>]` writes the four sheets in `assets/sprites/characters/ivo/` from twelve stills in `tools/art/sources/ivo/attack_poses/` (eleven Codex key poses plus `guard.png`). Each pose sits in a 128 px frame with its feet on art row 47 (game row 95) and its body on the flip axis, column 63.5.
- **Smears.** `SMEARS` (`build_ivo_attacks.py:35`) are crescents along the swing's path, pivoted on the pose's shoulder, or a vertical streak for the pogo. Style `plain` erases the blade and paints over the pose; `lead` (thin, bright) and `trail` (the whole sweep fading behind the blade) keep the blade and paint only behind the body.
- **Timing by holds.** `SHEETS` (`:57`) lists one pose per 1/12 s frame, so no clip changed length. Standing combo (`STANDING_1`, `STANDING_2`, `:54`): wind-up, a rising smear, strike with a leading smear, follow-through with a trailing smear, guard (5 frames); then chop wind-up, strike, follow-through, guard (4). Running attack (`SWING_1`, `:49`): 5 + 4 frames over run frames 0-7 then 0. Air slash: 4 frames. Pogo: 6 frames.
- **Running legs.** `on_running_legs` (`build_ivo_attacks.py:145`) keeps the attack pose above the hips over a run frame's legs. In play, `Player.move_axis` (`player.gd:353`) returns 0 only for a standing attack (`CTX_IDLE`, `:360`), so a running attack keeps moving.
- **Hit windows.** `Hitbox:monitoring` is keyed on the strike and smear frames in `ivo.tscn`: 0.1667-0.3333 s on the first standing and first running swing; 0.0833-0.25 s on the second standing swing, the second running swing and the air slash; 0.1667-0.4167 s on the pogo. The `Hitbox/CollisionShape2D` position and scale are keyed to the steel in those frames; reaches are tabled in `architecture/ivo-at-2x` (slash 0..48 px forward, chop 0..40, pogo 22 px below the feet).
- **One hit per window.** Ivo's `Hitbox` sets `strikes_once` (`scenes/combat/hitbox/hitbox.gd`): a hurtbox already struck since monitoring turned on is ignored, so a knockback that carries a target out of the box and back cannot land a second hit (`bugs/one-swing-hits-the-brute-twice-when-its-shove-carries-it-out-and-back`). The running attack's legs are the CORE-10 run's, so its frames 3, 4 and 7 are in flight (`ivo_sheet_test` FLIGHT).
- **Clips.** `PlayerAnimationResolver` owns `ATTACK_IDLE_1` .. `ATTACK_POGO` (`player_animation_resolver.gd:16-22`). Swing 1 is sheet frames 0-4, swing 2 frames 5-8; jump and fall attacks share `ivo_attack_air`.
- **Tests.** `ivo_sheet_test` checks the sheet contract: feet on row 95 except the named flight frames, every clip within 2 art px of the flip axis (attacks measured on feet or torso without the steel), an attack's body moving at most 2 art px between frames (the running attack on its upper body), every colour from `ivo_palette.png`. `combat_reach_test` checks that every enemy and guardian move touches a grounded Ivo and measures his keyed boxes.

## Why

- The PixelLab in-betweens held the sword out for six frames: "The attack animation still very strange. Not good, not fluid, doesn't even seem like an attack. The running attack is weird too, because the character is moving, but it's legs aren't" (user, 2026-10-11).
- The fifth round changed only the standing combo: "The attacks are mostly fine, just need to improve the swish from the standing attack the flowness." (user, 2026-10-11). Ending each swing on the guard pose lets the chop's wind-up start where the slash ends.
- The boxes follow the art: "Shrink to the art" (user, 2026-10-11). Enemies and guardians were retuned to those reaches as data in CORE-09 (`systems/guardians`, "Reach against Ivo's sword").

## Gotchas / pitfalls

- Re-running `build_ivo_attacks.py` overwrites all four sheets; edit the poses or the tables, never the PNGs.
- A clip's length must still equal its `AttackPhaseData.duration`; `Character._assert_clip_length` (`character.gd:155`) fails at startup in debug builds if they drift.
- Moving a sheet sideways means moving every Hitbox key of that clip with it (CORE-08 review, `architecture/ivo-at-2x`, "Flip axis and attack bodies").
- `Hitbox:*` has a `RESET` track: a script write is overwritten every frame. Gate the decision in script or key it in the clip (`systems/animation`).
- Growing or shrinking a box changes every fight tuned in CORE-09; re-run `combat_reach_test` and the CORE-09 timelines.
