---
id: architecture/memory-gated-height-field
type: architecture
title: Water motion is a spring height field whose integration is gated per column by memory, with no stop threshold
status: active
tags: [water, greyhush, stopped-time, simulation, memory-field, freeze]
related: [architecture/memory-field-cpu-gpu-split, architecture/memory-runs-through-pause, bugs/water-swell-flattened-by-spread, bugs/ice-front-leaps-dead-columns]
created: 2026-09-22
updated: 2026-09-23
source_files:
  - scenes/world/environment/water/water_surface_field.gd
  - scenes/world/environment/water/water_body.gd
  - scenes/world/interactables/freezable_water/ice_front.gd
---

## Context

Design 03 §2: the grey is stopped time - a clock "advances at the rate that point is
remembered". §6.2 wants dead water still and a splash's crest to stay. A pool can straddle
a pulse edge, so one clock per body cannot express it.

## Options considered

- **Shader `TIME` waves scaled by memory.** Amplitude damping - exactly what §2 forbids.
- **One `MemoryClock` per body.** A single anchor cannot express half a pool in a pulse.
- **Analytic waves on per-column local time.** Columns that ran inside a pulse keep a
  permanent phase scar after it leaves; it never heals.
- **Chosen:** a CPU spring field (`WaterSurfaceField`, pure, tested), each column's `dt`
  scaled by the memory over it; the ambient swell is the springs' moving TARGET.

## Decision

- **No stop threshold** (user decision, 2026-09-22): grey water moves in proportion to its
  memory and is fully still only at exactly 0. They asked for water that is "not 100%
  still in the grey, nor exaggerated"; this is also the literal reading of §2 - the
  threshold `MemoryClock` has is an implementation detail, and water deliberately does not
  copy it. At 0 the state is bit-for-bit unchanged (tested over 10,000 steps).
- Springs couple on each column's distance FROM THE SWELL, not raw height; coupling raw
  heights smoothed the swell away (`bugs/water-swell-flattened-by-spread`).
- Splashes write DISPLACEMENT, so water that is not moving still keeps the shape.
- Cosmetics (the reflection's band shift, caustics, the swell's phase) run on ONE body
  clock, `time += delta * max(rates)`, which stops only when the whole body is forgotten.
  Consequence worth knowing: in a pool that is only partly grey, the grey columns chase a
  full-speed swell with slowed springs, so their swell is smaller rather than slower.
- Ice holds columns through `set_hold`; the field never learns about ice otherwise.
- **Lakes do not simulate** (2026-09-23, `architecture/water-two-projections`): a lake seen from above
  has no waterline to move and no `WaterProfile`. It keeps a clock per column instead of one per
  body - the one-clock shortcut above is fine for a pool, not for a lake the width of a room.
- FREEZE's `IceFront` follows the same rule for GROWTH (fronts and setting run at the
  memory under them, spent one column at a time) but NOT for the thaw (user decision): the
  thaw is its own front from the origin on its own clock, so a song in a dead place never
  leaves a permanent bridge and the crossing stays a race.

## Consequences

- A crest in water at memory 0 is permanent; at 0.1 it relaxes ~10x slower (measured
  in-engine in Downtown's well); a pulse makes it relax at full speed; the field heals once
  everything is alive (tested against an always-alive control).
- The sim is TIME: pausable, gated by a `VisibleOnScreenNotifier2D`, stopped in
  deactivated rooms, and lost on `Room.evict()`.
- Semi-implicit Euler at `max_substep` 1/120 is stable at the default profile
  (ω·dt ≈ 0.75 < 2); rates are clamped to 1 because a larger one would break that.
