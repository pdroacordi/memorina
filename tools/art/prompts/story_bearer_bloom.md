---
id: story_bearer_bloom
command: generate
target: res://assets/sprites/story/bearers/bloom/frame_1_base.png
size: 384x176
frames: 1
view: side
no_background: false
source: codex
---
STORY-04 bearer fragment, spring: the living stem, "a mão de terra" (design `drafts/camada_pessoal.md` §3; plan `docs/knowledge/architecture/story-04-bearer-fragments.md`, "The look" and "Art"). Four engraved frames of one memory, each an opaque canvas of 384x176 art px (1 px per art px, drawn at Sprite2D scale 2: 768x352 game px; the view between the bars is 320x144 art px, so a pan reaches 64x32). Every canvas holds only the four neutral greys of `tools/art/cut_engraving.py` (`GREYS`: #3c3c3c, #606060, #8c8c8c, #b8b8b8) and the key ink #FF00FF, which `engraving.gdshader` tints with the song's `SeasonPalette`; the greys go through `gh_print`. Only ink-only layers move ("only ink moves; the grey never does").

Files (all in `assets/sprites/story/bearers/bloom/`; the target above is the first, the test checks it):

| Frame | Caption (pt_BR, draft) | Base | Moving ink layers (`ink_only`, tileable, suggested drift px/s) |
|---|---|---|---|
| 1 | Ninguém plantava no inverno. Ela plantava assim mesmo. | `frame_1_base.png`: the old woman kneels in an empty snowy field and presses a green stalk into the snow | `frame_1_snow.png` (snow, drift 0,6) |
| 2 | Ela dizia que a terra escuta quem volta todo dia. | `frame_2_base.png`: she sits in the snow beside the grown stalk, singing, a hand over it | `frame_2_snow.png` (snow, drift 0,4) |
| 3 | Deixou o bosque com quem ia ficar. | `frame_3_base.png`: years later, a young wood; bent with age, she holds one stalk out to the wooden stag | `frame_3_petals.png` (petals, drift 3,4) |
| 4 | O caule nunca parou de crescer. | `frame_4_base.png`: the stag's twig hand holds the stalk, still green; she is gone | `frame_4_petals.png` (petals, drift 2,3) |

Made by Codex image generation (codex-consult image mode, 2026-11-13): a first 2x2 board (`tools/art/sources/story/bearers/bloom/board_2x2_codex.png`, panels drawn 1.5:1, too tall to crop to the canvas) was given back as the look reference for a portrait board of four wide strips (`board_codex.png`), with our own guardian stills (`guardians_ref.png`, the four restored frame 0s enlarged) as the stag's reference. Prompt: the LOOK/LAYOUT block of `tools/art/sources/story/bearers/prompt_style.txt` with the ink "a fresh leaf GREEN (#3c9a32)", then the four panels of `tools/art/sources/story/bearers/bloom/frames.txt`.
Cut: `python -I tools/art/cut_engraving.py board tools/art/sources/story/bearers/bloom/board_codex.png assets/sprites/story/bearers/bloom --ink=#3c9a32` (panels in reading order, centred crop to the canvas aspect, ink by hue at full size then by 30% area cover, greys by area mean snapped to `GREYS` and median-filtered). Moving layers: `python -I tools/art/cut_engraving.py motes <out> snow --count=70 --seed=11` (frame 1), `snow --count=45 --seed=12` (2), `petals --count=40 --seed=13` (3), `petals --count=28 --seed=14` (4).
Negative: text, letters, signature, black ink, white highlights, second ink colour, soft gradients, blur, frame border
