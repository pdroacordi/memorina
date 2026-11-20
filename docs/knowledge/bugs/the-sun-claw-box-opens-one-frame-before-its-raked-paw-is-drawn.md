---
id: bugs/the-sun-claw-box-opens-one-frame-before-its-raked-paw-is-drawn
type: bug
title: The Sun claw's box opens one physics frame before the raked-paw frame, so a hit can land while the paw is still drawn high
status: fixed
severity: low
tags: [guardians, summer, sun, grd-18, animation, hitbox, art]
related: [playtests/2026-11-20-grd18-leaf-sun-mentor-art, systems/guardians]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/characters/guardians/summer_guardian/summer_guardian.tscn
---

## Summary

In the Sun's `attack_1` (claw), the `Hitbox:monitoring` key is at 0.1666666 s but the `Sprite2D:frame` key for
`claw_rake` 7 (the paw raked to the floor ahead) is at 0.167 s. At 60 Hz the tenth physics step lands at 0.16667 s,
between the two, so the box is live for one physics frame while `claw_rake` 6 (the paw raised level with the head) is drawn.

## Symptom

`playtests/2026-11-20-grd18-leaf-sun-mentor-art`, forced claw against a still Ivo at 105 px: the per-frame log shows
`S fr6 hb=true` at strike frame 10, then `fr7` at frame 11. Ivo's hit registered on frame 10, and the screenshot of that
frame shows the hit with the paw drawn up by the head, nothing on the floor
(`screenshots/2026-11-20-grd18-leaf-sun-mentor-art/sun_claw_box_opens_on_raised_paw.png`, middle tile). One frame
(16.7 ms), so it is barely visible in play, but it breaks "a hit lands only where art is drawn", and it repeats on every claw.

## Root cause

`summer_guardian.tscn:303`: `"times": PackedFloat32Array(0, 0.06, 0.11, 0.167, 0.36)` for the frame track, against
`0.1666666` for `Hitbox:monitoring`, `monitorable` and `visible` in the same clip. The frame key was written rounded.
A scan of every Leaf, Sun and mentor clip found no other frame key that falls less than one physics frame after a box edge.

## Fix

Not fixed. Key the frame at 0.1666666 (the box's time), or open the box at 0.167.

## Fix (2026-11-20)

The claw's `claw_rake` 7 key moved to 0.1666666, the same key as the box.
