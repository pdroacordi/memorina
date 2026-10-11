---
id: ivo_idle
command: animate3
target: res://assets/sprites/characters/ivo/ivo_idle.png
size: 128x128
frames: 10
keep: 0-9
generate: 10
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_ref_64.png
action: idle (the approved pilot, PixelLab's ivo_idle64 frames cut to tools/art/sources/ivo/ivo_idle_pilot_strip.png; never regenerated)
source: pixellab
---
Ivo's `idle` sheet (serves idle, memorina_draw (0-2), memorina_idle (2-4)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). The approved pilot (PixelLab animate-with-text-v3 from `ivo_ref_64.png`, 10 frames). Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo ivo_idle_pilot_strip tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_idle.png --keep=0-9 --frame=128 --at=32,34 --strip=64`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 32,34 in the 128 px frame. The approved pilot strip is re-framed, not regenerated ("Yes, do the rest (Recommended)", user, 2026-10-11).
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
