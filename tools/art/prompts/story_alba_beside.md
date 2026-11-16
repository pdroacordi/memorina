---
id: story_alba_beside
command: animate3
target: res://assets/sprites/world/story/alba/beside.png
size: 64x64
frames: 4
view: side
direction: east
reference: res://tools/art/sources/story/alba_beside_v2_2x.png
action: seated upright on a low stone that is not drawn, turned toward someone seated close beside her, hands in her lap, breathing slowly with a slight gentle smile, her head tilting a little; her braid hangs still down her back; she stays seated, feet flat on the ground
keep: 0-2,1-1
generate: 8
source: pixellab
---
Alba seated beside Ivo on the flat stone, turned to him with a slight smile (line 07), a loop (STORY-07, `architecture/story-07-epilogue` §Art 2). Rejected v1 (not kept; its strips and frames are not in the repo): "a proporção está errada" and "refazer alba e tbm o ivo nessa sentado, o cara tá esquisitão" (user, 2026-11-16). v1 was 22 art px with her lap 6 art px over her feet, so on the stone it was lifted 3 art px and her head stood 1-3 art px above Ivo's.

Targets: 64x64 frames at the 2x density, feet on row 61, facing east (the scene flips her to face Ivo); her lap 9 art px over her feet (the stone's seat, as Ivo's), a short seated torso, 20 art px from the soles to the hair top, so seated her head top is 2 art px below `ivo_sit`'s (22), as standing she is shorter (26 to 29 art px); her head her standing head's size (7 rows, 8-9 wide); no lift on the stone. Palette: her own (`standing.png`, `sit.png`).

The still: her v1 `beside` frame 0 re-laid by hand in art px (head rows 0-6, one neck row, three torso rows, the lap, six shin rows: tools/art/sources/story/alba_beside_v2_paste.png), then redrawn clean by Codex at that size (references `standing.png` frame 0, the paste and `ivo_sit.png` frame 0, enlarged 20x; two plain redraws before it drew her head far too big), tools/art/sources/story/alba_beside_v2_codex.png, cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/alba_beside_v2_codex.png tools/art/sources/story/alba_beside_v2_cut.png --width=0 --height=20 --palette=assets/sprites/world/story/alba/standing.png,assets/sprites/world/story/alba/sit.png` (10x20 art px), her eye at art (7,4) and mouth at art (6,5) set to (142,69,33) by hand, and placed on a 64x64 canvas, feet on row 61, centred (tools/art/sources/story/alba_beside_v2_2x.png). Still approved: "Aprovar os dois" (user, 2026-11-16).

The clip: PixelLab animate-with-text-v3 from the still (frames in tools/art/sources/story/alba_beside/; a first take swung her braid out behind her, so the action asks it to hang still; in this second take she turns to face the viewer from frame 3, so 0-2 are kept, back and forth), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/alba_beside alba_beside_v2b tools/art/sources/story/alba_beside_v2_2x.png <out> --keep=0-2,1-1 --floor=61`. Clip approved: "Aprovar" (user, 2026-11-16).

Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, a drawn seat, crouching
