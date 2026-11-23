---
id: bugs/the-threshold-fields-memory-hold-stills-nothing-because-the-wheat-was-built-as-a-still
type: bug
title: The threshold fields' memory hold stills nothing, because the wheat was built as a still and winter grows no blades
status: resolved
severity: medium
tags: [props, ambient, memory-clock, greyhush, threshold, frost-edge, world-12, world-13, board-deviation]
related: [systems/props, systems/world, systems/grass, systems/air, gotchas/a-hand-placed-memory-source-slows-the-region-weather-under-it]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - scenes/world/rooms/threshold.tscn
  - scenes/world/environment/props/threshold/wheat_tall.tscn
  - scenes/world/environment/props/threshold/wheat_short.tscn
  - scenes/world/environment/props/threshold/scarecrow.tscn
  - scenes/world/environment/props/frost_edge/flagpole.tscn
  - scenes/world/environment/props/frost_edge/mast_snapped.tscn
  - resources/world/grass/threshold_earth_grass.tres
  - docs/knowledge/systems/props.md
  - docs/knowledge/systems/world.md
---

## Summary

Found in the WORLD-12..14 review, 2026-11-23, by reading. Not seen in a running game. The user chose "Hold the fields
still (Recommended)". The board's wording of that option was: "a hand-placed `MemorySource` over threshold_fields
holding the fields under 0.2 ... so the wheat stands frozen mid-sway until a pulse". The build added the source
(`threshold.tscn`, `FieldsStillMemory`, strength -0.15) but drew the wheat with no sway loop. Nothing else in the room
moves on the memory clock, so the hold has no visible target.

## Symptom

- Outside a pulse, every prop in threshold_fields is a still. The grass shows no blades either:
  `threshold_earth_grass.tres` has winter `density` 0, and the threshold's `Region.season` is WINTER (`systems/grass`:
  "winter none").
- Inside a pulse, the pulse's positive strength lifts the memory far above 0.2, so the hold does nothing there either.
  The wheat never sways, even though the board's option promised it would sway inside a pulse.
- What the source does change is incidental. In this room the fields are greyer than the region's 0.3, the blizzard
  runs at half rate and half push, and the snow and SFX muffle follow the lower memory
  (`gotchas/a-hand-placed-memory-source-slows-the-region-weather-under-it`).
- The same deviation applies to the other approved movers. The board's "Moves" lists the scarecrow's rag sleeve (4
  frames), the pennant and the torn sail (6 frames each, "they move only inside a pulse"). All of them were built as
  stills. The only record is in the art contracts: `threshold_wheat_tall.md` says "No sway loop: the fields are held
  under 0.2 by decision", and `frost_edge_flagpole.md` says "the board's 6-frame pennant loop ... is not drawn". No
  user decision is quoted for either.

## Root cause

"Hold the fields still" was read as "draw the wheat still". The decision meant that the memory holds a moving prop
still. Once the wheat had no frames, nothing was left for the memory source to hold, and `systems/props` and
`systems/world` (line 35) describe a purpose that cannot happen ("so their grass stands still until a pulse").

## Fix

**Resolved 2026-11-23**, option 1: "Sway loops, keep the hold (Recommended)" (user, 2026-11-23). The wheat (tall and
short) and the scarecrow's rag sleeve sway in 4-frame loops, the pennant and the torn sail in 6-frame loops, all through
`AmbientMotion`, each frame 0 the approved still (`tools/art/draw_ambient_frames.py` sway, swing `--box`/`--cloth`,
wave). `FieldsStillMemory` stays, so the fields' movers stand frozen mid-sway and move inside a pulse; `systems/props`,
`systems/world` and `systems/air` (the weaker gust, accepted) now say so.

The options that were offered:
1. Give the wheat (and the scarecrow's sleeve) the board's 4-frame sway through `AmbientMotion`, and the pennant and
   sail their 6 frames. The hold then does what the decision describes. This is the board as approved.
2. Keep the stills and remove `FieldsStillMemory`. Without movers it only greys the room and weakens the blizzard.
3. Keep both, but record the stills as a user decision. Correct the props and world entries so they say what the source
   does: grey and slow the fields' weather, not still the grass.

## Prevention

When an approved board item says what moves, the systems entry names each mover and its frame count, and any change
quotes the user. A memory patch authored for dressing names the drawable it holds still, and a reviewer checks that
the drawable can move at the patch's memory in the region's season.
