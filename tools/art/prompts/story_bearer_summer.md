---
id: story_bearer_summer
command: generate
target: res://assets/sprites/story/bearers/summer/frame_1_base.png
size: 384x176
frames: 1
view: side
no_background: false
source: codex
---
STORY-04 bearer fragment, summer: the pierced stone, "a mão antiga" (design `drafts/camada_pessoal.md` §3; plan `docs/knowledge/architecture/story-04-bearer-fragments.md`, "The look" and "Art"). Four engraved frames of one memory, each an opaque canvas of 384x176 art px (1 px per art px, drawn at Sprite2D scale 2: 768x352 game px; the view between the bars is 320x144 art px, so a pan reaches 64x32). Every canvas holds only the four neutral greys of `tools/art/cut_engraving.py` (`GREYS`: #3c3c3c, #606060, #8c8c8c, #b8b8b8) and the key ink #FF00FF, which `engraving.gdshader` tints with the song's `SeasonPalette`; the greys go through `gh_print`. Only ink-only layers move ("only ink moves; the grey never does").

Files (all in `assets/sprites/story/bearers/summer/`; the target above is the first, the test checks it):

| Frame | Caption (pt_BR, draft) | Base | Moving ink layers (`ink_only`, tileable, suggested drift px/s) |
|---|---|---|---|
| 1 | Ela era velha quando a montanha ainda fumava. | `frame_1_base.png`: noon in the caldera, the sun high, the very old woman sitting still on a flat stone, a thin smoke far off | `frame_1_embers.png` (embers, drift 0,-3) |
| 2 | Segurava o dia mais longo para quem precisava de mais tempo. | `frame_2_base.png`: the sun stopped overhead; she plays a pipe; her shadow burned dark on the stone, heat ripples | none: the stopped noon holds still |
| 3 | Ninguém viu quanto tempo levou. Ela tinha tempo. | `frame_3_base.png`: close, her old hands bore a round volcanic stone with a thorn; sun and moon marks on the stone count the days | `frame_3_embers.png` (embers, drift 1,-2) |
| 4 | Ficou a sombra. Isso basta para o verão. | `frame_4_base.png`: the volcanic lion lies with the holed stone between its paws; her seated shadow, playing, stays on the stone with nobody casting it | none |

Made by Codex image generation (codex-consult image mode, 2026-11-13), two calls: the first board (`tools/art/sources/story/bearers/summer/board_v1_codex.png`) was busy (dense hatching on every crater wall) and its shadow in frame 4 was a small blob, so it was given back with the approved winter board (`frost/board_codex.png`) and our own guardian stills (`guardians_ref.png`) for a calmer redraw with a large seated shadow (`summer/board_codex.png`, kept). Prompt: the LOOK/LAYOUT block of `tools/art/sources/story/bearers/prompt_style.txt` with the ink "a deep sun-gold OCHRE (#c8820a)", then the four panels of `summer/frames.txt`. Codex filled the figures in pale cream, which the raised least chroma leaves as paper.
Cut: `python -I tools/art/cut_engraving.py board tools/art/sources/story/bearers/summer/board_codex.png assets/sprites/story/bearers/summer --ink=#c8820a "--shift=4:-40,0" --chroma=0.3` (frame 4 moved left so the shadow stays inside; the lion's tail falls outside the canvas). Moving layers: `motes <out> embers --count=24 --seed=41` (1), `embers --count=16 --seed=43` (3).
Negative: text, letters, signature, black ink, white highlights, second ink colour, soft gradients, blur, frame border
