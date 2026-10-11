---
id: ivo_sit
command: animate3
target: res://assets/sprites/characters/ivo/ivo_sit.png
size: 128x128
frames: 10
keep: 0-9
generate: 10
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_seated_64.png
action: resting: the same man, always in right-facing profile, sits at rest on a low bench that is not drawn, hands on his knees, breathing slowly and deeply, his shoulders rising and falling, his head nodding a little; his short hair and the ends of his blue scarf stir gently with each breath; he stays seated, boots flat on the ground
source: pixellab
---
Ivo's `sit` sheet (serves sit): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_seated_64.png` (64 px canvas), 10 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_sit`; the returned frames are kept in tools/art/sources/ivo/sit/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/sit ivo_sit tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_sit.png --keep=0-9 --frame=128 --at=34,34`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 34,34 in the 128 px frame. The first frame is the seated pose of the Codex pose sheet; his thighs sit at the bench's seat (19 px above the floor).
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
