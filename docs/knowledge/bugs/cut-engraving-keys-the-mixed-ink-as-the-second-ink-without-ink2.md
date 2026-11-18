---
id: bugs/cut-engraving-keys-the-mixed-ink-as-the-second-ink-without-ink2
type: bug
title: cut_engraving.py board writes the --mixed hue as key #00FFFF (the second ink) when --ink2 is not given
status: fixed
severity: low
tags: [art-pipeline, engraving, story-42, final-fragment, tools]
related: [architecture/story42-the-final-fragment, systems/bearer-fragments, systems/art-pipeline]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - tools/art/cut_engraving.py
---

## Summary

`board` builds its ink list from the options that are present, but `write_base` maps the list's positions to the
fixed keys `(KEY, KEY_2, KEY_MIXED)`. A cut with `--ink` and `--mixed` and no `--ink2` writes the mixed lines as
`#00FFFF`, so the shader draws them flat in the second ink instead of the trembling mixed ink.

## Symptom

Found in the STORY-42 review; latent, because both shipped boards were cut with all three inks. A board for a panel
with the winter blue and the mixed crack but no pink, cut as `--ink=... --mixed=...`, gives a crack that never
trembles and reads as solid flower pink (or as ink A when `second_ink` is null).

## Root cause

`tools/art/cut_engraving.py`, `__main__`: `inks = [_colour(opts[k]) for k in ("ink", "ink2", "mixed") if k in opts]`
drops the missing `ink2` slot, so `mixed` takes index 1. `engrave` returns per-pixel indices into that list and
`write_base` does `for i, key in enumerate((KEY, KEY_2, KEY_MIXED))`, so index 1 becomes `KEY_2`.

## Fix

Not fixed. Carry the key with each ink (for example a list of `(hue, key)` pairs built from the options present) and
have `write_base` write `key` for each index, or reject `--mixed` without `--ink2`.

## Prevention

When a CLI's optional arguments fill positional slots, keep the slot identity (here the output key) next to the
value instead of inferring it from the list position.

## Fix (2026-11-18, before the STORY-42 commit)

The options keep their slots: `inks` holds `None` for a missing `--ink2` or `--mixed`, and `ink_index` never matches a `None` ink, so `--mixed` always writes `#FFFF00`. A recut of board 1 with all three inks is pixel-identical to the shipped panels. The stray `#FFFF00` texels in panels 1 (1) and 3 (33) were filled with the nearest grey, so only panels 4 and 5 hold the mixed ink, and only in their moving layers.
