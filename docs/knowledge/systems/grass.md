---
id: systems/grass
type: system
title: Generated grass - blades on every grassy top, bent by characters and swayed on the memory clock, frozen in the grey
status: active
tags: [grass, blades, shader, spring, memory-clock, stopped-time, seasonal-art, world-23]
related: [architecture/generated-grass, systems/props, systems/greyhush, systems/seasonal-art, systems/rooms, systems/foreground]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/environment/grass/
  - resources/world/grass/
  - resources/world/tiles/biome_tileset.gd
  - scenes/world/rooms/maps/room_map_node.gd
---

# Generated grass

**Never break:** grass moves only on its cell's memory clock and holds exactly below `AmbientMath.STOP_THRESHOLD` (0.2); it never collides and nothing reads it back; it is derived from the map, never authored. `MAX_BLADE_ART` in `GrassLook` and `grass_blades.gdshader` is one bound: change both.

Design 04 section 1 ("Grama gerada"): "What if the grass was generated instead of pixels? it moves when int contact with the player." (user, 2026-10-10); "Freeze in the grey (Recommended)". Plan and options: `architecture/generated-grass`.

- **Where.** `GrassPlacement.runs(map, grows)` (pure) finds every exposed top whose drawn look has a `GrassLook` in the room's biome (`BiomeTileset.grass(look)`): the cell above is air, holds no water or reach, and is not a secret. Consecutive tops of one look are a `GrassRun`; an end beside air is open (its rounded corner stays bare), an end at the map edge, against ground or beside a secret is closed. Built when the room builds, never imported.
- **Nodes.** `RoomMapNode` adds a `Grass` child (`GrassField`) after `Ledges` and before `Solid` when there are runs, outside the editor. Per run: a back `GrassStrip` in the root canvas (z 0: greyed, reflected, under water) and, when `front_share` > 0, a front strip joined to `ForegroundPass` so blades stand over Ivo's feet.
- **Motion.** A spring per 4 px segment (`GrassSprings`, pure) steps at `delta * rate`, where the rate is the cell's memory (sampled every 3 physics frames) and 0 below the stop threshold: bend and velocity hold exactly, and resume from that pose. `GrassContact` (pure) leans each segment away from a body standing on its walk line; a body in grey grass pushes nothing. Each cell's two sway clocks advance on the same rate and reach the shader as phases.
- **Drawing.** `grass_blades.gdshader` draws one-art-pixel blades on the world-anchored 2x grid: a blade roots where an integer hash of its art column is under the band's density; its height, stiffness and sway phase come from more hashes, its bend from its segment. Season band per game pixel from the season mask, like the tiles: spring and summer green, autumn dry, winter none (the snow lip shows). No `TIME`, no `FRAGCOORD`, alpha 0 or 1.
- **The tile lip.** A grass look's spring lip is a turf: `"max_blade": 1` in its recipe. The blade palette (`<look>_blades.png`, a row per band) is written by `assemble_tile_sheet.gd` from the recipe (`"grass": true`; spring the grass lip's greens, autumn the litter lip's `blades`).
- **Cost.** A run off screen, or with nothing to move, does nothing; positions are cached at ready; a body's push is worked out only while it stands in the run's contact band. The clip gives way sideways by a blade's lean, so a tip may cross a room seam.
- **Process.** `GrassField` inherits its process mode, so a deactivated room's DISABLED reaches it, and it returns while hidden. It stops under a performance freeze and a menu hold, like props. Its state lives in the contents: eviction or a death rebuild resets blades upright.
- **Indoors** (2026-10-10). An interior grows no grass: `RoomMapNode` skips `_grow_grass` when its `Room` is `interior`, whatever the floor (a cellar's earth banks keep their roots, `bugs/the-tavern-cellar-lost-its-enraizar-secret-to-stone`). The village houses and, since 2026-10-13, the four region interiors (threshold_farmhouse, woods_hut, lake_fisher_hut, orchard_inn) are built of wood (`%`, `-`), so they show no turf lip; earth stays where a song needs it. Indoors the tiles draw band 0 in every season (`systems/seasonal-art`), so planks never carry a snow or leaf lip either.
- **Today.** The village biome's earth (spring 0.7, 3-7 art px; autumn 0.45, 2-5) and stone (0.25, 1-3; 0.15, 1-2); the threshold, spring_woods, frozen_lake and wind_orchards biomes grow grass on earth and stone (`resources/world/grass/<biome>_<look>_grass.tres`, WORLD-07); frost_edge, lighthouse and the two caldera biomes grow none. No room uses `legacy` any more. Wind does not bend grass yet.
