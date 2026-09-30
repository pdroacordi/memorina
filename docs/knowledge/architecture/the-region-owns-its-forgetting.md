---
id: architecture/the-region-owns-its-forgetting
type: architecture
title: A place is not the boss's to own - the region holds its wells of forgetting
status: active
tags: [regions, rooms, memory-field, guardians, ownership, solid]
related: [architecture/memory-field-cpu-gpu-split, architecture/guardian-fight-phase-machine, bugs/a-restored-region-kept-its-crater]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/world/rooms/region_memory.gd
  - scenes/world/rooms/region.gd
  - scenes/world/game.gd
  - globals/save_system.gd
  - scenes/characters/guardians/guardian.gd
---

## Decision

"How much of this region is remembered right now" is owned by one node, `RegionMemory`,
a child of the `Region` whose `MemorySource` children ARE the region's wells of
forgetting. `Region` keeps identity (season, which guardian) and delegates; `Game` is the
only writer of `MemoryField.baseline`; `Guardian` owns nothing of the place at all.

## The problem it replaces

Nothing owned it. Three layers each kept a piece:

- `Region.memory_baseline` + `current_baseline()` - the authored value.
- `Game._on_player_entered_room` - pushed it into the field, ONLY at a doorway.
- `Guardian._lift_region()` - found the field by group and tweened the GLOBAL baseline
  itself, because nothing else could react to a restoration that happens while the player
  is already standing in the room. The well itself was a `Corruption` node authored
  inside the guardian's own prefab, pinned `top_level` to wherever the guardian spawned.

So a CHARACTER owned a piece of LEVEL geometry and wrote global world state.

## The mechanism that makes room-level authoring impossible

`MemoryField.sample()` skips any source that is not `is_visible_in_tree()`, and
`Room.deactivate()` hides a room's contents. A well authored inside a room - or inside a
guardian standing in one - can therefore only be felt from inside that room. Home Village
is three rooms. Design section 4.1 describes the memory of a REGION, not of a room, and
section 4.3's death marks accumulate per region; authored in room contents they would be
destroyed outright by `Room.evict()`.

Authoring the wells in the region's own composition scene fixes this for free: a region
scene is always resident, so its sources are always registered and always visible.
Measured from Downtown with Bloom Hollow deactivated: the arena's well reads 0.05 and
downtown's own 0.10 - identical to the readings from inside the arena.

## Shape

    Region (Node2D, the composition scene)
      Memory (RegionMemory)           authored, lift_time, changed(level)
        DowntownWell    (MemorySource, -0.70)
        BloomHollowWell (MemorySource, -0.75)
      Downtown / Woods / BloomHollow  (Room)

- `RegionMemory.restore(seconds)` tweens its level to 1.0 and every well's `strength` to
  0, then hides them. `seconds <= 0` assigns instead - that is a later visit, loaded
  already whole rather than lifted. `tween_method`, not `tween_property`, so `changed`
  fires as it climbs instead of leaving listeners to poll. `TWEEN_PAUSE_PROCESS`, because
  a lesson freezes TIME, not MEMORY.
- `RegionMemory` never touches `SaveSystem`. Whether the guardian is restored is the
  `Region`'s judgement, pushed in - the same rule components already follow.
- `Region` re-emits `RegionMemory.changed` as `memory_changed`, so consumers listen to the
  region rather than to its parts (the idiom `Player` already uses for `jumped`).
- `Game` connects to it through the rooms it is already walking (`Room.get_region()`), so
  no new group, and writes the field only while that region is the one being shown.

## Why SaveSystem announces it

`SaveSystem.restore_guardian()` gained `signal guardian_restored(guardian)`. The obvious
alternative - `Guardian.restored`, which already existed and which NOTHING was connected
to - requires the guardian's room to be resident and the region to find it. The save is
the one thing that knows, whatever order the world loaded in. The autoload stays thin: it
announces a change to state it already holds.

## Consequences

- Restoring a guardian now restores the whole region, including rooms it never entered.
- `MemoryField.baseline` has exactly one writer.
- Death marks have somewhere to live.
- A region with several rooms, or several guardians, needs no new machinery.

## Known gap

`Region.guardian` and the arena prefab's `GuardianStats.id` are authored independently and
nothing asserts they agree. Set them inconsistently and the fight restores, the save
records it, and the region silently never lifts.
