# The art prompt library

One file per asset the game needs art for: its **frame contract** (where the
sheet lands, its frame size and count) and the **words** that ask PixelLab for
it. The contract is the law; the prompt is how we try to meet it.
`tests/tools/art/art_prompt_test.gd` checks every entry is sound and that its
target exists at exactly the contract's size - placeholders count, so code can
land before art does.

## An entry: `<id>.md`

```
---
id: pressure_plate                 ; must equal the file name
command: generate                  ; generate | animate
target: res://assets/sprites/world/props/pressure_plate/pressure_plate.png
size: 32x12                        ; ONE frame, WxH, in game pixels
frames: 2                          ; frames side by side in the sheet
view: side                         ; side | low top-down | high top-down
direction: west                    ; characters face LEFT (the scenes flip them)
no_background: true
outline: single color black outline
shading: basic shading
detail: medium detail
source: pixellab                   ; or "pack: <file>" when cropped from a licensed pack
reference:                         ; animate / seed only - OUR art, never a pack's
action:                            ; animate only
---
A worn stone floor plate set flush into earth, ...
Negative: text, watermark, background scenery
```

(The `;` notes above are explanation, not syntax - an entry has plain
`key: value` lines.) The body is the description; `Negative:` is the negative
prompt. Both are appended to the shared preamble in `style.md`, which is where
the project-wide look lives.

## The loop

1. **Write the entry** (or find it). Size it from the scene that will use it:
   tiles are 32 px, Ivo is 96 px at 2x, props sit on 32 px cells.
2. **Placeholder first**: `"<godot>" --headless --path . -s res://tools/art/make_placeholders.gd`
   draws the contract's exact sheet, so the scene can reference the target now.
3. **Generate** (costs credits - see the `pixellab` skill):
   `.\tools\pixellab\pixellab.ps1 generate -Prompt pressure_plate`
   writes to `%TEMP%\pixellab\` (never into `assets/`).
4. **Look at it.** Read the PNG. Reject anything that breaks `style.md`.
5. **Process into the contract**:
   `"<godot>" --headless --path . -s res://tools/art/process_image.gd -- --prompt=pressure_plate --in=<png>`
   keys out the background (flood fill from the edges), cuts and resizes the
   frames (nearest neighbour), snaps to `tools/art/palette.json`, packs the
   strip into `target`. Then `--import`.
6. **Credit it** in `CREDITS.md` (PixelLab-generated, or the pack).

A pack-sourced asset (`source: pack: ...`) skips step 3: crop it from the
pack yourself and run step 5 on the crop - the contract and palette still apply.

## Rules learned the hard way (mostly from FAG-orbita's art pipeline)

- **Pin the palette.** Generated art that is not snapped to the world's colours
  never sits in the world. `tools/art/extract_palette.gd` rebuilds the palette
  from the tiles and backgrounds.
- **Background is keyed from the edges**, never by "remove anything magenta":
  a purple body stays purple.
- **Thick shapes at small sizes.** A 32x12 prop drawn with fine detail turns to
  mud when snapped to 1:1 pixels. Ask for bold silhouettes and few colours.
- **One thing per frame.** No scenery, floor or background painted into a
  prop's or a character's frames.
- **Bodies centred in their frame** (an off-centre body jumps on every flip).
- **Never upload a third-party pack's art as a PixelLab reference** - the
  GandalfHardcore license forbids AI training. References are our own art.
- **Never generate straight into `assets/`.** Art enters the project only
  through step 5, after a look.
