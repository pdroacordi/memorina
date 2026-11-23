# dressing_threshold_concept_codex.png

Look-only dressing concept for WORLD-12 Threshold Road (threshold_fields) (board `docs/design/drafts/early_regions_dressing_board.md`), Codex image generation, 2026-11-22. Not shipped; the prop sheets follow its approval.

- Reference attached: `tools/art/references/regions/board_threshold.png` (our own approved WORLD-30 style board), downscaled to 40% (880 px wide). No pack art, nothing from `assets/`.
- Command: `codex exec -s workspace-write --skip-git-repo-check --ephemeral -C <scratchpad>/<dir> -i board_threshold.png - < prompt.txt` (codex-consult image mode). The raw file is kept unprocessed, 1619x971.
- One generation.

## Prompt

```text
Draw ONE set-dressing concept picture for a 2D side-view pixel-art metroidvania called Memorina. Look: minimalist 16-bit pixel art for a 2D side-view metroidvania set in a lived-in medieval valley, crisp hard pixels, no anti-aliasing, no smooth gradients, simple flat shapes with clear silhouettes and few details, limited palette, base colours at MEDIUM brightness, no outlines, no baked lighting, glow or cast shadows, no text.

The attached image is our own approved style board for this region (our own art, not a pack): match its ground tiles, its backdrop layers, its sky colours and the building front shown in its mock screen. The small hero figure in the board's mock screen must NOT appear in your picture.

Composition: a wide side-view game screen, landscape about 1620 px wide by 970 px tall (5:3). Strict side view like a platformer: flat ground along the bottom with the board's exposed-top tiles, the parallax backdrop layers behind, props standing on the ground line at their real scale (a man would be about 60 px tall in this picture; a door about 80 px). Props sit behind the play space as dressing; leave the walkable floor readable and clear.

Region: Threshold Road (winter, a farm on the road out of the village that stopped at its meal and its harvest; the world is half forgotten, colours a little greyed). Room shown: the fields around the farmhouse (threshold_fields), the thatched stone farmhouse front from the board's mock screen at centre-right with its plank shed.
Dressing, all on the ground line:
- grey wheat in tall uncut stands along the floor, frost-grey and pale gold, thinned in front of the farmhouse; the wheat is FROZEN MID-SWAY: every stalk bent the same way in one held gust, ears tilted, stopped like a photograph;
- on a low earth knoll at the left, a winter scarecrow in grey-brown rags and a torn coat, one ragged sleeve lifted and held still mid-flutter, a battered hat, with ONE black crow perched on its outstretched arm;
- broken fence runs with snapped rails left of the knoll and right of the house; a SECOND black crow perched still on one fence post;
- an abandoned wooden cart tipped over on a broken wheel, with one bound sheaf of wheat beside it and a loose unbound sheaf;
- a scythe left standing upright in the wheat;
- a lone bare leafless field tree on the right rise;
- dry thistles, snowy rocks, a dead shrub, low snow drifts.
Far background: the board's winter backdrop: an empty plain with a low horizon, mist, distant fence posts, pale grey-blue winter sky (#8094aa to #d0d8de) with soft pixel clouds.

No people, no hero, no animals except those named above. No text, no labels, no UI, no frame border.
Avoid: blurry, anti-aliased, smooth gradient, photorealistic, painterly, 3d render, text, watermark, signature, noisy dithering, busy texture, speckle, neon colours, black outline, outlines, baked lighting, very dark image.

Use your image generation tool EXACTLY ONCE; do not regenerate or draw variants. Do NOT resize, crop or post-process the generated file. Copy it byte-for-byte to ./raw.png in the current directory, then reply with only its pixel size.
```
