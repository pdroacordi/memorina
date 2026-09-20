---
id: bugs/creature-pass-bilinear-blur
type: bug
title: Guardians (and Ivo) rendered blurred because the creature pass SubViewport filtered linearly
status: active
severity: medium
tags: [rendering, guardians, greyhush-shield, pixel-art]
related: [gotchas/subviewport-does-not-inherit-default-texture-filter]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/world/memory/creature_mask.gd
  - scenes/world/memory/greyhush_shield.gd
---

## Summary

Every creature drawn through `CreatureMask` (all `SILHOUETTE` shields: Ivo, Frost
Guardian, Bloom Guardian) was bilinear-filtered while the world was nearest-filtered.

## Symptom

User report after the first guardian build: "the guardian (both of them) is a little
blurred when compared to the rest" and "there are moments that the own character seems
rather blurred". BruteShadow, which uses `HALO` mode and therefore the world pass, was
crisp.

## Root cause

`CreatureMask` is a `SubViewport`; a SubViewport's `canvas_item_default_texture_filter`
defaults to LINEAR regardless of `project.godot`'s nearest setting. See the gotcha entry.

## Fix

`scenes/world/memory/creature_mask.gd` `_ready()`: copy the root viewport's
`canvas_item_default_texture_filter`. Verified with the playtest harness
(`playtests/2026-09-20-bloom-guardian-call`).

## Prevention

No automated check; the gotcha entry is the safeguard. Any new SubViewport must set it.
