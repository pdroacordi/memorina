# The art prompt library

One file per asset the game needs art for: its **frame contract** (where the
sheet lands, its frame size and count) and the **words** that ask an image
generator for it (Codex CLI by default, PixelLab for animations). The contract is the law; the prompt is how we try to meet it.
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
source: codex                      ; codex | pixellab | "pack: <file>" | "procedural: <tool>"
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
3. **Generate**, never into `assets/`:
   - **Codex** (the default for a still, `source: codex`): the `codex-consult`
     skill's image mode turns the entry into a prompt on a magenta background
     and draws it in the scratchpad. Give thin or tall subjects their aspect
     in numbers.
   - **PixelLab** (animations from a reference, `source: pixellab`; costs
     credits - see the `pixellab` skill):
     `.\tools\pixellab\pixellab.ps1 generate -Prompt pressure_plate`
     writes to `%TEMP%\pixellab\`.
4. **Look at it.** Read the PNG. Reject anything that breaks `style.md`.
5. **Process into the contract**:
   `"<godot>" --headless --path . -s res://tools/art/process_image.gd -- --prompt=pressure_plate --in=<png> --key=#ff00ff`
   keys out the background, cuts the frames and crops them to their shared
   bounds, snaps to `tools/art/palette.json` at full size, then scales each by
   ONE factor into its frame, bottom-centre (a big shrink keeps each block's
   most common colour), and packs the strip into `target`. Then `--import`,
   and look at it enlarged: a 64x12 sheet is unreadable at 1x.
6. **Credit it** in `CREDITS.md` (Codex- or PixelLab-generated, or the pack).

A pack-sourced asset (`source: pack: ...`) skips step 3: crop it from the
pack yourself and run step 5 on the crop - the contract and palette still apply.

## Rules learned the hard way (mostly from FAG-orbita's art pipeline)

- **Pin the palette.** Generated art that is not snapped to the world's colours
  never sits in the world. `tools/art/extract_palette.gd` rebuilds the palette
  from the tiles and backgrounds.
- **Background is keyed from the edges** when the key is guessed from the
  corner, so a purple body stays purple. An explicit `--key` is a colour the
  subject was drawn WITHOUT, so it is cleared everywhere - including the holes
  a subject encloses (a ring's eye, the gaps in a braid).
- **Proportions are kept, never stretched.** A picture off the contract's
  aspect ends up smaller than its frame; re-prompt with the aspect in numbers
  rather than distorting pixel art.
- **Thick shapes at small sizes.** A 32x12 prop drawn with fine detail turns to
  mud when snapped to 1:1 pixels. Ask for bold silhouettes and few colours.
- **One thing per frame.** No scenery, floor or background painted into a
  prop's or a character's frames.
- **Bodies centred in their frame** (an off-centre body jumps on every flip).
- **Never upload a third-party pack's art to a generator as a reference** -
  the GandalfHardcore and ZeggyGames licences forbid AI training. References
  are our own art.
- **Never generate straight into `assets/`.** Art enters the project only
  through step 5, after a look.
