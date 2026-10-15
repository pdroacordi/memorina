---
id: bugs/a-redoma-shell-is-a-step-up-the-lake-icefall-switchback
type: bug
title: A Redoma shell played on a lake_icefall landing is a step about 150 px high, so double jump plus Redoma climbs the 9-row gaps that make the icefall one-way
status: resolved
severity: low
tags: [world-35, rooms, one-way, redoma, bell-jar, double-jump, kit-check, frozen-lake]
related: [systems/world, systems/bell-jar, systems/rooms, gotchas/a-one-screen-shaft-cannot-shut-out-wall-climb, architecture/room-reachability-audit]
created: 2026-10-14
updated: 2026-10-15
source_files:
  - scenes/world/rooms/frozen_lake/contents/lake_icefall.room
  - scenes/world/memory/song_effects/shell/frost_shell.tscn
  - resources/memory/bell_jar_pulse_stats.tres
---

## Summary

WORLD-35 step 3 (uncommitted, on a665105). The docs say the icefall is one-way for every kit without wall climb,
because the gap from the row-45 landing up to row 36 is 9 rows (288 px) and the double jump rises 269 px. A
`FrostShell` is solid from outside and Ivo may stand on it (`systems/bell-jar`), so it adds about 150 px. The
"+both" kit (double jump and Redoma) climbs the gap. The kit check does not model a shell as ground, so it cannot
see this.

## Symptom

Scratch timeline (review, 2026-10-14): `skills [0, 2]`, `known_songs [0, 1]`, Frost restored.
- Redoma played at (7090, -480) on the row-45 landing, under the row-36 landing's open end (cols 1-6).
- Ivo walks east out of the ring, runs back west under the row-36 landing and double-jumps once past its west
  edge. He lands on the shell at (7218, -626), 146 px over the landing.
- Jump and double jump with right held: apex feet -838, landing on the row-36 landing at (7414, -768).

Played at col 4 instead, the shell's top is out of reach: between the shell and the row-36 landing's underside
there is 50 px, less than Ivo's 54 px. The step works where the ring's top sits under the open end.

## Root cause

The one-way claim counted jumps only. A Redoma shell is a temporary floor up to 192 px over the pulse origin.

## Fix

Resolved 2026-10-15. The switchback's landings, the only floors a shell could be played on inside the icefall, are gone.
- lake_icefall is one straight shaft, standable only at its mouth, 1792 px over threshold_bridge's east deck.
- From any floor under it, a double jump plus a shell (192 + 270 = 462 px) ends far below lake_icefall's bottom
  (y -384); from the deck the feet reach y -302.
- The kit check still does not model a shell. The margin is checked by numbers in `systems/world` and the room
  headers, and recorded in `gotchas/a-redoma-shell-is-standable-ground-up-to-192-px-over-its-origin`.

## Prevention

A one-way gap must exceed the double jump plus the highest temporary floor the kit can make: a Redoma shell (up to
192 px over its origin), an ice sheet, a root span.
