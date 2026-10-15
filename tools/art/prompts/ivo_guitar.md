---
id: ivo_guitar
command: animate3
target: res://assets/sprites/characters/ivo/ivo_guitar.png
size: 128x128
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/ivo_guitar_still_2x.png
action: strumming an acoustic guitar: the right hand brushes down and up across the strings over the sound hole, the head nods gently with the beat; feet stay planted, the guitar stays in place
keep: 0-3,2-1
generate: 8
source: pixellab
---
Ivo playing his guitar, a simple strumming loop (STORY-10; "the sprite for playing the guitar is very wrong. Not the style of Ivo character. Better redo it. Also, transform it into animation, not static. Simple animation", user, 2026-10-15). The still is Ivo's own idle frame with only his arms changed and the guitar added: Codex redrew it on his pixel grid from that frame and a layout sketch (tools/art/sources/story/ivo_guitar_still_codex.png), cut by `python -I tools/art/cut_single_prop.py tools/art/sources/story/ivo_guitar_still_codex.png <out> --width=0 --height=29 --palette=assets/sprites/characters/ivo/ivo_idle.png,assets/sprites/world/props/interiors/ivo_house/guitar.png` and pasted on a 128x128 frame (head column on x 64, feet on row 96): tools/art/sources/story/ivo_guitar_still_2x.png. The loop is PixelLab animate-with-text-v3 from that frame (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/story/ivo_guitar_still_2x.png -Frames 8 -Action "<action>"`; frames kept in tools/art/sources/story/ivo_guitar_strum/; frames 4-6 squashed his body and turned his face, so only 0-3 are kept, played back and forth), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_guitar_strum ivo_guitar_strum tools/art/sources/story/ivo_guitar_still_2x.png assets/sprites/characters/ivo/ivo_guitar.png --keep=0-3,2-1 --floor=95 --centre=36-56`.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery
