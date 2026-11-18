---
id: story_mentor_wake_raise
command: animate3
target: res://assets/sprites/world/story/mentor/wake_raise.png
size: 128x96
frames: 6
keep: 0-5
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/mentor_grey_ref.png
action: the tall old hooded man in a long grey robe stiffly lifts his empty hand toward his mask as if holding a flute that is not there; the hand stops at the wrong place, beside the mask, fingers clawed around nothing; a small jerk; the arm drops back to his side; his hand stays empty; seen from the side facing left the whole time
source: pixellab
---
The flute raised the wrong way, the last beat of the awakening (STORY-38, `docs/knowledge/architecture/story38-the-keeper-wakes.md`), answered "Mão vazia (Recommended)" (user, 2026-11-17, Q4): the Memorina is in Ivo's hands since the gift and every mentor guardian clip plays an absent flute (`guardian_mentor_play_song`). It plays inside `mentor_wakes.tres` (0.8 s) as the `RaisingWrong` `StagedStrip` of `Props/Mentor` (intro `wake_raise`), the bridge from the keeper to the guardian body, as "B, com a ponte (Recommended)" (user, 2026-11-17) was for the opening's turn.

Measured: 6 frames in the guardian's own sheet format, 128x96 art px each, 1 px per art px, drawn like the body: the strip at (720, 576), Sprite2D scale (-2, 2), centred, so facing east in game and west in the file. Held unevenly: per-frame durations 0.1 to 0.25 s, 0.8 s in all (the `SpriteFrames` durations, speed 10). The last frame is `mentor_guardian_idle.png` frame 0 exactly (art bbox (47, 36)..(90, 96), feet on art row 95), so the cut to the body at the scene's end does not jump (`mentor_wakes_test.test_the_raise_ends_on_the_guardians_first_frame`); the first is that frame too. Made: frames 0 and 5 are idle frame 0 exactly; frames 1-4 are PixelLab frames 1, 3, 5, 7 of one run, cut by `tools/art/cut_inhabitant.py` (`--write=1 --floor=191 --drop=45`), raws in `tools/art/sources/guardians/guardian_mentor_wake_raise/` and `guardian_mentor_wake_raise_cut.png`. Held 0.1, 0.15, 0.2, 0.1, 0.15, 0.1 s. Approved: "Aprovar as quatro (Recommended)" (user, 2026-11-17). Reference: `tools/art/sources/guardians/mentor_grey_ref.png` (the guardian's own grey at 2x), with `mentor_play_grey_2x.png` for the hand at the mask; our own art only, never a pack sprite (the packs' licences forbid AI training). Cut as `guardian_mentor_play_song`, then frame 5 replaced by idle frame 0 with `tools/art/compose_strip.py`.
Negative: outlines, black contour, front view, facing right, turning around, flute, pipe, instrument, glow, sparks, colour, motion lines, text, ground, scenery
