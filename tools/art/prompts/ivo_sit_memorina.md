---
id: ivo_sit_memorina
command: animate3
target: res://assets/sprites/characters/ivo/ivo_sit_memorina.png
size: 128x128
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/ivo_sit_memorina_v2_2x.png
action: seated on a low bench that is not drawn, playing a small pan flute held at his lips with both hands: he breathes into it, his shoulders rise and fall softly and his head sways a little with the melody; he stays seated, boots flat on the ground, the flute stays at his mouth; always in right-facing profile
keep: 0-3,2-1
generate: 8
source: pixellab
---
Ivo seated on the flat stone playing the Memorina, the loop of the epilogue (STORY-07, `architecture/story-07-epilogue` §Art 1). Rejected v1 (not kept; its strips and frames are not in the repo): "a proporção está errada" and "refazer alba e tbm o ivo nessa sentado, o cara tá esquisitão" (user, 2026-11-16). v1 was 24 art px tall, its upper body 15 art px over the seat against `ivo_sit`'s 13, and cut 2 art px east of the sit axis.

Targets, measured on `ivo_sit.png` frame 0: 128x128 frames at the 2x density, feet on row 95; 22 art px from the soles to the hair top, lap 9 art px over the soles (the stone's seat, 18 game px), 13 art px from the seat to the head top, head 8x8 art px; the legs' centroid on `ivo_sit`'s (within 1 art px), so the seated clips never jump; upright and relaxed, the flute at his lips with both hands under his chin. Palette: his own (`tools/art/sources/ivo/ivo_palette.png`) plus the flute's from `ivo_memorina_play.png`.

The still: a Codex redraw in three calls (references `ivo_sit.png` frame 0, `ivo_idle.png` frame 0 and `ivo_memorina_play.png` frame 0, enlarged 20x; the third moved the flute up to his lips from the first; the second drew him standing and was not used), tools/art/sources/story/ivo_sit_memorina_v2_codex.png, cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/ivo_sit_memorina_v2_codex.png tools/art/sources/story/ivo_sit_memorina_v2_cut.png --width=0 --height=22 --palette=tools/art/sources/ivo/ivo_palette.png,assets/sprites/characters/ivo/ivo_memorina_play.png` (12x22 art px) and placed on a 128x128 canvas, feet on row 95, its legs' centroid on `ivo_sit`'s (tools/art/sources/story/ivo_sit_memorina_v2_2x.png). Still approved: "Aprovar os dois" (user, 2026-11-16).

The clip: PixelLab animate-with-text-v3 from the still (frames in tools/art/sources/story/ivo_sit_memorina/; 4-6 lean his head far back, so 0-3 are kept, back and forth), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_sit_memorina ivo_sit_memorina_v2 tools/art/sources/story/ivo_sit_memorina_v2_2x.png <out> --keep=0-3,2-1 --floor=95` (no `--centre`: the still already sits on the axis and the frames do not drift). Clip approved: "Aprovar" (user, 2026-11-16).

Negative: outlines, black contour, front view, facing left, glow, music notes, text, ground, scenery, a drawn seat
