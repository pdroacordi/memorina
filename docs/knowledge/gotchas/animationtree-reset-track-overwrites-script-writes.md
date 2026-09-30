---
id: gotchas/animationtree-reset-track-overwrites-script-writes
type: gotcha
title: A script write to any property with a RESET track is silently overwritten every frame
status: active
tags: [animationtree, reset-track, footgun]
related: [architecture/animation-driver-resolver-pattern]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/characters/character.gd
  - scenes/characters/guardians/guardian.gd
---

## Summary

`RESET` is the default pose, and the `AnimationTree` owns every property it declares. If a
script writes to a property that has a `RESET` track (`Hurtbox:monitorable`, `Hitbox:*`,
`GreyhushShield.amount`, ...), the tree silently overwrites that write on the very next
frame the tree blends toward `RESET` — there is no error, no warning, the value just
snaps back.

## Details

Each clip keys only what it changes (hitbox geometry per swing, i-frames); everything
else blends back to `RESET`. This is intentional and good — it's what keeps clips
independent — but it means the property is *owned by the tree*, not by whoever last
wrote it from script.

## Why

This was discovered independently in at least two places already: `Character._on_hit_received`
has to ignore hits while dead by gating the *decision* in script (rather than trying to
force `Hurtbox:monitorable` false from script), and a guardian's `GreyhushShield.amount`
is kept entirely script-owned and deliberately never keyed in any clip, because keying it
would fight the script's per-frame corruption/lucidity/restoration logic every single
frame. `BruteShadow` keeps its whole tree inactive until spawn for exactly this reason —
there's no way to "protect" a property from RESET while the tree is active.

## Gotchas / pitfalls

- If you need a property to be both animated *and* script-controlled, the answer is never
  "write it after the tree updates" — order-of-operations games with `_process` vs
  `_physics_process` are fragile. Either key the decision in the clip, gate the decision
  in script before it reaches the property, or keep that property permanently out of the
  tree's RESET set (script-owned only, as with `GreyhushShield.amount`).
- When adding a new clip, check whether it's implicitly creating a RESET track for a
  property you didn't mean to hand to the tree — Godot creates one automatically the first
  time you key a property in the animation editor.
