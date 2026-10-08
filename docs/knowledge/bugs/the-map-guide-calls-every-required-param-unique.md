---
id: bugs/the-map-guide-calls-every-required-param-unique
type: bug
title: The generated map guide says every required entity param is "unique across every map", which is false for a door's link and to_room
status: active
severity: low
tags: [maps, map-guide, generated-docs, legend, doors, world-09]
related: [architecture/doors-and-interiors, systems/rooms]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/rooms/maps/map_guide.gd
  - docs/maps/README.md
---

## Summary

`MapGuide` writes `**required** - unique across every map` for every name in an entry's
`required_params`. Since WORLD-09, `E` (Door) has two required params that are not unique, so
the guide tells authors something false.

## Symptom

The `E` - Door table in `docs/maps/README.md` reads:
- `link` | **required** - unique across every map
- `to_room` | **required** - unique across every map

In fact a `link` is shared by exactly two doors, and many doors name the same `to_room`. Both
doors of `door_trial.room` name `door_trial_inside`. The legend description beside the table
says the opposite ("Each link joins exactly two doors"). An author or agent who trusts the
table writes a unique link per door, and `room_files_test` then fails with "used by 1 doors".

## Root cause

`scenes/world/rooms/maps/map_guide.gd:72` hard-codes uniqueness in the text for a required
param. Until WORLD-09 every required param was a save or bench id (`save_id`, `bench_id`) and
really was unique, so the shortcut held.

## Fix

Open. Write `**required**` alone, and keep any uniqueness rule in the entry's `description`
(the brute's and the bench's descriptions already say "unique across every map"). Then
regenerate the guide (`tools/maps/gen_map_docs.tscn`).

## Prevention

Generated text should state only what the generator knows. "Required" comes from
`required_params`; uniqueness is a rule of each entity, and the validator and
`room_files_test` enforce it per entity.
