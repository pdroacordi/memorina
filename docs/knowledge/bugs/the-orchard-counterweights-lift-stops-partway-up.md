---
id: bugs/the-orchard-counterweights-lift-stops-partway-up
type: bug
title: "Not a bug: the orchard_counterweights lift seemed to stop 86 px up; it rises its full 448 px, and the stills were misread"
status: resolved
severity: low
tags: [world-35, wind-orchards, counterweights, lift, soltar, puzzle, playtest-method]
related: [playtests/2026-10-15-world35-step4]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_counterweights.room
  - scenes/world/interactables/gate/mechanism.gd
---

## Summary

The WORLD-35 step 4 playtest reported Outono Logico 1's lift stalling part-way. Logged state showed that it rises its
full travel. The report came from two misread stills.

## Symptom

- Soltar was played from the lower chamber's east floor (feet (-5936, -1632)). Only the right load fell onto
  `plate_lift`.
- Stills at t 6.1 and t 7.6 seemed to show the lift held 86 px up.

## Root cause

Not a bug: misread stills.
- Temporary prints in `Mechanism._physics_process` and `PressurePlate._on_load_changed`, removed after. The same timeline
  logged:
  - `plate_lift` load 1.5 at t about 5.15;
  - the lift's `_progress` 0 → 1 in 3.5 s, local y 672 → 224 (the full 448 px) by t about 8.7;
  - the plate let go at t about 10, when the grey returns the load, and the lift sank back.
- At t 7.6 the lift had already left the frame through its top. The platform taken for it was something else.

## Fix

None needed.
- The ride works (`tools/playtest/scripts/world35s4_c0_lift_ride.json`): Soltar from the east floor, a jump west onto the
  lift as it starts to rise, up to the block tops, then east into orchard_summit.
- From the lift's east end both loads fall and the lift jams, as design 02 section 8 (Outono Lógico 1) intends.

## Prevention

- Do not judge a moving mechanism from stills.
- Log its state with a temporary print, or the playtest trace when it covers the body.
- Check that the mechanism is still in the frame.
