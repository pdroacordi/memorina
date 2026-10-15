---
id: story_daughter_guitar_out
command: animate3
target: res://assets/sprites/world/story/daughter/guitar_out.png
size: 64x64
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/daughter_guitar_out_2x.png
action: idle: a young girl holding a guitar out in front of her with both arms, offering it, breathing, the guitar bobbing a little, she waits; feet stay planted
keep: 0-3,2-1
generate: 8
source: pixellab
---
The daughter holding the guitar out to Ivo, an idle loop in 64x64 frames, facing east (05, 1d). "The child in the second shown frame is too static (and too different from the one in the first shwon frame)" (user, 2026-10-15; STORY-12). The still is her pose cut from tools/art/sources/story/opening_poses_codex.png (`--box=55,95,320,395 --height=22`) on a 64x64 frame (tools/art/sources/story/daughter_guitar_out_2x.png). PixelLab animate-with-text-v3 from it (frames in tools/art/sources/story/daughter_guitar_out/; frames 4-8 sprout stray specks over her, so 0-3 are kept back and forth), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/daughter_guitar_out daughter_guitar_out tools/art/sources/story/daughter_guitar_out_2x.png <out> --keep=0-3,2-1 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
