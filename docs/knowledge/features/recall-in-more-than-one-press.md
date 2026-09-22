---
id: features/recall-in-more-than-one-press
type: feature
title: A remembered skill can take more than one press, so the double jump is taught rather than waited for
status: active
tags: [qte, recall, abilities, guardians, double-jump]
related: [bugs/recall-move-range-exceeds-hitbox-reach, bugs/pogo-over-a-guardian-is-a-free-ride]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/characters/ivo/abilities/ability_recall_component.gd
  - resources/characters/guardians/ability_recall_stats.gd
  - scenes/characters/ivo/player.gd
  - scenes/ui/recall_prompt/recall_prompt.gd
---

## Summary

The double jump's recall used to wait: `AbilityRecallStats.requires_airborne` held the
moment closed until the Bloom burst's lift had put Ivo in the air, and if it never did,
the moment never came at all. A QTE that asks for a double jump while the player stands
on the ground is not nonsense - it is the lesson. It now asks for BOTH presses.

## Details

- `grounded_steps` is how many presses the memory takes when it opens with the feet
  planted (2 for the double jump, 1 for the roll). Caught already airborne, any memory
  is the single press that is left to give.
- `airborne_finish` says the last press only counts off the ground. A press given
  standing is not counted and returns false - and because the same press is also
  buffered by `JumpComponent`, it performs the ordinary jump that earns the next step.
  That is the whole trick: press one IS the setup for press two.
- `step_window` puts fresh real seconds on the clock for each press but the last.
- Where the feet are is the BODY's judgement, pushed in through `arm(stats, grounded)`
  and `notify(action, airborne)`, the same way `enabled` carries the item gate. The
  component never reaches for a `CharacterBody2D`.
- `RecallPrompt` draws one key per press in a row and the draining ring HOPS to the next
  as each lands, the spent one going pressed and dim; `RecallAura` flares on every step.
  No prose, no counter.
- The ordering that makes it work was already there: `PlayerInput.jump_pressed` reaches
  the recall in the same frame it is buffered, and `_try_jump` runs later in
  `_process_motion`, so the press that completes the memory finds the skill unlocked.

## Why

The old shape made the moment's existence depend on someone else's knockback. The new
one depends only on the player, and it teaches the move in the act of remembering it -
which is what docs/design/02_mecanicas.md section 4 asks for.
