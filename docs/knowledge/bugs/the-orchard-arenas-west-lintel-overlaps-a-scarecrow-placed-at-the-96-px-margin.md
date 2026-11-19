---
id: bugs/the-orchard-arenas-west-lintel-overlaps-a-scarecrow-placed-at-the-96-px-margin
type: bug
title: The orchard arena's west lintel reaches below the scarecrow's head, so a scatter blink to the 96 px margin puts the body inside the stone and physics pops it 18 px east
status: resolved
severity: low
tags: [guardians, autumn, leaf, grd-15, blink, motion, arena, margin, collision]
related: [systems/guardians, bugs/a-guardian-step-inside-the-leap-margin-runs-the-wrong-way]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - resources/characters/guardians/motion/blink_motion.gd
  - resources/characters/guardians/motion/motion_context.gd
  - scenes/characters/guardians/guardian.gd
  - scenes/world/rooms/wind_orchards/contents/orchard_arena.room
---

## Summary

Every Leaf motion clamps to `lucidity_leap_margin` (96 px) from the arena's edge (`guardian.gd:519`, `MotionContext.clamp_x`).
The west lintel (`orchard_arena.room`, cols 0-2, rows 1-4) ends at y 160, and the 156 px capsule standing on the floor
(y 288) reaches up to y 132. The scarecrow cannot stand closer than x 114. A blink teleports it to x 96 regardless.

## Symptom

Probe (headless, 2026-11-19, GRD-15 review): a capsule of r18 h156 on the orchard floor overlaps the room's collision for
every feet x from 96 to 114, and not at 115. After `Character.teleport_body` to (96, 288), the first `move_and_slide`
leaves it at (114.07, 287.99).

In play, at stage 2 with wall climb owned (the bramble gate is gone), Ivo stands pinned at the west FightWall (feet x
about 42). The scatter plans `clamp_x(42 - 64)` = 96, which is 54 px from Ivo and so accepted by `min_gap`. The swirl is
drawn at 96. The body is teleported into the lintel, and depenetration moves it to 114 while it is still hidden. The
mover then pushes it back toward 96 every frame of the strike. The hop and the dive aimed at the same corner stop at 114,
18 px short of their planned landing; their shadow (32..160) still covers.

## Root cause

The 96 px margin is the lucidity leap's, and it is used for every motion clamp. It accounts for the arena's walls but
not for a ceiling lower than the body. The lucidity leap never lands at 96 here, because it always goes to the side
farther from Ivo. The GRD-15 moves aim at Ivo, so they do.

## Fix

Fixed in GRD-15 (2026-11-19) by the room change of
`bugs/the-orchard-arenas-west-lintel-caps-ivos-jump-at-74-px-so-the-leaf-claw-cannot-be-dodged-there`: the orchard
`Arena` now starts at col 3 (x 96), so every motion clamp (`lucidity_leap_margin` 96) keeps the scarecrow's feet at
x 192 or more, 78 px east of the lintel's face at x 96 for an 18 px half body. The lucidity leap, the blink, the hop and
the dive can no longer place it in the stone. Pinned by `guardian_talk_rooms_test` (no leap lands on a fight wall) and
`room_files_test`.

## Options considered

Not fixed. Options:
- give the autumn guardian a `lucidity_leap_margin` of 120 (this also moves the lucidity leap's clamp);
- add a separate motion margin on `Guardian`, fed to `MotionContext.margin`, set to 120 for the scarecrow;
- or lift the lintel by one row in `orchard_arena.room`. Check its notes first: the lintel height is tuned against the
  bramble gate and the double jump.

## Prevention

When an arena gets a motion guardian, check every point `clamp_x` can return against the room's solids for the full
body height. The pure tests use an empty arena and cannot see this.
