---
id: story_ivo_memorina_take
command: animate3
target: res://assets/sprites/characters/ivo/ivo_memorina_take.png
size: 128x128
frames: 10
view: side
direction: east
reference: res://tools/art/sources/story/ivo_memorina_take_f0_2x.png
action: his raised hand closes around the small pan flute and he slowly brings it down and in, holding it in front of his chest, looking at it; feet stay planted; always in right-facing profile
keep: 0-2,2-2,4-1,1-1,1-1
generate: 8
source: pixellab
---
Ivo taking the Memorina (STORY-35, `docs/knowledge/architecture/story35-memorina-hand-over.md`; pose `MEMORINA_HELD`, then `memorina_hold`). 10 frames, once: frames 0-2 at 0.125 s, frames 3-9 at 0.1 s (1.075 s). It ends on `ivo_memorina_lower.png` frame 1, the flute held in front of his chest ("Ivo holds it under his chin, breathing", user, 2026-11-22), so `memorina_lift` (lower 1, 0) and `memorina_put_away` (lower 1, 2, 3) follow without a pop.

Measured by script (2026-11-23). Frame 0 = `ivo_memorina_reach.png` frame 4 with `give.png` frame 3's flute moved by (+53, -30) (mentor file to Ivo file at `ivo_near` facing west: world x = 786 - mentor column = 839 - Ivo column, y = 546 + mentor row = 576 + Ivo row), to file (77..90, 34..49), and five 2x2 finger blocks closed over its foot. Of the keeper's 180 flute pixels, 160 are drawn identically here and 20 lie under the fingers; no flute pixel lies outside them. Frames 1-2 = the generation's frames 1 and 2 (frame 1 moved 2 px back, so his legs stand where frame 0's do); frame 3 = frame 2 with its rows remapped (head top 34 to 33, shoulders 50, waist 62 to 64, feet 95) and its flute redrawn as the keeper's at 14x12; frames 4-7 = frames 4, 3, 2, 1 of a second generation from `ivo_memorina_lower.png` frame 1 (action "slowly lifts the small pan flute in his hand forward and up to the height of his eyes in front of him, his arm reaching out", frames `raise_rev_*.png`, played backward), each with its back arm replaced by `ivo_memorina_lower.png` frame 1's (rows 50-79, columns 0-57) and its flute replaced by the keeper's scaled to 11x10, 9x8, 7x6 and 5x4; frame 8 = `ivo_memorina_lower.png` frame 1 with the hand 2 px higher; frame 9 = `ivo_memorina_lower.png` frame 1 exactly. Measured by script (2026-11-23): the flute's pixels right of column 70 run 160, 156, 164, 120, 77, 53, 29, 14, 12, 12, so from frame 2 it only shrinks and loses at most 44 px a frame. Before, frame 3 dropped it from 160 px to 12 in one frame while the figure changed drawing (STORY-35 playtest, "noticeable at speed"). The change of drawing, from the reach generation's proportions to `ivo_memorina_lower`'s, now falls between frames 3 and 4, with the flute still 120 px and the arm forward on both sides of it. Every frame: feet row 95, whole-frame centroid 63.2..66.5.

Approved reference: `ivo_memorina_reach.png` frame 4 with `give.png` frame 3's flute (`tools/art/sources/story/ivo_memorina_take_f0_2x.png`). Frames in `tools/art/sources/story/ivo_memorina_take/`; the generation's frames 3-8 were dropped (PixelLab swelled the flute to the size of his torso). Built by `python -I tools/art/build_story35_hand_over.py`. Colours: Ivo's palette, the Memorina still and the keeper's flute (`tools/art/sources/story/ivo_memorina_take_palette.png`, written by the build; the keeper's flute adds 3 colours to the Memorina still's, so `ivo_sheet_test` `HELD_PROPS` names that strip for this sheet).
Negative: outlines, black contour, front view, glow, text, ground, scenery, playing, blowing
