---
id: bugs/creature-pass-frozen-transform-floats-bodies
type: bug
title: Creatures float off the floor whenever the camera moves while the tree is paused
status: fixed
severity: high
tags: [rendering, subviewport, pause, camera, greyhush, cinematic]
related: [architecture/memory-runs-through-pause, gotchas/subviewport-does-not-inherit-default-texture-filter, bugs/creature-pass-bilinear-blur]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/world/memory/creature_mask.gd
  - scenes/world/game.tscn
---

## Summary

`CreatureMask` has no camera of its own: `_process` copies the main viewport's
`canvas_transform` every frame. That `_process` was PAUSABLE, so the moment anything
moved the camera while `get_tree().paused` was true, the creature pass kept drawing at
the transform it had when the pause began - every creature (Ivo, guardians) rendered at
the old zoom and offset, visibly detached from the floor they stand on.

## Symptom

"The camera started to zoom in and there characters stood there, floating." Seen during a
guardian's lesson, where the world is frozen for the track and `GameCamera.push_in`
zooms from 1.0 to 1.15 through the pause. The gap grows with the zoom, so it reads as
the characters drifting upward as the shot closes in.

## Root cause

`scenes/world/memory/creature_mask.gd:_process` is the only thing that keeps the pass
aligned, and the node inherited PAUSABLE from the tree. Latent since the creature pass
was built - the memorina's focus zoom is also a pause-process tween, so a draw whose
zoom landed after a freeze would have shown it too; nothing had moved the camera that
far under a pause before the lesson push-in.

## Fix

`process_mode = 3` (ALWAYS) on the `CreatureMask` node in `game.tscn`, with the reason
written into the script's docstring. It joins the memory layer, which already runs
through a pause (see the architecture entry).

## Prevention

The rule to carry: any node whose whole job is to MIRROR another node's transform or
state each frame must run in the same pause mode as the thing it mirrors, or it silently
renders a stale copy. Worth checking whenever a new pass or proxy viewport is added.
