---
id: bugs/a-boar-charge-that-hits-ivo-by-a-ledge-dazes-inside-him-and-contact-takes-a-second-life
type: bug
title: A boar charge that hits Ivo near a ledge knocks him only ~70 px, the boar dazes on top of him, and its contact hitbox takes a second life the frame his 0.85 s invulnerability ends
status: resolved
severity: medium
tags: [core-13, creatures, boar, contact, knockback, ledge, invulnerability, threshold-bridge]
related: [systems/creatures, architecture/corrupted-creatures, playtests/2026-10-29-core13-boar-and-scorpion]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - tests/scenes/characters/enemies/enemy_test.gd
  - scenes/combat/hitbox/hitbox.gd
  - resources/characters/creatures/boar/boar_charge.tres
  - resources/characters/creatures/boar/boar_stats.tres
  - scenes/characters/enemies/enemy.gd
  - scenes/characters/enemies/ai/walker_ai.gd
  - scenes/characters/ivo/ivo.tscn
---

## Summary

At `threshold_bridge` the boar charges west toward the gap and dazes at the ledge (~x 7159-7171),
as designed. When the charge hits Ivo first, its knockback (420, lift 140) carries him about
70 px west in ~0.35 s. Meanwhile the boar runs on at 300 px/s and stops at the ledge 0-15 px
from his feet. `Enemy` keeps `ContactHitbox.monitoring` on through RECOVER, the daze lasts 1.0 s,
and Ivo's hurtbox invulnerability is 0.85 s (`ivo.tscn:2412`). So the contact lands a second
hit exactly 0.85 s after the first, and the knockback throws Ivo back east. One charge costs
two of his three lives, and the second hit can push him into the gap pit.

## Evidence (4 of 4 standing-hit runs, trace lines from the runner)

| Run (timeline) | 1st hit (charge) | Boar dazes at | 2nd hit (contact, boar in `recover`) |
|---|---|---|---|
| `map_closed_by_hit` (start 7240, 150) | t 2.173, Ivo 7233 → 7169 | t 2.512, dx -1.3 then -9.6 | t 3.017 (+0.844 s), Ivo knocked east to 7219 |
| `map_open_at_death` (same start) | ~2.15 | dx ~-10 | by 3.01 (hp 1) |
| `traverse_opening_e_bridge_gap` (unedited) | ~7.45, Ivo 7217 → 7146 | t ~7.7, dx 13.0 | ~8.25, then fell into the gap pit (hp 1) |
| `bench_rest_and_death` (new start) | ~10.6, Ivo 7229 → 7158 | ~10.95, dx 1.6 | ~11.4 (death, 3rd life) |

In `map_closed_by_hit`, Ivo stands still on the floor at 7169.05 from t 2.659 to 2.994 with the
dazed boar 9.6 px away. Then hp goes 2 → 1 at 3.017.

Not seen when Ivo jumps the charge (`core13_boar_bridge` variants): he lands 46-62 px east
of the dazed boar.

## Why it matters

The design sells the daze as the punish window ("dazed by a wall or a ledge"). Here it is the
worst moment to be near the boar, and the player has had control for only ~0.35 s, while
still landing from the knockback. Contact costing 1 is the user's decision (2026-10-29); one
*charge* costing 2 is not.

## Fix (for the implementer; not applied)

Any of:
- After an attack hits, keep the target immune to that creature's contact until the creature's
  move finishes (per-attacker grace). This is the general fix.
- Turn off contact damage during an `ends_on_wall` recovery (the boar is stunned, its body
  harmless). The design must agree.
- Raise the charge's knockback so Ivo clears the boar's stop point, or end the charge on a
  hit (`ends_on_hit`).

Re-run `map_closed_by_hit` after the fix: hp should stay at 2 through the daze (t 2.5-3.5).

## Resolution (2026-10-29)

The general fix, data-free and for every creature: once the current move has hit, the creature's body stops hurting until the move ends, recovery included. One move costs one life.

- `Hitbox` gained `hit_landed(target)`, emitted only when the hurtbox was not invulnerable before the hit. `connected` still fires on every touch, because Ivo's pogo bounces off an i-framed target too.
- `Enemy` sets `_move_landed` when a move hitbox lands, or when `ContactHitbox` lands during ACTIVE or RECOVER. The flag is set from the physics flush and only read in `_sync_areas`. `_sync_areas` keeps `ContactHitbox` and the scorpion's `Guard` off while the flag holds, and clears it once `EnemyAI.is_busy()` is false (cooldown or ready).
- A hit blocked by Ivo's invulnerability does not count, so a charge that passes through an i-framed Ivo still lets the body hurt him later in the daze.
- Ivo still standing in the boar when the daze ends is touched again, after at least the 1.0 s daze: his own choice.
- Tests (`tests/scenes/characters/enemies/enemy_test.gd`):
  - `test_after_its_move_lands_the_body_stops_hurting_until_the_move_ends`
  - `test_a_landed_strike_also_quiets_the_tail_guard`
  - `test_one_charge_costs_exactly_one_life`: a hurtbox riding inside the boar with Ivo's 0.85 s invulnerability takes exactly one hit from the charge to the end of the daze. Without the fix it takes 2 to 3.
- Not re-played: re-run `map_closed_by_hit` (hp should stay at 2 through t 2.5-3.5).
