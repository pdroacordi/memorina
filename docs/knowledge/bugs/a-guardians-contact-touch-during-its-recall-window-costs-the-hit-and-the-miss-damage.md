---
id: bugs/a-guardians-contact-touch-during-its-recall-window-costs-the-hit-and-the-miss-damage
type: bug
title: A touch of the Bloom stag's body while the double-jump recall is open closes it as a miss and costs two life notes
status: resolved
severity: medium
tags: [guardians, recall, bloom, hit-gate, contact, miss-damage, grd-14, review]
related: [systems/guardians, bugs/the-frost-charge-recall-opened-as-its-fists-already-touched-ivo, bugs/a-single-guardian-move-can-cost-two-notes-through-its-contact-box]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/abilities/ability_recall_component.gd
  - resources/characters/guardians/bloom_guardian/recall_double_jump.tres
---

## Symptom

Found in the third GRD-14 review (computed, then probed). Ivo has 3 notes. A Bloom double-jump recall is open (`open_recall(recall_double_jump, guardian)`). One hit of damage 1 arrives from a child of the guardian, as the `ContactHitbox` delivers it. Ivo ends on 1 note and the recall closes as a miss. The probe script is `probe_recall_double.gd` in the review scratchpad; it printed `hp before=3 after=1 armed=false`.

The design decision is "One note per string (Recommended)" (user, 2026-11-18), and one touch cost two notes. The player also loses a lesson he could still have finished: before GRD-14 the window stayed open after a contact hit, and an airborne Ivo needed only one more press.

## Root cause

`Player._on_hit_received` (`scenes/characters/ivo/player.gd`, the `_hit_by_recall_source` branch) calls `_recall.miss()` for any hit with `damage > 0` whose source is the recall's source or one of its descendants. That covers every hitbox under a guardian: the move `Hitbox`, the `ContactHitbox`, and the spawns under the `GuardianSpawner`. Only the move box is the blow the recall teaches to escape.

`miss()` then runs `_on_skill_recall_missed`, which takes `miss_damage` straight through `Health`. So the hit's own damage and the miss cost are both paid. `HitGate` cannot refuse the second one, because it never passes through a `Hitbox`.

Which recall moves this reaches:
- **Bloom burst:** `damage` 0, the contact box live (`body_contact` true), and `recall_double_jump.miss_damage` 1. This is the path that costs two notes.
  - The recall opens at the 120 px cue. The burst box only reaches about 66 px.
  - If Ivo is not launched (he stood 70-120 px off, or backed off as the Bloom table advises), nothing records him in the gate and he has no i-frames, so touching the stag's body while the window is open takes the contact hit and then the miss damage.
- **Frost charge:** `miss_damage` 0 and contact off, so a fist hit costs one note. This is the intended case.
- **Autumn gust:** contact is live but `miss_damage` is 0. A scarecrow close to the wall Ivo is pushed against would close the window with a touch, which costs one note and the lesson.

## Fix

Fixed in GRD-14 (2026-11-18), both parts:
1. Only the move's own box closes the recall. The guardian passes its `Hitbox` as the blow (`Player.begin_recall(stats, duration, source, blow)`, `open_recall(stats, source, blow)`), and `Player._on_hit_received` closes the window only when a damaging hit comes from that blow. Its `ContactHitbox` and its spawns leave the window open, as before GRD-14.
2. A window closed by the blow's hit pays no `miss_damage` (`_recall_closed_by_hit`): the hit was already the cost.

Tests (`player_recall_test`):
- `test_only_a_damaging_hit_from_the_move_box_closes_it_as_a_miss`;
- `test_a_bloom_contact_touch_costs_one_note_and_its_burst_closes_without_miss_damage` (the real `recall_double_jump.tres`, miss_damage 1, and the stag's `ContactHitbox`);
- `test_a_frost_fist_hit_closes_the_roll_window_at_its_own_cost`.

## Prevention

`player_recall_test.test_a_damaging_hit_from_the_recall_source_closes_it_as_a_miss` uses `_stats` and a bare child node as the "fist". Add a case with the Bloom stats (`miss_damage` 1) and a hit from the guardian's `ContactHitbox` that asserts:
- the window stays open;
- one touch costs at most one note.

More generally, any path that charges `Health` directly (`miss_damage`, dissonance) bypasses `HitGate`. Check it against "one note per string" whenever it can fire in the same frame as a gated hit.
