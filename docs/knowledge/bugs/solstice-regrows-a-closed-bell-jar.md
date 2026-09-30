---
id: bugs/solstice-regrows-a-closed-bell-jar
type: bug
title: Solstice stretches a Redoma pulse after its shell has closed, so the closed ring grows and sweeps whatever stands just outside it
status: fixed
severity: medium
tags: [solstice, redoma, frost-shell, pulse-stretch, physics, composition]
related: [architecture/the-bell-jar-closes-once, bugs/solstice-cannot-stretch-a-root-span-it-was-never-built]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/memory/song_effects/shell/frost_shell.gd
  - scenes/world/memory/song_effects/solstice/solstice_aura.gd
  - scenes/world/memory/color_pulse/pulse_timeline.gd
---

## Summary

`FrostShell` closes once its pulse leaves ATTACK, precisely because "a growing ring
would shove whatever it swept". `PulseTimeline.stretch` is allowed during SUSTAIN,
though, and grows the radius by `reach` (1.4) over `GROW_TIME` (1 s). `FrostShell`
refits its segments whenever the radius moves by more than 0.5 px
(frost_shell.gd:56-57), so a closed 192 px ring grows to about 269 px at roughly
1.3 px per frame.

## Symptom

Found in review, not reproduced in engine. Play Redoma, step out of the ring (the
collision exception is dropped once you are clear of it), then play Solstice nearby.
The ring expands into Ivo and into any Props body resting against it. A thin segment
moving a pixel or so into a capsule each frame depenetrates it outward, so everything
within about 77 px of the outside of the shell is shoved outward, and whatever stands
on top of it is lifted. The hold-out disc and the air shelter grow too.

## Root cause

The shell's "closed" state does not freeze its geometry. It trusts the pulse never to
grow again after ATTACK, and Solstice broke that assumption.

## Fix

Open. Once closed, refit to `minf(pulse.radius(), _radius)` so the ring only ever
shrinks. Alternatively, `SolsticeAura` could stretch a BELL_JAR pulse's duration but
not its reach. The first keeps the rule inside the shell, where it belongs.

## Prevention

Any `PulseEffect` whose physics depends on the pulse no longer growing must enforce
that itself. `ColorPulse.stretch` can reopen growth at any time before CONTRACT.

## Resolution (2026-09-30)

Fixed: once closed, `FrostShell` refits to `minf(pulse.radius(), _radius)`, so a stretch after closing never grows the ring; the shelter and the held-out water follow the shell's own radius, not the pulse's.
