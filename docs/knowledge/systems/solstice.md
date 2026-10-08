---
id: systems/solstice
type: system
title: Solstice: stretching other pulses
status: active
tags: [solstice, pulse, stretch]
related: []
created: 2026-10-02
updated: 2026-10-07
source_files: []
---

# Solstice: stretching other pulses

Moved verbatim from `CLAUDE.md` ("The longest day") on 2026-10-02.

Design 02 section 7.1: Solstice acts on memory, not on the world. **`SolsticeAura`** (the song's `PulseEffect`, warm rays turning on the disc's edge) calls `ColorPulse.stretch(reach, duration)` on every other pulse overlapping it; `PulseTimeline.stretch` takes once, only while the pulse still opens or holds, multiplies its reach (`SolsticeAura.reach`, 1.4) and its sustain (`duration`, 3.0), and grows into the new reach over `GROW_TIME` rather than jumping. So every effect that lives as long as its pulse - the shadow on a plate, a root bridge (the grower builds the spans a stretch brings into reach), the rain - lasts longer and reaches farther with no rule of its own. Ice does not: it thaws on its own clock whatever the pulse does. A closed Redoma shell never grows back out under a stretch. Alone it holds colour long in a dead place (`solstice_pulse_stats.tres`: a 24 s sustain and `contract_min_factor` 1.0). Sombra has its own shorter pulse (`shadow_pulse_stats.tres`, ~9 s) so that the long corridor (a fifth trials region, `trials_solstice`, 80 cells) is Solstice's puzzle: the shadow alone is gone before Ivo reaches the door, stretched it lasts the walk (`solstice_trial_test.gd`). The region's second room, the empty house (`empty_house`, design 02 §8.4 Combinado 4), needs it in any order: the shadow alone ends before Ivo gets from its plate to the door even rolling, and stretched it covers Soltar at the cocoon on the way out (`empty_house_test.gd`, at the trials' memory 0.35, which shortens a pulse's contraction).

User decision, 2026-10-07, "Solístico dura mais": `duration` went from 2.5 to 3.0. At 2.5 the empty house was at its limit: for Solstice to be needed even by a player chaining rolls, the corridor had to be so long that walking out after Soltar passed the door only with perfect input (`playtests/2026-10-07-empty-house`). Every stretched pulse now holds longer.
