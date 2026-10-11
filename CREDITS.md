# Credits

Third-party art used in Memorina, with the terms it was taken under.

## World

- **Ground tiles and backgrounds** (`assets/sprites/world/tilesets/legacy/earth.png` and
  `stone.png`, `assets/sprites/world/background/`) - from the *FREE Platformer Assets* pack by
  **GandalfHardcore**, https://gandalfhardcore.itch.io/. Licence (the pack's READ ME):
  use in commercial and non-commercial games and modification allowed; reselling,
  repackaging or redistributing the assets, AI training, NFT use and inclusion in game
  development tools are prohibited. The legacy sheets are the pack's floor tiles (earth, and
  stone derived from the earth) rearranged into corner-Wang quarters by
  `tools/art/assemble_tile_sheet.gd --from-blob` (WORLD-07). Pack art is never uploaded to an
  image generator as a reference (the AI-training clause). `legacy/wood.png` and `wall.png`
  are flat placeholders drawn by the same tool.

- **Village fronts, the door and the village backdrop** (`assets/sprites/world/props/village/` but the bell tower's front, `assets/sprites/world/props/door/door.png`, `assets/sprites/world/background/village_valley/`) - Codex image generation from the prompts in `tools/art/prompts/`, with our approved concept and our own village tiles as the only references; the raw pictures are kept in `tools/art/sources/` and cut by `tools/art/cut_facades.py` and `tools/art/cut_backdrop.py` (the sky is drawn by the latter).

- **Region fronts and doorways** (`assets/sprites/world/props/{spring_woods,threshold,frozen_lake,wind_orchards,frost_edge}/`, `assets/sprites/world/props/door/door_{passage,stairwell,hatch_up,hatch_down}.png`) - Codex image generation with our approved village concept and our own village fronts and door as the only references; kept in `tools/art/sources/{region_facades,doorways,stairwell}_codex.png` and cut by `tools/art/cut_facades.py`.
- **Villagers and animals** (`assets/sprites/world/inhabitants/`) - stills from one Codex sheet (our concept and our village fronts as the only references, `tools/art/sources/village_people_codex.png`), idle loops PixelLab-generated (`animate-with-text-v3`) from those stills, cut by `tools/art/cut_inhabitant.py`.

- **The bell tower's bell, palette and front** (`assets/sprites/world/props/helix_stair/bell_tower_bell.png`, `resources/world/helix/bell_tower_look.tres`, `assets/sprites/world/props/village/bell_tower_facade.png`) - one Codex style board (`tools/art/sources/bell_tower_board_codex.png`; our approved village concept, our placeholder stair and our short tower front as the only references): the bell cut by `tools/art/cut_board_prop.py`, the turning tower's colours sampled from it, the tall front cut from its right panel by `tools/art/cut_facades.py`.
- **Interior props** (`assets/sprites/world/props/interiors/`) - Codex image generation: one sheet per room (`tools/art/sources/interiors/<sheet>_props_codex.png`, redrawn 2026-10-11 in the flat style; the empty house's cobweb is from `empty_house_props_codex_v1.png`), drawn from its approved Codex room board with our Ivo still as the scale figure (our own art the only references), cut by `tools/art/cut_props.py`; chimneys stretched by `tools/art/stretch_prop.py`.
- **Village plank tiles** (`tools/art/tiles/sources/village_planks_*.png`) - painted by `tools/art/tiles/paint_planks.py` in the colours of the PixelLab tiles-pro plank body they replace (2026-10-11).

- **Cave, strata and interior backdrops** (`assets/sprites/world/background/{village_strata,earth_caves,ice_caves,basalt_caves,interior_timber,interior_stone}/`) - Codex image generation (no reference image), kept in `tools/art/sources/backdrop_*_codex.png` and cut by `tools/art/cut_wall.py`.

- **Village ground** (`assets/sprites/world/tilesets/village/`) - the soil and cobble textures are Codex
  image generation reduced to 16 px, the planks and plaster-and-timber are PixelLab-generated
  (tiles-pro); all are kept in `tools/art/tiles/sources/`,
  styled from our approved concept `tools/art/references/village_concept.png` (Codex); the
  dual-grid shapes and the season lips are drawn by `tools/art/assemble_tile_sheet.gd` from the
  recipes in `tools/art/tiles/village_*.json` (`WangSheet`); the secret walls' crack decals (`crack.png`, here and in
  `legacy/`) are drawn by `tools/art/draw_cracks.gd`.

- **Props** (`assets/sprites/world/props/`: pressure plate, stone gate, lift, seesaw plank
  and fulcrum, drawbridge, hanging cocoon, root strand, fallen log, the rest bench, the door) - generated for this project with
  Codex CLI's image tool from the prompts in `tools/art/prompts/`, then keyed, snapped to
  the world palette and packed by `tools/art/process_image.gd`. No third-party art was
  given as a reference. The village concept painting `tools/art/references/village_concept.png` (the
  approved look, `tools/art/prompts/style.md`) is Codex image generation too. `leaf_wall.png`, the foreground placeholders in `assets/sprites/world/foreground/demo/` (drawn by a script, 2026-10-09), the wind gust and dash, the rain splashes and the HUD's
  life note (`assets/sprites/hud/life/life_note.png`) are drawn by `tools/art/draw_procedural_sprites.gd`.

## Ivo

- **Ivo's body** (`assets/sprites/characters/ivo/`, every sheet) - generated for this project from our own approved
  still (`tools/art/sources/ivo/ivo_still_2x.png`, cut from a Codex CLI image, `ivo_lineup_codex.png`). The seated,
  wall-cling, climbing, back-view, lying, guard and air-guard poses are one Codex image drawn beside that still
  (`ivo_poses_codex.png`); every clip but the attacks is PixelLab animate-with-text-v3 from the still or a pose, cut by
  `tools/art/cut_inhabitant.py`. The attacks are Codex key poses drawn beside the same still
  (`ivo_attack_poses_ground_codex.png`, `ivo_attack_poses_air_codex.png`) with smears drawn by
  `tools/art/build_ivo_attacks.py` (contracts `tools/art/prompts/ivo_*.md`). No third-party art was given as a reference.
  The ZeggyGames *2D Pixel Art Character Template Asset Pack* sheets these replace are no longer in the project; that
  licence forbids AI training, so they were never uploaded to a generator.

## Particles

- **Jump and landing dust** (`assets/sprites/particles/dust/`) - `land_dust_256x256.png`
  is pixel-identical to `landdust-64x32.png` in the local `Free Assets/Textures` folder,
  which also holds Cainos' *Pixel Art Platformer - Village Props*
  (https://cainos.itch.io/pixel-art-platformer-village-props; free and commercial use,
  no redistribution). That pack's page does not list dust effects, so their origin is
  **unconfirmed**: find the source before shipping, or replace them.

## Guardians

- **Frost Guardian** (`assets/sprites/characters/guardians/frost_guardian/`) —
  *Boss: Frost Guardian* by **chierit**, https://chierit.itch.io/boss-frost-guardian.
  Licensed [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/): frames from
  the free tier, stitched into per-clip strips; otherwise unmodified.
- **Bloom Guardian** (`assets/sprites/characters/guardians/bloom_guardian/`) —
  the two-headed flower from *Free Forest Bosses Pixel Art* by **Free Game Assets
  (Craftpix)**, https://free-game-assets.itch.io/free-forest-bosses-pixel-art-sprite-sheet-pack,
  under the [Craftpix free licence](https://craftpix.net/file-licenses/) (commercial
  use permitted, redistribution of the source files is not).

## UI

- **Key prompts, frames and banners** (`assets/sprites/hud/memorina/input_*.png`,
  `assets/sprites/hud/input/` - the keyboard, D-pad, stick, Xbox and PlayStation glyphs, the save quill `assets/sprites/hud/save/kept_quill.png`,
  `assets/sprites/hud/recall/`, the menu panel, banner and buttons `assets/sprites/hud/menu/`,
  the notebook's spellbook, its open and page-turn strips, right tabs 01-04 and mini icons 15, 16, 20,
  23 `assets/sprites/hud/notebook/`,
  the `memorina_*` fonts) — from the *RPG UI pack* by
  **Franuka**, https://franuka.itch.io/ (free for commercial use; a link back is asked for).
  Modified: `memorina_text_font_size_8.ttf` redraws the tilde of ã õ ñ Ã Õ Ñ as a wave
  (`tools/fonts/patch_tilde.py` rebuilds it from the pack original).
- **Title logo** (`assets/sprites/hud/title/memorina_logo.png`) - generated for this project with
  Codex CLI's image tool from `tools/art/prompts/memorina_logo.md`, then keyed, snapped to the world
  palette and shrunk by `tools/art/process_image.gd`. No third-party art was given as a reference.
