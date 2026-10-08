---
id: systems/bell-jar
type: system
title: Redoma: the frost shell
status: active
tags: [bell-jar, redoma, shell, shelter]
related: [architecture/the-bell-jar-closes-once]
created: 2026-10-02
updated: 2026-10-07
source_files: []
---

# Redoma: the frost shell

Moved verbatim from `CLAUDE.md` ("The bell jar") on 2026-10-02.

Design 02 section 7.1: Redoma's one rule is **nothing enters, everything may leave**.

- **`FrostShell`** is the song's `PulseEffect`: a thin frost ring drawn on the pulse's CLEAN disc (`draw_arc`, not antialiased, a few rime crystals re-rolled on a slow clock), shrinking with it. Its collider is a ring of `SegmentShape2D` on physics layer 4 ("Shell"), refitted to the radius each physics frame. It **closes when the pulse stops growing** (a growing ring would shove whatever it swept): every Player and Props body inside then gets a collision exception, dropped once it is clear of the ring - so it may leave, and from outside it is solid (what falls on it rolls off, whoever left can stand on it). Ivo and loads collide with layer 4; enemies do not, so the shell bars matter, not creatures, and is never a combat shield.
- **It shelters**: a `DiscShelter` (an `AirflowShelter`) makes `Airflow.sample` return still air inside it, and `Airflow.is_sheltered()` is the one answer to "does weather reach here" - a `RainBasin` wholly under it does not fill, and rain lands ON the shell (its layer stops the drops), so wind and rain agree that shelter starts when the shell closes.
- **It holds water out** (`WaterBody.hold_out(holder, centre, radius)` / `release`), pixel for pixel: the discs reach the pool's shaders as `held_discs` (`wc_held()` in `water_common.gdshaderinc`, the same test as `WaterBody._refresh_dry()` - change one, change the other), so the water stands against the curve with its lighter line along it, the veil leaves a body inside dry, and the hazard's outline follows the same curve (reused `CollisionPolygon2D`s, above and below the disc) until the shell shrinks off it. **A lake is never held out** (`WaterBody.is_lake()`): it lies in front of the land seen from above, and a hole cut in it read as the water vanishing, not standing back (the user's call, 2026-09-30).
- **Playing inside the gale** (design 02 §8, Inverno Lógico 1) is winter trial puzzle 2: a squall gusts with calms shorter than six notes, so any song played in it breaks; Redoma played at its edge shelters a performance inside. The second song there is Soltar on a drawbridge whose hinge only a pulse played inside the squall reaches - a level-design pick (the user left the song to the builder, 2026-10-07, "Você escolhe"), not a rule. `winter_trial_test.gd` checks it from the real map, profile and memory.
- **Redoma's pulse is its own** (`bell_jar_pulse_stats.tres`, 192 px, 8 s sustain, 5 s contraction).
