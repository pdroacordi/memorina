---
id: architecture/roots-join-earth-to-earth
type: architecture
title: Enraizar reads where roots can grow from the room map and grows them by the pulse, frame by frame
status: active
tags: [enraizar, roots, root-span-finder, climbing, climbable, room-map, pulse-effect]
related: [architecture/rooms-are-text, architecture/weight-and-presence]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/memory/song_effects/roots/root_span_finder.gd
  - scenes/world/memory/song_effects/roots/root_strands.gd
  - scenes/world/memory/song_effects/roots/root_grower.gd
  - scenes/world/memory/song_effects/roots/root_span_view.gd
  - scenes/characters/components/climb_component.gd
  - scenes/world/interactables/climbable/climbable.gd
---

## Summary

The room is text, so the song can read the ground's MATERIAL: `RootSpanFinder` scans the
`RoomMap` for earth faces that face each other (bridge, shaft, pillar) and ignores stone.
`RootGrower` then grows two strands per crossing only while both faces are in the clean
disc, at the memory under each tip, and withers a face the pulse lets go of. Climbing is a
generic component on a `Climbable` place.

## Why

Design 02 section 7.1: "raizes ligam terra a terra", no aiming - the player positions so
the pulse covers both ends. Authoring nothing per puzzle means any earth geometry in any
room answers the song; the puzzle is the room and the pulse radius.

## Gotchas / pitfalls

- A ledge in the middle of a chasm, placed so the pulse covers both banks, is also a
  stepping stone across it. The trial's ledge is low and off-centre: the near bank is in
  reach (no trap), the far one is not, and Enraizar's radius is sized to that.
- Growing one strand before the other in the same step let the first take the whole gap:
  they now grow at once and share what is left.
- A 180-degree rotated sprite draws its art on the other side of its line; centre it with
  the sprite's local `offset`, not its position.
