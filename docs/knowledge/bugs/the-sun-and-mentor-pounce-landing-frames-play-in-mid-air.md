---
id: bugs/the-sun-and-mentor-pounce-landing-frames-play-in-mid-air
type: bug
title: The Sun's and the mentor's pounce landing frames show 0.12-0.17 s before touchdown, 60-72 px in the air, and the mentor's box has no art on its trailing half after landing
status: fixed
severity: medium
tags: [guardians, summer, mentor, pounce, grd-18, animation, art, hitbox]
related: [playtests/2026-11-20-grd18-leaf-sun-mentor-art, systems/guardians]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/characters/guardians/summer_guardian/summer_guardian.tscn
  - scenes/characters/guardians/mentor_guardian/mentor_guardian.tscn
  - resources/characters/guardians/summer_guardian/summer_pounce_slam.tres
  - resources/characters/guardians/mentor/mentor_pounce.tres
---

## Summary

Both pounce clips key their landing frame before the `LeapMotion` puts the body on the floor. The landing pose is
drawn flat and stretched, so it hangs over Ivo for 6-10 physics frames. The mentor's landing frames 5-6 have no drawn
limb on one half of its symmetric box.

## Symptom

`playtests/2026-11-20-grd18-leaf-sun-mentor-art`, per physics frame (one physics step per drawn frame):

| Clip | Landing frame from | Height then | Touchdown | Early by |
|---|---|---|---|---|
| Sun `attack_7`, `pounce` 4 | 0.700 s | 72 px | 0.867 s | 0.167 s (10 frames); `pounce` 5 at 0.80 is still 30 px up |
| Mentor `attack_6`, `pounce` 4 | 0.600 s | 61 px | 0.717 s | 0.117 s (7 frames); all 4 forced pounces |

Screenshots: `sun_pounce_landing_pose_in_air.png` (the lion lies flat in the air over Ivo, then drops) and
`mentor_pounce_landing.png`. The task brief and the clip table say the Sun lands at about 0.7 s; the motion lands at 0.85-0.87
(`LeapMotion` in the air 0.25-0.85, as the move table says).

The mentor's box is x -30..30, y -48..0, live 0.62-0.85. Measured on `mentor_guardian_pounce.png`, the art in the bottom 48 px
spans 58 px on one side of the centre on frame 5 (0.70-0.80) and up to 12 px past it on frame 6 (0.80-0.85), with
nothing on the other half. In game the drawn legs are on the side the mentor travelled toward, so the empty half is the
trailing side, which is where `PAST_IVO` 24 puts Ivo. In the open-floor run an Ivo at dx 17 on that side stood in the live box
with only dark robe wisps above him (`mentor_pounce_landing.png`, tile 051.998). He was not hit only because his
invulnerability from an earlier touch was still running. A still Ivo is normally hit earlier, at 0.63-0.65, while frame 4's
wide body passes over him. Only an Ivo who walks or lands into the trailing half late meets the empty box.

## Root cause

`summer_guardian.tscn:1281`, `"times": PackedFloat32Array(0, 0.3, 0.7, 0.8, 0.95)` (frame 4 at 0.7), against the
`LeapMotion` air window that ends at 0.85. `mentor_guardian.tscn:1180`, `(0, 0.1, 0.35, 0.6, 0.7, 0.8)` (frame 4 at 0.6),
against touchdown at 0.717. The mentor's box offset is (0, -24) with scale (3, 2.4), centred, while frames 5-6 are drawn off-centre.

## Fix

Not fixed. Move the landing frame to the touchdown (Sun 0.85, mentor 0.70) and hold the in-air frame until then; or start
the fall frame there and land on the next. For the mentor, either shift the box toward the drawn legs on frames 5-6
(keyed per frame, as the Frost slam's box is) or close it at touchdown. Check `combat_reach_test` after either change.

## Fix (2026-11-20)

The landing frame now keys at touchdown: Sun `attack_7` `pounce` 4@0.86, 5@0.93, 6@1.0; mentor `attack_6` 4@0.71, 5@0.77, 6@0.83, and the mentor's box opens at 0.71 instead of 0.62 (`combat_reach_test` failed with the box live over the airborne frame). Open: the mentor's frames 5-6 draw the limbs on the leading half of the centred box only.
