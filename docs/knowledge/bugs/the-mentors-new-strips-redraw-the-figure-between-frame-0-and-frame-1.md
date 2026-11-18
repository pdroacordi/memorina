---
id: bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1
type: bug
title: The mentor's STORY-37 strips (breath, tilt, lower, hold-out) change most of the figure between frame 0 (the exact still) and frame 1 (the PixelLab redraw), so the breath twitches twice a cycle
status: fixed
severity: medium
tags: [story-37, story, mentor, lighthouse, staged-strip, breath, art, pixellab, seam, jitter]
related: [playtests/2026-11-18-story37-the-mentor-moves, architecture/story37-the-mentor-moves-while-he-talks, systems/story, systems/art-pipeline]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - assets/sprites/world/story/mentor/holding_breathe.png
  - assets/sprites/world/story/mentor/empty_hand_breathe.png
  - assets/sprites/world/story/mentor/tilt.png
  - assets/sprites/world/story/mentor/lower.png
  - assets/sprites/world/story/mentor/hold_out.png
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
---

## Summary

In every new mentor strip, frame 0 was replaced by the exact still composite (so the cuts are pixel-exact), but frames 1+
are the PixelLab drawing. That drawing's inner shading, mask and snow flecks sit 1 art px to the side of the still's, so
0 -> 1 changes far more of the figure than the motion itself. The breath loop plays 0 1 2 3 2 1, so the figure redraws
twice every 1.75 s.

## Symptom

Measured on the source sheets (128x128 canvas, art at 2x; counts in canvas px that differ in RGBA):

| Strip | 0 -> 1 | 1 -> 2 | 2 -> 3 | Best colour alignment 0 vs 1 |
|---|---|---|---|---|
| `holding_breathe` | 2510 | 496 | 352 | shift x +2 (1 art px) leaves 890 |
| `empty_hand_breathe` | 2510 | 496 | 352 | +2 leaves 842 |
| `tilt` | 2734 | 440 | - | +2 leaves 1452 |
| `lower` | 2772 | 1596 | 1688 | +2 leaves 1080 |
| `hold_out` | 2894 | 1452 | 804 | +2 leaves 1090 |
| `raise` (STORY-11, control) | 568 | 300 | - | - |

The figure is ~4500 opaque canvas px. The silhouette barely moves (alpha-only 0 -> 1 differs by 304 px with the best
shift at (0, 0)): it is the inside that is redrawn. In game at zoom 1.5 (window px, >20 difference, mentor crop only):
breath 0 -> 1 = 8208, 1 -> 2 = 2766, 2 -> 3 = 1872. The 0 <-> 1 step is 3-4x the breath. See
`playtests/screenshots/2026-11-18-story37-the-mentor-moves/07_breath_cycle_frame0_differs.png` (frames 0 and the
return to 0 match each other, frames 1-5 match each other, the two groups do not) and `08_holding_breathe_source_frames_0_to_3.png`
(the robe's dark stripes and the mask step sideways between the first and second figure).

From stills, this reads as a texture shimmer at each end of the exhale, not as breathing. How visible it is at
speed in the 0.05 grey must be judged by a human. The tilt's 0 -> 1 has the same jump, in the first 0.1 s of "Guardo.".

## Root cause

The plan (`architecture/story37-the-mentor-moves-while-he-talks`, "Frame 0 of each strip is replaced by the exact still
composite at cut time") swaps frame 0 for the still, but never re-registers frames 1+ to it. `mentor_moves_test` checks
only that frame 0 equals Holding's frame 0 (the seams), never how far frame 1 is from frame 0, so it passes.

## Fix

Not fixed. Options, art side: re-register frames 1+ onto the still (shift the interior 1 art px and repaint the shading
from frame 0, so 0 -> 1 is the size of the breath), or drop the substituted frame 0 from the breath loop and instead make
every seam strip's frame 0 the PixelLab frame 0 (then the turn, raise and gesture seams need the same redraw).
A seam test that bounds `diff(frame0, frame1)` against `diff(frame1, frame2)` (for example at most 2x) would catch it.

## Prevention

When a generated strip's frame 0 is replaced by a still, measure the 0 -> 1 difference against the in-loop differences
before approving it. `raise.png` (568 vs 300) shows what a matched frame 0 looks like.

## Fix (2026-11-18, before the STORY-37 commit)

`tools/art/lock_to_still.py` rebuilds every strip as the still plus only the pixels that differ from the generation's own frame 0 (after the same even shift that lays that frame on the still). The 0→1 step of the breath fell from 2510 to 302 changed px (1→2 404, 2→3 312); the tilt's from 2734 to 814, the lower's to 640, the hold-out's to 826. `mentor_moves_test.test_no_step_redraws_the_figure` holds every step under a third of his opaque pixels.
