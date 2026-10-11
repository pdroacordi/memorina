---
id: ivo_run
command: animate3
target: res://assets/sprites/characters/ivo/ivo_run.png
size: 128x128
frames: 8
keep: 0-7
generate: 8
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_run_flight_64.png
action: sprint cycle, a run and never a walk: the same man, always in right-facing profile, sprints on the spot without moving across the frame; this first frame is the flight phase, both boots in the air; each stride he lands on the front foot under his hips, pushes off hard and leaps into the next flight phase with his whole body rising, the leading knee driven up high and the trailing leg stretched far behind; torso leaning forward, fists pumping hard opposite the legs; his short hair streams back and bounces with each leap, the ends of his blue scarf fly out behind him; his sword stays in its scabbard at his hip
source: pixellab
---
Ivo's `run` sheet (serves run): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_run_flight_64.png` (64 px canvas), 8 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_run`; the returned frames are kept in tools/art/sources/ivo/run/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/run ivo_run tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_run.png --keep=0-7 --frame=128 --at=32,34`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 32,34 in the 128 px frame. Redone after "I find that some animation that should be improved of Ivo are his pushing and his running. His running seems only like a walk." (user, 2026-10-11). Three earlier takes from standing or striding poses kept both feet on the ground; the first frame is now a stride lifted 4 px off the floor (generated frame 5 of the third take), so the cycle has a flight phase: frames 0, 1, 5 and 6 are off the ground.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
