---
id: story_mentor_breathe
command: animate3
target: res://assets/sprites/world/story/mentor/empty_hand_breathe.png
size: 128x128
frames: 4
view: side
direction: west
reference: res://tools/art/sources/story/mentor_holding_2x.png
action: a tall ancient guardian of wood and frost stands still and breathes slowly, its mantle of lichen rising and falling one pixel at the shoulders and hem, its pale wooden mask lifting slightly on the inhale; its raised hand does not move; it stays in place
keep: 0-3
generate: 4
source: pixellab
---
The mentor breathing while he talks (05, Act 3; STORY-37: "o guardião poderia ter mais animações enquanto fala", user, 2026-11-17, then "Respirar + gestos (Recommended)"; "Keeps breathing (Recommended)", user, 2026-11-18). The `EmptyHand` `StagedStrip` of `Props/Mentor` loops it from the gift to `mentor_goes_still`; `story_mentor_holding_breathe` is the same frames with the flute pasted on the hand, the `Holding` loop.

Measured: 4 drawn frames played 0 1 2 3 2 1 and looped, 0.375 / 0.25 / 0.25 / 0.375 / 0.25 / 0.25 s (1.75 s a breath). The motion is 1 art px (2 game px) at most: the shoulders, the hem and the mask; the raised hand stays on its pixels in every frame, so the flute pasted on it in the Holding loop never detaches. Canvas: 128x128 frames, feet on row 125, frame (24, 6) is the stills' (0, 0); the strip sits at offset (-61, -126) from his feet at (720, 672) with `flip_h`, as `raise.png` and `play.png` (`systems/story`, STORY-11). The reference faces east (Holding); every kept frame is mirrored back to face west like his stills. Frame 0 is replaced at cut time by Holding exactly (`empty_hand.png` with `memorina_in_hand.png` at its place), so every cut to and from Holding is pixel-exact. Our own art only, never a pack sprite (the packs' licences forbid AI training). Plan: `docs/knowledge/architecture/story37-the-mentor-moves-while-he-talks.md`. Frame 0 of this strip is `empty_hand.png` alone (no flute).

Cut by `python -I tools/art/cut_inhabitant.py <frames dir> story_mentor_breathe tools/art/sources/story/mentor_holding_2x.png <out> --keep=0-3 --floor=125 --centre=60-124`, mirrored, frame 0 replaced by the still; a frame where the hand moved has its hand pasted back from frame 0.
Negative: outlines, black contour, front view, glow, text, ground, scenery, walking, arm movement

As built (2026-11-18): the frames are in `tools/art/sources/story/mentor_breathe/`; `python -I tools/art/cut_inhabitant.py tools/art/sources/story/mentor_breathe story_mentor_breathe tools/art/sources/story/mentor_holding_2x.png <cut.png> --keep=0-3 --frame=128 --at=0,0 --floor=125`, then `python -I tools/art/lock_to_still.py <cut.png> tools/art/sources/story/mentor_empty_hand_frame0.png <target> --keep=0,1,2,3 --mirror --still-box=17,14,43,48`: frame 0 is the still and later frames draw only what moved from the generation's own frame 0, so nothing else flickers (`bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`). The box is the flute and the hand under it, kept from the still in every frame.
