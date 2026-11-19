---
id: bugs/the-leaf-dive-aims-at-ivos-airborne-feet-and-ends-in-the-air
type: bug
title: DiveMotion lands at Ivo's feet y as they were at the strike's start, so a dive thrown at a jumping Ivo ends in mid-air and drops on the spot late, after its shadow is gone
status: resolved
severity: medium
tags: [guardians, autumn, leaf, grd-15, dive, motion, overhead-pick, shadow]
related: [systems/guardians, architecture/grd-12-guardian-fight-engine, bugs/a-guardian-motion-left-undriven-mid-strike-keeps-gravity-off-and-the-world-passed-through]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - resources/characters/guardians/motion/dive_motion.gd
  - scenes/characters/guardians/guardian.gd
  - resources/characters/guardians/autumn_guardian/autumn_dive.tres
  - tests/resources/characters/guardians/autumn_guardian/autumn_guardian_kit_test.gd
---

## Summary

`DiveMotion.plan` sets the landing offset to `ctx.target.y - ctx.feet.y`. `ctx.target` is Ivo's feet at the strike's
start (`guardian.gd:517`), so an airborne Ivo gives a landing in the air. The Leaf's dive (reach up 96, first in the
array) is the overhead pick for a jump from stage 1 on. Its 0.45 s wind-up starts while Ivo rises, so the strike usually
begins with Ivo near the apex of his jump.

## Symptom

Found in the GRD-15 review by reading the code. Traced single jump (`autumn_guardian_kit_test.JUMP`): Ivo passes 28 px
about 0.07 s after take-off. If the cooldown has run out, the dive winds up at once and its strike starts at about
0.52 s, with his feet about 133 px up.

- The path rises 100 px, then drifts 80 % of the way across, then "dives" 33 px upward. At 1.0 s it ends with the feet
  133 px over the floor and the body top at the room's top edge.
- The landing box (`attack_7`, 0.85-1.2 s) opens in the air where Ivo was.
- When the path ends, gravity takes over and the body falls about 133 px. At 980 px/s² that is about 0.52 s, so it lands
  about 1.5 s into the strike. The shadow is gone by then (`warn` 1.0 + `fade` 0.15).
- The body hurts on touch during the recovery (`body_contact` true). An Ivo who walks back onto the marked spot to
  "punish the landing" can be crushed by a body that is still falling.
- After a double jump, the end point can be more than 100 px above the room, out of the frame.

## Root cause

`dive_motion.gd:23`: `var landing := Vector2(ctx.clamp_x(ctx.target.x) - ctx.feet.x, ctx.target.y - ctx.feet.y)`.
`LeapMotion` and `BlinkMotion` both land at y offset 0, the floor they left. `DiveMotion` was used only by the engine
fixture until GRD-15. `guardian_motions_test` and `test_the_dive_shadow_covers_its_whole_reach` both build the context
with Ivo's feet at the guardian's floor, so the airborne case is never planned.

## Fix

Fixed in GRD-15 (2026-11-19). `DiveMotion.plan` lands at y offset 0, the take-off floor, under Ivo's x as he was at
the strike's start; the `AT_LANDING` shadow already lay there. Test:
`guardian_motions_test.test_a_dive_at_an_airborne_ivo_lands_on_the_floor` (Ivo 140 px and 260 px up, a jump and a
double jump; the path ends at `(200, 0)`).

## Options considered

Not fixed. Land on the take-off floor: `Vector2(ctx.clamp_x(ctx.target.x) - ctx.feet.x, 0.0)`. That is what "dives onto
Ivo's spot" means, and it is where the `AT_LANDING` shadow already lies (`SpawnPlacement` uses `floor_y`). Add a
`guardian_motions_test` case with Ivo 140 px above the guardian's feet that asserts `end_offset().y == 0`.

## Prevention

A motion that lands must plan its landing on the floor, never on Ivo's feet. Ivo's y is the only input that is
routinely airborne. Every motion test should include an airborne target.

## Playtest evidence (2026-11-19, `playtests/2026-11-18-grd15-leaf-feel`)

Not reproduced in play: 15 of 15 dives in four runs (dodging driver, god and no god) started their strike with Ivo on the
floor and landed at the floor (guardian y -1248.0/-1248.1 at recovery). Each was picked as Ivo jumped a returning blade,
near the apex of a single jump; by the strike's start, 0.45 s later, he had landed. The case needs a strike that starts
while Ivo is still airborne, for example a double jump or a jump taken just as the cooldown ends. The runs did not test that.
