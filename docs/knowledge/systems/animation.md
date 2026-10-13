---
id: systems/animation
type: system
title: Animation: code decides, the AnimationTree renders
status: active
tags: [animation, animation-tree, resolver, driver]
related: [architecture/animation-driver-resolver-pattern, gotchas/animationtree-reset-track-overwrites-script-writes, architecture/ivo-at-2x]
created: 2026-10-02
updated: 2026-10-13
source_files:
  - scenes/characters/animation_resolver.gd
  - scenes/characters/character.gd
  - scenes/characters/ivo/ivo.tscn
  - tools/art/cut_inhabitant.py
  - tools/art/build_ivo_run.py
---

# Animation: code decides, the AnimationTree renders

Moved verbatim from `CLAUDE.md` ("Animation") on 2026-10-02.

**Code decides, the AnimationTree renders.** Each character's `AnimationTree` is a flat set of clips with NO transitions and NO `advance_expression` strings. Two components sit beside it: `AnimationDriver` (generic playback — starts a clip only when the name changes) and an `AnimationResolver` (one concrete subclass per character: `PlayerAnimationResolver`, `BruteShadowAnimationResolver`). Every frame `Character._physics_process` calls `resolve()` on the resolver and hands the result to the driver. `resolve()` is an ordered priority chain; its order is the only tie-break anywhere.

- **The resolver owns the character's entire clip vocabulary** as `const` StringNames at its top, and nothing else names a clip — not the character script, not `Character`. The resolver reads the character's public predicates (`is_rolling()`, `just_hit()`, ...) and the driver; gameplay that needs to know an animation finished asks the resolver in gameplay terms (`is_death_finished()`, `is_spawn_finished()`). Adding an animation is: author the clip, add its node to the tree, add a const and one line at the right priority in the resolver. Never write a clip name as a loose `&"..."` literal — a typo in a const name fails to compile, a typo in a literal silently plays nothing. Never add a transition to a state machine.

- **Intro / one-shot clips** (`jump_start`, `fall_start`, `wall_landing`, `land`, `air_spin`, `hurt`, `spawn`) are held until they finish via `AnimationDriver.holding()` / `sequence()`; the resolver never needs their durations. An event that must restart the *same* clip (a pogo chain, a second hit mid-flinch) calls `AnimationDriver.request_replay()`. Events that arrive from the physics flush (hits, area triggers) land *after* the frame's `_physics_process`, so a pulse for them (`Character.just_hit()`) is cleared after the resolve, not before.
- **`RESET` is the default pose, and the tree owns every property it declares.** Each clip keys only what it changes (hitbox geometry per swing, i-frames); everything else blends back to `RESET`. Consequence: a script write to any property with a `RESET` track (`Hurtbox:monitorable`, `Hitbox:*`) is silently overwritten every frame. Gate the *decision* in script instead (`Character._on_hit_received` ignores hits while dead), or key it in the clip. `BruteShadow` keeps its tree inactive until spawn for exactly this reason.
- **Durations that must equal a clip's length are asserted at startup** in debug builds (`Character._assert_clip_length`): `roll_time + roll_recovery_time` vs the roll clip, every `AttackPhaseData.duration` vs its swing, `LandingStats.hard_land_time` vs `land`, `BruteShadowAttackStats.attack_duration` vs `attack`. Retune either side and the assert says which pair drifted.
- When a component takes over logic that previously emitted a signal from `Player`, `Player` must RE-EMIT that signal, because `ivo.tscn`'s connections are declared with `from="."`. This is why `Player` relays `jumped`, `double_jumped` and `hard_landed`.

## Ivo's sheets (CORE-08, 2026-10-11)

Ivo is drawn at the world's 2x density, 29 art px (58 px) tall, by Codex and PixelLab from our own still; the plan and its revisions are [`architecture/ivo-at-2x`](../architecture/ivo-at-2x.md).

- **One 128x128 frame for every sheet** (`assets/sprites/characters/ivo/ivo_<clip>.png`): the floor line is row 96 and the body sits on the flip axis, column 63.5 (`Sprite2D` is centred), so `Sprite2D.position` stays `(0, -32)` and no clip keys an offset. Wall clips put his front on the capsule's edge (column 75) instead of the centre. The art faces east; `Character` flips it (`flip_h = facing < 0`).
- **No clip's length, step or timing changed.** The attack clips' frame indices, hframes and Hitbox geometry did change. A sheet holds exactly the frames its clips key, chosen from PixelLab's returned frames by the contract's `keep`, settled by `--floor` (feet on row 95) and `--centre` (body on the axis) (`tools/art/prompts/ivo_<clip>.md`; `cut_inhabitant.py --keep`); the contract's `generate:` is the count PixelLab was asked for. The run is cut the same way by `tools/art/build_ivo_run.py`, which keeps its three flight frames off the floor and recolours the jaw's stubble to skin. The two-swing sheets put swing 1 in frames 0-4 and swing 2 in 5-8; jump and fall attacks share `ivo_attack_air`.
- **The body is unchanged:** capsule radius 11, height 54, now centred at x 0 (was -1). Hair is not body, so every authored jump clears the same gaps (`ivo_sheet_test` pins `MapGuide.ivo_reach()`).
- **Attacks are key poses, smears and holds** (`tools/art/build_ivo_attacks.py`), not generated in-betweens; the running attack is its upper body over the run cycle's legs.
- **The Hitbox matches the swing the art shows.** Each attack clip keys the capsule's position and scale to the box its active frames cover; reaches are in `architecture/ivo-at-2x`; enemies and guardians were retuned to them in CORE-09 (`systems/guardians`, "Reach against Ivo's sword"), and `tests/scenes/combat/combat_reach_test.gd` measures the keyed boxes.
- `tests/scenes/characters/ivo/ivo_sheet_test.gd` holds the contract: sheet width = hframes x 128, frame keys below hframes, texture and hframes keyed before frame, clip lengths, feet on row 95 in every grounded frame but the flight frames listed in `FLIGHT` (run 3, 4 and 7, the running attack 3, 4 and 7, 1-3 art px up), every clip's body within 2 art px of the flip axis (attacks measured on the feet or torso without the steel; the running attack on the torso, its legs being the run's), an attack's body moving at most 2 art px between frames, wall clips at the capsule edge instead, no frame touching its border, every colour from `tools/art/sources/ivo/ivo_palette.png`.

The user's decisions, in their words:

- "Redraw at 2x, ~52 px (Recommended)" (2026-10-10).
- The design: "Yes, the taller one (Recommended)" (2026-10-11): 29 art px tall.
- The pipes on his back: "Remove them (Recommended)" (2026-10-11).
- The weapon: "His short sword, drawn to swing (Recommended)" (2026-10-11): the sword stays in its scabbard at his hip and comes out only for attacks.
- The sword's reach: "Shrink to the art" (2026-10-11): every Hitbox shape is resized to the swing the new art shows; enemies and guardians were retuned to it in CORE-09 (2026-10-11).
- The idle pilot: "Yes, do the rest (Recommended)" (2026-10-11).
- PixelLab spend for the clips: "Go ahead (Recommended)" (2026-10-11), up to 30 animate3 calls.
- On the first clips: "I find that some animation that should be improved of Ivo are his pushing and his running. His running seems only like a walk." (2026-10-11): run and brace were redrawn (`architecture/ivo-at-2x` Revision).
- Third round: "The jumping and falling animation could be improved. The attacking animation is weird as well. ... Many things on the game seem to just be flaoting. ivo while running doesn't touch the ground." (2026-10-11); on the attack: "The swing itself", "Too short/weak", "Sliding or popping"; PixelLab: "Approve 15 more (Recommended)". The jump and all attacks were redrawn, and every grounded frame was settled on the floor line (`architecture/ivo-at-2x` Revision).
- Fourth round: "The attack animation still very strange. Not good, not fluid, doesn't even seem like an attack. The running attack is weird too, because the character is moving, but it's legs aren't" (2026-10-11). The attacks are rebuilt from key poses and smear frames, and the running attack runs on the run cycle's legs (`architecture/ivo-at-2x` Revision).
- Fifth round: "The attacks are mostly fine, just need to improve the swish from the standing attack the flowness." (2026-10-11). The standing combo gained a rising smear, a leading and a trailing smear, and an ease back to guard; the running attack, air slash and pogo stayed as they were.
- Sixth round: "the run animation should still be worked on, it does not look natural as of now." (2026-10-12); of a key-pose build and a PixelLab retake the user picked "2: PixelLab" (2026-10-13). After a redrawn head and re-timed bob: "the new running animation changes too much of the Ivo style. The one you presented me before we removed the beard was far better (the pixel lab one)" (2026-10-13), then "Stubble pixels only (Recommended)" for the run and "Revert to before" for the attack faces. The run is the PixelLab take as first presented, its jaw stubble recoloured to skin, with flight frames, and the running attack was rebuilt on its legs (`architecture/ivo-at-2x` Revision).
