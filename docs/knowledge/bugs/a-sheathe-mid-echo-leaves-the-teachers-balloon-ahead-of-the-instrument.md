---
id: bugs/a-sheathe-mid-echo-leaves-the-teachers-balloon-ahead-of-the-instrument
type: bug
title: Sheathing mid-echo resets the instrument's PhraseEcho but not the teacher's TeachingFlow count, so after a redraw one right note lights the whole balloon and the teacher never sings the phrase again
status: resolved
severity: medium
tags: [core-04, teachers, echo, phrase-echo, teaching-flow, balloon, sheathe, desync]
related: [systems/teaching-creatures, architecture/teaching-creatures, systems/songs-and-the-memorina, playtests/2026-10-29-core04-teaching-creatures]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/ivo/abilities/memorina_component.gd
  - scenes/world/creatures/teaching_creature.gd
  - scenes/world/creatures/teaching_flow.gd
  - scenes/characters/ivo/player.gd
---

## Summary

The echo's progress lives in two places: `PhraseEcho._count` (the instrument) and
`TeachingFlow._count` (the teacher's balloon and repeat clock). A plain sheathe (the
draw key pressed again) resets the first and tells the teacher nothing, so the two drift apart.

## Symptom

Found in the CORE-04 review (code trace, not yet playtested). At the thrush (R R R): draw,
play R R (two glyphs lit), press draw to sheathe, stay in reach. The teacher stays silent
for as long as Ivo waits. Redraw and play one R: all three glyphs light, but nothing happens.
Two more R are needed before the flourish. Snail (L R L): L R, sheathe, redraw, L gives the same
result.

## Root cause

- `MemorinaComponent.sheathe()` (`memorina_component.gd:95-103`) calls `_echo.reset()` and
  emits only `sheathed`. Unlike `interrupt()` (`:105-114`), it emits no `sequence_failed` when the echo has
  progress.
- The toggle path `Player._try_memorina()` (`player.gd:789-793`) calls `_memorina.sheathe()`
  directly.
- `TeachingCreature` (`teaching_creature.gd:73-83`) does not connect `memorina_sheathed`, so
  `TeachingFlow._count` keeps its value. `note_echoed()` (`teaching_flow.gd:92-100`) then
  increments from the stale count and emits `lit(_count)`. `tick()` in LISTENING
  (`teaching_flow.gd:157-162`) returns while `_count > 0`, so `repeat_after` never runs.

## Playtest confirmation (2026-10-29)

Reproduced twice in the real game (`playtests/2026-10-29-core04-teaching-creatures`), with
`tools/playtest/scripts/core04_sheathe_mid.json` run through `tools/playtest/scripts/core04_probe_driver.gd`. Snail,
Ivo at (944,-1672), fresh save:

| t (s) | input | Ivo's echo | flow / balloon |
|---|---|---|---|
| 2.30 | draw | open, 0 | LISTENING, lit 0 |
| 2.60, 3.00 | L, R | 2 of 3 | lit 2 |
| 3.50 | draw (sheathe) | reset to 0 | LISTENING, **lit 2** |
| 3.5-9.3 | none | | **no repeat** for 5.8 s (repeat_after 4 s), and the balloon shows 2 lit |
| 9.70 | L after a redraw | 1 of 3 | **lit 3** (looks complete, nothing saved) |
| 10.10, 10.50 | R, L | complete | FLOURISH, the half saved (the save stays correct) |

Frames: `playtests/screenshots/2026-10-29-core04-teaching-creatures/sheathe_mid_echo_keeps_two_lit.png`. At 3.10 s, 2 lit;
at 9.00 s, still 2 lit and silent; at 9.80 s, all 3 lit after one L.

## Fix

Resolved 2026-10-29 by the first option below (see Resolution). The options were:
- Have the flow hear the reset: `TeachingCreature` connects `Ivo.memorina_sheathed` and, while it
  owns the echo, calls a new `TeachingFlow.echo_cleared()` (count 0, `lit(0)`, LISTENING
  repeat clock restarted).
- Or make `sheathe()` emit `sequence_failed` for echo progress, as `interrupt()` does. This also
  plays the mistake sound, which may not be wanted for a voluntary sheathe.

## Prevention

Add a `teaching_creature_test` case: two right notes, `sheathe()`, redraw, one right note.
Assert the balloon lights one glyph and the flow repeats after `repeat_after`. As a general
rule, every path that resets `PhraseEcho` must have a matching path in the teacher.

## Resolution (2026-10-29)

`TeachingCreature` connects `Player.memorina_sheathed`; while the echo is its own it calls `TeachingFlow.echo_cleared()`, which in LISTENING with progress sets the count to 0, emits `lit(0)` and restarts the `repeat_after` clock. No mistake sound for a voluntary sheathe. After a mistake the count is already 0, so the clear does nothing and the retry at `sequence_reset` still comes; after a plain half `learn_song_half` closes the echo before it sheathes, so the flourish is untouched. Tests: `teaching_flow_test.test_a_cleared_echo_unlights_and_repeats`, `test_a_clear_after_a_mistake_keeps_the_retry`, `teaching_creature_test.test_a_sheathe_mid_echo_resets_the_teacher` (L R, sheathe: unlit; the teacher sings again; redraw, L lights one glyph).
