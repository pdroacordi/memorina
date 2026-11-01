---
id: lighthouse_lamp
command: generate
target: res://assets/sprites/world/props/frost_edge/lighthouse_lamp.png
size: 64x112
frames: 2
view: side
no_background: true
source: codex
---
The great lamp of the lighthouse lantern (lighthouse_top, GRD-06), hung from the lantern's roof over the hatch. Seen straight on from the side: a short iron chain from the top edge to a squat iron cap, under it a tall rounded beehive lens of stacked glass rings (four or five bands) in a thin dark iron cage, a small iron drip-cup at the bottom. Frame 1 unlit: the glass cold and pale blue-grey, the rings marked by slightly darker bands. Frame 2 lit: the same lamp, the glass warm amber and pale gold, its centre band the lightest; no halo, rays or glow outside the glass (the scene adds the light). Both frames the same silhouette, pixel for pixel, so the lighting is a cross-fade. One Codex image generation (tools/art/sources/props/lighthouse_lamp_codex.png); the unlit half cut by `python -I tools/art/cut_single_prop.py <raw> <out> --width=30 --height=56 --palette= --flat=10 --box=0,0,715,1106`, and the lit frame is that frame with its glass recoloured amber, the centre band pale gold, so the two match pixel for pixel. `lighthouse_lamp_chain.png` (64x10) is rows 12-21 of the sheet, one chain link repeated from the roof (y 64) down to the lamp (y 114). The world's restoration lights it ("The lamp is lit.", mentor_final, approved 2026-10-30); `Lamp` in lighthouse_top_contents.tscn is a FactStaging, Lit on SCENE_SEEN world_restoration. Approved: "Aprovar a arte" (user, 2026-11-01).
Negative: outlines, black contour, halo, rays, glow, bloom, light beams, perspective, ceiling, floor, background, text, people
