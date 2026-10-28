---
id: note_blank
command: generate
target: res://assets/sprites/hud/memorina/note_blank.png
size: 16x16
frames: 1
source: procedural: tools/art/draw_note_blank.py
---
The Memorina sheet's and the notebook's blank note slot: a note of a half-known song that is not known yet (SONG-14, architecture/half-songs). An empty key outline, dotted every other pixel, in the glyphs' mid outline value (104, 111, 153), inside the key glyphs' ink box (x 3-11, y 4-13 of 16), so it sits on the staff's middle line the size of a key. Drawn by `python -I tools/art/draw_note_blank.py assets/sprites/hud/memorina/note_blank.png`.
Negative: fill, glow, question mark, text
