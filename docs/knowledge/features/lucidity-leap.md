---
id: features/lucidity-leap
type: feature
title: A guardian breaks off and leaps clear of the frame before it calls
status: active
tags: [guardians, cinematic, camera, physics, collision]
related: [features/encounter-sheet-slot, architecture/guardian-fight-phase-machine]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/world/camera.gd
---

## Summary

Lucidity used to begin as a HUD event: the guardian stopped where it was and a sheet slid
in. It now begins as something you watch - the guardian breaks off, throws itself over the
top of the frame and lands at the far side of the arena, and only the landing stages the
call. The two phases are separated by an action instead of by a panel.

## Details

- `_begin_lucidity_leap()` turns a desired arc height into a launch against the world's
  own gravity (`speed = sqrt(2 * g * lucidity_leap_height)`), so the arc is authored in
  pixels and survives a gravity change. Horizontal speed is the distance over the flight
  time of that arc, set once at take-off.
- It lands `lucidity_leap_distance` (300 px) from Ivo, on the side it already stood -
  far enough that the camera holding the pair puts them at opposite edges. If the arena
  has run out on that side it goes over his head to the other, which is the better shot
  anyway. `GameCamera.bounds()` (new accessor) is what "the arena" means here: what the
  room lets the frame show, rather than re-deriving an extent from the tilemap.
- **It passes through the world on the way up.** `collision_mask` is 0 while it is above
  the floor it left, and comes back as it descends past that line, so it lands on real
  ground. Without this the Bloom arena's low platform swatted it down after 34 px - an
  arc meant to leave the frame has to be allowed through the ceiling.
- `leapt` / `landed` are signals wired to a `DustEmitter` in each guardian scene, exactly
  the idiom `ivo.tscn` uses for jump and landing dust; the landing shakes the camera.
- `lucidity_leap_timeout` calls from where it stands if the leap never lands (a pit, a
  missing floor). A fight must not be able to stall on a cinematic.

## Known gap

Guardians have no jump clip - the phase is already LUCIDITY during the arc, so the
resolver shows the `lucid` frame, which is an idle today. A real leap pose would be the
next thing to draw.
