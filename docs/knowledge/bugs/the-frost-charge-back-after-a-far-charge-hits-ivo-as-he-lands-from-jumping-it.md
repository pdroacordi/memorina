---
id: bugs/the-frost-charge-back-after-a-far-charge-hits-ivo-as-he-lands-from-jumping-it
type: bug
title: A Frost charge thrown from about 250 px stops about 60 px past Ivo, and its charge-back's box opens while he is still coming down from jumping the first fists
status: resolved
severity: medium
tags: [guardians, frost, grd-14, charge, charge-back, fairness, playtest]
related: [playtests/2026-11-18-grd14-frost-feel, playtests/2026-11-18-grd14-frost-fight, systems/guardians]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/characters/guardians/frost_guardian/frost_charge.tres
  - resources/characters/guardians/frost_guardian/frost_charge_back.tres
  - scenes/characters/guardians/frost_guardian/frost_guardian.tscn
---

## Summary

The documented dodge for the charge-back is "jump the fists (or roll)". After a charge thrown from far away it does not
work with a jump. The charge-back then starts about 60 px from Ivo while he is still in the air from jumping the first
charge. Its body-front box opens 0.5 s later, while he is still coming down. All 5 such charge-backs in 5 runs hit the
driver. All 13 charge-backs that started 197-238 px away missed. A jump-only player can dodge only by jumping the first
charge too early, then jumping again almost on landing. Otherwise only the roll works.

## Symptom

`guardian_fight_player_driver.gd` (session copy `pin_driver.gd`) jumps an owned charge 0.24 s before its fists arrive
(`PL_CHARGE=jump`):

| run | first charge thrown from | charge-back starts at | box live, Ivo's feet | hit |
|---|---|---|---|---|
| god1 t 53.09 | 243 px | dx -60.1 | 30 px up, falling | t 54.33, dy 47.9 |
| rolljump2 t 125.05 | 255 px | dx -60.2 | 37 px up, falling | t 127.49 |
| nogod t 120.82 | 248 px | dx -63.3 | falling | t 122.56, dy 41.7 |
| dropoff t 42.36, 120.86 | 251 px | dx -59.7 / -60.4 | falling | t 44.10, 122.56 |

Trace (rolljump2): the charge's strike starts at 125.757, its lunge at 126.257. Ivo jumps at 126.313 and is 138 px up when
the charge-back starts at 126.929, with the golem 60 px past him. The golem holds still through the skid and turn. The
box opens at 127.429 with Ivo 37 px up and falling. He is hit at 127.485.
Frames: `playtests/screenshots/2026-11-18-grd14-frost-feel/charge_back_landing.png`.

## Root cause

- The charge covers about 311 px (455 px/s from 0.5 s to 1.167 s, plus the skid), so from 250 px it ends about 60 px
  past Ivo.
- A far charge's fists arrive late (0.5 + (250 - 112) / 455 = 0.80 s), so a natural jump takes off late, at about
  0.55 s. Measured single jump: 1.2 s in the air.
- The charge-back has no telegraph (0.0) and opens its box at 0.5 s, from the body's front. That is 1.667 s after the
  first strike began, before Ivo lands.
- `attack_height` 200 lets the link fire on an airborne Ivo by design (`systems/guardians`, "The charge-back").

Jump-only window, from the measured jump curve (the hurtbox foot clears 104 px from 0.30 to 0.92 s after take-off):

- The first take-off must come in strike seconds -0.13..0.18, before the lunge starts.
- The second jump must take off by 1.38, about 0.2 s after landing.

## Fix

Fixed in GRD-14 (2026-11-18).
- The charge-back has a 0.5 s wind-up again (`windup_7`: charge frames 12-13, the skid and turn) and the body holds still
  through it: `Guardian._on_attack_telegraphed` zeroes the x speed on every link's wind-up, so a lunge does not carry the
  golem on through it. The ~90 px slide that made the telegraph a problem before is gone.
- The rule, pinned by `frost_guardian_kit_test.test_an_ivo_who_jumped_the_charge_has_landed_before_the_charge_back`:
  from every throw distance (42-260 px), an Ivo who jumps the first fists as late as still clears them (take-off when
  the fists are 0.26 s away, his traced jump: 1.2 s in the air) has landed at least 0.35 s before the charge-back's box
  can reach him (charge 1.167 + wind-up 0.5 + box at 0.5). At 0.45 s the far throws had 0.33-0.35 s.

## Prevention

Add a kit test: for every throw distance 42-260 px, an Ivo who jumps the first fists with the documented timing must
have one ground jump (0.30 s rise) or one roll available before the charge-back's box reaches him.
