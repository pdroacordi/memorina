---
id: bugs/paired-frame-kept-its-look-ahead
type: bug
title: The camera's look-ahead pushed one of a framed pair off the screen
status: fixed
severity: medium
tags: [camera, guardians, framing, cinematic]
related: [features/lucidity-leap, features/encounter-sheet-slot]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/world/camera.gd
---

## Summary

`GameCamera` leads the subject's facing by `look_ahead_distance` (96 px of `offset.x`).
That is right when the frame is about one body. It is wrong when the frame is about two:
the camera sat exactly on the pair's midpoint and the shot was still 96 px off, which is
96 px the far body loses at the edge.

## Symptom

After a guardian leapt to the far side of the arena, it stood 5 px OFF the left edge for
the whole call. The instinct was that the leap had gone too far, or that the room's bounds
were clamping the camera. Both were wrong: logged, `camera x=3953` was the exact midpoint
of 3724 and 4182, the room bounds were 1920 px wide and nowhere near, and
`offset=(96.0, -48)` was the whole difference.

## Fix

`_look_ahead_target()` answers 0 while `_pairing`, and every path that changes the lead -
a turn, `frame_pair`, `release_pair` - goes through one `_tween_look_ahead()`. The lead
eases back when the pair is released. Measured after: guardian at screen 91, Ivo at 549,
both comfortably inside a 640 px frame at 458 px apart.

## Prevention

When a framing number looks wrong, print the camera's position, its offset, its zoom and
the viewport size before touching the thing being framed. Two of the three guesses here
(the leap is too far; the room is clamping) would have made the shot worse while leaving
the real cause in place. And any camera behaviour written for "the subject" needs an
answer for the moments the frame is about something else.
