---
id: item_icon_bread
command: generate
target: res://assets/sprites/hud/items/item_icon_bread.png
size: 16x16
frames: 1
view: side
no_background: true
shading: basic shading
detail: low detail
source: codex
---
An item icon for the item-acquired notice (UI-11, `systems/notices`): 16x16 art px drawn at 2x on the 640x360 HUD, the size of the notebook's quill (`assets/sprites/hud/notebook/icon_quill.png`, 16x16) beside which it shows, on its left. The round loaf from the bakery (`Enums.PlayerItem.BREAD`): one round, domed country loaf with a scored cross on its crust, golden-brown, seen from the side and a little above, filling most of the frame. Script draft 2 ("Approve draft 2 (Recommended)", user, 2026-10-15): "Bread. The round one." A bold, readable silhouette with few flat colours at medium brightness and no outline (the user's "no outlines", `style.md`), so it reads over any room; no ground line, centred in its frame with a 1 px margin. Drawn 2026-10-16: one Codex sheet of the three icons (the notebook's own icons and the story-cast board the only references), kept in tools/art/sources/hud/item_icons_codex.png, cropped per icon and processed by `tools/art/process_image.gd --prompt=item_icon_bread --key=#ff00ff`.
Negative: outlines, black contours, long loaf, baguette, two loaves, basket, plate, hand, person, text, letters, background, frame, border, shadow on the ground, blur, noise, dithering
