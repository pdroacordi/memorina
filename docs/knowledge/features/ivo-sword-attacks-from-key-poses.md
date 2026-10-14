---
id: features/ivo-sword-attacks-from-key-poses
type: feature
title: Ivo's sword attacks are key poses with drawn smears, and they hit only on the strike and smear frames
status: active
tags: [ivo, combat, attack, animation, art-pipeline, hitbox, smear]
related: [systems/animation, architecture/ivo-at-2x, systems/guardians, systems/art-pipeline, playtests/2026-10-11-ivo-at-2x, playtests/2026-10-11-core09-retune, playtests/2026-10-14-core11-sword-reach]
created: 2026-10-13
updated: 2026-10-14
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
- **Smears.** `SMEARS` (`build_ivo_attacks.py:37`) are crescents along the swing's path, pivoted on the pose's shoulder, or a vertical streak for the pogo. Style `plain` erases the blade and paints over the pose; `lead` (thin, bright) and `trail` (the whole sweep fading behind the blade) keep the blade and paint only behind the body. An arc never passes below the floor row (art row 47).
- **Reach (CORE-11).** Each hit-window arc has a `reach`: in front of its pivot the crescent is an ellipse that many times as wide, so it ends 12 px further forward at the same height and keeps its inner edge at the hand. `slash_lead` 1.6, `slash_trail` 1.33, `chop_lead` 1.36, `chop_trail` 1.39, `slash` (running) 1.5, `chop` (running) 1.36, `air` 1.32. The pogo streak is 19 art px long (was 16) and 5.2 thick (was 5, so its widest row stays 6 art px). `slash_rise` (frame 1, outside the window) is unchanged.
- **Timing by holds.** `SHEETS` (`:65`) lists one pose per 1/12 s frame, so no clip changed length. Standing combo (`STANDING_1`, `STANDING_2`, `:62`): wind-up, a rising smear, strike with a leading smear, follow-through with a trailing smear, guard (5 frames); then chop wind-up, strike, follow-through, guard (4). Running attack (`SWING_1`, `:57`): 5 + 4 frames over run frames 0-7 then 0. Air slash: 4 frames. Pogo: 6 frames.
- **Running legs.** `on_running_legs` (`build_ivo_attacks.py:159`) keeps the attack pose above the hips over a run frame's legs. In play, `Player.move_axis` (`player.gd:353`) returns 0 only for a standing attack (`CTX_IDLE`, `:360`), so a running attack keeps moving.
- **Hit windows.** `Hitbox:monitoring` is keyed on the strike and smear frames in `ivo.tscn`: 0.1667-0.3333 s on the first standing and first running swing; 0.0833-0.25 s on the second standing swing, the second running swing and the air slash; 0.1667-0.4167 s on the pogo. The `Hitbox/CollisionShape2D` position and scale are keyed, once per clip, to the box the steel of those frames covers: from x 0 to the steel's front and as high as the steel in front of x 0; the pogo as wide as its steel, from the feet down to its point. Body px, x forward, y up negative (capsule radius 11.672157, height 82):

| Clip | Hit frames | CORE-08/10 box | CORE-11 box | Forward reach | Brute / Bloom / Frost, centre to centre |
|---|---|---|---|---|---|
| attack_idle_1 (slash) | 2-3 | 0..48, -66..-14 | 0..60, -66..-14 | 48 -> 60 (+12) | 67 -> 78.5 / 84-98 -> 95.5-109.5 / 82 -> 93.5 |
| attack_idle_2 (chop) | 6-7 | 0..40, -62..0 | 0..52, -62..0 | 40 -> 52 (+12) | 59 -> 70.5 / 76-90 -> 87.5-101.5 / 74 -> 85.5 |
| attack_run_1 | 2-3 | 0..40, -76..-38 | 0..52, -76..-38 | 40 -> 52 (+12) | 53 -> 65 / 76-90 -> 87.5-101.5 / 74 -> 85.5 |
| attack_run_2 | 6-7 | 2..40, -66..-14 | 0..52, -66..-14 | 40 -> 52 (+12) | 58.5 -> 70.5 / 75.5-89.5 -> 87.5-101.5 / 73.5 -> 85.5 |
| attack_jump, attack_fall | 1-2 | 0..38, -60..-24 | 0..50, -60..-24 | 38 -> 50 (+12) | 56.5 -> 68.5 / 73.5-87.5 -> 85.5-99.5 / 71.5 -> 83.5 |
| attack_pogo | 2-4 | -10..8, 0..22 | -10..8, 0..28 | 22 -> 28 below the feet (+6, +27%) | - |

  The +12 px is 25% of the slash and 30-32% of the shorter swings. The Bloom pair is its near and far side (its hurtbox sits 7 px off centre). One box covers the whole window, so on a strike frame whose smear comes a frame later the box leads the drawn blade: running swing 1 frame 2 (blade to 40, box 52), running swing 2 frame 6 (blade to 28), the air slash frame 1 (38), the standing slash frame 3 (trail to 52, box 60), the pogo frames 2 and 4 (blade 10 below the feet, box 28). Both points, the +12 px with enemy spacing retuned by the same ratio and one box per window leading the bare blade on a strike frame, went to the user, who decided (2026-10-14): "keep +12 px and the hitbox as is".
- **One hit per window.** Ivo's `Hitbox` sets `strikes_once` (`scenes/combat/hitbox/hitbox.gd`): a hurtbox already struck since monitoring turned on is ignored, so a knockback that carries a target out of the box and back cannot land a second hit (`bugs/one-swing-hits-the-brute-twice-when-its-shove-carries-it-out-and-back`). The running attack's legs are the CORE-10 run's, so its frames 3, 4 and 7 are in flight (`ivo_sheet_test` FLIGHT).
- **Clips.** `PlayerAnimationResolver` owns `ATTACK_IDLE_1` .. `ATTACK_POGO` (`player_animation_resolver.gd:16-22`). Swing 1 is sheet frames 0-4, swing 2 frames 5-8; jump and fall attacks share `ivo_attack_air`.
- **Tests.** `ivo_sheet_test` checks the sheet contract: feet on row 95 except the named flight frames, every clip within 2 art px of the flip axis (attacks measured on feet or torso without the steel), an attack's body moving at most 2 art px between frames (the running attack on its upper body), every colour from `ivo_palette.png`, and `test_every_swing_reaches_exactly_as_far_as_its_drawn_steel`: each sword clip's keyed box equals, within 1 px, the box its hit-window frames' steel asks for, so a rebuilt sheet or a moved key fails the suite until the other follows. `combat_reach_test` checks that every enemy and guardian move touches a grounded Ivo, that the standing combo lands both swings on a parked brute, and that each guardian's comfort point is outside Ivo's longest swing and its `give_ground_distance` lies between its contact reach and its main move's range.

## Why

- The PixelLab in-betweens held the sword out for six frames: "The attack animation still very strange. Not good, not fluid, doesn't even seem like an attack. The running attack is weird too, because the character is moving, but it's legs aren't" (user, 2026-10-11).
- The fifth round changed only the standing combo: "The attacks are mostly fine, just need to improve the swish from the standing attack the flowness." (user, 2026-10-11). Ending each swing on the guard pose lets the chop's wind-up start where the slash ends.
- The boxes follow the art: "Shrink to the art" (user, 2026-10-11). Enemies and guardians were retuned to those reaches as data in CORE-09 (`systems/guardians`, "Reach against Ivo's sword").
- The reach grew in CORE-11: "can we make the attack range a bit bigger? Altering a bit the sprite" (user, 2026-10-14), then "About +25% (Recommended)": "The swing's smear and blade arc drawn about 12-14 px longer, and the hitbox follows the drawn steel. Enemy and guardian spacing retuned so fights stay fair (the earlier tuning matched Ivo's drawn reach)." Only the smears changed, because the user had rejected a redraw that changed his style ("the new running animation changes too much of the Ivo style", 2026-10-13). The smears widen forward, not outward in every direction: a radial growth (tried first) raised the running slash's crescent from y -76 to -92, a moon over his head; the ellipse keeps every box's height. `playtests/2026-10-14-core11-sword-reach`.

## Gotchas / pitfalls

- Re-running `build_ivo_attacks.py` overwrites all four sheets; edit the poses or the tables, never the PNGs.
- A clip's length must still equal its `AttackPhaseData.duration`; `Character._assert_clip_length` (`character.gd:155`) fails at startup in debug builds if they drift.
- Moving a sheet sideways means moving every Hitbox key of that clip with it (CORE-08 review, `architecture/ivo-at-2x`, "Flip axis and attack bodies").
- `Hitbox:*` has a `RESET` track: a script write is overwritten every frame. Gate the decision in script or key it in the clip (`systems/animation`).
- Growing or shrinking a box changes every fight tuned in CORE-09 and CORE-11; re-run `combat_reach_test` and the CORE-09 timelines, and retune the brute's `stop_distance` and the guardians' `comfort_distance`; `give_ground_distance` stays under each guardian's main move's range (`systems/guardians`).
- A smear may not reach column 63 or row 63 of its art frame (`test_no_frame_touches_its_border`): the standing slash at 60 px forward has 2 px left, the pogo at 28 px below the feet 2 px. More reach needs a wider frame, and then the body must stay centred on the flip axis and every Hitbox key move with it.
