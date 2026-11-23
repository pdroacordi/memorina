# dressing_frost_edge_concept_codex.png

Look-only dressing concept for WORLD-13 Frost Edge and the lighthouse (frost_shore beside lighthouse_base) (board `docs/design/drafts/early_regions_dressing_board.md`), Codex image generation, 2026-11-22. Not shipped; the prop sheets follow its approval.

- Reference attached: `tools/art/references/regions/board_frost_edge.png` (our own approved WORLD-30 style board), downscaled to 40% (880 px wide). No pack art, nothing from `assets/`.
- Command: `codex exec -s workspace-write --skip-git-repo-check --ephemeral -C <scratchpad>/<dir> -i board_frost_edge.png - < prompt.txt` (codex-consult image mode). The raw file is kept unprocessed, 1619x971.
- Second generation. The first, from the same prompt without the 'nearly monochrome grey' paragraph and the figurehead's 'lying on its side', came back cold blue at full saturation and was dropped.

## Prompt

```text
Draw ONE set-dressing concept picture for a 2D side-view pixel-art metroidvania called Memorina. Look: minimalist 16-bit pixel art for a 2D side-view metroidvania set in a lived-in medieval valley, crisp hard pixels, no anti-aliasing, no smooth gradients, simple flat shapes with clear silhouettes and few details, limited palette, base colours at MEDIUM brightness, no outlines, no baked lighting, glow or cast shadows, no text.

The attached image is our own approved style board for this region (our own art, not a pack): match its ground tiles, its backdrop layers, its sky colours and the building front shown in its mock screen. The small hero figure in the board's mock screen must NOT appear in your picture.

Composition: a wide side-view game screen, landscape about 1620 px wide by 970 px tall (5:3). Strict side view like a platformer: flat ground along the bottom with the board's exposed-top tiles, the parallax backdrop layers behind, props standing on the ground line at their real scale (a man would be about 60 px tall in this picture; a door about 80 px). Props sit behind the play space as dressing; leave the walkable floor readable and clear.

Region: Frost Edge (winter, the frozen sea coast under a lighthouse, memory 0.05: almost fully forgotten). The whole picture is NEARLY MONOCHROME GREY: about 95 percent desaturated, neutral greys from light ash to dark slate, NOT blue, with only the faintest whisper of the original hues (the lighthouse's red band and the pennant are a dull grey with the barest hint of red, the sky a flat pale grey, the frozen sea grey-white). Compare the board's grey value-check picture: it should look almost like that. Grey here means STOPPED TIME, not a colour filter: everything that would move is held frozen mid-gesture.
Show two neighbouring rooms side by side as one continuous shore, split about 60/40:
LEFT (frost_shore): the dark sea-cliff stone ground with a snow lip from the board; the dark wooden hull of a wrecked ship lying broken on the shore with a snapped mast leaning, its spar and a TORN SAIL frozen mid-flap, stiff in the air; on a rock spur at the far left a carved wooden gull figurehead (a ship's bow carving, wings folded) lying on its side half buried in the snow, a round buoy beside it, frozen kelp and ice crust hanging on the rock faces; a rope coil and a barrel washed up; an iron anchor at the foot of a great frozen breaker wave whose curl is suspended in the air, spray droplets hanging still above it.
RIGHT (lighthouse_base): the base of the white masonry lighthouse with its red band and arched wooden door from the board's mock screen; a fog bell hanging on a wooden post; oil cans and an iron coal bin by the door (door itself clear); a tall flagpole with a TORN PENNANT frozen mid-flap, rigid and sideways; a low iron railing at the right edge on the lookout; gull nests with old feathers on ledges; snowy rocks, frost moss, snow drifts, icicles.
Background: the board's frozen sea backdrop: frozen waves and ice floes stopped mid-surge, pale winter sky (#8094aa to #d0d8de), all near grey.
No ice-arena pieces, no claw marks, no monster, no guardian.

No people, no hero, no animals except those named above. No text, no labels, no UI, no frame border.
Avoid: blurry, anti-aliased, smooth gradient, photorealistic, painterly, 3d render, text, watermark, signature, noisy dithering, busy texture, speckle, neon colours, black outline, outlines, baked lighting, very dark image.

Use your image generation tool EXACTLY ONCE; do not regenerate or draw variants. Do NOT resize, crop or post-process the generated file. Copy it byte-for-byte to ./raw.png in the current directory, then reply with only its pixel size.
```
