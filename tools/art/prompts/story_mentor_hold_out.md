---
id: story_mentor_hold_out
command: animate3
target: res://assets/sprites/world/story/mentor/hold_out.png
size: 128x128
frames: 4
view: side
direction: west
reference: res://tools/art/sources/story/mentor_holding_2x.png
action: a tall ancient guardian of wood and frost slowly stretches its arm forward and a little down, offering the small pan flute in its open hand to someone small standing in front of it, and holds it there; its mask looks down at the flute; it stays in place
keep: 0-3
generate: 6
source: pixellab
---
The flute held out on "Muitas mãos. Nenhuma ~guardou~." (`DLG_MENTOR_GIFT_02`; the approved draft `docs/design/drafts/story32_34_talks.md` says "(estende a flauta)"; STORY-37, "Out, until the gift (Recommended)", user, 2026-11-18). Played by the `MentorHoldOut` `LineGesture` (`holds`): its last frame stays until the gift beat stands `EmptyHand` in. STORY-35 (the hand-over as a scene) starts from that last frame.

Measured: 4 drawn frames played 0..3 once, 0.1 / 0.15 / 0.15 s, then held on 3 (0.4 s to the hold); the generation's frames 4-6 thin the mantle and were dropped. The arm ends out toward Ivo standing at `ivo_near` (776, 672), 56 px east of his feet; the flute lies on the open hand. Canvas: 128x128 frames, feet on row 125, frame (24, 6) is the stills' (0, 0); the strip sits at offset (-61, -126) from his feet at (720, 672) with `flip_h`, as `raise.png` and `play.png` (`systems/story`, STORY-11). The reference faces east (Holding); every kept frame is mirrored back to face west like his stills. Frame 0 is replaced at cut time by Holding exactly (`empty_hand.png` with `memorina_in_hand.png` at its place), so every cut to and from Holding is pixel-exact. Our own art only, never a pack sprite (the packs' licences forbid AI training). Plan: `docs/knowledge/architecture/story37-the-mentor-moves-while-he-talks.md`.

Cut by `python -I tools/art/cut_inhabitant.py <frames dir> story_mentor_hold_out tools/art/sources/story/mentor_holding_2x.png <out> --keep=0-3 --floor=125 --centre=60-124`, mirrored.
Negative: outlines, black contour, front view, glow, text, ground, scenery, throwing, walking

As built (2026-11-18): the frames are in `tools/art/sources/story/mentor_hold_out/`; `python -I tools/art/cut_inhabitant.py tools/art/sources/story/mentor_hold_out story_mentor_hold_out tools/art/sources/story/mentor_holding_2x.png <cut.png> --keep=0-6 --frame=128 --at=0,0 --floor=125`, then `python -I tools/art/lock_to_still.py <cut.png> tools/art/sources/story/mentor_holding_frame0.png <target> --keep=0,1,2,3 --mirror`: frame 0 is the still and later frames draw only what moved from the generation's own frame 0, so nothing else flickers (`bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`).
