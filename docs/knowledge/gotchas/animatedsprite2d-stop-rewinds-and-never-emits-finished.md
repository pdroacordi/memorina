---
id: gotchas/animatedsprite2d-stop-rewinds-and-never-emits-finished
type: gotcha
title: AnimatedSprite2D.stop() rewinds to frame 0 and never emits animation_finished; play() of a finished one-shot restarts it; visibility_changed fires under a hidden parent
status: active
tags: [animatedsprite2d, animation-finished, stop, visibility-changed, staged-strip, line-gesture]
related: [systems/story, architecture/story37-the-mentor-moves-while-he-talks, gotchas/a-killed-tween-never-emits-finished]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/world/story/staged_strip.gd
  - scenes/world/story/line_gesture.gd
---

## Summary

Measured on 4.7 (headless probe, 2026-11-18): `AnimatedSprite2D.stop()` mid-clip sets `frame` to 0 and `is_playing()` false, and `animation_finished` never fires for that run. `play()` of the same non-looping clip after it finished restarts it from frame 0. `visible` toggled on a child whose parent is hidden still emits the child's `visibility_changed` (with `is_visible_in_tree()` false).

## Details

- A one-shot clip that ran to its end emits `animation_finished` once and stays on its last frame (`frame` = last, not playing).
- `stop()` is the only way a run ends without the signal; `pause()` keeps the frame.
- `StagedStrip` relies on all three: it calls `stop()` when hidden, so a strip a stand-in replaced or a stage change hid never reports a finish, and a strip shown again plays from frame 0. `LineGesture` releases its stand-in on `animation_finished`, so the release can only come from a strip still shown (or one still fading out as a cross-fade's `from`, which `FactStaging.release`'s name check makes a no-op).

## Gotchas / pitfalls

- Anything that must run when a clip ends (a release, a cleanup) does not run if the sprite was stopped. Pair it with the path that stopped it, as `FactStaging._go_to` drops stand-ins itself.
- A strip shown while its staging is covered gets `visibility_changed` with `is_visible_in_tree()` false, so a handler must test `is_visible_in_tree()`, not `visible`.
