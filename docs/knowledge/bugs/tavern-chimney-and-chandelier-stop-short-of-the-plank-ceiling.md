---
id: bugs/tavern-chimney-and-chandelier-stop-short-of-the-plank-ceiling
type: bug
title: The tavern fireplace's chimney ends 24 px under the one-way plank ceiling and the chandelier hangs 36 px under it, attached to nothing
status: resolved
severity: low
tags: [props, interiors, tavern, world-11, one-way-ledge, placement]
related: [systems/props, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/home_village/contents/village_tavern_contents.tscn
  - assets/sprites/world/props/interiors/tavern/tavern_fireplace.png
  - tools/art/prompts/interior_tavern_tavern_fireplace.md
  - tools/art/stretch_prop.py
---

## Summary

`TavernFireplace6` (96x224 at (800, 672)) reaches y 448, the bottom of row 13, and `Chandelier3` (68x60 at
(650, 520)) starts at y 460. Above both, row 13 cols 18-30 are `-` one-way planks, which `RoomMapNode._ledge_layer`
draws cell-aligned with art only in the top 8 px of the cell (y 416..424). The ceiling there is at y 424, not 448.

## Symptom

Status: open (WORLD-11 interiors review, 2026-10-11; visible in the author's in-game board of the tavern ground
floor). The chimney stops in mid-air 24 px below the planks, and the chandelier's hook hangs 36 px below them.
`systems/props` says "Chimneys rise to the ceiling".

## Root cause

The stretch height (224 = 672 - 448) treats every row-13 cell as a full-height ceiling. Under a one-way plank
the visible underside is the plank's bottom, 24 px higher. The same holds for anything hung from a plank span.

## Fix

Resolved 2026-10-11: the fireplace restretched to 248 px (top y 424) and the chandelier hung at y 484 (top y 424), both at the planks' drawn edge.

Stretch the fireplace to 248 (`stretch_prop.py ... 248`, contract `size: 96x248`, scene offset (-48, -248)) or
move it under the solid cells (cols 0-17); hang the chandelier from y 424 (position y 484) or give its art a chain.

## Prevention

A ceiling height for a prop is the bottom of the nearest drawn surface above it: a full cell's bottom for solid
ground, the cell top plus the ledge art height for `-`/`=`.
