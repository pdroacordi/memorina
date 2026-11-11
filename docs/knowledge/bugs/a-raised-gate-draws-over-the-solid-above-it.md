---
id: bugs/a-raised-gate-draws-over-the-solid-above-it
type: bug
title: A raised gate (G) slides into the solid above it and is drawn over it; in orchard_windy_gap it stands 64 px above the shelf, in front of the new pear tree, and lifts Ivo
status: open
severity: medium
tags: [gate, mechanism, rooms, world-42, orchard-windy-gap, empty-house, draw-order, clipping]
related: [playtests/2026-11-11-world42-puzzle-parts, systems/rooms, systems/props]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - scenes/world/interactables/gate/gate.tscn
  - scenes/world/interactables/gate/mechanism.gd
  - scenes/world/rooms/wind_orchards/contents/orchard_windy_gap.room
  - scenes/world/rooms/home_village/contents/village_empty_house.room
---

## Summary

`gate.tscn` is a 24x96 body with `travel = (0, -96)`. Placed under a ceiling or a shelf, the open gate moves into the
solid cells above it. Its `Sprite2D` is drawn over the ground tiles there, so the open gate shows through the stone or
planks. Its body also carries anything standing in its column up with it.

## Symptom

Seen in `playtests/2026-11-11-world42-puzzle-parts` (uncommitted WORLD-42 tree on 4f916be4):

- **orchard_windy_gap** (gate at cell 2,8, floor y -1632, shelf row 5 = y -1760..-1728): the closed gate fills rows
  6-8 under the shelf. Open, it spans y -1824..-1728. It covers the shelf's stone at col 2 and stands 64 px above the
  shelf's top, in front of the WORLD-42 pear tree's trunk (frames `03_windy_gap_gate_rises_through_the_shelf.png`,
  `05_windy_gap_colour_sequence.png` at 14.10 s). Ivo was standing at x -7583.5, at the shelf's west end where the
  gale is played. The gate lifted him to y -1823.1. He stood on it until it closed at ~24.5 s and lowered him back to
  -1760. This is the spot `rv_w5`/`world35s4_f` play Vendaval from.
- **village_empty_house** (gate at cell 4,3, upper floor y 12128, ceiling row 0 = y 12000..12032): the closed door
  fills rows 1-3, floor to ceiling. Open, it spans y 11936..12032, wholly inside the ceiling row and above the room.
  Its lower band is drawn over the ceiling planks (`09_empty_house_raised_door_over_ceiling.png`, look_up held).
- **summer trial** (test bed): the open gate overlaps the stone column hanging over it (`10_summer_trial_plate_gate_seesaw.png`).

Reproduce: `tools/playtest/scripts/world42_windy_gap_puzzle_colour.json` (open gate 13.5-24.5 s) and
`world42_empty_house_release_grey.json` (open from ~8.9 s).

## Root cause

The gate's travel is a fixed 96 px up, whatever is above it. `RoomMapNode` adds entities after the ground layers at
the same z, so a moving body's sprite draws over the tiles it enters. Nothing in the `.room` checks that the cells a
mechanism travels into are air. The windy gap's gate and shelf predate WORLD-42, and no earlier playtest reported the open gate, but the new tree now
stands directly behind it.

## Fix

Not decided. Options: open downward or sideways where the cells above are solid; give `G` a per-entity `travel`; draw
mechanisms under the ground layers so a gate slides into the stone instead of over it; or have `room_files_test`
fail when a mechanism's travel rect meets solid cells. The lift in orchard_counterweights is the same `Mechanism`, but
its travel was not seen to cross solid.

**Partly fixed 2026-11-11 (WORLD-42):** `gate.tscn`'s `Sprite2D` has `z_index` -1, so the ground tiles (z 0) draw over the part of an open gate inside solid cells; it still draws over props (z -10). Re-shot: the Empty House's open door is hidden behind the ceiling planks. **Still open:** in orchard_windy_gap the open gate rises 64 px above the one-row shelf into open air (in front of the pear tree) and lifts a player standing in its column; that is the room's geometry (a 96 px gate under a 32 px shelf) and is roadmap WORLD-43.
