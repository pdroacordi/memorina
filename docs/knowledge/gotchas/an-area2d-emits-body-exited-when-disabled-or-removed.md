---
id: gotchas/an-area2d-emits-body-exited-when-disabled-or-removed
type: gotcha
title: An Area2D emits body_exited when it is disabled or leaves the tree, and body_entered again when it comes back, so an enter/exit counter stays balanced
status: active
tags: [godot, physics, area2d, signals, rooms, soft-landing, world-35]
related: [systems/rooms, gotchas/a-redoma-shell-is-standable-ground-up-to-192-px-over-its-origin]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/environment/soft_landing/soft_landing.gd
  - scenes/characters/components/landing_component.gd
  - scenes/world/rooms/room_residency.gd
---

# An Area2D emits body_exited when disabled or removed

**Rule:** a body-side counter fed by an Area2D's `body_entered` and `body_exited` stays balanced across room
deactivation and eviction. No reset on a room swap is needed.

- **What Godot does (verified headless on 4.7.2, WORLD-35 step 3 re-review).** An Area2D emits `body_exited` for every
  body inside it in each of these cases:
  - it is disabled (`DISABLE_MODE_REMOVE`, or a parent set to `PROCESS_MODE_DISABLED`, as `Room.deactivate` does);
  - it leaves the tree, as an evicted room's contents do.

  It emits `body_entered` again when it is enabled or added back with the body still inside.
- **Where it matters.** `SoftLanding` tells Ivo's `LandingComponent` on enter and on exit, and the component counts
  zones (`systems/rooms` "Soft landing"). If a room idles or is evicted while he stands in its zone, the count goes back
  down; when the room wakes, it goes back up. `exit_soft_zone` still clamps at 0, so a stray exit never leaves the
  count negative.
- **Not relied on.** A teleport (`Character.teleport`) out of a zone also ends in `body_exited` at the next physics
  flush. A landing judged in that same step can still read the old count, which is harmless: the body is leaving.
