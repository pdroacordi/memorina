---
id: gotchas/time-scale-zero-stops-delta-particles-and-time
type: gotcha
title: At Engine.time_scale = 0, every process delta is exactly 0, CPU particles and shader TIME stop, and only tweens that ignore the time scale move
status: active
tags: [time-scale, pause, hold, tween, particles, shader, time, menu]
related: [architecture/pause-menu-worldfreeze-reuse, systems/songs-and-the-memorina, systems/screens, systems/greyhush]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/world/world_freeze.gd
  - scenes/world/memory/greyhush_renderer.gd
---

## Summary

`WorldFreeze.hold()` (a menu) sets `Engine.time_scale` to 0. Measured in Godot 4.7.2,
windowed, with a scratch probe:

| What | At scale 0 | Control at scale 1 |
|---|---|---|
| `_process(delta)` | delta exactly 0: 363 frames over 2 real s, 0 non-zero | normal |
| Tween with `set_ignore_time_scale(true)` | advances: 61 of 100 after 0.6 real s | advances |
| Default tween | stops | advances |
| `CPUParticles2D` | stop: 0 changed pixels over 2 real s | 3869 changed pixels in 0.3 s |
| Shader `TIME` | stops: 0.0 s over 2 real s | 2.008 s over 2 real s |

The frame in flight when the scale changes still uses the old scale.

## Details

- Anything that must keep moving under a hold (a menu's own animation) needs
  `set_ignore_time_scale(true)`. A `_process(delta)` animation is dead there.
- Shader `TIME` follows the time scale, so it also slows with a recall. The greyhush edge
  reads its own `greyhush_time` global (`systems/greyhush`) so that the clock it follows
  is explicit.
- A real-seconds conversion `delta / Engine.time_scale` divides by 0 at scale 0. The
  project writes `delta / maxf(Engine.time_scale, 0.001)` (`Player` recall tick,
  `RecallAura`, `KeyGlyph`, `RecallPrompt`). With delta 0 that gives 0, so these stop
  rather than producing inf or NaN; a `KeyGlyph` blink does not run under a hold.
- Audio is not stepped by delta: an ALWAYS `AudioStreamPlayer` keeps playing at scale 0.
  `MemorinaVoice` pulls `WorldFreeze.is_held()` into `stream_paused`.

## Gotchas / pitfalls

- A new ALWAYS node that animates from ticks, `set_ignore_time_scale` or an audio stream
  keeps moving under a hold unless it checks `WorldFreeze.is_held()`.
- On screen (2026-10-02): two frames 2 real s apart under the held pause menu are
  pixel-identical over the ring-out, a spreading pulse and the lesson lead-in.
