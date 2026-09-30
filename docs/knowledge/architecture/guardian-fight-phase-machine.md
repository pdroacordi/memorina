---
id: architecture/guardian-fight-phase-machine
type: architecture
title: GuardianFight is a pure, tested phase machine; Guardian does all the sounding and saving
status: active
tags: [guardian, boss-fight, state-machine, refcounted, testing]
related: [architecture/animation-driver-resolver-pattern]
created: 2026-09-20
updated: 2026-09-21
source_files:
  - scenes/characters/guardians/guardian_fight.gd
  - scenes/characters/guardians/guardian.gd
  - tests/scenes/characters/guardians/guardian_fight_test.gd
---

## Summary

`GuardianFight` (`RefCounted`, no Node, fully unit-tested) owns the phase logic —
`DORMANT → PRESSURE → LUCIDITY → RELAPSE → PRESSURE … → RESTORED`, the hit threshold, the
recall gate, the answer window, the relapse clock and the aggression that every failure
adds. `Guardian` (the Node) drives it and performs every
side effect. Nothing else reads the phase except the animation resolver.

## Details

- A guardian encounter is pressure → lucidity window (call-and-response) → consequence,
  per `docs/design/02_mecanicas.md` sections 3–4.
- Hits destabilise, they never wound: `Guardian._on_hit_received` skips `Health` and
  knockback entirely and counts the hit into the fight instead. `Health` on a guardian is
  inert by design.
- A concrete guardian is a scene plus a `GuardianStats` resource
  (`resources/characters/guardians/<name>/`) — never a subclass, unless it does something
  genuinely no resource can describe.
- The Player↔Guardian contract is intentionally small: the guardian calls `open_call` /
  `sound_call_note` / `close_call` / `begin_recall` / `learn_song` on the player, and
  listens for `call_answered`, `sequence_failed`, `skill_recalled`, `skill_recall_missed`.
- The recall is a gate, not a chance (2026-09-21): `set_recall_pending(true)` makes hits
  saturate at the threshold without opening a window; `skill_recalled()` is then the blow
  that opens it. `Guardian` reads the save for the flag; the machine never does.
- Every answer short of the last passes through `RELAPSE`, timed by
  `GuardianStats.relapse_time` (scaled by `FAILED_RELAPSE_SCALE` after a failure) and
  ended by `tick()` on its own, announced only through `phase_changed`; hits do not
  count in it. `Guardian` uses the phase to stage the colour drain, the stagger and the
  groan, and to release the camera and the lights when it ends.
- The staging (`Player.stage_call` / `unstage_call`) and the cure counts on `open_call`
  are the only additions to the contract; the guardian's side on `call_opened` is
  computed by `Player` from the staged caller.

## Why

Keeping the phase machine `RefCounted` and side-effect-free is what makes
`tests/scenes/characters/guardians/guardian_fight_test.gd` possible without a running
scene tree — the phase transitions, thresholds and aggression scaling are tested as pure
logic, and `Guardian` is the only place that can get the *wiring* wrong.

## Gotchas / pitfalls

- Restoration is persistent (`Enums.Guardian`, `PlayerData.restored_guardians`,
  `SaveSystem.restore_guardian`). A restored guardian starts in `RESTORED` on every later
  visit and never fights again — don't reset this state when iterating on arena layout.
- The emergency QTE (`AbilityRecallComponent`) ticks in **real** seconds
  (`delta / Engine.time_scale`), because `WorldFreeze.slow()` is the only writer of
  `Engine.time_scale` and the recall window must not itself be slowed by the effect it's
  reacting to.
