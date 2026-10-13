---
id: bugs/the-lake-well-hatch-prompt-is-cut-by-the-top-of-the-frame
type: bug
title: lake_well's hatch stands on row 2, so its Up prompt starts 12 px above the room and the frame cuts its top 12 of 32 px
status: resolved
severity: low
tags: [doors, prompt, frozen-lake, well, world-29, ui]
related: [systems/rooms, systems/world, architecture/water-two-projections, bugs/the-fishing-village-well-has-no-way-out]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/interactables/door/door.gd
  - scenes/world/rooms/frozen_lake/contents/lake_well.room
  - tests/scenes/world/interactables/door/door_prompts_test.gd
---

## Summary

The WORLD-29 hatch in lake_well sits at cell (9,2), so its floor point is 96 px below the room top. `Door._dress`
places the prompt 108 px above the floor for `hatch_up`, which puts it 12 px above the room. lake_well is one screen
tall, so the frame top is the room top and the top 12 of the glyph's 32 px are never drawn. This is the room's only exit.
Found in review of the WORLD-29 working tree; the implementer saw it in a still, and the numbers below come from the code.

## Symptom

Ivo stands on the catch under the hatch. The Up key glyph shows only its lower 20 px, cut flat by the frame's top edge.

## Root cause

- `door.gd` `_dress()`: `_prompt.position.y = minf(-104, sink - texture.get_height() - PROMPT_GAP - _prompt.size.y)`.
  For `hatch_up` this is `0 - 68 - 8 - 32 = -108`.
- The door's origin is the cell's bottom centre (`RoomMapNode.entity_position`, FEET), here room y 96. The prompt
  therefore spans room y -12..20.
- The frame yields above a room only to keep Ivo's body whole (`GameCamera.set_reach`). His head is at about y 42, so
  the frame does not yield.
- The hatch cannot be moved down. The catch is row 3, and the squall's top is exactly y 96
  (`bugs/the-fishing-village-well-squall-blows-ivo-off-the-climb-out`), so a lower catch would put Ivo back in the wind.

Any door whose floor is 108 px or less below its room's top (row 2 or higher) has the same cut. Today lake_well's
hatch is the only one: lighthouse_interior's hatch is on row 4.

## Fix

Resolved 2026-10-13 in `Door`. `Door.prompt_position(look, prompt_size, feet, bounds)` (static) keeps the prompt above
the art while it fits inside the door's room (`Room.of(self).get_bounds()`). When it would leave the room, it goes beside
the art at the art's middle, to the right, or to the left if the right side leaves the room too. `_dress` uses it. In
lake_well the hatch's prompt now stands to the right of the hatch, room y 46..78. A door outside a room (a contents scene
opened alone) keeps the prompt above. The room data is unchanged.

## Prevention

Done: `door_prompts_test` places every door's prompt in every map with `Door.prompt_position` and fails when one leaves its room; `door_test` covers the above, right and left cases.


Add a world check to `room_files_test` (or `facade_doors_test`): every door's prompt rect, computed the way `_dress`
computes it, lies inside its room's bounds.
