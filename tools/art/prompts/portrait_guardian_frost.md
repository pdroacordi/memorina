---
id: portrait_guardian_frost
command: generate
target: res://assets/sprites/hud/portraits/guardian_frost.png
size: 96x96
frames: 1
view: side
direction: east
source: codex
---
The Frost guardian, restored and at peace: a heavy ice golem with a dark blue-grey stone head and huge stone shoulders, pale blue ice crystals on its shoulders and the back of its head, a small calm pale-blue eye, a heavy brow, no mouth. A dialogue portrait for the speaker `guardian_frost` (GRD-08 / STORY-18, `architecture/guardian-performance-and-talks`, `systems/dialogue`): a head-and-shoulders bust of the restored face facing right, 48 art px tall at 2x, shown in the box's 48x48 portrait slot, matching the guardian's GRD-07 sprite. Drawn by Codex in one picture with the other guardian's bust (tools/art/sources/guardians/guardian_portraits_codex.png), with only our own art as references: the GRD-07 restored strip's frame 0 enlarged, our concept tools/art/sources/guardians/guardians_concept_codex.png, and our portraits mentor.png and ivo.png for the style. Cut by `python -I tools/art/cut_single_prop.py tools/art/sources/guardians/guardian_portraits_codex.png assets/sprites/hud/portraits/guardian_frost.png --width=0 --height=48 --box=1010,110,1760,875 --parts --palette=tools/art/sources/guardians/frost_still.png`, snapped to the guardian's own colours. Then padded with one transparent art-px column on the left (94 -> 96 px), so the width is a multiple of 4 and the centred slot lands on the 2x grid (`gotchas/a-centred-texture-rect-can-land-half-an-art-pixel-off-the-grid`); the box leaves off the leftmost back crystals so the bust is no wider than the 96 px slot (a wider texture would shrink by a non-integer factor).
Negative: outlines, black contour, text, frame, background, speckle, gradients
