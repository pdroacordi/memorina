---
id: bugs/the-frost-slam-jump-window-closes-before-the-fists-fall
type: bug
title: The Frost slam cannot be jumped in the last ~0.1 s of its wind-up, which leaves ~0.1 s after the "both fists up" pose; the systems entry's jump timings rise too fast
status: resolved
severity: low
tags: [guardians, frost, grd-14, slam, jump, wall, readability, playtest]
related: [playtests/2026-11-18-grd14-frost-feel, systems/guardians]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/characters/guardians/frost_guardian/frost_slam.tres
  - scenes/characters/guardians/frost_guardian/frost_guardian.tscn
  - docs/knowledge/systems/guardians.md
---

## Summary

`systems/guardians` (the slam, user decision "Jump clears the raised fists (Recommended)") says a single jump clears the
slam's box if it takes off "in the wind-up's last 0.35 s". It assumes the foot of Ivo's hurtbox is above 104 px from
0.24 to 0.85 s after take-off. Measured, the foot is above 104 px only from about 0.30 to 0.92 s.

A wall-pinned Ivo was hit 1 of 1 times when he took off 0.05 s before the strike, and 1 of 20 times at 0.10 s. Every
take-off 0.15-0.35 s before the strike cleared it (8 of 8). The real window ends about 0.1 s before the strike starts.

The full "both fists up" pose (`windup_3` frame 4) shows at 0.45 s of the 0.65 s telegraph. A player who waits for that
pose has about 0.1 s left to jump. Against a wall the jump is the only dodge.

## Symptom

- **Jump curve.**
  - Setup: a 0.4 s hold, traced per physics frame on flat ground at lake_shore (100, -1650). Apex 141.5 px.
  - Feet height after take-off: 0.133 s 58.9 px; 0.167 s 71.3; 0.233 s 93.3; 0.267 s 102.9; 0.30 s 111.6; 0.90 s
    115.3; 0.933 s 107.8.
  - The hurtbox foot is 6 px above the feet (`hurtbox.tscn`: capsule r 8, h 44, at y -28).
  - So the foot is above 104 from about 0.30 to 0.92 s, and above 60 from about 0.15 to 1.06 s. The entry says
    0.24-0.85 and 0.11-0.97.
- **Pinned at the west wall** (session `pin_driver.gd`, `PL_PIN=west`, `PL_SLAM_LEADS`). Lead = seconds before the
  strike starts, at the driver's press:

| lead | slams | hit |
|---|---|---|
| 0.20-0.35 | 7 | 0 |
| 0.15 | 1 | 0 (a second case, `pinsweep` t 134.78, logged a 3.32 s telegraph age, so it is discarded) |
| 0.10 | 20 | 1 (`pinw` t 46.48: take-off 0.07 s before the strike at 46.257; box opens at 46.424 with the feet 93.2 px up) |
| 0.05 | 1 | 1 (`pinw2` t 73.38, feet 93 px up) |

## Root cause

The window was computed from a jump that rises faster than the game's. The box opens 0.167 s into the strike, and the
foot reaches 104 px about 0.30 s after take-off. So a take-off later than about 0.1 s before the strike (input latency
included) is still under the box's top when it opens.

The swipe is not affected: its box top is 60 px. Of 12 jumps 0-0.10 s before its strike, 11 cleared it. The 12th
hit Ivo on the floor (dy 2.1), so the press was likely lost. Jumps 0.05 s after the first frame were hit 4 of 4 times. Its whole 0.55 s wind-up is a valid window.

## Fix

Fixed in GRD-14 (2026-11-18), both ways the entry suggested:
- **Only the fists on the floor hit:** the slam's box is x 34..80, y -48..0 (was y -104..0, which took the arms), from
  0.167 to 0.5 s; `attack_height` 40. The foot of Ivo's hurtbox clears 48 px about 0.1 s after take-off.
- **The pose comes early:** `windup_3` shows both fists up (slam 4) at 0.15 s of the 0.65 s wind-up, 0.5 s before the strike.
- A jump taken any time from that pose to 0.1 s before the fists fall clears them, on Ivo's traced jump
  (`frost_guardian_kit_test.test_a_jump_clears_the_slam` reads the pose, the box and the window from the clips).
- `systems/guardians` now gives the swipe, slam and wall timings from the traced jump.

## Prevention

Derive dodge timings in `combat_reach_test` from `ivo_jump_stats` and gravity, not from prose.
