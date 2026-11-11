---
id: bugs/a-gust-never-breaks-a-song-played-at-a-downwind-lip
type: bug
title: MEM-16's lip hold zeroes a standing Ivo's wind slide at a ledge, so is_still() holds and a gust never breaks a drawn Memorina there
status: resolved
severity: medium
tags: [air, wind, mem-16, memorina, is-still, song-break, ledge]
related: [playtests/2026-11-11-mem16-gust-feel, systems/air, systems/songs-and-the-memorina, bugs/the-winter-squall-never-breaks-a-song-at-the-trials-memory, bugs/a-hazard-respawn-puts-ivo-back-into-the-gust-that-dropped-him]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - scenes/characters/ivo/player.gd
---

## Summary

Open (found in review of the uncommitted MEM-16 change, not yet played). `Player._hold_the_lip`
sets `velocity.x = 0` whenever there is no move input and the wind slides Ivo toward a lip.
`move_axis()` is 0 while the Memorina is drawn, so the hold also runs during a performance.
`is_still()` then sees zero speed and the gust never interrupts the song.

## Details

- `player.gd:584-595`: the hold is gated only on `move_axis()`, velocity and carry. It has no
  `is_memorina_drawn()` gate and does not mark the frame as moved.
- `player.gd:382-383`: the song breaks only on `not is_still()`. `is_still()` (line ~500)
  reads `absf(velocity.x) < STILL_SPEED_EPSILON`, which the hold has just made 0.
- Repro by reading: stand on the floor, downwind of the gust, with the lip ahead in the gust's
  direction. A gust slides Ivo to the lip and the hold parks him there with velocity 0 every
  frame. Draw in the gust (or in the calm before it) and play. Each frame `ground_update` steers
  toward the drift and the hold zeroes it again, so nothing breaks the song. Mid-floor, the same
  gust breaks the song on its first moving frame.
- This breaks the air.md rule "a gust does [break a standing performance], through the existing
  `is_still()`" in exactly the places where the wind pushes toward a drop. The winter squall
  puzzle is not exposed: its wind blows west and the floor's west lip (col 29) lies outside the
  zone (cols ~41-51). Any other `WindZone`, and every regional-weather room with a downwind lip,
  is exposed.

## Fix (proposed)

Have the hold count as motion for the song but not for the body: when `_hold_the_lip` zeroes a
slide, set a per-frame flag that `is_still()` reads as not still (or interrupt the performance
there). A parked, braced Ivo then cannot play through a gust, the same as on open floor.

## Prevention

Anything that cancels wind motion must say whether the wind still counts as moving Ivo for
`is_still()`. Add a `player_wind_test` case: drawn at a downwind lip, a gust over the deadzone
must interrupt the Memorina.

## Play evidence (2026-11-11, `playtests/2026-11-11-mem16-gust-feel`)

- **Before the fix** (code of 16:50, run `lip2`): forced memory 1, Ivo turned west and slid to threshold_bridge's east
  lip (x 7136.0, held from t 7.94). The draw at t 8.11 was accepted in a 220 px/s gust, and all six FREEZE notes
  sounded (t 8.40-9.75) with velocity 0. The song broke only at t 9.91, as the gust fell (strength 0.87), when the drawn
  half-shelter drift shrank to a sub-pixel step that the ray no longer saw cross the lip. The same draw stopped at
  x 7136.5 (`lip5`) broke at once: an 8 px/s step left the ray over ground. Mid-deck (`ctl5`) the draw was refused. At
  the lip the outcome depended on the sub-pixel stop point.
- **After the fix** (`_lip_held_frame`, 17:00:29; runs `lip6`, `lip6b`, `lip2b`): the draw at the held lip is refused
  in all three runs (`is_still()` false, velocity 0, every other gate false), the same as mid-deck.
