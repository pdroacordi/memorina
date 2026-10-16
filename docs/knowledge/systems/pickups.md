---
id: systems/pickups
type: system
title: Pickups: an item lying in the world, taken with Up, present only while the save does not own it
status: active
tags: [pickup, item, save, input, rooms, story-02]
related: [systems/life-benches-death, systems/rooms, systems/dialogue, systems/notebook, systems/input, architecture/doors-and-interiors, architecture/room-reachability-audit, playtests/2026-10-15-story02-sword-pickup]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/interactables/item_pickup/item_pickup.gd
  - scenes/world/interactables/item_pickup/item_pickup.tscn
  - scenes/characters/components/pickup_component.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/ivo.tscn
  - resources/world/maps/room_legend.tres
  - scenes/world/rooms/threshold/contents/threshold_farmhouse.room
  - tools/playtest/playtest_runner.gd
---

# Pickups

**Never break:** An item's presence in the world is derived from the save, never recorded: an `ItemPickup` shows only while `PlayerData.owned_items` lacks its item, read on ready and on `progress_changed`. Taking it is a live gain (`SaveSystem.set_item_owned`), so a death before a bench forgets it and the item lies there again.

## Summary

STORY-02. Script draft 2, Act 2 (user, "Approve draft 2 (Recommended)", 2026-10-15): "The farmhouse: a meal stopped mid-bite, a chair pushed back, and the sword on the table, where someone set it down to eat (STORY-02, Up to take). The notebook's existing line for the sword is enough." No dialogue box and no text. Design 04 §3.2: threshold_farmhouse holds "Marca da espada (STORY-02)".

The Memorina is not a pickup: the mentor's talk grants it in STORY-03 through a line's `grants` (`systems/dialogue`).

## The pickup (`ItemPickup`, legend `i`)

- `scenes/world/interactables/item_pickup/`: an Area2D on layer 6 masking the Player body, like `Door` and `Talkable`, so Ivo's `DoorSensor` finds it.
- Legend `i`: kind ENTITY, reach role CONTENT, required params `item` (an `Enums.PlayerItem`: 0 the sword) and `texture` (a .png path).
- Other params:
  - `rest_offset` ([x, y] px from its cell's bottom centre to the item's bottom centre; the item lies on a table top);
  - `width_cells` / `height_cells` (the reach, 2x2 by default, centred, rising from its floor).
- The look is a `Sprite2D` drawn standing on its bottom row at `rest_offset`. The `look_up` `KeyGlyph` prompt stands 8 px over the item or the reach, whichever is higher, while Ivo is in reach, not talking (checked every physics frame, as `Talkable` does), and the item lies there.
- Its prompt shows only where Up would take the item: `Player.reaches`, the door sensor (STORY-14; `systems/dialogue`).
- It is a room-map entity, so it draws at z 0, in front of the contents' `Props` (z -10).
- `ItemPickup.lies(item, data)` is the one rule (static, pure): not owned. `is_available()` adds `is_visible_in_tree()`. `take()` calls `SaveSystem.set_item_owned(item, true)` and emits `taken(item)`; the sprite hides through `progress_changed`.

- **Its line** (STORY-16): param `talk` (a DialogueSet path) is what Ivo says as he takes it. `Player._try_pickup` reads `talk_after_take()` after the take and emits `pickup_talk_started(dialogue, at)` → `DialogueDirector.start_dialogue`, so the talk starts from the take itself and no zone can miss it. The farmhouse sword says "…Sorry. I'll need this." (`sword.tres`; bugs/the-sword-line-is-missed-when-ivo-takes-it-from-the-west-edge-of-its-reach).

## Ivo

- `PickupComponent` (`Ivo/Pickups`) reads the `DoorSensor` overlaps: `reachable()` is an available pickup.
- The Up chain is door, then talk, then pickup (`_try_door`, `_try_talk`, `_try_pickup` in `Player._process_motion`), then the helix stair and climbing.
  - All three use the one Up buffer (`UP_BUFFER`, 0.1 s, ticked every frame) and the one gate list `_free_for_up`: on the floor, no roll, swing, knockback, climb, wall slide, Memorina, stair, call, recall or fight.
  - A door or a talk in reach wins. A refused press is spent. Taking drops the other buffered presses.
- No animation: the item leaves the table, the item-acquired notice shows its icon and name (`systems/notices`) and the notebook quill announces the ITEM entry (`systems/notebook`).
- Without the sword, Ivo cannot swing (`Player._can_use_sword` reads the save), so the pickup is the start of combat in a new game.

## Today

One pickup: the sword in `threshold_farmhouse` (cell 9,8; `rest_offset` (-4, -19); `width_cells` 4).
- Its bottom centre is at room-local (300, 269), on the meal table's planks (the table prop is centred at x 304 on floor y 288; its planks' top row is y 268).
- Ivo reaches it from the floor in front of or beside the table, x 240 to 368.
- The art is `assets/sprites/world/pickups/sword.png` (42x10, contract `tools/art/prompts/pickup_sword.md`).
- The table props are the orchestrator's, under `Props` in `threshold_farmhouse_contents.tscn`.

## Debug and playtests

- A new game owns nothing in any build (STORY-14), so the sword lies on the farmhouse table in a debug run too; a playtest timeline without `owned_items` gets the runner's kit (the sword and the Memorina), so the sword shows there only with `owned_items` that leave it out.
- The playtest runner's `"owned_items": [ids]` sets the owned items to exactly that list before the scene loads (`tools/playtest/README.md`).
- `tools/playtest/scripts/sword_pickup.json` starts in the farmhouse without the sword, attacks (nothing), walks to the table, takes it with Up and swings (`playtests/2026-10-15-story02-sword-pickup`).

## The reachability audit

The sword stays in every kit's base milestone (`reach_kits.tres`, "sword"), not gained at the farmhouse. It opens no gate, and the audit models neither combat nor the pogo bounce off a struck enemy that the sword gates, so a farmhouse milestone would change no kit's reach. An orchestrator call, 2026-10-15, under the user's "base = movement and sword" (2026-10-14). The pickup's reach role CONTENT makes its floor an anchor like any reward. Revisit if a gate ever needs the sword.

## Tests

- `tests/scenes/world/interactables/item_pickup/item_pickup_test.gd`: the rule, shown and hidden both ways, a rewind puts it back, rest offset and prompt.
- `tests/scenes/characters/ivo/player_pickup_test.gd`: Up takes once, airborne refused, a press refused by a roll is spent, a press just short of the reach waits `UP_BUFFER`, a door and a talk win, the prompt hides while talking, no swing without the sword and a swing after.
- `prop_scenes_test.test_every_rooms_props_node_draws_at_minus_ten`: every contents' `Props` is at z -10, so the item draws in front of the table by z, not by tree order.
- `room_files_test`: every `i` names a known item and existing art, and the sword lies once, in threshold_farmhouse.
- `map_guide_test`: the legend and `docs/maps/README.md`.
