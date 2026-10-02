---
id: systems/solstice
type: system
title: Solstice: stretching other pulses
status: active
tags: [solstice, pulse, stretch]
related: []
created: 2026-10-02
updated: 2026-10-02
source_files: []
---

# Solstice: stretching other pulses

Moved verbatim from `CLAUDE.md` ("The longest day") on 2026-10-02.

Design 02 section 7.1: Solstice acts on memory, not on the world. **`SolsticeAura`** (the song's `PulseEffect`, warm rays turning on the disc's edge) calls `ColorPulse.stretch(reach, duration)` on every other pulse overlapping it; `PulseTimeline.stretch` takes once, only while the pulse still opens or holds, multiplies its reach and its sustain, and grows into the new reach over `GROW_TIME` rather than jumping. So every effect that lives as long as its pulse - the shadow on a plate, a root bridge (the grower builds the spans a stretch brings into reach), the rain - lasts longer and reaches farther with no rule of its own. Ice does not: it thaws on its own clock whatever the pulse does. A closed Redoma shell never grows back out under a stretch. Alone it holds colour long in a dead place (`solstice_pulse_stats.tres`: a 24 s sustain and `contract_min_factor` 1.0). Sombra has its own shorter pulse (`shadow_pulse_stats.tres`, ~9 s) so that the long corridor (a fifth trials region, `trials_solstice`, 80 cells) is Solstice's puzzle: the shadow alone is gone before Ivo reaches the door, stretched it lasts the walk (`solstice_trial_test.gd`).
