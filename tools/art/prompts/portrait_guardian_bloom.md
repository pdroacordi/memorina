---
id: portrait_guardian_bloom
command: generate
target: res://assets/sprites/hud/portraits/guardian_bloom.png
size: 92x96
frames: 1
view: side
direction: east
source: codex
---
The Bloom guardian, restored and at peace: a tree-stag spirit with a pale cream deer-skull face, a calm dark eye, tall brown branch antlers with pink blossoms, a mossy green mantle with pink flowers over pale wood shoulders. A dialogue portrait for the speaker `guardian_bloom` (GRD-08 / STORY-18, `architecture/guardian-performance-and-talks`, `systems/dialogue`): a head-and-shoulders bust of the restored face facing right, 48 art px tall at 2x, shown in the box's 48x48 portrait slot, matching the guardian's GRD-07 sprite. Drawn by Codex in one picture with the other guardian's bust (tools/art/sources/guardians/guardian_portraits_codex.png), with only our own art as references: the GRD-07 restored strip's frame 0 enlarged, our concept tools/art/sources/guardians/guardians_concept_codex.png, and our portraits mentor.png and ivo.png for the style. Cut by `python -I tools/art/cut_single_prop.py tools/art/sources/guardians/guardian_portraits_codex.png assets/sprites/hud/portraits/guardian_bloom.png --width=0 --height=48 --box=30,30,820,875 --parts --palette=tools/art/sources/guardians/bloom_still.png,assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_restored.png`, snapped to the guardian's own colours.
Negative: outlines, black contour, text, frame, background, speckle, gradients
