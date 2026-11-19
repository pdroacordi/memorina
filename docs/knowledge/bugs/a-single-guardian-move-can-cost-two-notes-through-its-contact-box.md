---
id: bugs/a-single-guardian-move-can-cost-two-notes-through-its-contact-box
type: bug
title: The Frost body drop cost two life notes in one throw (contact in the fall, then contact in the recovery); the string gate never refuses its own first link
status: resolved
severity: low
tags: [guardians, frost, grd-14, hit-gate, contact, body-drop, playtest]
related: [playtests/2026-11-18-grd14-frost-feel, bugs/one-note-per-string-is-not-held-by-the-contact-box-or-a-links-spawns, systems/guardians]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/combat/hitbox/hit_gate.gd
  - scenes/characters/guardians/guardian.gd
  - resources/characters/guardians/frost_guardian/frost_body_drop.tres
---

## Summary

"One note per string (Recommended)" (user, 2026-11-18): a string costs Ivo at most one life note, by any of its hitboxes
(`systems/guardians`). The implementation says "the first link is never refused". A move with no links is a one-link
string, so its contact box can hit again after Ivo's 0.85 s of i-frames.

One Frost body drop hit Ivo twice, 0.99 s apart:
- once by the falling body;
- once by the landed body during the recovery (`body_contact` is true on the body drop).

## Symptom

`pinw2` (session `pin_driver.gd`, `PL_PIN=west`, `PL_GOD=1`), stage 2, one body drop, string id 21:
- 107.043, hp 2 -> 1, `atk=frost_body_drop clock=S hb=false dx=38.4 dy=-35.3`: the body coming down.
- 108.037, hp 3 -> 2 (god top-up in between), `atk=frost_body_drop clock=R hb=false dx=30.6 dy=1.8`: the landed body,
  in the recovery.

The driver walked back toward the golem after the first knockback, which caused the second touch. No other string hit
twice in 9 runs (scan of every `[hit]` pair inside one string).

## Root cause

`HitGate` refuses a hit only from a later link of the string. Any number of hits from the first link pass, limited only
by Ivo's i-frames. The body drop keeps `body_contact` true through its 0.8 s recovery, so the move outlasts the i-frames.

## Fix

Fixed in GRD-14 (2026-11-18). `HitGate` now holds a target once for the whole string, its first move included, from
the first wind-up to the end of the last recovery (`begin_string` on the first wind-up, `end_string` when the AI is no
longer attacking). Between strings it refuses nothing, so the body still hurts on touch between moves. A spawn that
outlives its string's recovery (an ice wave still running) is no longer held. Tests: `hit_gate_test`.

## Prevention

Add a `guardian_string_gate` test: a move whose strike plus recovery outlasts the i-frames, against an Ivo who stays in its
contact box, costs one note.
