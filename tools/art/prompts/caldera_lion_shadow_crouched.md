---
id: caldera_lion_shadow_crouched
command: generate
target: res://assets/sprites/world/props/summer_caldera/lion_shadow_crouched.png
size: 224x100
frames: 1
view: side
no_background: true
source: procedural: tools/art/burned_shadow.py
---
The Sun Guardian's burned shadow (crouched): its own frame as a flat char silhouette at alpha 136 on caldera_arena's back wall (GRD-04: "a lion of porous volcanic stone whose shadow stays burned on the ground"; "sombra depois", user, 2026-10-30; the board's proposal, "your proposition", user, 2026-11-20). `python -I tools/art/burned_shadow.py assets/sprites/characters/guardians/summer_guardian/summer_guardian_charge_windup.png 3 <out>`. Approved with the board docs/design/drafts/guardian_regions_dressing_board.md (user, 2026-11-20: "approved"; the sheets shown at game size before placing). Sized against Ivo's 29 art px (tools/art/region_prop_sizes.json, tools/art/interior_prop_sizes.json).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, glow, blur, text, people
