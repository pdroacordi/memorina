---
id: bugs/a-direction-held-when-the-map-opens-pans-it-off-ivo
type: bug
title: A walk direction still held when the map opens pans it at once, so a map opened while walking is not centred on Ivo
status: fixed
severity: medium
tags: [map, input, pan, stick, arrows, menu-input, ui]
related: [systems/map, playtests/2026-10-06-map, architecture/map-reveal-seen-cells-per-room, systems/screens, systems/input, gotchas/a-stick-is-pressed-on-every-motion-event]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/ui/map/map_screen.gd
  - scenes/ui/menu/menu_input.gd
---

## Summary

`MenuInput.pan` polls `Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")`. The arrows
and the left stick are also `move_left` / `move_right`. A player who presses M or LB while
walking still holds the direction, and `MapScreen._process` reads it as pan intent from its first
frame. The map opens on Ivo and slides away to the clamp edge within half a second. This breaks
the user's decision that the map opens centred on Ivo, in the most common way to open it.

## Symptom

Reproduced on 5a5f9c8 + the uncommitted UI-04 tree. Timelines:
`tools/playtest/scripts/map_opened_while_walking.json` (stick) and `map_blocks_ivo.json` (Right
arrow). Ivo walks right from x 1000 in Woods; LB at t 2.6 s with the stick still at +1.0:

| t after LB | Ivo x | map centre x |
|---|---|---|
| 0.02 s | 1301.8 | 1329 |
| 0.15 s | 1302.7 | 1655 |
| 0.50 s | 1302.7 | 1745 (seen area's right edge, the clamp) |

The keyboard run is the same: Right held, M at t 2.6 s, centre 1745 at t 2.9 s with Ivo at 1302.7.
Screenshot: `playtests/screenshots/2026-10-06-map/open_while_walking_pans_away.png` (the
seen box's right edge sits at screen centre). The same applies vertically to a held Up/Down.
Up is `ui_up`, and on the pad also the stick's look axis.

## Root cause

- `MapScreen.open()` calls `set_process(true)` (map_screen.gd:48-56). The first `_process` reads
  `menu_input.pan` (map_screen.gd:35-44), which is polled state, not an event.
- The held move direction is already pressed on `ui_left`/`ui_right` when the map opens, so it
  pans at full speed: 160 pack px/s, which is 2560 world px/s at 4 px per cell.
- `PlayerInput.blocked` stops the same direction from moving Ivo, but nothing stops it from
  reaching the map.

## Fix

Fixed 2026-10-06 (UI-04 round 2), with the per-axis variant below.
- `MapScreen.pan_held(pan, seconds)` keeps `_pan_armed` per axis. `open()` resets it to zero, and an axis is armed the first time it reads zero.
- A walk direction held through the open is therefore ignored until it is released, while an axis at rest (Up while Right is still held) pans at once.
- The same method caps each frame's step at `MAX_PAN_SECONDS` (0.05 real s).

Evidence:
- `map_screen_test`:
  - `test_a_direction_held_through_the_open_does_not_pan`;
  - `test_each_axis_arms_on_its_own`;
  - `test_reopening_disarms_the_pan`;
  - `test_a_hitch_pans_one_capped_step`.
- `map_opened_while_walking.json` (stick +1.0 held, LB at 2.6 s) logged Ivo at 1301.8 → 1302.7 and the map centre at 1300 at 0.02, 0.15 and 0.5 s after LB and after the release; before the fix it was 1655, then 1745.
- `map_blocks_ivo.json` (Right held, M): the centre stays at 1300 with Right held.
- Screenshot: `playtests/screenshots/2026-10-06-map/open_while_walking_fixed.png`, the seen box centred.

Options considered:
- Latch the pan on open. `MapScreen` ignores `pan` until it has read `Vector2.ZERO` once, so a
  held direction must be released before it pans. One bool and no new input reader; it stays
  inside `MapScreen`.
- Ignore it per axis: re-arm each axis separately, so releasing Right does not wait for a
  held Up.
- A grace time after the open is worse: a stick held longer than the grace still drags the map
  away.

## Prevention

Add a `MapScreen` suite case: open with a non-zero `pan` stub, step `_process`, and assert
that `centre()` is still the subject's position until the stub reads zero.
