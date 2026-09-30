---
id: playtests/2026-09-30-sombra-and-soltar-trials
type: playtest
title: Sombra's door, seesaw and lure and Soltar's counterweights and cocoon, played for real
status: active
tags: [sombra, soltar, vendaval, trials, pressure-plate, seesaw, lure, counterweight]
related: [architecture/weight-and-presence, architecture/played-pulses-hold-in-a-pause, bugs/room-entity-links-depended-on-file-order, bugs/released-load-refused-to-unfreeze-in-the-physics-flush]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - tools/playtest/scripts/song_shadow_door.json
  - tools/playtest/scripts/song_shadow_seesaw.json
  - tools/playtest/scripts/song_shadow_lure.json
  - tools/playtest/scripts/song_release_counterweight.json
  - tools/playtest/scripts/song_release_gale_cocoon.json
---

## Summary

All five puzzles solve end to end with real input. Found and fixed on the way: entity
links depending on file order (the lift never linked), Soltar unfreezing in the physics
flush (loads never fell), played pulses running through the next song's performance,
loads hanging too low to walk under, the cocoon's shelf out of the camera's view, the
cocoon tumbling and catching on tile seams, and the gale blowing it past the plate (a stop).

## What was seen

- Door: the shadow (dark, warm shimmering rim, Ivo's playing pose) holds the plate; the
  gate stays up while Ivo walks through.
- Seesaw: the shadow holds the long arm down; Ivo walks up and jumps from the raised
  short end onto the 8-cell cliff.
- Lure: from the roof Ivo wakes the Brute Shadow unseen; it walks to the shadow and
  breaks it; Ivo drops down the shaft behind it.
- Counterweights: the right load drops on its plate and the lift rises out of frame.
- Cocoon: Soltar from under the shelf's middle, Vendaval from the left; it slides to the
  stop on the plate, the last gate rises, Ivo walks through.

## What this cannot judge

Timing windows are measured by a script, not a person: the Soltar-then-Vendaval sequence
leaves a few seconds of slack after the 16 s sustain. The jam (wrong counterweight) is
unit-tested, not played. The lure's tunnel reads as a floating slab, not a tunnel.
