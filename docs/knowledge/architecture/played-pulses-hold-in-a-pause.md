---
id: architecture/played-pulses-hold-in-a-pause
type: architecture
title: A pulse Ivo played holds still while the world is frozen; a guardian's lesson pulse does not
status: active
tags: [color-pulse, pause, performance, world-freeze, composition, soltar, vendaval]
related: [architecture/memory-runs-through-pause, architecture/weight-and-presence, gotchas/playtest-clock-pauses-with-the-tree]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/memory/color_pulse/color_pulse.gd
  - scenes/world/memory/color_pulse/pulse_emitter.gd
---

## Summary

Every `ColorPulse` is `PROCESS_MODE_ALWAYS` (a lesson's pulse must spread under the
pause). That made every pulse keep running through the NEXT song's performance, ~7 s of
frozen world, so a second song arrived after the first one's effect was gone. Now
`PulseEmitter.holds_in_pause` (true on Ivo, false on both guardians) stops a played
pulse's clock and particles while the tree is paused.

## Details

`ColorPulse._physics_process` returns early when `holds_in_pause and get_tree().paused`;
its particles are made PAUSABLE. The root stays ALWAYS, so rendering and the memory
layer are untouched.

## Why

Design 02 section 7.4's compositions (Soltar then Vendaval, Vendaval then Congelar,
Chuva then Congelar) are two songs in a row. A performance freezes world time; a song
already played is world time like the water (whose crest also holds under the freeze).

## Alternatives considered

Longer pulses for every song: hides the problem and changes every song's feel.
