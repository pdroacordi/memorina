---
id: bugs/a-jump-buffered-in-the-air-with-down-held-drops-through-a-ledge-on-landing
type: bug
title: A jump buffered in the air with Down held drops Ivo through a `=` ledge on landing instead of jumping
status: resolved
severity: medium
tags: [ledge, one-way, drop-through, jump-buffer, input, player, world-19]
related: [architecture/drop-through-ledges, systems/input, systems/rooms, bugs/a-press-buffered-into-the-boarding-frame-acts-on-the-helix-stair]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/jump_component.gd
  - scenes/characters/components/ledge_drop_component.gd
---

## Summary

The drop branch in `Player._try_jump` (player.gd:1412-1413) checks `on_floor` when the buffered jump
fires, not where the press was made. A press made in the air up to `jump_buffer_max` (0.12 s) before
landing on a `=` ledge with Down held fires on the landing frame with `on_floor` true, so Ivo drops
through instead of jumping. `architecture/drop-through-ledges` ("Jump buffer") and the code comment at
player.gd:1412 both say this case is a jump.

## Symptom

Found in the WORLD-19 review (2026-11-23) and confirmed with a headless probe that uses the real `ivo.tscn`
on the `player_ledge_drop_test` room: Down held from the start, Ivo falling onto the row-4 `=` span,
jump pressed at y 118.6 while still in the air (ledge top 128). `dropped_through` fired 2 frames later,
on the landing frame. `jumped` never fired, and Ivo ended on the floor below (y 224).

Players hold Down in the air for the camera peek, and for the pogo (Down + attack). A player who pogoes
onto a ledge and presses jump just before landing goes through the ledge, and possibly into the pit
under it.

## Root cause

`_try_jump(on_floor)` receives the `is_on_floor()` from the start of the frame. On the first frame after
a landing that is already true, and `get_slide_collision_count()` already holds the floor contact that
`LedgeDropComponent._floor_room` reads. The jump buffer does not record whether Ivo was on the floor at
the press (`JumpComponent.buffer_jump`, jump_component.gd:27), so "on the floor when the buffer fires"
cannot tell an on-floor press from a press made in the air.

None of the `player_ledge_drop_test` cases presses jump in the air.

## Fix

Fixed 2026-11-23 (see Resolution). As suggested: record the floor state at the press. For example,
`JumpComponent.buffer_jump()` stores `_buffered_on_floor := _body.is_on_floor()` (cleared with the
buffer), and the drop branch also requires it. An on-floor press is read against the last physics step,
which is the same floor that `try_drop` reads. Both keys pressed in one frame on the floor still drop.
Add a `player_ledge_drop_test` case: Down held, jump pressed 1-2 frames before landing on `=`. It
expects one `jumped` and no `dropped_through`.

## Prevention

A buffered press fires on a later frame. Any branch that decides what a buffered press means from state
read at fire time (`on_floor`, a held axis) must check that state against the frame of the press too.
This bug and `bugs/a-press-buffered-into-the-boarding-frame-acts-on-the-helix-stair` share that shape.

## Resolution (2026-11-23)

`JumpComponent.buffer_jump()` stores `_buffered_on_floor` from `is_on_floor()` at the press, cleared with the buffer and on launch; `buffered_on_floor()` answers it while a press is buffered. `Player._try_jump`'s drop branch requires it beside `on_floor`. `player_ledge_drop_test.test_a_jump_buffered_in_the_air_with_down_held_jumps_on_landing` (Down held, jump pressed about 12 px above the `=` span, past coyote) expects one `jumped` and no `dropped_through`.
