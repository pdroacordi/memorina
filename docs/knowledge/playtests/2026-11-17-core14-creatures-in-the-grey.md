---
id: playtests/2026-11-17-core14-creatures-in-the-grey
type: playtest
title: CORE-14 - corrupted creatures drawn as ink in the grey
status: active
build: uncommitted CORE-14 change over f548cc9d
area_tested: "tools/playtest/scripts/core13_crab.json, core13_hornet.json and core13_boar_bridge.json, run before and after the change."
tags: [core-14, creatures, greyhush, shader, playtest]
related: [systems/creatures, systems/greyhush]
created: 2026-11-17
updated: 2026-11-17
ratings: { fun: 0, fluidity: 0, aesthetics: 0 }
screenshots:
  - screenshots/2026-11-17-core14-creatures-in-the-grey/crab_before.png
  - screenshots/2026-11-17-core14-creatures-in-the-grey/crab_after.png
  - screenshots/2026-11-17-core14-creatures-in-the-grey/hornet_before.png
  - screenshots/2026-11-17-core14-creatures-in-the-grey/hornet_after.png
---

# CORE-14: creatures in the grey

## What the runs show

- Before, the crab by the wreck on `frost_shore` (x ~420 on screen) was light grey on light grey snow and planks; only its legs' gaps showed it (`crab_before`). After, it is a dark shape with its legs and shell readable (`crab_after`).
- Before, the hornet was a few grey pixels against the haze (`hornet_before`). After, its body is a dark cluster and its frayed wings scatter dark pixels (`hornet_after`).
- Ivo stays in colour; the ink does not touch him (his pixels carry no unshielded mark).
- The boar run never brings the boar into frame, before or after; it was not judged.

## Cannot be judged from frames

- Whether ink reads too heavy in a dark cave (the ink's light end is 0.36, darker than most lifted grey ground). None of the runs was in a cave.
- How a pulse's dithered edge crossing a creature looks in motion.
