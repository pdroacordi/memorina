---
id: story_daughter_window
command: animate3
target: res://assets/sprites/world/story/daughter/window.png
size: 64x64
frames: 4
view: side
direction: north
reference: res://tools/art/sources/story/daughter_window_2x.png
action: seen from behind, standing on tiptoe with her hands on a high window sill that is not drawn, looking out and waiting; she rises a little higher on her toes and settles back, her braid swaying on her back; she never turns around
keep: 0-2,1-1
generate: 6
source: pixellab
---
The daughter at the house window with her back to the room, waiting for Ivo, a loop (STORY-07, `architecture/story-07-epilogue` §Art 4, optional; stand-in: `standing.png` flipped). The playtest (`playtests/2026-11-16-story07-walk-home-reunion`) found that at zoom 1 the stand-in reads as standing by the table, since the window hangs high (y 200) over it; this pose faces the window. Measured: 64x64 frames at the 2x density, feet on row 61, body centred; standing she is 22 art px (`standing.png`, rows 18-61), on tiptoe with her arms up about 24x11 art px to her fingertips. Palette: her own (`standing.png`, `walk.png`). The still is a Codex redraw from her own sprites (the only references; tools/art/sources/story/daughter_window_codex.png), cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/daughter_window_codex.png tools/art/sources/story/daughter_window_cut.png --width=0 --height=24 --palette=assets/sprites/world/story/daughter/standing.png,assets/sprites/world/story/daughter/walk.png` and placed on a 64x64 canvas, feet on row 61, centred (tools/art/sources/story/daughter_window_2x.png). PixelLab animate-with-text-v3 from it (frames in tools/art/sources/story/daughter_window/; from frame 3 she lowers her arms and steps, so 0-2 are kept, back and forth), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/daughter_window daughter_window tools/art/sources/story/daughter_window_2x.png <out> --keep=0-2,1-1 --floor=61 --centre=10-40`. Still approved for animation: "Filha na janela" (user, 2026-11-16). Clip approved: "Aprovar; boca à mão (Recommended)" (user, 2026-11-16).
Negative: outlines, black contour, front view, face, side view, glow, text, ground, scenery, a drawn window
