---
id: gotchas/flattening-a-shrunk-codex-cut-erases-small-pictograms
type: gotcha
title: A pictogram on a prop under about 12 art px (a note, a recipe, a tally) vanishes when cut_props shrinks and flattens it; draw it pixel by pixel or redraw the prop at size
status: active
tags: [art, props, codex, pixellab, pictograms, cut-props, world-11]
related: [systems/props, systems/art-pipeline]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - tools/art/draw_pictograms.py
  - tools/art/clean_prop.py
---

## What happens

`cut_props.py` reduces a Codex object by each block's most common colour and `--flat=7` keeps 7 colours per object.
At Ivo's scale a pinned note is 5 to 10 art px; its dark pictogram is a minority in every block, and the 7 colours
go to the paper and the wood, so the cut is a blank square. WORLD-11's house of notes lost every note, the recipe's
egg and flower and the tally marks; the lanterns' lit panes and the cart's spokes turned to mush the same way.

## What to do

- A story mark that must read (a note, a recipe, a sign's pictogram) is drawn on the art grid from a template
  (`tools/art/draw_pictograms.py`) in the cut props' own colours, and placed as its own prop over the furniture.
- A small prop that turned to mush is redrawn at its exact art size by PixelLab pixflux with the board's cut at 1x as
  the init image (`pixellab.ps1 generate -Width -Height -NoBackground -Reference`), then `clean_prop.py`.
- Making the prop bigger to save its mark breaks its size against Ivo; check `prop_grounding_test`'s size tables.
