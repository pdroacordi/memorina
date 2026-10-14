---
id: bugs/kit-check-ice-forms-only-on-the-highest-water-any-song-can-raise
type: bug
title: The kit check puts ice only on the top of the highest water any song raises, so a kit with Congelar but not the raising song gets no ice at its own water line
status: resolved
severity: low
tags: [tech-08, kit-check, reachability, water, ice, freeze, audit]
related: [architecture/room-reachability-audit, systems/water, systems/rooms]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/rooms/maps/reach/reach_grid.gd
  - scenes/world/rooms/frozen_lake/contents/lake_high_wall.room
---

## Symptom

Found in the TECH-08 review (2026-10-14, uncommitted). In `lake_high_wall`, `f` water fills rows 18-24 and `u` sits
above it at rows 15-17. Kit ice exists only on row 15 and needs Congelar plus Redoma. The flat ice on the standing water
at row 18, which the room header calls "flat ice" and which Congelar alone makes, is not in any kit's grid. Nothing
changes today, because Congelar and Redoma come in the same milestone (frost). The gap appears once a kit holds one
without the other, for example if the Redoma fragment is split from the Frost Guardian.

## Root cause

`ReachGrid._add_water` (`reach_grid.gd:230-237`) places `SONG_FLOOR` only where `not body.has(cell + UP)`, and `body`
holds the standing, rained and shelled cells together. The comment "Ice tops the highest water a kit can raise there"
describes a per-kit top, but the code places a single top for all kits.

## Fix

Fixed 2026-10-14, before commit. `ReachGrid._add_water` adds kit ice on the top of the resting water under a reach
(where `standing` has no standing cell above). Its need is Congelar alone. The top of the highest water keeps
Congelar plus the song that raises it. The resting-level ice is a kit layer only: added to the union, it merged
lake_high_wall's STORY-06 ladder step (15,17) into an ice surface. The union audit then stopped judging that ledge,
which is the known blind spot, and its allowlist entry went stale. So the union keeps one ice top per column.
`reach_kit_check_test` pins it on an `f` pool under a `u` reach: Congelar alone gives ice at the resting row and none at
the reach top, Congelar + Redoma gives both, and the base kit gets neither.

## Prevention

A layered need should give every partial kit its own floor. When the fixtures cover only the full kit, add a fixture
for the partial one.
