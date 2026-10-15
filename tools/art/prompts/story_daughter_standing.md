---
id: story_daughter_standing
command: animate3
target: res://assets/sprites/world/story/daughter/standing.png
size: 64x64
frames: 8
view: side
direction: east
reference: res://tools/art/sources/story/daughter_standing_2x.png
action: idle: a young girl standing quietly, breathing slowly, her braid swaying a little, she shifts her weight and looks down then up; feet stay planted
keep: 0-7
generate: 8
source: pixellab
---
Ivo's daughter standing, an idle loop, 22 art px in 64x64 frames, facing east. "The child in the second shown frame is too static (and too different from the one in the first shwon frame)" (user, 2026-10-15; STORY-12). The still is the same girl as her guitar pose, redrawn by Codex on that pose's pixel grid with empty hands (tools/art/sources/story/daughter_standing_codex.png), cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/daughter_standing_codex.png <out> --width=0 --height=22 --palette=assets/sprites/world/story/daughter/guitar_out.png` onto a 64x64 frame (tools/art/sources/story/daughter_standing_2x.png). PixelLab animate-with-text-v3 from it (frames in tools/art/sources/story/daughter_standing/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/daughter_standing daughter_standing tools/art/sources/story/daughter_standing_2x.png <out> --frames=8 --floor=61 --centre=10-40`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
