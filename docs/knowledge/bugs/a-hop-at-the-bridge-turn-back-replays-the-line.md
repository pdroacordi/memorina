---
id: bugs/a-hop-at-the-bridge-turn-back-replays-the-line
type: bug
title: Any jump inside the Old Bridge turn-back zone replays "Assim não." on landing
status: fixed
severity: medium
tags: [dialogue, talkable, auto-start, story-33, threshold]
related: [playtests/2026-11-17-story33-bridge-turn-back, systems/dialogue, bugs/the-bridge-turn-back-faces-east-when-ivo-stops-at-the-room-edge]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - scenes/world/interactables/talkable/talkable.gd
  - scenes/world/rooms/threshold/contents/threshold_bridge.room
---

## Summary

The Talkable at `threshold_bridge` 0,8 is 2 cells (64 px) tall, so even a 73 px tap hop lifts Ivo's body out of it. Landing re-enters the zone, which re-arms the auto start, and 0.3-0.4 s later the talk opens again. The talk blocks Ivo until Z is pressed. Every hop at the bridge wall therefore costs a modal "Assim não." box.

## Symptom

Playtest `2026-11-17-story33-bridge-turn-back`, without the sword, Portuguese locale:

- Run r4: after the first line is closed, Ivo holds right against the wall (x 6485) and jumps at t 4.8. He peaks at y 144, lands at t 6.05, and the log shows `blocked=true` with the box open again at t 6.35. The `move_left` sent at 6.4 is swallowed until Z is pressed.
- Run e1: Ivo spawns at (6405, 280), the talk opens and Z closes it, then a 0.1 s tap jump peaks 73 px up. He lands at t 3.9, and the box opens again by t 4.1.

Screenshot: `playtests/screenshots/2026-11-17-story33-bridge-turn-back/hop_replays_the_line.png`.

## Root cause

- `Talkable._on_body_entered` arms the auto start whenever `_bodies` goes from 0 to 1. `_on_body_exited` disarms it at 0 (`talkable.gd`, `_on_body_*`).
- The zone is `height_cells` 2: y 224..288 world, rising from the cell's floor. The talkable masks `Seat.PLAYER_BODY`. The body capsule is 54 tall, so any jump that lifts the feet more than ~64 px leaves the zone.
- `sword_turn_back` is `repeats` (`pending` ignores heard), so every landing counts as a new approach.

## Options considered (before the fix)

Options:
- Give this Talkable a zone at least as tall as Ivo's highest jump: 146 px with a held jump, so `height_cells` 6 or more, or the wall's 9.
- Or re-arm an auto start only when Ivo leaves the zone sideways, not when he leaves it upward.

The first is data only. Keep `talkable_rooms_test` green either way.

## Prevention

A `repeats` auto talk next to a wall that tempts a jump needs a test that jumps in place inside its zone and asserts the talk does not reopen.

## Fix (2026-11-17)

The Talkable at `threshold_bridge` 0,8 is `height_cells` 6 (192 px; a held jump peaks 146 px), so a hop stays inside the zone and never re-arms the auto start. In the same pass the wall moved onto the first step (4,7) so Ivo stops against the step's face, and `up_starts` false hides the Up prompt over empty air.

## Fix (2026-11-17, confirmed by playtest)

The Talkable at `threshold_bridge` 0,8 is now `height_cells` 6, which is 192 px, taller than the 146 px peak of a held jump. In the second run of `playtests/2026-11-17-story33-bridge-turn-back`, neither a held jump at the step nor a tap hop reopened the box. The line still repeats after Ivo leaves west and comes back.
