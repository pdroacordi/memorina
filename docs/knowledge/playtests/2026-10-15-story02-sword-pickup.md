---
id: playtests/2026-10-15-story02-sword-pickup
type: playtest
title: STORY-02 - the sword on the farmhouse table, taken with Up, then the first swing
status: active
build: 131a6ad (STORY-02 uncommitted)
area_tested: "threshold_farmhouse: start without the sword, an attack press, the walk to the meal table, Up, the swing"
tags: [pickup, item, story-02, farmhouse, sword]
related: [systems/pickups, systems/notebook]
created: 2026-10-15
updated: 2026-10-15
ratings: { fun: 3, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-15-story02-sword-pickup/00_farmhouse_no_sword.png
  - screenshots/2026-10-15-story02-sword-pickup/01_attack_does_nothing.png
  - screenshots/2026-10-15-story02-sword-pickup/02_at_the_table.png
  - screenshots/2026-10-15-story02-sword-pickup/03_taken.png
  - screenshots/2026-10-15-story02-sword-pickup/04_swing.png
---

# STORY-02: the sword pickup

Timeline `tools/playtest/scripts/sword_pickup.json` (`"owned_items": []`, Ivo at (12080, 12286) in threshold_farmhouse).

## What the run showed

- The sword lies on the meal table's planks, drawn in front of the table and its plates (`00`).
- An attack press without the sword does nothing: `attack=false`, `state=idle` (log `no_sword`, `01`).
- Walking right stops Ivo at x 12296 in front of the table. The Up prompt stands over the sword (`02`).
- Up takes it: the sword leaves the table and the notebook quill appears in the corner for the sword's ITEM entry (`03`, `04`).
- The next attack swings: `attack=true`, `state=attack_idle_1` (log `swing`, `04`).

## What screenshots cannot show

- Whether taking the sword with no sound and no gesture reads as a moment. Only the table and the quill change. A pickup sound, or a short raise of the sword, is a feel call for later, not built.

## Observations

- With Ivo standing in front of the table, his body covers the sword while the prompt shows (`02`). The prompt stands clear over both.
