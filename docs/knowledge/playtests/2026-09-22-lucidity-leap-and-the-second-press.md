---
id: playtests/2026-09-22-lucidity-leap-and-the-second-press
type: playtest
title: The guardian leaves the frame before it calls, and the recalled double jump can finally be seen
status: active
build: 4079249 + the round-11 changes
area_tested: Bloom Hollow and the lighthouse - the leap into lucidity; the double-jump recall pressed from the ground
tags: [guardians, cinematic, qte, recall, double-jump, camera]
related: [features/lucidity-leap, bugs/air-jump-assigned-mid-rise-is-invisible]
created: 2026-09-22
updated: 2026-09-22
ratings: { fun: 4, fluidity: 4, aesthetics: 5 }
screenshots:
  - screenshots/2026-09-22-lucidity-leap/21_airborne.png
  - screenshots/2026-09-22-lucidity-leap/22_landed_calling.png
  - screenshots/2026-09-22-lucidity-leap/31_frost_landed.png
---

## What was tested

A throwaway probe (deleted afterwards) pressed the double-jump recall the way a hand
would - `Input.parse_input_event`, a real hold, a release - and logged what each press
did, then beat both guardians to lucidity and followed the leap frame by frame.

## Findings

- **The QTE was never broken; the jump was.** The chain logged perfectly on the first
  probe - `step remaining=1`, then `RECALLED`, `DOUBLE_JUMP` - while the velocity went
  from -184 to -198 px/s. An air jump ASSIGNS `velocity.y`, so pressed mid-rise it is a
  gain of 38 px/s: invisible. Own bug entry. After the fix the recalled jump launches at
  -462 against the ground jump's -490, which is a second launch you can see.
- **The first leap was swatted out of the air after 34 px** by the Bloom arena's low
  platform. An arc meant to leave the frame has to be allowed through the ceiling: the
  guardian now passes through the world while it is above the floor it left, and takes
  collision back as it descends. `21_airborne.png` is the shrub sailing out of the top
  of the frame, clear of the platform it used to hit.
- **The landing reads exactly as the phase change it is.** `22_landed_calling.png`: the
  guardian at the far left, Ivo at the right, the sheet centred above them, the call only
  starting once the dust settles. Measured 311 px apart against a 300 px target.
- The golem does the same (309 px), and because it is tall the sheet stands aside rather
  than centring - the two rules compose (`31_frost_landed.png`).

## What this cannot judge

Whether the arc's timing feels right in motion - how long the guardian is out of frame,
and whether the pause before the call is a beat or a wait. Nothing here watches it at
speed. In the lighthouse the camera is clamped by the room's edge, so the golem sits close
to the frame's left border after landing; whether that wants a shorter leap for that arena
is a judgement a still cannot make.

## Ratings rationale

- fun 4: unchanged; this round was the moment around the fight, plus one real fix.
- fluidity 4: the recalled jump answers the press now.
- aesthetics 5: the phase change is an action you watch instead of a panel that appears.
