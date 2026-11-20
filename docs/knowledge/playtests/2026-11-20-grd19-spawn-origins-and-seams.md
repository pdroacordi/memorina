---
id: playtests/2026-11-20-grd19-spawn-origins-and-seams
type: playtest
title: GRD-19 spawn release points, the Sun charge crouch and the mentor pounce box - release points sit on the mouth and hand in both facings, but pods thrown west draw 16 px behind them; the charge seam is fixed, and the charge-back now pops into the crouch
status: active
build: b53b26ca + uncommitted GRD-19 working tree (guardian_spawn.gd release, spawn_context.gd, guardian_spawner.gd, lob.gd, the three .tres, summer/mentor/bloom guardian .tscn); --import at 15:52, nothing under scenes/ resources/ assets/ globals/ changed after it (checked 16:02)
area_tested: "caldera_arena (Sun spit, charge, charge-back), lighthouse_top (mentor seeds, pounce), bloom_hollow (Bloom seed lob); each move forced 2x per facing against a still god-mode Ivo, every physics frame drawn"
ratings: { readability: 3, aesthetics: 3 }
tags: [guardians, grd-19, art, animation, spawns, lob, hitbox, summer, mentor, spring, playtest]
related: [systems/guardians, playtests/2026-11-20-grd18-leaf-sun-mentor-art, bugs/the-sun-embers-and-mentor-seeds-leave-from-the-guardians-back-not-its-mouth-or-hand, bugs/a-mirrored-spawn-art-frame-draws-one-frame-width-east, bugs/the-sun-charge-back-pops-from-standing-into-the-charge-crouch, gotchas/a-negative-width-texture-rect-flips-in-place-at-its-position, bugs/the-sun-and-mentor-pounce-landing-frames-play-in-mid-air]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - tools/playtest/scripts/guardian_art_check_driver.gd
  - resources/characters/guardians/guardian_spawn.gd
  - resources/characters/guardians/spawn_art.gd
  - scenes/characters/guardians/spawns/lob/lob.gd
  - scenes/characters/guardians/summer_guardian/summer_guardian.tscn
  - scenes/characters/guardians/mentor_guardian/mentor_guardian.tscn
  - scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn
---

## Summary

A re-check of the GRD-19 fixes to the GRD-18 findings (`playtests/2026-11-20-grd18-leaf-sun-mentor-art`).
- **Release points (item 1): fixed in data, not yet on screen for westward throws.** The logged launch point lies on
  the Sun's mouth, the mentor's fingertips and Bloom's raised hand, mirrored correctly for both facings. But a pod
  whose `Lob.facing` is west draws 16 px east of that point (`bugs/a-mirrored-spawn-art-frame-draws-one-frame-width-east`).
- **Charge (item 2): the seam is fixed.** The wind-up and the strike start on the same crouch, with no stand-up.
- **Charge-back (item 2): now pops.** The charge-back stands for its own wind-up, then snaps into that crouch
  (`bugs/the-sun-charge-back-pops-from-standing-into-the-charge-crouch`).
- **Mentor pounce (item 3): OK.** The box sits inside the drawn limbs on every landing frame, in both facings.

## Method

The art check driver, as in GRD-18: a forced `GuardianAI._next`, `comfort_distance` 0,
`max_physics_steps_per_frame = 1`, and a still Ivo topped up at hp 1. A scratch copy (session scratchpad
`g19/drv.gd`) added:
- `[lob] new` lines: each `Lob`'s world `launch()` point and its offset from the feet, with the sprite frame then;
- `lobs=` on every `[shot]`: the screen release point and the current pod point;
- a shot every 3 physics frames while any lob is under 0.9 s old.

Facings: the default spawn puts Ivo west of each guardian. `AC_IVO_X` put him east (Sun 3650, mentor 11800,
Bloom -5900). Sheets mark the live box in red, Ivo's hurtbox in cyan, and each release point with a yellow cross.

Runs:
- `sun1`: spit, charge, charge-back x2, shipped driver;
- `sun2`: spit x2, one rep west and one east;
- `men1`: seeds and pounce x2, west;
- `men2`: seeds and pounce x2, east;
- `blo1` and `blo2`: seed lob x2, west and east.

## 1. Thrown pods and embers

| Guardian | Release (from feet, facing east) | Logged | On screen |
|---|---|---|---|
| Sun ember spit | (92, -52) | ±92, -52 in both facings. Pods fire on `ember_spit` 5, 6, 6 (frame 5 at 0.1, 6 at 0.2, 7 at 0.35). | East: the ember sits in the open jaws (`sun_ember_spit_east.png`). West: drawn on the face behind the jaw. |
| Mentor seeds | (48, -94) | ±48, -94. Pods fire on `seed_cast` 4, 4, then the third on the step `seed_cast` 5 appears. | East: centred on the fingertips (`mentor_seeds_east_hold_and_hover.png`). West: 2 of 3 pods on the forearm, 1 centred (its landing was behind the mentor). |
| Bloom seed lob | (36, -106) | ±36, -106. Same frame pattern as the mentor. | East: at the raised hand. West: on the antlers beside the hand (`bloom_seed_lob_west.png`). |

`pod_release_both_facings.png` puts all six side by side. The cross is at the hand or mouth in every tile; only the
west pods are off it, by exactly one frame width. A windowed probe confirmed the cause: a 16 px frame drawn with
`frame_rect`'s flip covers x 116..132 instead of 100..116
(`gotchas/a-negative-width-texture-rect-flips-in-place-at-its-position`). This is not a GRD-19 regression. Before
GRD-19 the pods started at the back, so the shift was hidden there. It is the one thing left between the fix and
"the pod appears at the hand".

**The held throw pose.** `seed_cast` 4 and `seed_lob` 4 hold 0.1-0.31 s, about 13 physics frames. Frame by frame,
nothing in the hold looks frozen: the raised arm reads as the throw. But each pod waits at its release point through
its 0.4 s warning (`Lob._hit_offset`). When the arm drops at 0.31, pods 1-3 stay hanging where the hand was, 25-30 px
above the lowered hand, until 0.5, 0.6 and 0.7 s. In the mentor and Bloom strips the arm drops forward and low, so
the pods read as left floating in the air (`mentor_seeds_east_hold_and_hover.png`, second row). The Sun's head
whips low on frame 7 at 0.35 with the same effect, which is milder because the embers stay near the head. This is a
feel note, not a bug. Holding frame 4 to 0.31 cannot cover the warning. Options: hold the pose to about 0.7, or let
a pod follow the hand until its flight starts.

The third pod fires at 0.30 s, and frame 5 is keyed at 0.31, which is the same physics step (0.3167). The `[lob]`
line for pod 3 reports frame 5 in all 8 mentor and Bloom reps. The shots, taken every 3 frames, cannot tell whether
its first drawn frame shows 4 or 5. At most one frame, low severity.

## 2. Sun charge and charge-back

| Move | Observed | Verdict |
|---|---|---|
| Charge (`summer_charge`) | Wind-up `charge_windup` 0, 2 at 0.2, 3 at 0.35. The strike starts on `charge_windup` 3, then 2 at 0.2 and 3 at 0.3, in place. At 0.5 it cuts to `attack_2` 6 with the box and lunges; 7-13 every 0.083. | **OK.** The wind-up to strike seam is identical frames. The crouch-to-frame-6 cut keeps the head and mane at the same height and reads as the spring off the crouch (`sun_charge_windup_to_lunge.png`). The 2-3-2-3 coil is a small change and reads as a held, tense crouch, not a freeze. The GRD-18 stand-up is gone. |
| Charge-back (`summer_charge_back`) | Wind-up `attack_2` 0, 1 (standing, head high) for 0.5 s, then `charge_windup` 3 on the first strike frame, then the crouch for 0.5 s in place, then `attack_2` 6 and the dash. | **Pops.** Standing to crouched in one physics frame, in both reps (`sun_charge_back_stand_to_crouch_pop.png`, tiles 2 to 3). This is a GRD-19 regression on the move that shares the strike (bug filed). |

The box opens with frame 6 at 0.5. Ivo was hit on that first lunge frame at dx 84-86 in 2 of 4 lunges. That
matches the drawn mane and forelegs, which reach him.

## 3. Mentor pounce box

Rows y -48..-6, measured in the screenshots as pale pixels (all channels > 185) relative to the feet, against the
logged live box:

| Frame | Box | Drawn | Verdict |
|---|---|---|---|
| 4 (0.71-0.77, landing) | x -30..30 | x -85..78 | Box inside the sprawled landing pose. |
| 5 (0.77-0.83) | x 2..30 (mirrored -30..-2 facing west) | 8..48 / 12..48 east; -47..-9 / -46..-12 west | Box over the back two-thirds of the limbs. No box over empty floor. |
| 6 (0.83-0.85) | x 2..30 | -3..42 / 0..42 east; -42..-1 / -39..2 west | As frame 5. |

**OK in both facings** (`mentor_pounce_landing_box_east.png`, `mentor_pounce_landing_box_west.png`). The empty
trailing half from GRD-18 is gone. The drawn limbs reach 12-18 px past the box's front at 30, which is the lenient
side (art without a hit), kept for the pinned case. The landing frame 4 now shows at touchdown: `air=false` from
0.717 in men1 and 0.733 in men2.

Not GRD-19: in both runs a still Ivo was hit by the mentor's body at 0.633-0.65, while it passed over him about 35 px
up, before the box opened. That is body contact, which was unchanged and not judged here.

## What screenshots cannot show

- **Feel at 60 fps.** These runs drew every physics frame at about 4-6 real fps. The following are inferred from
  frame counts, not seen at speed:
  - the charge-back pop (one frame, after 0.5 s standing);
  - the 16 px pod offset;
  - the pods hovering for up to 0.4 s after the arm drops.
  A human playtest should confirm how loud each one is.
- **Only a still Ivo.** Hits on a moving or jumping Ivo are inferred from the box and the art.
- **Audio and camera** were not judged.
- The mirrored-art shift also applies to `FloorPatch` tufts, `FloorRunner` spikes, `Boomerang` and `LeafSwirl`.
  It follows from the code and the probe, but this session did not look at those frames.

## Re-check (fixes)

Build: the same working tree plus the coordinator's two fixes, after a `--import` at 16:20. Nothing under scenes/,
resources/, assets/ or globals/ changed after it (checked 16:24). The fixes:
- `SpawnArt.frame_rect` now mirrors in place: `Rect2(at, Vector2(-w, h))`.
- `summer_charge_back` now strikes on `attack_9` (clip_index 8), the old standing `attack_2` 0..13.

The scratch driver re-ran, every physics frame drawn: `sun3` (spit west x2, charge-back x2), `men3` (seeds west x2) and
`blo3` (seed lob west x2).

| Item | Result |
|---|---|
| Westward pods and embers | **OK.** Measured: the centre of the pod or ember's bounding box against the logged release point, from shots with a single lob in its warning. Before → after: Sun 16.9 → 0.4-0.8 px; mentor 15.8 → -0.2 px; Bloom 17-18 → 1-2 px. The east-facing controls read -2 to -3, the error of the 2 px grid and the colour pick. Each pod now sits on the mouth or fingertips (`pod_release_west_fixed.png`, before on the left, fixed on the right). A windowed probe of `SpawnArt.draw_frame(..., flip = true)` at foot x 108 now covers x 100..116, the same as the unflipped draw. |
| Mirrored floor patch / runner | **Not judged by eye.** Every patch frame in these shots was still in its warning: the procedural bars, identical before and after (0 differing pixels in the mentor floor strip). Their tufts and runner spikes use the same `draw_frame`, so the probe covers them, but no live tuft was framed. |
| Sun charge-back seam (twice) | **OK.** The wind-up shows `attack_2` 0, 1 (standing). The strike shows `attack_2` 0, 1, 2, 3, 4, 5 every 0.083 s, settling gradually toward the lunge, then 6 with the box at 0.5 and the dash (`sun_charge_back_fixed_no_pop.png`). Both reps are identical. The only step back is wind-up 1 → strike 0, two nearly identical standing frames: the same seam the move had before GRD-19, not a pop. |

`bugs/a-mirrored-spawn-art-frame-draws-one-frame-width-east` and
`bugs/the-sun-charge-back-pops-from-standing-into-the-charge-crouch` are fixed. The feel notes above still stand,
and still need a human playtest at 60 fps: pods hover at the release point through their 0.4 s warning after the
arm drops.
