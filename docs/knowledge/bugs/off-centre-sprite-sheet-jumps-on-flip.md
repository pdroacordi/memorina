---
id: bugs/off-centre-sprite-sheet-jumps-on-flip
type: bug
title: Bloom Guardian's body jumped sideways on every turn because the art was off-centre in its frame
status: active
severity: low
tags: [sprites, animation, guardians, facing]
related: []
created: 2026-09-20
updated: 2026-09-20
source_files:
  - assets/sprites/characters/guardians/bloom_guardian/
  - scenes/characters/character.gd
---

## Summary

`Character.face_towards()` mirrors the sprite with `flip_h`, which mirrors about the
frame's centre. The flower's body sat 13 px right of centre (its bite lunge fills the
left), so each turn shifted the body by 27 px at 2× scale — read as a "glitchy" hitbox and
flip.

## Symptom

User report: "The hurtbox is glitchy, its flipping is too."

## Root cause

Craftpix's 96×96 frames are composed for a left-facing lunge, not for mirroring.
Measured extents: idle body x 33..90 (centre 61.5 vs frame centre 48); lunge reaches x 5.

## Fix

Sheets re-padded to 128-wide frames with the original drawn at x = 3, which puts the body
centre at 64 and keeps the lunge unclipped (`hframes` unchanged, so no scene edit). The
frost sheets were already centred (56..134 in 192).

## Prevention

`.claude/skills/pixellab/SKILL.md` and the guardian conventions now require the body to
be centred in the frame; measure with a per-frame bbox before importing any new sheet.
