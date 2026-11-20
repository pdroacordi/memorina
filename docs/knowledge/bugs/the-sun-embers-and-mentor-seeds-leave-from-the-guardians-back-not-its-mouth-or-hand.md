---
id: bugs/the-sun-embers-and-mentor-seeds-leave-from-the-guardians-back-not-its-mouth-or-hand
type: bug
title: The Sun's embers and the mentor's seed pods appear on the guardian's back (feet x, a fixed height up), not at the drawn mouth or hand
status: active
severity: medium
tags: [guardians, summer, mentor, spawns, lob, grd-18, art]
related: [playtests/2026-11-20-grd18-leaf-sun-mentor-art, systems/guardians]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/characters/guardians/spawns/lob/lob.gd
  - scenes/characters/guardians/summer_guardian/spawns/ember.tscn
  - scenes/characters/guardians/bloom_guardian/spawns/seed_pod.tscn
---

## Summary

A `Lob` starts its flight at `context.origin + Vector2(0, -hand)`: the guardian's feet x, `hand` px up. The lion is
132 px long and the GRD-18 `ember_spit` strip whips its head low and forward, so each ember sits on the lion's back,
over its hind half, through its 0.4 s warning, about 90 px behind the drawn mouth. The seed pods appear at the mentor's
hip, on the side away from the casting hand.

## Symptom

`playtests/2026-11-20-grd18-leaf-sun-mentor-art`, forced ember spit: at strike 0.2-0.35 s the ember is drawn at the top
of the lion's back while the head is down at the floor ahead (`screenshots/2026-11-20-grd18-leaf-sun-mentor-art/sun_ember_from_back.png`),
then it rises out of the back. Forced seeds: the pods appear at the mentor's waist, behind the body, while `seed_cast` 4-5 throws
the arm forward (`mentor_thorn_row_and_seeds.png`, bottom row). High confidence: it repeats on every throw, and the
launch point is the code's, not a timing accident.

## Root cause

`lob.gd:44-45` (`launch()`) has no forward offset. `ember.tscn` sets `hand = 80`; `seed_pod.tscn` sets `hand = 60` (the
mentor throws the Bloom pod scene). The point suited the Bloom stag's placeholder throw, but neither the lion's mouth nor the
mentor's hand is above its feet.

## Fix

Not fixed. Give `Lob` a forward offset in the guardian's facing (a `mouth`/`hand` Vector2), set per scene: the
lion's mouth on `ember_spit` 5-7 is about 60-90 px ahead and 20-40 px up; the mentor's hand on `seed_cast` 4 is about
20-30 px ahead at chest height. The flight and landing spots are unchanged, so no dodge changes.
