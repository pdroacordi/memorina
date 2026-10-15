---
id: ivo_memorina_play
command: animate3
target: res://assets/sprites/characters/ivo/ivo_memorina_play.png
size: 128x128
frames: 8
view: side
direction: east
reference: res://tools/art/sources/story/ivo_memorina_still_2x.png
action: playing a small pan flute held at his lips with both hands: he breathes into it, his shoulders rise and fall softly and his head sways a little with the melody; feet stay planted, the flute stays at his mouth
keep: 2-6,5-3
generate: 8
source: pixellab
---
Ivo playing the Memorina, a loop for every performance (`memorina_idle`). "Should have an animation for when playing memorina too." (user, 2026-10-15; STORY-11). The still is his own idle frame with the hands and the pan flute taken from a Codex redraw on his pixel grid (tools/art/sources/story/ivo_memorina_still_codex.png; its torso had turned to skin, so only the hands and flute were kept over the idle frame): tools/art/sources/story/ivo_memorina_still_2x.png. PixelLab animate-with-text-v3 from it (frames in tools/art/sources/story/ivo_memorina_play/; 0-1 repeat the still and 7 changes his hair, so 2-6 are kept, back and forth), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_memorina_play ivo_memorina_play tools/art/sources/story/ivo_memorina_still_2x.png <out> --keep=2-6,5-3 --floor=95 --centre=36-56`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
