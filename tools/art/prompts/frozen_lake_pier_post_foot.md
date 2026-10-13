---
id: frozen_lake_pier_post_foot
command: generate
target: res://assets/sprites/world/props/frozen_lake/pier_post_foot.png
size: 16x12
frames: 1
view: side
source: procedural: tools/art/draw_post.py
---
The foot of a pier post where it enters the lake (WORLD-29): a pale ripple row one art px wider than the post on each side, on the waterline, then the post pulled toward the lake's dark blue in two flat steps (half, then three quarters). `pier_post.tscn` draws it at absolute z 52, over the lake (50) and ice (51), under the void (60). Drawn by `python -I tools/art/draw_post.py assets/sprites/world/props/frozen_lake/pier_post_foot.png --height=6 --foot`.
Negative: outlines, black contours, speckle, noise, dither, gradients, perspective, foam, splash, glow, blur, text, letters, numbers, people
