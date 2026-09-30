---
id: bugs/solstice-cannot-stretch-a-root-span-it-was-never-built
type: bug
title: RootGrower builds only the spans its UNSTRETCHED pulse could reach, so Solstice never lets a root bridge reach farther
status: fixed
severity: medium
tags: [solstice, enraizar, roots, pulse-stretch, composition]
related: [architecture/roots-join-earth-to-earth, bugs/solstice-regrows-a-closed-bell-jar]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/memory/song_effects/roots/root_grower.gd
  - scenes/world/memory/song_effects/solstice/solstice_aura.gd
  - scenes/world/memory/color_pulse/pulse_timeline.gd
---

## Summary

`RootGrower._ready()` (root_grower.gd:38) filters the room's spans once, against
`pulse.song().pulse_stats.max_radius + one tile`. A Solstice stretch later multiplies
the pulse's reach (`PulseTimeline.stretch`, x1.4 by default), and `holds()` does follow
the stretched clean disc. But a span beyond the original reach was never built, so no
`RootSpanView` exists to grow into it. `SolsticeAura`'s docstring and CLAUDE.md
("a root bridge ... reaches farther with no rule of its own") promise that it does.

## Symptom

Found in review. Play Enraizar where a bridge's far bank is 300 px from the origin
(`root_pulse_stats` is 280 px), then Solstice (or the other way round). The colour
reaches the far bank, but no root ever grows from it.

## Root cause

The candidate set is decided at mount time from static stats. The stretch arrives later
and only changes `radius()`.

## Fix

Open. Build every span in the room (or those within
`max_radius * SolsticeAura.reach`), and let `holds()` decide per frame what grows.
Alternatively, rebuild the view list once when `pulse.is_stretched()` first turns true.

## Prevention

A `PulseEffect` that caches geometry from `Song.pulse_stats` must read the pulse's live
`radius()` instead. The stats are not the pulse once Solstice exists.

## Resolution (2026-09-30)

Fixed: `RootGrower` keeps every candidate span and builds views for what `ColorPulse.max_radius()` reaches; when a stretch raises it, the spans newly in reach get views that frame (`_build_within`).
