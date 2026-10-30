---
id: portrait_guardian_autumn
command: generate
target: res://assets/sprites/hud/portraits/guardian_autumn.png
size: 92x96
frames: 1
view: side
direction: east
source: codex
---
The autumn guardian (the Leaf Guardian), restored and at peace: its round, slightly cracked bone mask with two dark eye holes and a stitched mouth, a hood of dry autumn leaves around and behind it, the top of its thin bone shoulders. A dialogue portrait for the speaker `guardian_autumn` (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`, `systems/dialogue`): a head-and-shoulders bust facing right, 48 art px tall at 2x, shown in the box's 48x48 portrait slot. Drawn by Codex in one picture with the other GRD-04 guardian's bust (tools/art/sources/guardians/guardian_portraits_autumn_summer_codex.png, prompt beside it), with only our own art as references: the approved concepts (scarecrow_concept_codex_r1.png, sun_lion_concept_codex.png) and our portraits guardian_frost.png, guardian_bloom.png and ivo.png for the style. Cut by `python -I tools/art/cut_single_prop.py tools/art/sources/guardians/guardian_portraits_autumn_summer_codex.png assets/sprites/hud/portraits/guardian_autumn.png --width=0 --height=48 --box=60,110,830,887 --parts --palette=tools/art/sources/guardians/scarecrow_still.png`, snapped to the guardian's own colours; the box keeps the bust no wider than the 96 px slot. The stitched mouth does not survive the reduction to 48 art px, so it is painted back by hand after the cut: a 5 art px line at art row 22, x 31-35, with stitches above and below at x 32 and 34, in the still's darkest colour (75, 32, 24).
Negative: outlines, black contour, text, frame, background, speckle, gradients
