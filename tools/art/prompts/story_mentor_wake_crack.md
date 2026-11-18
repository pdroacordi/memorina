---
id: story_mentor_wake_crack
command: generate
target: res://assets/sprites/world/story/mentor/wake_crack.png
size: 128x128
frames: 5
view: side
direction: east
no_background: true
source: procedural: tools/art/crack_reveal.py
---
The grey cracking on the keeper as he wakes (STORY-38, `docs/knowledge/architecture/story38-the-keeper-wakes.md`): after the turn, the stasis grey splits and the guardian's darker, corrupted grey shows through; he does not move. The user: "ele não espera encontrar o guardião que antes ele conversava agora agressivo" (2026-11-17), and asked for "Cena de despertar (Recommended)". It plays inside `mentor_wakes.tres` (0.7 s) as the `Cracking` `StagedStrip` of `Props/Mentor` (intro `wake_crack`); it replaced the placeholder (a 0.7 s cross-fade from Stasis to the guardian's idle frame). Approved: "Aprovar as quatro (Recommended)" (user, 2026-11-17).

Measured: 5 frames at 8 fps (0.625 s), 128x128 each, the turn's canvas: feet on row 125, offset (-67, -126) from his feet at (720, 672), drawn facing east, not flipped. Frame 0 is Stasis exactly: `stasis.png` mirrored at canvas (24..109, 6..125). The guardian's idle frame 0 is 43x60 art px (art bbox (47, 36)..(90, 96) of its 128x96 frame), so at its Sprite2D scale 2 it is 86x120 px, the stills' size and top (y 552), standing 9 px west of mirrored Stasis: at canvas (15..100, 6..125). Frame 4 shows that guardian grey through the cracks over Stasis's silhouette; it need not equal the guardian frame, since `RaisingWrong` follows and ends on it. Made procedurally, with no generation: PixelLab animate-with-text-v3 from the mirrored still padded 2x (`tools/art/sources/story/mentor_stasis_east_2x.png`) twice dissolved the figure instead of cracking it. `python -I tools/art/crack_reveal.py <stasis mirrored> 24,6 <idle frame 0 mirrored, 2x nearest, cropped to its bbox> 15,6 <out> 128x128 5 --start=80,16 --seed=7`: seeded random-walk cracks grow down from the mask on the 2x art grid, show the guardian's grey through them, and pale flakes fall from their edges; frame 0 is mirrored Stasis exactly (`mentor_wakes_test.test_the_strips_meet_the_stills`). Our own art only, never a pack sprite.
Negative: outlines, black contour, front view, moving, turning, glow, flash, sparks, colour, motion lines, text, ground, scenery
