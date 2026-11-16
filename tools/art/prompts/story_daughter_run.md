---
id: story_daughter_run
command: animate3
target: res://assets/sprites/world/story/daughter/run.png
size: 64x64
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/daughter_run_2x.png
action: running forward eagerly, a full run cycle, body leaning forward, knees lifting high, arms swinging, her braid flying behind her; always in right-facing profile
keep: 1-6
generate: 8
source: pixellab
---
The daughter running to Ivo at the reunion, a loop (STORY-07, `architecture/story-07-epilogue` §Art 3; stand-in: `walk.png` at pace 1). Measured: 64x64 frames at the 2x density, feet on row 61, body centred (columns 20-45, as `walk.png`); standing she is 22 art px (`standing.png`, rows 18-61), running about 21x15 art px. Palette: her own (`standing.png`, `walk.png`). The still is a Codex redraw of `standing.png` and `walk.png` on her pixel grid (our sprites the only references; tools/art/sources/story/daughter_run_codex.png), cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/daughter_run_codex.png tools/art/sources/story/daughter_run_cut.png --width=0 --height=21 --palette=assets/sprites/world/story/daughter/standing.png,assets/sprites/world/story/daughter/walk.png` and placed on a 64x64 canvas, feet on row 61, centred (tools/art/sources/story/daughter_run_2x.png). PixelLab animate-with-text-v3 from it (frames in tools/art/sources/story/daughter_run/; 0 is the still, 7 paints orange specks on her legs), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/daughter_run daughter_run tools/art/sources/story/daughter_run_2x.png <out> --keep=1-6 --floor=61 --centre=10-40`. Still approved for animation: "Filha correndo" (user, 2026-11-16). Clip approved: "Aprovar; boca à mão (Recommended)" (user, 2026-11-16).
Negative: outlines, black contour, front view, facing left, glow, motion lines, dust, text, ground, scenery
