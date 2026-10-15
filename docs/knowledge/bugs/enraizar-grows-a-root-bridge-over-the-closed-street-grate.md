---
id: bugs/enraizar-grows-a-root-bridge-over-the-closed-street-grate
type: bug
title: Enraizar played on village_gate_east's road grows a root bridge across the closed street grate, because RootSpanFinder reads only the grid and the grate's four cells are air there
status: resolved
severity: low
tags: [world-35, rooms, fact-grate, roots, enraizar, home-village, review]
related: [systems/rooms, systems/roots-and-climbing, systems/world, playtests/2026-10-15-world35-step5]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/memory/song_effects/roots/root_span_finder.gd
  - scenes/world/memory/song_effects/roots/root_grower.gd
  - scenes/world/interactables/fact_barrier/fact_barrier.gd
  - scenes/world/interactables/fact_barrier/fact_grate.tscn
  - scenes/world/rooms/home_village/contents/village_gate_east.room
---

## Summary

WORLD-35 step 5 (uncommitted, review 2026-10-15). The `FactGrate` (`g`) fills road cells 29-32 of village_gate_east
with a StaticBody2D, and those cells are air in the grid. `RootSpanFinder._bridges` finds an earth-to-earth BRIDGE from
(28, 9) to (33, 9), 4 cells wide. Enraizar played on the road near the closed grate grows roots across the iron.

## Symptom

Scratch timeline (review): Ivo at (4060, 288) on the road west of the closed grate, Enraizar known (song 6), plays
DOWN LEFT DOWN RIGHT DOWN UP. About 3 s after the last note, root strands lie along the top of the closed grate from its
west stone block towards its middle (still `root1`). They grow over a solid floor that has no gap to cross.

Headless check: `RootSpanFinder.find(load("res://scenes/world/rooms/home_village/contents/village_gate_east.room"), 14, 4, 2, 8)`
returns one span: `BRIDGE (28, 9) -> (33, 9), rows (9, 9)`.

## Root cause

`RootSpanFinder` sees only `RoomMap` cells (`_earth`, `_solid`). The legend tells authors to keep a grate's four cells as air
in the grid ("Keep the four cells air in the grid"), so the hole exists when the grate opens. Nothing tells the finder that
a closed body fills those cells. `RootGrower._ready` builds views for every span within the pulse's reach.

## Fix

Fixed 2026-10-15, before commit (orchestrator: "a closed barrier/grate is solid for roots; an open one is air").
- `RootSpanFinder.Span.cells()` lists the air cells a span crosses. `RootSpanFinder.clear_of(spans, blocked)` drops the spans that cross a blocked cell.
- `RootGrower._ready` drops the spans that cross a closed `FactBarrier`'s body, using `FactBarrier.is_closed()` and `body_rect()` mapped to cells. It reads this once per pulse, when the pulse opens. Once the summer guardian is restored, the grate is open, and a bridge across the open hole grows.
- Only FactBarriers count. Stone gates (`G`) and leaf curtains are untouched.
- A scan of every `.room` found two barriers on a root span: the street grate, and woods_deep's root wall (`knows_root.tres`). The root wall is closed only while Ivo does not know Enraizar, when no pulse can grow anything, so nothing changes there in play.
- `root_span_finder_test` covers the span cells and the filter. It also checks village_gate_east's real map: with the grate closed, no bridge from (28, 9) to (33, 9); with it open, the bridge is there.
## Prevention

An entity that fills grid air with a solid body (a grate, a fence) is invisible to every grid-only reader:
`RootSpanFinder`, `RootCatchFinder`, `RoomMapNode.ground_at`. When adding one, list those readers and decide for each
whether the closed body counts as ground.
