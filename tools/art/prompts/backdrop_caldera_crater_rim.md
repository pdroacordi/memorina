---
id: backdrop_caldera_crater_rim
command: generate
target: res://assets/sprites/world/background/summer_caldera/crater_rim.png
size: 512x72
frames: 1
source: procedural: tools/art/draw_crater_rim.py
---
The rim layer of `resources/world/backdrops/caldera_crater.tres`, drawn after the basalt wall at its scroll (0.55, 0.32) its 64th row on the row over the wall's top (`horizon_row` -59 = the wall's -123 + 64) and its last 8 rows over the wall itself, the same pixels, so no row opens between the two quads, so the open crater's inner wall ends in a ragged ridge of basalt column tops instead of a straight line across the near layer's floor (WORLD-32; design 04 section 6: "Uma sala alta que atravessa o horizonte mostra o céu em cima e os estratos embaixo"). Measured: the wall is 512 px wide at 2x and repeats on both axes; the rim is the wall's own texture continued upward (rim row r copies wall row (r - 32) mod 256, art px), so the wall and the rim are the same pixels from the row over the wall's top down (`backdrop_set_test.test_a_straight_topped_layer_is_covered_by_the_next`). Columns 8-16 art px wide, 7-24 art px over the wall's top, tops tilted by up to 3 art px, a lit top face two steps over the wall's lightest value, a shaded front edge, a little ash on the caps (the ash tiles' darkest value), joints that fade out before the wall's top; at least 8 empty art rows over the tallest column (10 with seed 30). One band (no seasons on basalt), NONE above and below. Drawn by `python -I tools/art/draw_crater_rim.py assets/sprites/world/background/basalt_caves/far.png assets/sprites/world/background/summer_caldera/crater_rim.png` (seed 30, picked of 60 for the most varied ridge with no long low stretch).
Negative: outlines, straight top line, battlements, regular steps, glow, lava, light source, text, speckle, high contrast
