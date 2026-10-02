---
id: systems/art-pipeline
type: system
title: Art pipeline: contracts, generation and processing
status: active
tags: [art, pipeline, codex, pixellab, palette]
related: []
created: 2026-10-02
updated: 2026-10-02
source_files:
  - tools/art/process_image.gd
  - tools/art/prompts/README.md
---

# Art pipeline: contracts, generation and processing

Moved verbatim from `CLAUDE.md` ("Art pipeline") on 2026-10-02.

Art the game needs is a **contract** before it is a picture: `tools/art/prompts/<id>.md` gives its target path, frame size and frame count, and the generator prompt for it (appended to the one shared look in `tools/art/prompts/style.md`); `tools/art/prompts/README.md` is the format and the loop. `tools/art/make_placeholders.gd` draws the contract's exact sheet so scenes can use it before the art lands, and `art_prompt_test.gd` fails while any target is missing or mis-sized. Stills are drawn by Codex CLI (the `codex-consult` skill's image mode, on magenta, in the scratchpad); animations from a reference by `pixellab.ps1 generate -Prompt <id>`. `tools/art/process_image.gd` then keys the background out (an explicit `--key` everywhere, enclosed holes included), crops the frames to their shared bounds, snaps to `tools/art/palette.json` (extracted from the world art by `extract_palette.gd`) at full size, and scales each by ONE factor into its frame, bottom-centre, keeping each block's most common colour on a large shrink - proportions are never stretched, so a picture off the contract's aspect is re-prompted, not distorted. Pure steps live in `ImageOps` (tested). Never generate into `assets/`, never upload pack art as a reference (the GandalfHardcore and ZeggyGames licences forbid AI training), and credit everything in `CREDITS.md`.
