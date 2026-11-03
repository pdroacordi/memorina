---
id: bugs/region-scenes-set-music-before-their-script-so-no-region-plays-a-theme
type: bug
title: The six region scenes write `music =` above `script =`, so `Region.music` is null at runtime and no region theme ever plays
status: fixed
severity: high
tags: [music, regions, tscn, property-order, song-16]
related: [playtests/2026-11-03-music-levels-and-sync, systems/music]
created: 2026-11-03
updated: 2026-11-03
source_files:
  - scenes/world/rooms/home_village.tscn
  - scenes/world/rooms/threshold.tscn
  - scenes/world/rooms/spring_woods.tscn
  - scenes/world/rooms/frozen_lake.tscn
  - scenes/world/rooms/wind_orchards.tscn
  - scenes/world/rooms/summer_caldera.tscn
---

## Summary

SONG-16 (commit 2e385e24) put `music = ExtResource("99_music")` on the region root node **before**
`script = ExtResource("1_region")` in all six region scenes. On instancing, Godot applies node properties in file
order: `music` is set while the node is still a plain `Node2D`, which has no such property, so it is dropped. The
script is attached next, and `Region.music` keeps its default `null`. `RegionMusic.on_room_changed` then sees a
region without a cue and requests nothing: the world is silent everywhere outside a guardian fight.

## Evidence (playtest 2026-11-03)

- `audio_probe.gd` in a windowed run: `RegionMusic._region` = HomeVillage, then SpringWoods; `region.music = <null>`,
  `_request = <null>`, `Music._requests.size() = 0`, Music bus peak -200 dB for the whole 20 s walk.
- The packed scene's state lists `music` as the node's first property, before `script`
  (`PackedScene.get_state().get_node_property_name(0, 0) == "music"`).
- With the probe assigning `load("res://resources/music/region_<scene>.tres")` to each Region at runtime
  (`AUDIO_FIX_REGION=1`) the themes play, crossfade on the village/woods seam and follow memory as designed.

## Fix direction

Move `music = ...` below `script = ...` in each region `.tscn` (or re-save the six scenes from the editor). A test
that instantiates each region scene and asserts `music != null` would catch it; `music_cue_test` checks the
resources, not that the scene keeps them.

## Resolution (2026-11-03)

The six scenes now set `music` after `script`. Re-check `region5` in `playtests/2026-11-03-music-levels-and-sync`: the
village and woods themes play from the scenes themselves, and they crossfade and follow memory as designed.
