---
id: bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room
type: bug
title: A running neighbour room's backdrop draws into the current room's view, so the background pops at every in-region seam
status: resolved
severity: medium
tags: [rooms, residency, backdrop, parallax, seam, glide, world-05, aesthetics]
related: [playtests/2026-10-09-traversal-woods-lake, systems/backdrops, systems/rooms, bugs/a-neighbour-room-has-no-ground-until-ivo-enters-it, bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory]
created: 2026-10-09
updated: 2026-10-10
source_files:
  - scenes/world/rooms/room_residency.gd
  - scenes/world/rooms/room.gd
  - scenes/world/environment/backdrop/backdrop.gd
---

## Summary

Since `RoomResidency` keeps every room that touches the current room running, those rooms' contents are
shown too, and that includes their `Backdrop`. A neighbour's parallax layers then draw over parts of the
current room's view. What the background shows at a fixed camera depends on which room is current. When
Ivo crosses an in-region seam, it changes on one frame while the camera stands still.

## Symptom

Uncommitted WORLD-05 seam work on ea47690 (imported 23:25:32).

**The pop at the seam:**
- Timelines: `tools/playtest/scripts/traverse_woods_lake_w7a_rv_square_to_mill_glide.json` and
  `..._w7c_rv_mill_to_square_glide.json`. Each walks across the village_square/village_mill seam at
  x 1920, taking a screenshot every 0.05 s.
- Forward (square → mill): the camera centre is (1600, 204) on both frames f1.75 and f1.80, yet 381,841 of
  921,600 window pixels (41%) change on the crossing frame. The pixel change for the 0.05 s steps around
  it is 4,000-6,000.
  - The pine layer on the right vanishes.
  - The mountain moves ~130 game px.
  - Flat panels of fill colour appear.
  - Screenshot: `playtests/screenshots/2026-10-09-traversal-woods-lake/rv_square_to_mill_backdrop_pop.png`.
- Back (mill → square): the camera moves 6 px on the crossing frame (2234 → 2228), and 51% of the pixels
  change. The view goes from flat olive and pale slabs to a full detailed pine forest
  (`rv_mill_to_square_backdrop_pop.png`).

**The resting view is wrong too:**
- The same spot in village_mill, at the same time into `traverse_woods_lake_k2_mill_floor_trail_slab_stub.json`
  (frame k01.6), looks different on the two builds (`rv_mill_backdrop_before_and_after_residency.png`):
  - build 6fa077a, one visible room: sky, mountains and pines;
  - the WORLD-05 build: a dark pine band covers the sky, and a flat olive band lies just above the floor.
- Flat fill slabs also show in village_lane_west, woods_deep and woods_edge.

## Root cause (likely; not traced in code)

- `RoomResidency.settle` calls `Room.activate()` on every touching room, and `activate()` both runs and
  shows the contents.
- Each `Backdrop` sizes its quads to `BackdropMath.cover_rect`: what its own room's camera can show, plus
  32 px.
- A layer whose `scroll_scale` is below 1 moves with the camera. While the camera is in the neighbour room,
  that room's layers (and their fills past the strip) therefore slide into the current room's view.
- All backdrops sit at z -30, so tree order decides which room's layer is on top.
- Before WORLD-05 residency only the current room was visible: the previous room was `deactivate()`d,
  which hides it. This did not arise then.

## Impact

- Every in-region seam pops the background on the crossing frame, in the middle of the glide that was meant
  to hide the transition. It is the most visible artefact of a seam walk.
- Resting views are polluted by whichever neighbours are running. The picture also depends on history,
  because idle rooms are hidden.

## Fix

Not fixed. Options for the implementer:
- Draw only the current room's backdrop, plus during a glide the room being left. Neighbours still run for
  collision (`bugs/a-neighbour-room-has-no-ground-until-ivo-enters-it`), but their backdrops are hidden.
- Or clip each room's backdrop to its own room's bounds in world space, so a layer can never draw outside
  its room.

## Prevention

A test that activates two touching rooms, puts the camera inside one, and asserts that no visible
`Backdrop` layer of the other covers any part of the view.

## Resolution (2026-10-10)

`Backdrop` passes its room's bounds to `backdrop_layer.gdshader` as `room_rect`. The shader discards every
fragment whose world position (after the `Parallax2D` scroll) lies outside it. Re-checked on the
uncommitted tree, imported 23:58:40 (`playtests/2026-10-09-traversal-woods-lake`, Re-check):
- **square → mill** (`traverse_woods_lake_w7a_rv_square_to_mill_glide.json`): the crossing frame changes
  2k pixels (was 381k); a still frame changes 4-6k. The glide frames fall smoothly (219k → 5k) with the
  pan's speed. The pines and mountains are continuous
  (`playtests/screenshots/2026-10-09-traversal-woods-lake/rv2_square_to_mill_glide_clipped_backdrop.png`).
- **mill → square** (`..._w7c_rv_mill_to_square_glide.json`): no frame changes more than the pan explains.
- **The mill's resting view** (frame k01.6 of `..._k2_mill_floor_trail_slab_stub.json`) differs from build
  6fa077a's by 252 pixels (dust motes). The sky is back (`rv2_mill_backdrop_first_session_vs_clipped.png`).
