---
id: story_mentor_lower
command: animate3
target: res://assets/sprites/world/story/mentor/lower.png
size: 128x128
frames: 4
view: side
direction: west
reference: res://tools/art/sources/story/mentor_holding_2x.png
action: a tall ancient guardian of wood and frost slowly lowers the hand holding a small pan flute from its chest down to its waist, as if tired, then raises it back up; its mask bows slightly with the hand; it stays in place
keep: 0-3
generate: 8
source: pixellab
---
The hand lowering on "Guardava. ~Guardava~." (`DLG_MENTOR_GIFT_09`; STORY-37; "Down and back (Recommended)", user, 2026-11-18): the hand sinks and comes back up within the line, so the phrase's `raise.png` still starts from Holding. Played by the `MentorLower` `LineGesture` as the line shows, then released to the Holding loop.

Measured: 4 drawn frames (0 Holding, 3 the lowest, the hand at about his waist) played 0 1 2 3 2 1 0 once, 0.1 / 0.15 / 0.15 / 0.7 / 0.2 / 0.2 / 0.1 s (1.6 s). The flute stays in the hand in every frame. Canvas: 128x128 frames, feet on row 125, frame (24, 6) is the stills' (0, 0); the strip sits at offset (-61, -126) from his feet at (720, 672) with `flip_h`, as `raise.png` and `play.png` (`systems/story`, STORY-11). The reference faces east (Holding); every kept frame is mirrored back to face west like his stills. Frame 0 is replaced at cut time by Holding exactly (`empty_hand.png` with `memorina_in_hand.png` at its place), so every cut to and from Holding is pixel-exact. Our own art only, never a pack sprite (the packs' licences forbid AI training). Plan: `docs/knowledge/architecture/story37-the-mentor-moves-while-he-talks.md`.

PixelLab returns the whole down-and-up; the kept frames are Holding and three on the way down (the generation's frames 0-3; from frame 4 the mantle thins). Cut by `python -I tools/art/cut_inhabitant.py <frames dir> story_mentor_lower tools/art/sources/story/mentor_holding_2x.png <out> --keep=0-3 --floor=125 --centre=60-124`, mirrored.
Negative: outlines, black contour, front view, glow, text, ground, scenery, dropping the flute, walking

As built (2026-11-18): the frames are in `tools/art/sources/story/mentor_lower/`; `python -I tools/art/cut_inhabitant.py tools/art/sources/story/mentor_lower story_mentor_lower tools/art/sources/story/mentor_holding_2x.png <cut.png> --keep=0-8 --frame=128 --at=0,0 --floor=125`, then `python -I tools/art/lock_to_still.py <cut.png> tools/art/sources/story/mentor_holding_frame0.png <target> --keep=0,1,2,3 --mirror`: frame 0 is the still and later frames draw only what moved from the generation's own frame 0, so nothing else flickers (`bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`).
