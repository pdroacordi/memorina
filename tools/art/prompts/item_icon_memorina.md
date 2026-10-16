---
id: item_icon_memorina
command: generate
target: res://assets/sprites/hud/items/item_icon_memorina.png
size: 16x16
frames: 1
view: side
no_background: true
shading: basic shading
detail: low detail
source: codex
---
An item icon for the item-acquired notice (UI-11, `systems/notices`): 16x16 art px drawn at 2x on the 640x360 HUD, the size of the notebook's quill (`assets/sprites/hud/notebook/icon_quill.png`, 16x16) beside which it shows, on its left. The Memorina (`Enums.PlayerItem.MEMORINA`): a small pan flute patched by many hands, its pipes of different lengths and different materials (bone, reed, wood, metal), bound by a cord, upright, filling the frame. It must read as the same instrument Ivo plays (`assets/sprites/characters/ivo/` Memorina clips and the mentor's `memorina_in_hand`, our art, the only references). A bold, readable silhouette with few flat colours at medium brightness and no outline (the user's "no outlines", `style.md`), so it reads over any room; no ground line, centred in its frame with a 1 px margin. Drawn 2026-10-16: one Codex sheet of the three icons (the notebook's own icons and the story-cast board the only references), kept in tools/art/sources/hud/item_icons_codex.png, cropped per icon and processed by `tools/art/process_image.gd --prompt=item_icon_memorina --key=#ff00ff --no-palette`; the world palette swallowed the pipes' materials, so it keeps its own colours, and a stray cord pixel was removed.
Negative: outlines, black contours, single flute, recorder, horn, glow, music notes, hand, person, text, letters, background, frame, border, shadow on the ground, blur, noise, dithering
