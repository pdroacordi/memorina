---
id: story_mentor_holding_breathe
command: cut
cut_from: story_mentor_breathe
target: res://assets/sprites/world/story/mentor/holding_breathe.png
size: 128x128
frames: 4
keep: 0-3
view: side
direction: west
source: pixellab
---
The mentor breathing with the Memorina in his hand, the `Holding` `StagedStrip` loop (STORY-37; "Keeps breathing (Recommended)", user, 2026-11-18). No generation of its own: the frames of `story_mentor_breathe` (`empty_hand_breathe.png`) with `memorina_in_hand.png` pasted on the hand at Holding's place, the flute baked in because the runtime overlay is gone. Played as the breathe strip (0 1 2 3 2 1, 1.75 s). Canvas: 128x128 frames, feet on row 125, frame (24, 6) is the stills' (0, 0); the strip sits at offset (-61, -126) from his feet at (720, 672) with `flip_h`, as `raise.png` and `play.png` (`systems/story`, STORY-11). The reference faces east (Holding); every kept frame is mirrored back to face west like his stills. Frame 0 is replaced at cut time by Holding exactly (`empty_hand.png` with `memorina_in_hand.png` at its place), so every cut to and from Holding is pixel-exact. Our own art only, never a pack sprite (the packs' licences forbid AI training). Plan: `docs/knowledge/architecture/story37-the-mentor-moves-while-he-talks.md`.

As built (2026-11-18): the frames are in `tools/art/sources/story/mentor_breathe/`; `python -I tools/art/cut_inhabitant.py tools/art/sources/story/mentor_breathe story_mentor_breathe tools/art/sources/story/mentor_holding_2x.png <cut.png> --keep=0-3 --frame=128 --at=0,0 --floor=125`, then `python -I tools/art/lock_to_still.py <cut.png> tools/art/sources/story/mentor_holding_frame0.png <target> --keep=0,1,2,3 --mirror --still-box=17,14,43,48`: frame 0 is the still and later frames draw only what moved from the generation's own frame 0, so nothing else flickers (`bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`). The box is the flute and the hand under it, kept from the still in every frame.
