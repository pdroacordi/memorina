---
id: gotchas/sprite-frame-out-of-bounds-on-clip-switch
type: gotcha
title: Switching from a wider strip to a narrower one logs "Index p_frame = N is out of bounds" for one frame
status: active
tags: [animation, animationtree, sprite2d, hframes]
related: [architecture/animation-driver-resolver-pattern]
created: 2026-09-21
updated: 2026-09-21
source_files:
  - scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn
  - scenes/characters/enemies/brute_shadow/brute_shadow.tscn
---

## Summary

Every character keys `Sprite2D:hframes` and `Sprite2D:frame` per clip, one strip per
clip. When the tree jumps from a clip whose strip is wider (attack, 6 or 14 frames) to a
narrower one (hurt, 4 or 7) while the old frame index is past the new width, Godot logs
`ERROR: Index p_frame = 5 is out of bounds (vframes * hframes = 4)` once. Seen on both
guardians (hit mid-walk or right after a swing) and on BruteShadow's attack -> hurt; it
predates the guardian work.

## Details

The frame is clamped by the engine, so the cost is a wrong frame for at most one tick
plus console noise on every flinch - not a gameplay bug. The mechanism has not been
traced (the order the mixer applies `frame` and `hframes` in the switch tick is the
suspect). Two candidate fixes when it is worth the time: pad every strip of a character
to the same frame count so `hframes` never changes, or key `frame` to 0 explicitly in a
one-key track ahead of `hframes`. Do not "fix" it by adding a transition to the state
machine - the resolver rule forbids transitions for a reason.
