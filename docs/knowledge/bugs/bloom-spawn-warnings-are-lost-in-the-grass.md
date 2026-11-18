---
id: bugs/bloom-spawn-warnings-are-lost-in-the-grass
type: bug
title: The thorn row's crack and the seed pods' landing marks are drawn at the grass roots in the grass's own value, so the warnings do not read
status: fixed
severity: medium
tags: [grd-13, guardian, bloom, spawns, readability, floor-runner, lob, grass]
related: [systems/guardians, systems/grass, playtests/2026-11-18-grd13-bloom-fight]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/characters/guardians/spawns/floor_runner/floor_runner.gd
  - scenes/characters/guardians/spawns/lob/lob.gd
  - scenes/characters/guardians/spawns/floor_patch/floor_patch.gd
---

## Summary

FIXED 2026-11-18. Found (GRD-13 playtest, 2026-11-18). The board asks every move to be readable before it hits ("wind-up pose, a glint or
a shadow"). Two of the floor warnings are placeholders that don't read in bloom_hollow. `FloorRunner` warns with a
flickering 20x4 px `dark` rect at the floor. `Lob` marks its landing spot with a 2 px `dark` line. Both sit inside the
grass band (blades ~10 px tall) in a dark grey-green the same value as the grass base. The thorn row's crack also lies
under the guardian's front hooves (28 px ahead of the feet).

## Symptom

Screenshots, working tree (cb5416d6 + GRD-13), `screenshots/2026-11-18-grd13-bloom-fight/`:
- `row_warn.png`, `crack_zoom.png` (4x): during the 0.4 s warning the crack shows only on alternate flicker frames, as
  a slightly darker band at the grass roots under the hooves. At normal scale it cannot be seen. The running thorns
  (pale spikes, 28 px tall) read well.
- `pods_full.png`: 0.3 s into a pod's 0.4 s warning, neither pod nor landing mark is visible. In flight each pod is a
  10 px grey square. The 48 px thorn patches read as slightly paler grass blades.

When a thorn row is thrown at close range (Ivo within ~50 px), the row is live 0.65 s after the rearing pose ends.
That rearing pose is the burst's too. The crack is the only cue that tells the two apart.

## Options at filing

Not fixed. GRD-18 draws the real effects. Until then, draw the warnings above the grass blades and in the `light`
colour, or both values: the crack as a raised line of light pixels, and the landing mark as a light ring a few px above
the floor. Make the patch spikes taller than the grass.

## Fix

Fixed 2026-11-18 for the engine kinds (GRD-18 draws the real effects).
- `SpawnedAttack.draw_floor_warning` draws a light line with a dark rim at `WARN_RISE` (20 px: `GrassLook.MAX_BLADE_ART`
  x 2 + 4, over the tallest blade, which the front grass strip draws over the creature pass), and light sparks rising to
  it as the warning runs, alternating on the scaled clock (`_t`), never `TIME`.
- `FloorRunner` draws its crack with it, from its head along the way it will run; `Lob` marks its patch's width through
  its warning and its flight, and draws the pod light with a dark rim. Bloom's pod is 12 px (was 10) and its thorn patch
  22 px tall (was 14), over the blades.
- They stay in the creature pass: `ForegroundPass` is for foreground pieces (`systems/foreground`). At memory 0 they are
  greyed like the creatures, and the light/dark pair keeps the contrast; nothing in them depends on memory, so they show
  and move in the grey.

Not yet checked by a screenshot in bloom_hollow; the Prevention item for GRD-18 stands.

## Prevention

Add to the GRD-18 art contract: every floor warning reads against grass at memory 0 and 1, checked by a screenshot in
bloom_hollow.
