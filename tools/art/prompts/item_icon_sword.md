---
id: item_icon_sword
command: generate
target: res://assets/sprites/hud/items/item_icon_sword.png
size: 16x16
frames: 1
view: side
no_background: true
shading: basic shading
detail: low detail
source: codex
---
An item icon for the item-acquired notice (UI-11, `systems/notices`): 16x16 art px drawn at 2x on the 640x360 HUD, the size of the notebook's quill (`assets/sprites/hud/notebook/icon_quill.png`, 16x16) beside which it shows, on its left. The sword (`Enums.PlayerItem.SWORD`): a plain sword with a simple cross-guard and a leather-wrapped grip, laid on a diagonal from bottom-left (pommel) to top-right (tip) so it fills the 16x16 frame. It must read as the same object as the farmhouse pickup (`assets/sprites/world/pickups/sword.png`, our art, the only reference). A bold, readable silhouette with few flat colours at medium brightness and no outline (the user's "no outlines", `style.md`), so it reads over any room; no ground line, centred in its frame with a 1 px margin. Drawn 2026-10-16: one Codex sheet of the three icons (the notebook's own icons and the story-cast board the only references), kept in tools/art/sources/hud/item_icons_codex.png, cropped per icon and processed by `tools/art/process_image.gd --prompt=item_icon_sword --key=#ff00ff`.
Negative: outlines, black contours, scabbard, shield, ornate hilt, gems, glow, hand, person, text, letters, background, frame, border, shadow on the ground, blur, noise, dithering
