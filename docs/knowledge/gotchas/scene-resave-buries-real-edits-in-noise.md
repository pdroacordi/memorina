---
id: gotchas/scene-resave-buries-real-edits-in-noise
type: gotcha
title: Opening a .tscn in the editor full-resaves it, burying the one real edit inside unrelated metadata churn
status: active
tags: [tscn, editor, diff-review, footgun]
related: []
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/world/game.tscn
  - scenes/characters/enemies/brute_shadow/brute_shadow.tscn
---

## Summary

Godot rewrites an entire `.tscn` text file whenever it is saved from the editor, not just
the lines that changed. A diff of "one small edit" routinely also contains reordered
`ext_resource` declarations, newly backfilled `uid=` attributes on resources that predate
UIDs, freshly assigned `unique_id=` attributes on nodes, connection lists re-sorted
alphabetically, and redundant instance-level property overrides (e.g. `layout_mode = 3`)
either added or dropped depending on whether they now match the base scene's own value.
None of that is a behavioral change — but it sits in the same diff as whatever the editor
session actually intended to change, and it is easy to skim past a real one-line move
(a node's `position`, a `visible` flag) hiding among a dozen no-op metadata lines.

## Details

Observed in the same commit's worth of uncommitted changes to `scenes/world/game.tscn`
and `scenes/characters/enemies/brute_shadow/brute_shadow.tscn`:

- `game.tscn`: every `ext_resource` line got reordered and several gained a `uid=`
  attribute that was previously missing (harmless — Godot backfilling UIDs it already
  knows), every `[connection ...]` line was re-sorted alphabetically by signal name with
  no set change, and `layout_mode = 3` was dropped from two Control instances because it
  now matches their base scene's own default — all pure noise. Buried in the same diff:
  `World/Player`'s `position` moved from `Vector2(-173, 0)` (against a wall near
  Downtown, the documented default spawn — see
  `docs/knowledge/playtests/2026-09-20-harness-shakedown.md`) to `Vector2(2732, -58)`
  (inside the Woods room, between Woods and BloomHollow) — a real, easy-to-miss change to
  where every playthrough starts.
- `brute_shadow.tscn`: `visible = false` was dropped from the `EnemySight` and
  `SpawnTrigger` `Area2D` nodes. Confirmed harmless — `EnemySight`/`PlayerProximityTrigger`
  never read `visible`, and Area2D overlap detection is independent of it; the only effect
  is that their `CollisionShape2D` debug outlines now render in the 2D editor viewport.
  But it reads identically to a real change until checked against the scripts.

## Prevention

When reviewing a `.tscn` diff, first mentally (or with `git diff --word-diff`) separate
lines that are pure editor bookkeeping (`uid=` additions, `unique_id=` additions,
`[connection]` reordering with an unchanged set, redundant property overrides that mirror
the base scene) from lines that change an actual node property value someone would notice
at runtime (`position`, `visible`, `modulate`, exported script vars, `disabled`). Treat any
surviving property-value change as the real diff and verify it against the base scene it
came from, git blame, or asking whether it matches known intent — a leftover debug
placement (moving the player near a feature under test) is exactly the kind of change this
noise is good at hiding.
