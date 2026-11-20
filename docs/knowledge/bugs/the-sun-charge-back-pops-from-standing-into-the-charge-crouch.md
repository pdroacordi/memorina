---
id: bugs/the-sun-charge-back-pops-from-standing-into-the-charge-crouch
type: bug
title: The Sun's charge-back stands up for its own wind-up (attack_2 0-1), then cuts straight into the charge crouch GRD-19 put at the start of the shared attack_2 strike
status: fixed
severity: low
tags: [guardians, summer, charge, animation, art, grd-19]
related: [playtests/2026-11-20-grd19-spawn-origins-and-seams, playtests/2026-11-20-grd18-leaf-sun-mentor-art, systems/guardians]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/characters/guardians/summer_guardian/summer_guardian.tscn
  - resources/characters/guardians/summer_guardian/summer_charge_back.tres
---

## Summary

GRD-19 rekeyed the Sun's `attack_2` clip: `charge_windup` 3, 2, 3 through the 0.5 s lunge delay, then `attack_2`
6..13. That fixed the charge, whose wind-up `windup_2` ends on `charge_windup` 3. But `summer_charge_back` uses the
same strike (`clip_index` 1) after `windup_4` = `attack_2` 0@0, 1@0.25: the lion standing tall, head high. The
strike's first frame is the low crouch, so the return now snaps from standing to crouched in one frame. It then
holds the crouch in place for 0.5 s before the dash. Before GRD-19 it went standing to `attack_2` 0..5, a continuous
standing pose.

## Details

Seen twice in `playtests/2026-11-20-grd19-spawn-origins-and-seams` (forced `summer_charge_back`, every physics frame
drawn): `T` `attack_2` fr1, then `S` `charge_windup` fr3 on the next frame
(`screenshots/2026-11-20-grd19-spawn-origins-and-seams/sun_charge_back_stand_to_crouch_pop.png`, tiles 2 to 3). In a
fight the return is a stage-1 link after the charge (`from_stage 1`, `weight 0`). It follows the charge's recovery
(`attack_2` 12, 13), so the player sees: recovery, stand up (0.5 s), drop to the crouch (0.5 s), dash.

## Fix (2026-11-20)

`summer_charge_back` strikes on its own slot, `attack_9` (clip_index 8): a copy of the pre-GRD-19 `attack_2`, attack_2
0..13 from the standing start its wind-up ends on. The charge keeps the crouch on `attack_2`. Options that were weighed:
- Give `summer_charge_back` its own strike slot that keeps the old standing start.
- Make `windup_4` the charge crouch (`charge_windup` 0, 2, 3, as `windup_2`), so both moves telegraph the same way.

The second option also makes the return read as the charge it is. Either way, the 0.5 s `delay` of `DashMotion`
stays.

## Verified (2026-11-20)

Re-checked in `playtests/2026-11-20-grd19-spawn-origins-and-seams` ("Re-check (fixes)"). `summer_charge_back` strikes on `attack_9` (the old standing `attack_2` 0..13). The wind-up shows frames 0-1, then the strike 0-5 standing, then the lunge, with no crouch cut, in 2 of 2 reps.
