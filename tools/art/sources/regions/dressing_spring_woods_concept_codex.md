# dressing_spring_woods_concept_codex.png

Look-only dressing concept for WORLD-14 Spring Woods (woods_edge beside woods_deep) (board `docs/design/drafts/early_regions_dressing_board.md`), Codex image generation, 2026-11-22. Not shipped; the prop sheets follow its approval.

- Reference attached: `tools/art/references/regions/board_spring_woods.png` (our own approved WORLD-30 style board), downscaled to 40% (880 px wide). No pack art, nothing from `assets/`.
- Command: `codex exec -s workspace-write --skip-git-repo-check --ephemeral -C <scratchpad>/<dir> -i board_spring_woods.png - < prompt.txt` (codex-consult image mode). The raw file is kept unprocessed, 1619x971.
- One generation.

## Prompt

```text
Draw ONE set-dressing concept picture for a 2D side-view pixel-art metroidvania called Memorina. Look: minimalist 16-bit pixel art for a 2D side-view metroidvania set in a lived-in medieval valley, crisp hard pixels, no anti-aliasing, no smooth gradients, simple flat shapes with clear silhouettes and few details, limited palette, base colours at MEDIUM brightness, no outlines, no baked lighting, glow or cast shadows, no text.

The attached image is our own approved style board for this region (our own art, not a pack): match its ground tiles, its backdrop layers, its sky colours and the building front shown in its mock screen. The small hero figure in the board's mock screen must NOT appear in your picture.

Composition: a wide side-view game screen, landscape about 1620 px wide by 970 px tall (5:3). Strict side view like a platformer: flat ground along the bottom with the board's exposed-top tiles, the parallax backdrop layers behind, props standing on the ground line at their real scale (a man would be about 60 px tall in this picture; a door about 80 px). Props sit behind the play space as dressing; leave the walkable floor readable and clear.

Region: Spring Woods (spring, a blossoming forest of giant trunks, memory 0.4: colours gently softened but still green and pink). Use the board's forest earth with moss and blossom lip, its mossy cave rock, and its layered trunk-and-canopy backdrop with blossom.
Show two neighbouring rooms side by side as one continuous wood, split about 55/45:
LEFT (woods_edge): the woodcutter's log cabin with its grassy turf roof and stone chimney from the board's mock screen (no smoke: the hut is empty and cold); beside it the woodcutter's chopping block with an axe stuck in it, a neat log stack and a wooden saw horse; ferns and small wildflowers along the floor; a pink blossom tree to the right of the cabin; the base of one giant tree trunk rising behind the cabin out of the top edge.
RIGHT (woods_deep): huge old trunk bases with wide buttress roots standing behind raised earth ledges, bracket shelf fungus stepping up the trunks, clusters of small mushrooms and ferns on a root mound, long strands of hanging moss from branches, a mossy stump and mossy rocks, a fallen mossy log, flowering bushes, pink blossom petals drifting in the air at backdrop depth.
Background: the board's spring backdrop of layered trunks and blossoming canopies, soft blue spring sky (#5688c8 to #bad6e4).
No webs, no spiders, no creatures.

No people, no hero, no animals except those named above. No text, no labels, no UI, no frame border.
Avoid: blurry, anti-aliased, smooth gradient, photorealistic, painterly, 3d render, text, watermark, signature, noisy dithering, busy texture, speckle, neon colours, black outline, outlines, baked lighting, very dark image.

Use your image generation tool EXACTLY ONCE; do not regenerate or draw variants. Do NOT resize, crop or post-process the generated file. Copy it byte-for-byte to ./raw.png in the current directory, then reply with only its pixel size.
```
