---
id: bugs/a-guardian-stopped-by-ivos-death-outside-the-pressure-fights-again-in-the-death-fade
type: bug
title: Guardian._on_player_died stops only the move under way; a death in a lucidity or an opening lets the leap, the call, the relapse and the AI run on in the death fade
status: resolved
severity: low
tags: [guardians, death, lucidity, finale, dissonance, grd-15, review]
related: [systems/guardians, systems/life-benches-death, playtests/2026-11-18-grd15-leaf-feel]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/finale/guardian_finale.gd
---

## Summary

GRD-15 added `Guardian._on_player_died` (guardian.gd:549-553): cancel the move, `_ai.active = false`, clear the
spawns. That covers a death in PRESSURE, the case the feel pass saw. Every other path that turns the AI back on
ignores the death, so a death outside PRESSURE does not stop the fight. The guardian goes on through the lucidity
leap, the call, the window, the relapse and back to PRESSURE, all inside the death fade. The contact box also stays
live after a death in PRESSURE.

## Symptom

Reproduced in a headless probe (the Leaf scene and Ivo on a floor; hits up to the threshold, then `Ivo.died`).
The guardian was in LUCIDITY when he died, and the AI was inactive. The guardian still leapt, sang and timed the
window out, went LUCIDITY -> RELAPSE -> PRESSURE, set `_ai.active` back to true and telegraphed a move. (The probe's
timings are not the game's: Ivo's physics was off and the leap ran to its timeout.)

The final battle can reach this in play. In the DUAL stage a mixed note calls `Player.take_dissonance`
(guardian_finale.gd:106), which damages Ivo inside a LUCIDITY window and can kill him there. The window that is left
plus a failed relapse (`relapse_time` 1.4 x `FAILED_RELAPSE_SCALE` 0.6 = 0.84 s) can end well inside the death fade:
the death clip, then `Game.death_hold` 1.0 s, then `death_fade` 1.5 s. The mentor then swings at a corpse, which is
the symptom `_on_player_died` was written to remove.

## Root cause

- `_on_phase_changed` (guardian.gd:734-738) sets `_ai.active = true` on RELAPSE -> PRESSURE without checking for a death.
- `_on_opening_ended` (guardian.gd:714-715) does the same.
- `_after_move` still counts down `_lucidity_wait` and calls `_begin_lucidity_leap` (guardian.gd:229-233). The landing
  calls `_player.open_call` and `_stage()` on a dead Ivo: the HUD, the camera pair and the dim.
- `_fight.tick` still times the window out into `_close_call(false)` (guardian.gd:241-242).
- `_contact.monitoring` is still written as `phase == PRESSURE and body_hurts()` every frame (guardian.gd:249). The box
  is `continuous`, so a corpse left inside the body is hit again each time its i-frames lapse. `Character` skips the
  wound, but `Player._react_to_hurt` still emits `hurt`, which fires the hit-stop and the camera shake.

## Fix

Fixed in GRD-15 (2026-11-19). `_on_player_died` records `_player_dead`, zeroes `_lucidity_wait` and stops the call as
well as cancelling the move. On it: every `_ai.active` writer (`_close_call`, `_on_opening_ended`, RELAPSE -> PRESSURE in
`_on_phase_changed`) leaves the AI off; the lucidity wait no longer counts down; `_fight.tick` and the window meter stop;
a leap already in the air lands without staging or opening a call (`_finish_lucidity_leap`, `_frame`, `_stage`); and the
contact box stays off. Tests (`guardian_recall_answer_test`): a death in LUCIDITY (no leap, no relapse, the AI off for
6 s, an opened window that never runs out), a death before the opening ends or as a relapse hands back, and the contact
box off over a corpse. The finale's dissonance path is not driven by a test; it reaches the same `Player.died`.

## Options considered

Record the death (for example `_player_dead := true` in `_on_player_died`). Then gate on it, in one place each:

- `_ai.active` in `_close_call`, `_on_opening_ended` and `_on_phase_changed`;
- `_lucidity_wait` and the leap;
- the window clock;
- `_contact.monitoring`.

Simpler still: in `_on_player_died`, also zero `_lucidity_wait`, stop `_call` and leave the fight in a state that
no clock advances. A test: kill Ivo during LUCIDITY and during the opening, and assert the AI is never active again
and no move is telegraphed for 6 s.

## Prevention

A "stop" handler has to cover every writer of the state it stops. Grep for `_ai.active =` before adding one.
