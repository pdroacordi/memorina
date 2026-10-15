---
id: gotchas/a-redoma-shell-is-standable-ground-up-to-192-px-over-its-origin
type: gotcha
title: A Redoma shell is standable ground up to 192 px over its origin; a one-way gap has to beat the double jump plus that
status: active
tags: [rooms, room-map, reach, one-way, redoma, bell-jar, double-jump, world-35]
related: [systems/bell-jar, systems/rooms, systems/world, bugs/a-redoma-shell-is-a-step-up-the-lake-icefall-switchback, gotchas/a-one-screen-shaft-cannot-shut-out-wall-climb, architecture/room-reachability-audit]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/memory/song_effects/shell/frost_shell.tscn
  - resources/memory/bell_jar_pulse_stats.tres
  - scenes/world/rooms/frozen_lake/contents/lake_icefall.room
---

# A Redoma shell is standable ground

**Rule:** a gap meant to stop a kit that knows Redoma has to be taller than the double jump plus a shell: 270 + 192 =
462 px, about 14.5 rows over any floor the kit can play the song on, plus the 54 px body for a ceiling.

- **Why.** A `FrostShell` is solid from outside and Ivo may stand on it (`systems/bell-jar`). Its top is up to 192 px
  (`bell_jar_pulse_stats.tres` `max_radius`) over the origin it was played at. From the shell's top, a jump and a
  double jump add 270 px.
- **The kit check cannot see it.** `ReachGrid.for_kit` does not model a shell as ground, so a gap the audit calls
  one-way can still be climbed with Redoma. Check those gaps by numbers, and say where the numbers live.
- **Measured (WORLD-35 step 3 review, 2026-10-14).** On lake_icefall's first-draft switchback, a shell on the row-45
  landing put Ivo 146 px up. Jump and double jump then landed him on the row-36 landing, 9 rows (288 px) higher, so
  "+both" climbed the icefall (`bugs/a-redoma-shell-is-a-step-up-the-lake-icefall-switchback`).
- **The built icefall.** One straight shaft, standable only at its mouth. Its bottom (y -384) lies 544 px over
  threshold_bridge's highest floor (the east deck, y 160). The deck plus a shell plus a double jump reaches feet
  y -302, 146 px short of leaving the bridge for lake_icefall (y -448).
- A shell also counts toward a swap into a room above. `RoomExit` leaves a room upward once the feet are 64 px over its
  top, landing or not (`bugs/a-double-jump-on-threshold-bridge-enters-lake-icefall-and-spends-the-frozen-lake-title`).
