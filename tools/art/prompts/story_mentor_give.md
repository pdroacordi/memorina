---
id: story_mentor_give
command: animate3
target: res://assets/sprites/world/story/mentor/give.png
size: 128x128
frames: 4
view: side
direction: west
reference: res://tools/art/sources/story/mentor_hold_out_f3_2x.png
action: a tall ancient guardian of wood and frost, its arm held out with a small pan flute on its open hand, slowly lowers the arm and bows its pale mask a little, bringing the flute down to the chest height of a small man standing close in front of it; it stays in place
keep: 0-0,4-6
generate: 6
source: pixellab
---
The keeper lowers the flute to Ivo (STORY-35, `docs/knowledge/architecture/story35-memorina-hand-over.md`; design 05 Act 3 "(estende a flauta)", **[Presente]**). "Keeper lowers it (Recommended)" (user, 2026-11-22): the keeper's `Giving` strip lowers the flute about 30 px; Ivo takes it from where he stands. Stood in by `memorina_hand_over` as `Props/Mentor/Giving` (intro `give`, 0.1 / 0.15 / 0.15 s, held on 3).

Measured by script (2026-11-23). Canvas as `hold_out.png`: 128x128 frames, feet on row 125, offset (-61, -126) from his feet at (720, 672) with `flip_h`, so world x = 786 - file column, y = 546 + file row. In `hold_out.png` frame 3 the flute is file (18..31, 34..49), world x 755..768, y 580..595: 77..92 px over the floor, 19..34 px over Ivo's head (y 614 at `ivo_near` (776, 672)) and straight over his face (his nose is world x 764), so lowering it straight down would put it in his face. In frame 3 the flute is file (24..37, 64..79), world x 749..762, y 610..625 (centre (755.5, 617.5)): 30 px lower and 6 px back toward the keeper, its front 2 px short of Ivo's nose, its foot 1 px over the palm of `ivo_memorina_reach.png` frame 4. Frame 0 is `hold_out.png` frame 3 exactly; the flute is drawn in every frame.

Approved reference: `hold_out.png` frame 3 (`story_mentor_hold_out`), mirrored to face east as `tools/art/sources/story/mentor_hold_out_f3_2x.png`; our own art only (pack licences forbid AI training). Frames in `tools/art/sources/story/mentor_give/`. Built by `python -I tools/art/build_story35_hand_over.py`: the generation is cut (`cut_inhabitant.py ... --keep=0-6 --frame=128 --at=0,0 --floor=125`) and locked to `hold_out.png` frame 3 (`lock_to_still.py --mirror`), so only what moved is drawn over it; frames 1-3 are the generation's 4, 5, 6 with PixelLab's redrawn flute (taller, hanging) replaced by `hold_out` frame 3's own 14x16 flute over the arm's tip, kept 22 px or more from the frame's left edge. Colours: the mentor sheets' only.
Negative: outlines, black contour, front view, glow, text, ground, scenery, throwing, walking
