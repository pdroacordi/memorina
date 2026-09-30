---
name: room-map
description: Make or edit a Memorina room as a `.room` text map - ground (earth/stone), one-way ledges, water, enemies and interactables, one character per 32 px cell. Use whenever a room, level, arena, puzzle room or scenario is created or changed, when a legend character or placeable entity is added, or when the user asks to "make a map", "build a room", "design a level" or "lay out a puzzle".
---

# Room maps

Rooms are authored as text. The full reference - file format, legend, entity
params, links, Ivo's reach, errors - is `docs/maps/README.md`. Read it first;
this skill is the loop around it.

## Procedure

1. **Read `docs/maps/README.md`.** Its legend table and entity params are
   generated from the code, so they are current. Its "Sizing gaps" table is
   what Ivo can clear alone - a song puzzle must exceed it without the song
   and fit it with the song.
2. **Find or make the files.** A room is `scenes/world/rooms/<region>/<room>.tscn`
   (the trigger), `.../contents/<room>_contents.tscn` (backgrounds plus a
   `RoomMap` node) and `.../contents/<room>.room` (the map). A new room copies
   an existing contents scene and points its `RoomMap.map` at the new `.room`.
3. **Edit the `.room` text.** `[grid]` for ground, ledges and entities;
   `[water]` (same size) for water; `[entities]` for params by grid
   column,row. Write floors down to the grid's bottom row. Earth `#` where a
   song (Enraizar) may act, stone `S` where it must not.
4. **Validate.** `"<godot>" --headless --path . --import`, then the suite
   (`tests/scenes/world/rooms/maps/room_files_test.gd` checks every map). Fix
   what the errors name (file:line:column).
5. **Look at it.** A playtest timeline with `player_position` in the room
   (`tools/playtest/`, or the `godot-playtest` skill).
6. **Keep the guide true.**
   - Added a legend character or an entity export, or retuned Ivo's jump:
     `"<godot>" --headless --path . res://tools/maps/gen_map_docs.tscn`
     (`map_guide_test.gd` fails until you do).
   - Introduced a new convention (a new section, a new kind of link, a new
     placement rule): write it into the prose of `docs/maps/README.md` in the
     same change. The generated sections cover data; conventions are yours to
     record.

## Rules

- Never paint a room's ground in the editor or edit a `RoomMap` node's built
  children - they are a preview, rebuilt from the text and never saved.
- Never hard-code what a character means anywhere but
  `resources/world/maps/room_legend.tres`.
- Guardians and their `Arena` stay in the contents scene (a guardian's
  `arena_path` is a NodePath to its sibling); everything grid-aligned goes in
  the map.
