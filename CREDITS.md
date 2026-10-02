# Credits

Third-party art used in Memorina, with the terms it was taken under.

## World

- **Ground tiles and backgrounds** (`assets/sprites/world/tilesets/floor_tiles.png`,
  `assets/sprites/world/background/`) - from the *FREE Platformer Assets* pack by
  **GandalfHardcore**, https://gandalfhardcore.itch.io/. Licence (the pack's READ ME):
  use in commercial and non-commercial games and modification allowed; reselling,
  repackaging or redistributing the assets, AI training, NFT use and inclusion in game
  development tools are prohibited. The STONE half of `floor_tiles.png` (columns 9-17) is
  derived from the pack's earth tiles by `tools/art/derive_stone_tiles.gd`. Pack art is
  never uploaded to an image generator as a reference (the AI-training clause).

- **Props** (`assets/sprites/world/props/`: pressure plate, stone gate, lift, seesaw plank
  and fulcrum, drawbridge, hanging cocoon, root strand, fallen log, the rest bench) - generated for this project with
  Codex CLI's image tool from the prompts in `tools/art/prompts/`, then keyed, snapped to
  the world palette and packed by `tools/art/process_image.gd`. No third-party art was
  given as a reference. `leaf_wall.png`, the wind gust and dash, the rain splashes and the HUD's
  life note (`assets/sprites/hud/life/life_note.png`) are drawn by `tools/art/draw_procedural_sprites.gd`.

## Ivo

- **Ivo's body** (`assets/sprites/characters/ivo/`) - the *2D Pixel Art Character
  Template Asset Pack* by **ZeggyGames**, https://zegley.itch.io/2d-platformermetroidvania-asset-pack,
  scaled 2x. Licence (the pack's page): unlimited free and commercial projects,
  modification allowed; redistributing, reselling or sharing modified versions is not,
  and the art may not be used to train AI/ML models - so, like the GandalfHardcore
  packs, it is never uploaded to an image generator as a reference.

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
  `assets/sprites/hud/recall/`, the `memorina_*` fonts) — from the *RPG UI pack* by
  **Franuka**, https://franuka.itch.io/ (free for commercial use; a link back is asked for).
