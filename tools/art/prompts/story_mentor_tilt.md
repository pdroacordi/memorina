---
id: story_mentor_tilt
command: animate3
target: res://assets/sprites/world/story/mentor/tilt.png
size: 128x128
frames: 3
view: side
direction: west
reference: res://tools/art/sources/story/mentor_holding_2x.png
action: a tall ancient guardian of wood and frost, holding a small pan flute in its raised hand, slowly tilts its pale wooden mask down and forward as if nodding to someone small in front of it, then holds; its body and hand stay still; it stays in place
keep: 0-2
generate: 4
source: pixellab
---
The head tilt on "Guardo." (`DLG_MENTOR_GIFT_05`; STORY-37, "a head tilt on Guardo." under "Respirar + gestos (Recommended)", user, 2026-11-17). Played by the `MentorTilt` `LineGesture` as the line shows, the box open ("During the line (Recommended)", user, 2026-11-18), then released to the Holding loop.

Measured: 3 drawn frames played 0 1 2 1 0 once, 0.1 / 0.15 / 0.6 / 0.15 / 0.1 s (1.1 s, inside the 1.6 s `MentorPause` that follows). The mask moves about 1 art px down and forward (toward Ivo); body, mantle and flute hand stay on their pixels. Canvas: 128x128 frames, feet on row 125, frame (24, 6) is the stills' (0, 0); the strip sits at offset (-61, -126) from his feet at (720, 672) with `flip_h`, as `raise.png` and `play.png` (`systems/story`, STORY-11). The reference faces east (Holding); every kept frame is mirrored back to face west like his stills. Frame 0 is replaced at cut time by Holding exactly (`empty_hand.png` with `memorina_in_hand.png` at its place), so every cut to and from Holding is pixel-exact. Our own art only, never a pack sprite (the packs' licences forbid AI training). Plan: `docs/knowledge/architecture/story37-the-mentor-moves-while-he-talks.md`.

Cut by `python -I tools/art/cut_inhabitant.py <frames dir> story_mentor_tilt tools/art/sources/story/mentor_holding_2x.png <out> --keep=0-2 --floor=125 --centre=60-124`, mirrored; if no generation holds the body still, frames 1-2 are composed by moving the mask's pixels (`compose_strip.py`).
Negative: outlines, black contour, front view, glow, text, ground, scenery, walking, bowing the whole body

As built (2026-11-18): the frames are in `tools/art/sources/story/mentor_tilt/`; `python -I tools/art/cut_inhabitant.py tools/art/sources/story/mentor_tilt story_mentor_tilt tools/art/sources/story/mentor_holding_2x.png <cut.png> --keep=0-3 --frame=128 --at=0,0 --floor=125`, then `python -I tools/art/lock_to_still.py <cut.png> tools/art/sources/story/mentor_holding_frame0.png <target> --keep=0,1,2 --mirror`: frame 0 is the still and later frames draw only what moved from the generation's own frame 0, so nothing else flickers (`bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`).
