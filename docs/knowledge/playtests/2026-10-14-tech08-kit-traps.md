---
id: playtests/2026-10-14-tech08-kit-traps
type: playtest
title: TECH-08 kit traps - woods_deep's shaft exit at col 44 and the root wall
status: active
build: 443079b (TECH-08 uncommitted)
area_tested: "woods_deep pit: the east bank's single-jump exit over col 44, the root wall at col 32 closed without Enraizar and gone with it"
tags: [rooms, kit-check, woods-deep, enraizar, progression]
related: [bugs/the-woods-deep-pit-shaft-traps-a-kit-without-the-double-jump, architecture/room-reachability-audit, systems/rooms]
created: 2026-10-14
updated: 2026-10-14
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-14-tech08-kit-traps/01_shaft_bank.png
  - screenshots/2026-10-14-tech08-kit-traps/02_shaft_exit_block_top.png
  - screenshots/2026-10-14-tech08-kit-traps/03_shaft_exit_corridor.png
  - screenshots/2026-10-14-tech08-kit-traps/04_root_wall_closed.png
  - screenshots/2026-10-14-tech08-kit-traps/05_root_wall_open_with_enraizar.png
---

# TECH-08 kit traps: woods_deep's shaft exit and the root wall

Timelines: `tools/playtest/scripts/tech08_shaft_exit_single_jump.json`, `tech08_root_wall_closed.json`,
`tech08_root_wall_open_with_enraizar.json`. Windowed, `game.tscn`, debug save (sword and Memorina, no skills).

## Results

- **Shaft exit, no double jump:** PASS. From the east bank (feet -3088, 288; col 43, row 32), one jump with right
  pressed 0.2 s into the rise lands on the block top at (-2997.5, 192): col 46, row 30. Walking on drops into the east
  corridor at (-2885.6, 288). Before the fix this bank was a dead end for every kit without the double jump.
- **Root wall, no songs:** PASS. From the east bank (col 40) the wall stands at col 32, from the bank up into the slab's
  notch, across the pool. The kit check shows the wall is the only way west for a Redoma walker.
- **Root wall, Enraizar known (`known_songs: [6]`):** PASS. Same spot and frame: the wall is gone; the west bank's grass and
  the back wall behind the notch show.

## Notes

- The open col-44 cells show the backdrop, as the shaft beside them does. The pocket's `[back]` wall at rows 31-33 is
  unchanged. The block top now reads as a plain step down to the corridor.
- Not driven: growing the Enraizar bridge across the pool (the note input) and the drop into woods_root_caves after it.
  `reach_kit_check_test` and `room_kit_test` cover the route. The bridge's earth end (32,33) keeps air above it in the
  map, so `RootSpanFinder` still finds the span.
- What stills cannot show: whether the 0.2 s delay before steering into the opening feels natural. In the log the jump
  rose 112 px by t 1.5 and cleared the opening. A held right from the take-off may bump the shaft's east lip at row 30
  first; that was not tested.
