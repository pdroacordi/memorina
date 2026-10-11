---
id: ivo_land
command: animate3
target: res://assets/sprites/characters/ivo/ivo_land.png
size: 128x128
frames: 9
keep: 1-9
generate: 10
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_ref_64.png
action: hard landing: the same man, always in right-facing profile, lands hard from a high fall: he drops at once into a deep crouch with one hand touching the ground, holds it, then slowly straightens back up into his standing pose; his short hair and the ends of his blue scarf bounce down on the impact and settle as he rises; his sword stays in its scabbard at his hip
source: pixellab
---
Ivo's `land` sheet (serves land (0.75 s = LandingStats.hard_land_time)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_ref_64.png` (64 px canvas), 10 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_land`; the returned frames are kept in tools/art/sources/ivo/land/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/land ivo_land tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_land.png --keep=1-9 --frame=128 --at=32,34`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 32,34 in the 128 px frame.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
