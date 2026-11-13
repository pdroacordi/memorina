---
id: story_bearer_frost
command: generate
target: res://assets/sprites/story/bearers/frost/frame_1_base.png
size: 384x176
frames: 1
view: side
no_background: false
source: codex
---
STORY-04 bearer fragment, winter: the petrified branch, "a mão de inverno" (design `drafts/camada_pessoal.md` §3; plan `docs/knowledge/architecture/story-04-bearer-fragments.md`, "The look" and "Art"). Four engraved frames of one memory, each an opaque canvas of 384x176 art px (1 px per art px, drawn at Sprite2D scale 2: 768x352 game px; the view between the bars is 320x144 art px, so a pan reaches 64x32). Every canvas holds only the four neutral greys of `tools/art/cut_engraving.py` (`GREYS`: #3c3c3c, #606060, #8c8c8c, #b8b8b8) and the key ink #FF00FF, which `engraving.gdshader` tints with the song's `SeasonPalette`; the greys go through `gh_print`. Only ink-only layers move ("only ink moves; the grey never does").

Files (all in `assets/sprites/story/bearers/frost/`; the target above is the first, the test checks it):

| Frame | Caption (pt_BR, draft) | Base | Moving ink layers (`ink_only`, tileable, suggested drift px/s) |
|---|---|---|---|
| 1 | A aldeia do outro lado não tinha ponte, e o inverno chegava tarde. | `frame_1_base.png`: night, a wide dark lake, the village on the far shore, no bridge, a thin moon | `frame_1_flakes.png` (flakes, drift 0,3) |
| 2 | Ele não sabia nadar. Sabia esperar o frio. | `frame_2_base.png`: the man with a lantern plays the branch at the shore; ice slabs spread step by step under his feet | `frame_2_flakes.png` (flakes, drift 0,4) |
| 3 | Fez a estrada por um inverno inteiro. | `frame_3_base.png`: dusk; villagers with bundles (a child on a shoulder) follow him across the ice road | `frame_3_snow.png` (snow, drift 8,3: a crosswind) |
| 4 | Quando parou de andar, deixou o caminho onde estava. | `frame_4_base.png`: old, he kneels and pushes the branch into the ice; the stone-and-ice golem reaches to take it | `frame_4_flakes.png` (flakes, drift 0,3) |

Made by Codex image generation (codex-consult image mode, 2026-11-13), one portrait board of four wide strips (`tools/art/sources/story/bearers/frost/board_codex.png`) with the approved spring board (`bloom/board_codex.png`) as the look reference and our own guardian stills (`guardians_ref.png`) for the golem. Prompt: the LOOK/LAYOUT block of `tools/art/sources/story/bearers/prompt_style.txt` with the ink "a cold winter BLUE (#2f6fd0)", then the four panels of `frost/frames.txt`.
Cut: `python -I tools/art/cut_engraving.py board tools/art/sources/story/bearers/frost/board_codex.png assets/sprites/story/bearers/frost --ink=#2f6fd0 "--shift=3:-110,0;4:-50,0"` (frames 3 and 4 moved left so the walkers and the kneeling man stay inside). Moving layers: `motes <out> flakes --count=30 --seed=21` (1), `flakes --count=40 --seed=22` (2), `snow --count=80 --seed=23` (3), `flakes --count=35 --seed=24` (4).
Negative: text, letters, signature, black ink, white highlights, second ink colour, soft gradients, blur, frame border
