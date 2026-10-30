---
id: bugs/a-recall-forgot-its-source-so-a-directionless-escape-never-went-away
type: bug
title: A recall opened by its cue cleared its source before reading it, so a dodge with nothing held never went away from the guardian
status: resolved
severity: medium
tags: [guardians, recall, roll, wall-climb, grd-04]
related: [systems/guardians, architecture/grd-04-autumn-and-summer-guardians]
created: 2026-10-30
updated: 2026-10-30
source_files:
  - scenes/characters/ivo/player.gd
  - tests/scenes/characters/ivo/player_recall_test.gd
---

## Summary

`Player._tick_pending_recall` set `_pending_recall_source = null` and then called `_open_recall(stats)`, which read
`_pending_recall_source` to remember the escape direction. The source was always null by then, so
`_recall_escape_axis` stayed 0 and `_recall_escape_left` 0 on every recall since the cue path existed (4d8268b0).

## Symptom

A roll pressed with nothing held after the Frost charge's recall went the way Ivo faced (into the charge), not away
from it, as `_dodge_axis` (now `_escape_axis`) intended. Found in GRD-04: the autumn gust's wall-climb recall needs the
escape axis to grip the wall with nothing held, and `player_recall_test` showed the axis at 0 on the first frame.

## Fix

`_tick_pending_recall` keeps the source in a local and passes it to `_open_recall(stats, source)`. In the same change
`RECALL_ESCAPE_TIME` went from 0.6 to 0.9 s: a jump's apex comes at ~0.67 s, and a wall grip needs the axis there.
`player_recall_test.test_a_wall_cued_recall_opens_at_the_wall_and_grips_it_with_nothing_held` fails without either.

## Prevention

A value read after the line that clears it: pass what a callee needs as an argument instead of reading a field the
caller has just reset.
