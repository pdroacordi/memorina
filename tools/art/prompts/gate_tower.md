---
id: gate_tower
command: generate
target: res://assets/sprites/world/props/village/gate_tower.png
size: 80x198
frames: 1
view: side
source: codex
---
The top of a village gate tower seen straight on (no perspective, no side wall): a square shaft of the bell tower's tan rough ashlar with one dark timber band, two timber posts and one narrow arched slit window, under a steep pyramid roof of the village's red clay tiles that comes to one point at the horizontal centre, with a small dark finial; the eaves stand a little past the shaft. The shaft is cut straight across at the bottom (it continues into the gatehouse, which is the room's ground).
Why: "Cover with a tall gate tower (Recommended)" (user, 2026-10-13: "Draw each border gatehouse a little taller (a tower or roof peak above the seam) so the cut stays hidden behind it, the same way other seams hide behind stone."). It stands on the village's two border pillars (village_lane_west local x 0, village_gate_east local x 1280, position y 16), the shaft's 64 px on the pillar's two cells, the roof's point on the seam column up to 178 px over the room tops, above the highest frame (160 px over the tops, the ring), so the backdrop cut between two regions stays behind it (`backdrop_seams_test.test_a_gate_tower_covers_its_cut`). Art only: a prop never collides.
Drawn by Codex (one call, 2026-10-13; our bell_tower_facade.png, tavern_facade.png and the approved village_concept.png the only references), kept as tools/art/sources/village/gate_tower_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/village/gate_tower_codex.png assets/sprites/world/props/village/gate_tower.png --width=40 --palette=assets/sprites/world/props/village/bell_tower_facade.png,assets/sprites/world/props/village/tavern_facade.png`: 40 art px wide, 2x density, in the colours of the two fronts. Anchor (the shaft's bottom centre, the scene's -offset): 40,198.
Negative: outlines, black contour, perspective, side wall, lit windows, glow, text, letters, people, animals, trees, ground, sky, clouds, scenery
