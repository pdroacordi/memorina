---
id: bugs/sitting-is-not-gated-on-a-guardian-fight
type: bug
title: Ivo can sit (heal, save, wake rooms) in the middle of a guardian fight, and while seated the recall is neither cued nor timed
status: fixed
severity: medium
tags: [bench, sit, guardian, recall, qte, save, player, frost-guardian]
related: [architecture/the-life-loop-rewinds-by-reloading, bugs/presses-made-while-sinking-fire-on-respawn]
created: 2026-10-01
updated: 2026-10-01
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/world/game.gd
  - scenes/world/rooms/frost_edge/contents/lighthouse.room
  - scenes/world/rooms/frost_edge/contents/lighthouse_contents.tscn
---

## Summary

`Player._try_sit` (player.gd:511-526) refuses only while a call is STAGED
(`_staged_caller`). It does not refuse during PRESSURE, while a recall is pending or open,
or in the second between the recall and the lucidity leap. The `frost_edge_approach_bench`
sits inside the Frost Guardian's arena, so all of these can be reached. While Ivo is
seated, `_process_motion` returns (player.gd:296-302) before `_recall.tick` and
`_tick_pending_recall`, so the QTE stops: its cue is not checked and its window does not
drain.

## Symptom

Found in review of 1d02d6f..5319a40. Reasoned from the code; not captured in the engine.

- **Mid-fight rest.** The lighthouse room is the arena: the `Arena` rect is the same
  1920x602 rect as the room. The bench is at x of about -1264, and the guardian starts at
  170 with an `ArenaTrigger` radius of 560. Once the fight has begun, Ivo backs off to the
  bench (the guardian follows him to keep its spacing) and presses down. He is healed to
  full, `SaveSystem.rest_at` commits the save mid-fight, and `_wake_rooms` runs. He can
  repeat this between every exchange. Decision 6 asked for a bench on "the Frost Edge
  approach BEFORE the lighthouse".
- **Recall opened while seated.** The charge carries the ROLL recall. If its cue is met
  when `begin_recall` arrives (player.gd:780-786 ticks once with 0), `_open_recall` arms
  the window and `WorldFreeze.slow()` drops the world to 0.2. The window is never ticked
  again while he sits. When the player presses roll, the press goes through
  `_unless_seated` (player.gd:535), which only stands him up and drops the
  `_roll.buffer_roll`. The `_notify_recall(&"roll")` connection (player.gd:228) still
  fires, though, so the skill is unlocked with NO dodge. That breaks "the press that
  remembers also acts" (CLAUDE.md, Guardians).
- **Recall pending while seated.** If the cue is not yet met, `_tick_pending_recall` never
  runs, so the cue is never checked. The charge lands and `_react_to_hurt` stands him up.
  On the next frame the pending recall opens, after the blow, with Ivo already in
  knockback.
- **Sitting then pressing down with a recall already open.** `_try_sit` does not check
  `_recall.is_armed()`. The world then stays slowed for as long as he stays seated.
- **Seated when the call is staged.** He sits during `lucidity_delay` or the leap. The
  guardian lands and calls `stage_call` / `open_call` while he is seated. When the window
  opens, the first `draw_memorina` press only stands him up, which costs part of a timed
  answer window.

## Root cause

- `_try_sit` implements only part of the plan's gate, which was "no call is open". It has
  no notion of an engaged fight. It reads `_staged_caller`, which is set only from the
  landing to the end of the relapse.
- The seated branch of `_process_motion` returns early, above the recall's real-time
  clock. That clock has to run whatever the body is doing, and death and the hazard
  already have to drop it explicitly for that reason.
- The bench was placed inside the arena room. Frost Edge has only one room.

## Fix

Fixed 2026-10-01, in the commit after `dbc79ab`:

1. `Player._try_sit` refuses while a call is staged or set (`_staged_caller`,
   `_memorina.call_song`), while a recall is pending or armed, and while
   `Guardian.fight_at(get_tree(), global_position)` - any guardian out of DORMANT and
   RESTORED whose `Arena` holds the point (`Guardian.is_fighting_at`).
   **Pulled, not pushed.** The suggested flag pushed by the guardian goes stale: a
   guardian stops processing when its room is deactivated, and an arena has no doors, so
   a player who walks out mid-fight would keep the flag set and be refused at every bench
   in the world. Asking the guardians at the moment of the press reads their current phase
   and the arena's geometry, which stay true while the room sleeps.
2. `begin_recall`, `stage_call` and `open_call` stand him up first, so the QTE and the
   call never depend on posture.
3. The bench stays where it is (decision 6, "before the lighthouse"): the gate makes it a
   rest before the guardian wakes and after a death rewinds it to sleep, never during the
   fight - which is what a bench at an arena's door should be.

## Prevention

Every new posture state that returns early from `_process_motion` (SIT, and any future
rest or cutscene pose) must keep the real-time recall clock running. A test that arms a
recall, sits, and asserts the window still drains would catch the regression.
