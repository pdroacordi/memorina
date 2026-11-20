---
id: bugs/a-mirrored-spawn-art-frame-draws-one-frame-width-east
type: bug
title: Every mirrored SpawnArt frame draws one frame width east of its foot, so a pod or ember thrown west appears 16 px behind the release point (on the face, antlers or forearm)
status: fixed
severity: medium
tags: [guardians, spawns, spawn-art, lob, art, mirror, grd-19]
related: [gotchas/a-negative-width-texture-rect-flips-in-place-at-its-position, playtests/2026-11-20-grd19-spawn-origins-and-seams, bugs/the-sun-embers-and-mentor-seeds-leave-from-the-guardians-back-not-its-mouth-or-hand, systems/guardians]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - resources/characters/guardians/spawn_art.gd
  - scenes/characters/guardians/spawns/lob/lob.gd
  - scenes/characters/guardians/spawns/floor_patch/floor_patch.gd
  - scenes/characters/guardians/spawns/floor_runner/floor_runner.gd
  - scenes/characters/guardians/spawns/boomerang/boomerang.gd
  - scenes/characters/guardians/spawns/leaf_swirl/leaf_swirl.gd
---

## Summary

`SpawnArt.frame_rect(foot, true)` returns `Rect2(at + Vector2(size.x, 0), Vector2(-size.x, size.y))`. Godot draws a
negative-width rect from its position rightward
(`gotchas/a-negative-width-texture-rect-flips-in-place-at-its-position`), so every mirrored frame lands one frame
width (16 px for the pods and embers) east of where the unmirrored frame would be. GRD-19's release points are
correct in both facings, but a pod drawn mirrored misses them.

## Details

Seen in `playtests/2026-11-20-grd19-spawn-origins-and-seams`
(`screenshots/2026-11-20-grd19-spawn-origins-and-seams/pod_release_both_facings.png`). The scratch driver logged each
`Lob`'s `launch()` point. In every tested case the logged point sits at the drawn mouth or hand, in both facings:
- Facing east, the pod's centre is on the point.
- Facing west, the pod is drawn 16 game px east of the point:
  - Sun: on the lion's face, behind the jaw.
  - Mentor: on the forearm, behind the fingertips.
  - Bloom: on the antlers, beside the raised hand.

`Lob` mirrors by `facing < 0`, and `facing` is `SpawnPlacement.facing_at(landing, ctx)`: the side of the landing
spot, not the guardian's facing. So:
- A west-facing guardian whose pod lands behind it draws that pod correctly. In the mentor's west run, 2 of 3 pods
  were offset and 1 was centred, and the two kinds sat side by side at one release point.
- An east-facing guardian's pod that lands behind it (west) is drawn 16 px further forward.

Probe numbers: a plain 16 px draw at x 100 covers 100..116; `frame_rect`'s flip at the same foot covers 116..132.

The same `frame_rect` mirrors every other `FloorPatch` tuft, every other `FloorRunner` spike, a westward
`Boomerang` and `LeafSwirl` leaves. Each of those is shifted one frame width too. This session did not judge them
by eye. The ember patch tufts looked evenly spaced at a glance, but no measurement was taken.

## Fix (2026-11-20)

`SpawnArt.frame_rect(foot, true)` returns the unmirrored rect with a negative width, `Rect2(at, Vector2(-w, h))`, which
the renderer flips in place. Every caller (`Lob`, `FloorPatch`, `FloorRunner`, `Boomerang`, `LeafSwirl`) goes through
`draw_frame`, so all mirrored spawn art moved back onto its foot. `spawn_art_test.test_a_frame_lands_bottom_centre_on_the_art_grid`
pins the rect; only rendered pixels prove the draw (the gotcha), so the screenshots of the next playtest are the check.

## Fix plan before the fix

Not fixed. In `frame_rect`, keep `at` for the flipped rect: `Rect2(at, Vector2(-size.x, size.y))`. Then check that
`drawn_rect` and the `spawn_art_test` expectations still describe the drawn pixels. Pin it with a rendered or
expected-rect test that encodes the engine's behaviour, not the old assumption.

## Verified (2026-11-20)

Re-checked in `playtests/2026-11-20-grd19-spawn-origins-and-seams` ("Re-check (fixes)"). `frame_rect` returns `Rect2(at, Vector2(-w, h))`. Westward pods and embers now centre within 0-2 px of the release point (were 16-18 px off). The probe's mirrored draw covers the same x as the plain one.
