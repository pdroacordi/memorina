---
id: portrait_guardian_summer
command: generate
target: res://assets/sprites/hud/portraits/guardian_summer.png
size: 92x96
frames: 1
view: side
direction: east
source: codex
---
The summer guardian (the Sun Guardian), restored and at peace: the dark porous volcanic stone head of the lion with small orange pores and a calm half-closed eye, its mane of flat sunray stone petals in ochre and pale gold fanned around the head, the top of its chest. A dialogue portrait for the speaker `guardian_summer` (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`, `systems/dialogue`): a head-and-shoulders bust facing right, 48 art px tall at 2x, shown in the box's 48x48 portrait slot. Drawn by Codex in one picture with the other GRD-04 guardian's bust (tools/art/sources/guardians/guardian_portraits_autumn_summer_codex.png, prompt beside it), with only our own art as references: the approved concepts (scarecrow_concept_codex_r1.png, sun_lion_concept_codex.png) and our portraits guardian_frost.png, guardian_bloom.png and ivo.png for the style. Cut by `python -I tools/art/cut_single_prop.py tools/art/sources/guardians/guardian_portraits_autumn_summer_codex.png assets/sprites/hud/portraits/guardian_summer.png --width=0 --height=48 --box=960,90,1700,887 --parts --palette=tools/art/sources/guardians/sun_lion_still.png`, snapped to the guardian's own colours; the box keeps the bust no wider than the 96 px slot. Then padded with one transparent art-px column on the left (90 -> 92 px), so the width is a multiple of 4 and the centred slot lands on the 2x grid (gotchas/a-centred-texture-rect-can-land-half-an-art-pixel-off-the-grid).
Negative: outlines, black contour, text, frame, background, speckle, gradients
