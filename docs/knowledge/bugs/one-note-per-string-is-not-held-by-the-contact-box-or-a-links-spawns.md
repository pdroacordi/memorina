---
id: bugs/one-note-per-string-is-not-held-by-the-contact-box-or-a-links-spawns
type: bug
title: "One note per string" gates only the move Hitbox; a later link's body contact or spawn takes a second life note once Ivo's 0.85 s invulnerability ends
status: fixed
severity: medium
tags: [grd-12, guardian, strings, hit-gate, contact, invulnerability, user-decision, latent]
related: [systems/guardians, architecture/grd-12-guardian-fight-engine, bugs/a-boar-charge-that-hits-ivo-by-a-ledge-dazes-inside-him-and-contact-takes-a-second-life]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/combat/hitbox/hit_gate.gd
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_spawner.gd
---

## Summary

The user decided "One note per string (Recommended)": a string costs Ivo at most one life note. `HitGate` is set only on the move `Hitbox` (`guardian.gd:161`), so the phase-owned `ContactHitbox` and the string's spawns can still take a second note during the same string. Latent until a shipped move has `follow_ups`.

## Symptom

GRD-12 review (code reading). Take a string `lash -> lash` (telegraph 0.35 s, duration 0.6 s, as in `engine_guardian_stats.tres`):
1. Link 0's box hurts Ivo at about 0.3 s. Invulnerability runs to about 1.15 s.
2. Link 1 strikes from 0.95 s to 1.55 s. Its box is refused correctly.
3. An Ivo who was knocked into the body, or who stands in a link's `FloorRunner`, is hurt by `ContactHitbox` (`continuous`) or the spawn's `Hitbox` the frame his invulnerability ends. That is a second note inside one string.

The boar had the same shape: `bugs/a-boar-charge-that-hits-ivo-by-a-ledge-dazes-inside-him-and-contact-takes-a-second-life`.

## Root cause

- `systems/guardians` says both "a string costs Ivo at most one life note" and "Only the move box is gated; spawns and the phase-owned contact box are not". Those two statements contradict each other. The code follows the second.
- `guardian.gd:230` writes `_contact.monitoring` for the whole PRESSURE, and `ContactHitbox` has no gate.
- `guardian_spawner.gd:83-86` builds each spawn's `Hitbox` with no gate.

## Fix

Fixed in GRD-12 (2026-11-18). One `HitGate` now sits on the move `Hitbox`, the `ContactHitbox` and every spawn `GuardianSpawner.adopt` takes in (a lob's patch included). `Guardian._on_attack_finished` clears it when no link follows (the string's end or a cancel), so the contact between strings is never refused. Link 0 is never refused, so single moves hit as before. Test: `guardian_engine_test.test_every_hitbox_of_a_string_shares_its_gate_and_the_gate_ends_with_it`.

Not fixed. Give the contact box and every spawn fired inside a string the same `HitGate` instance, gated while `_ai.is_attacking()`. Or have the user restate the decision as "the move box only", and correct the contract sentence.

## Prevention

A `hit_gate`/`guardian_engine_test` case: a two-link string where link 0's box hurts Ivo and he stays inside the body until his invulnerability ends. Assert one life note lost.
