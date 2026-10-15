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
  are flat placeholders drawn by the same tool. **Unused in the game since 2026-10-13** (WORLD-07,
  WORLD-30): no room, trial, region or the title draws the pack's ground tiles or its forest
  backgrounds (`background/seasonal/`, `spring/`, `autumn/`, `winter/`, and their set
  `resources/world/backdrops/pine_woods.tres`); `biome_tileset_test` and `backdrop_set_test` fail if
  one does. The files stay on disk. What still reads them: the parser and `RoomMapNode` test
  fixtures (`tileset = legacy`, through `resources/world/tiles/biomes/legacy.tres`), and the dev
  tools `tools/art/extract_palette.gd` (local palette sampling), `tools/stack_seasonal_sheets.gd`
  (rebuilds `background/seasonal/`) and `assemble_tile_sheet.gd --from-blob`.

- **Village fronts, the door and the village backdrop** (`assets/sprites/world/props/village/` but the bell tower's front, `assets/sprites/world/props/door/door.png`, `assets/sprites/world/background/village_valley/`) - Codex image generation from the prompts in `tools/art/prompts/`, with our approved concept and our own village tiles as the only references; the raw pictures are kept in `tools/art/sources/` and cut by `tools/art/cut_facades.py` and `tools/art/cut_backdrop.py` (the sky is drawn by the latter).

- **The village gate tower** (`assets/sprites/world/props/village/gate_tower.png`, WORLD-30) - one Codex image generation (our bell tower and tavern fronts and our approved village concept the only references), kept in `tools/art/sources/village/gate_tower_codex.png` and cut by `tools/art/cut_single_prop.py` in the colours of those two fronts.
- **The lake border cairn** (`assets/sprites/world/props/frozen_lake/border_cairn.png`, WORLD-33) - one Codex image generation (our frozen_lake stone tiles, lake_cliff_rock wall and gate tower the only references), kept in `tools/art/sources/frozen_lake/border_cairn_codex.png` and cut by `tools/art/cut_single_prop.py` in the colours of the lake's stone tiles and the fisher hut.
- **The village gate, the orchard bramble barrier and the leaf curtain** (`assets/sprites/world/props/fact_barrier/fact_barrier.png`, `assets/sprites/world/props/wind_orchards/bramble_barrier.png`, `assets/sprites/world/props/wind_orchards/leaf_curtain.png`, WORLD-36) - one Codex image generation each (our village fence and gate tower, our orchard tiles and backdrop and the wind leaf the only references), kept in `tools/art/sources/village/` and `tools/art/sources/wind_orchards/` and cut by `tools/art/cut_single_prop.py`.
- **The woods root wall** (`assets/sprites/world/props/spring_woods/root_wall.png`, TECH-08) - one Codex image generation (our Bloom Woods earth tiles, woods backdrop and the orchard bramble barrier the only references), kept in `tools/art/sources/spring_woods/root_wall_codex.png` and cut by `tools/art/cut_single_prop.py`.
- **The heartwood wall** (`assets/sprites/world/background/heartwood/far.png`, WORLD-35) - one Codex image generation (our earth caves wall the only reference), kept in `tools/art/sources/backdrop_heartwood_codex.png` and cut by `tools/art/cut_wall.py`.
- **The icefall snow drift** (`assets/sprites/world/props/frozen_lake/snow_drift.png`, WORLD-35) - one Codex image generation (our frozen_lake stone tiles, threshold earth tiles and border cairn the only references), kept in `tools/art/sources/frozen_lake/snow_drift_codex.png` and cut by `tools/art/cut_single_prop.py`.
- **The orchard leaf pile** (`assets/sprites/world/props/wind_orchards/leaf_pile.png`, WORLD-35) - one Codex image generation (our snow drift, leaf curtain and orchard earth tiles the only references), kept in `tools/art/sources/wind_orchards/leaf_pile_codex.png` and cut by `tools/art/cut_single_prop.py`.
- **The caldera ash heap** (`assets/sprites/world/props/summer_caldera/ash_heap.png`, WORLD-35) - one Codex image generation (our snow drift and Summer Caldera ash and basalt tiles the only references), kept in `tools/art/sources/summer_caldera/ash_heap_codex.png` and cut by `tools/art/cut_single_prop.py`.
- **The Frost Edge wreck hull and the ship's hold wall** (`assets/sprites/world/props/frost_edge/wreck_hull.png`, `assets/sprites/world/background/ship_hold/far.png`, WORLD-35) - one Codex image generation each (our fisher's hut front, Frost Edge stone tiles and heartwood wall the only references), kept in `tools/art/sources/frost_edge/wreck_hull_codex.png` and `tools/art/sources/backdrop_ship_hold_codex.png` and cut by `tools/art/cut_single_prop.py` and `tools/art/cut_wall.py`.
- **The village street grate** (`assets/sprites/world/props/fact_barrier/street_grate.png`, WORLD-35) - drawn by a script, `tools/art/draw_street_grate.py`, from no reference: iron bars in the fact barrier's iron colours and stone end blocks in the village cobble colours (`assets/sprites/world/tilesets/village/stone.png`), both our own art.
- **Region fronts and doorways** (`assets/sprites/world/props/{spring_woods,threshold,frozen_lake,wind_orchards,frost_edge}/`, `assets/sprites/world/props/door/door_{passage,stairwell,hatch_up,hatch_down}.png`) - Codex image generation with our approved village concept and our own village fronts and door as the only references; kept in `tools/art/sources/{region_facades,doorways,stairwell}_codex.png` and cut by `tools/art/cut_facades.py`.
- **Villagers and animals** (`assets/sprites/world/inhabitants/`) - stills from one Codex sheet (our concept and our village fronts as the only references, `tools/art/sources/village_people_codex.png`), idle loops PixelLab-generated (`animate-with-text-v3`) from those stills, cut by `tools/art/cut_inhabitant.py`.

- **The bell tower's bell, palette and front** (`assets/sprites/world/props/helix_stair/bell_tower_bell.png`, `resources/world/helix/bell_tower_look.tres`, `assets/sprites/world/props/village/bell_tower_facade.png`) - one Codex style board (`tools/art/sources/bell_tower_board_codex.png`; our approved village concept, our placeholder stair and our short tower front as the only references): the bell cut by `tools/art/cut_board_prop.py`, the turning tower's colours sampled from it, the tall front cut from its right panel by `tools/art/cut_facades.py`.
- **Interior props** (`assets/sprites/world/props/interiors/`) - Codex image generation: one sheet per room (`tools/art/sources/interiors/<sheet>_props_codex.png`, redrawn 2026-10-11 in the flat style; the empty house's cobweb is from `empty_house_props_codex_v1.png`), drawn from its approved Codex room board with our Ivo still as the scale figure (our own art the only references), cut by `tools/art/cut_props.py`; chimneys stretched by `tools/art/stretch_prop.py`.
- **Village street props and the two new interiors** (WORLD-11, 2026-10-13; `assets/sprites/world/props/village/` street props, `mill_house_facade.png`, `notes_house_facade.png`, `assets/sprites/world/props/interiors/{notes_house,mill_house}/`) - Codex image generation: three street sheets, the house of notes' front, the well head and two prop sheets per new interior (`tools/art/sources/village/*_codex.png`, `tools/art/sources/interiors/{notes_house,mill_house}_{board,props,props2}_codex.png`; our Ivo still, our village fronts, our approved concept and our own interior boards the only references), cut by `tools/art/cut_props.py` and `tools/art/cut_facades.py`. The lantern post, wall lantern, cart, tavern sign, barrel, crate and chopping block were redrawn at their exact size by PixelLab (pixflux, our own cut as the init image; raws in `tools/art/sources/village/pixellab/`), and the flag, bunting, laundry line and bush loops are PixelLab `animate-with-text-v3` from our stills. Procedural (our tools): lit panes, lantern flames, the sign's swing and chimney smoke (`tools/art/draw_ambient_frames.py`), the water wheel's and the mill gear's turn (`tools/art/bake_rotation.gd`), season bands (`tools/art/season_bands.py`), the picture notes, recipe and tally board (`tools/art/draw_pictograms.py`) and the bridge piles and the bunting's pole (`tools/art/draw_post.py`).
- **Pier posts** (WORLD-29, 2026-10-13; `assets/sprites/world/props/frozen_lake/pier_post.png`, `pier_post_foot.png`) - procedural, `tools/art/draw_post.py` (the village timber; the foot `--foot`).
- **Village plank tiles** (`tools/art/tiles/sources/village_planks_*.png`) - painted by `tools/art/tiles/paint_planks.py` in the colours of the PixelLab tiles-pro plank body they replace (2026-10-11).

- **Cave, strata and interior backdrops** (`assets/sprites/world/background/{village_strata,earth_caves,ice_caves,basalt_caves,interior_timber,interior_stone}/`) - Codex image generation (no reference image), kept in `tools/art/sources/backdrop_*_codex.png` and cut by `tools/art/cut_wall.py`. The crater set (`resources/world/backdrops/caldera_crater.tres`, WORLD-30) stacks the Summer Caldera region layers over the basalt wall; its rim (`summer_caldera/crater_rim.png`, WORLD-32) is drawn by `tools/art/draw_crater_rim.py` from the basalt wall's own pixels.

- **Village ground** (`assets/sprites/world/tilesets/village/`) - the soil and cobble textures are Codex
  image generation reduced to 16 px, the planks and plaster-and-timber are PixelLab-generated
  (tiles-pro); all are kept in `tools/art/tiles/sources/`,
  styled from our approved concept `tools/art/references/village_concept.png` (Codex); the
  dual-grid shapes and the season lips are drawn by `tools/art/assemble_tile_sheet.gd` from the
  recipes in `tools/art/tiles/village_*.json` (`WangSheet`); the secret walls' crack decals (`crack.png`, here and in
  `legacy/`) are drawn by `tools/art/draw_cracks.gd`.

- **Region ground** (WORLD-07, 2026-10-13; `assets/sprites/world/tilesets/{threshold,frost_edge,lighthouse,spring_woods,frozen_lake,wind_orchards,summer_caldera}/`) -
  one Codex tile sheet per region (`tools/art/tiles/sources/<region>_tiles_codex_raw.png`; our five village tile
  bodies, enlarged, the only reference). The rock, woods and lake earth bodies are those Codex tiles reduced to 16 art
  px and quilted seamless by `tools/art/cut_tile_bodies.py` (the lake's stone is the Frost Edge rock recoloured, its
  planks our village planks recoloured); the other bodies are painted by `tools/art/paint_tile_bodies.py` from the specs
  in `tools/art/tiles/bodies/`, in colours sampled from those sheets. Sheets composed by
  `tools/art/assemble_tile_sheet.gd` from `tools/art/tiles/<region>_<look>.json`; cracks by `tools/art/draw_cracks.gd`.
  The approved style boards are in `tools/art/references/regions/` (our own art only).

- **Region backdrops and rock walls** (WORLD-07, 2026-10-13; `assets/sprites/world/background/{threshold,frost_edge,spring_woods,frozen_lake,wind_orchards,summer_caldera,sea_cliff_rock,lake_cliff_rock,orchard_limestone}/`) -
  Codex image generation, one strip per layer and one texture per wall (`tools/art/sources/<region>_<layer>_codex.png`,
  `tools/art/sources/backdrop_<wall>_codex.png`; our approved village concept, our village valley's spring band and
  our `ice_caves` and `earth_caves` walls the only references), cut by `tools/art/cut_backdrop.py` and
  `tools/art/cut_wall.py`. Every region set shares the village valley's sky.

- **Props** (`assets/sprites/world/props/`: pressure plate, stone gate, lift, seesaw plank
  and fulcrum, drawbridge, hanging cocoon, root strand, fallen log, the rest bench, the door) - generated for this project with
  Codex CLI's image tool from the prompts in `tools/art/prompts/`, then keyed, snapped to
  the world palette and packed by `tools/art/process_image.gd`. No third-party art was
  given as a reference. The village concept painting `tools/art/references/village_concept.png` (the
  approved look, `tools/art/prompts/style.md`) is Codex image generation too. The foreground placeholders in `assets/sprites/world/foreground/demo/` (drawn by a script, 2026-10-09), the wind gust and dash, the rain splashes and the HUD's
  life note (`assets/sprites/hud/life/life_note.png`) are drawn by `tools/art/draw_procedural_sprites.gd`.

## Ivo

- **Ivo's body** (`assets/sprites/characters/ivo/`, every sheet) - generated for this project from our own approved
  still (`tools/art/sources/ivo/ivo_still_2x.png`, cut from a Codex CLI image, `ivo_lineup_codex.png`). The seated,
  wall-cling, climbing, back-view, lying, guard and air-guard poses are one Codex image drawn beside that still
  (`ivo_poses_codex.png`); every clip but the attacks is PixelLab animate-with-text-v3 from the still or a pose, cut by
  `tools/art/cut_inhabitant.py`. The attacks are Codex key poses drawn beside the same still
  (`ivo_attack_poses_ground_codex.png`, `ivo_attack_poses_air_codex.png`) with smears drawn by
  `tools/art/build_ivo_attacks.py` (contracts `tools/art/prompts/ivo_*.md`). The run (2026-10-13) is PixelLab
  animate-with-text-v3 from the push-off pose of a Codex key-pose sheet drawn beside the same still
  (`tools/art/sources/ivo/run_keyposes/ivo_run_keyposes_codex.png`), its frames in `tools/art/sources/ivo/run_v5/`,
  cut and settled by `tools/art/build_ivo_run.py`. No third-party art was given as a reference.
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
