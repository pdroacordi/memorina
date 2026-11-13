---
id: story_bearer_autumn
command: generate
target: res://assets/sprites/story/bearers/autumn/frame_1_base.png
size: 384x176
frames: 1
view: side
no_background: false
source: codex
---
STORY-04 bearer fragment, autumn: the hollow bone, "a mão inquieta" (design `drafts/camada_pessoal.md` §3; plan `docs/knowledge/architecture/story-04-bearer-fragments.md`, "The look" and "Art"). Four engraved frames of one memory, each an opaque canvas of 384x176 art px (1 px per art px, drawn at Sprite2D scale 2: 768x352 game px; the view between the bars is 320x144 art px, so a pan reaches 64x32). Every canvas holds only the four neutral greys of `tools/art/cut_engraving.py` (`GREYS`: #3c3c3c, #606060, #8c8c8c, #b8b8b8) and the key ink #FF00FF, which `engraving.gdshader` tints with the song's `SeasonPalette`; the greys go through `gh_print`. Only ink-only layers move ("only ink moves; the grey never does").

Files (all in `assets/sprites/story/bearers/autumn/`; the target above is the first, the test checks it):

| Frame | Caption (pt_BR, draft) | Base | Moving ink layers (`ink_only`, tileable, suggested drift px/s) |
|---|---|---|---|
| 1 | Ele nunca ficava num lugar até a folha cair. | `frame_1_base.png`: the young man on a cliff edge, wind at his back, orchards and hills below | `frame_1_wind.png` (wind, drift 10,0), `frame_1_leaves.png` (leaves, drift 9,2) |
| 2 | A ave que ele não conseguiu manter. | `frame_2_base.png`: an orchard; he kneels holding the fallen bird and looks up after the flock flying off | `frame_2_birds.png` (birds, drift 6,-2) |
| 3 | Aprendeu que soltar também é uma canção. | `frame_3_base.png`: on a stone wall he plays the bone flute; all the leaves let go at once, the trees bare | `frame_3_leaves.png` (leaves, drift 6,5) |
| 4 | Foi o único que partiu sem pedir para ficar. | `frame_4_base.png`: the bone-and-leaf scarecrow holds the flute on a cord; he walks away small, with the wind | `frame_4_leaves.png` (leaves, drift 8,2), `frame_4_wind.png` (wind, drift 10,0) |

Made by Codex image generation (codex-consult image mode, 2026-11-13), two calls: the first board (`tools/art/sources/story/bearers/autumn/board_v1_codex.png`) drew him twice in frame 2, so it was given back to fix that panel alone (`autumn/board_codex.png`, kept), a portrait board of four wide strips with the approved winter board (`frost/board_codex.png`) as the look reference and our own guardian stills (`guardians_ref.png`) for the scarecrow. Prompt: the LOOK/LAYOUT block of `tools/art/sources/story/bearers/prompt_style.txt` with the ink "a warm autumn ORANGE-RED (#d0561a)", then the four panels of `autumn/frames.txt`. Codex tinted the figures' fills in a pale orange, so the cut raises the ink's least chroma.
Cut: `python -I tools/art/cut_engraving.py board tools/art/sources/story/bearers/autumn/board_codex.png assets/sprites/story/bearers/autumn --ink=#d0561a "--shift=1:-110,0;3:-60,0;4:10,0" --chroma=0.42`. Moving layers: `motes <out> wind --count=10 --seed=31` and `leaves --count=14 --seed=32` (1), `birds --count=7 --seed=33` (2), `leaves --count=45 --seed=34` (3), `leaves --count=20 --seed=35` and `wind --count=8 --seed=36` (4).
Negative: text, letters, signature, black ink, white highlights, second ink colour, soft gradients, blur, frame border
