# Dressing the three guardian regions: Frozen Lake, Wind Orchards, Summer Caldera (proposal board)

Request (user, 2026-11-20): "work now from /feature-loop world-15 to 17". Roadmap WORLD-15, WORLD-16, WORLD-17.

Status: approved (user, 2026-11-20): scope "sure" (every room as listed, arenas and puzzle rooms lightly); people "yes" (the fisherman, the innkeeper and a miller, idle loops, no talk); WORLD-37 and WORLD-38 folded into WORLD-16 "yes"; the burned shadows "your proposition" (the lion's own scorched silhouettes); the concepts "approved".

The tiles, backdrops and palettes of the three regions are already approved (`tools/art/references/regions/board_frozen_lake.png`, `board_wind_orchards.png`, `board_summer_caldera.png`, WORLD-30). This board adds what WORLD-11 gave the village: the props, what moves on the memory clock, the people, and the foreground. Concepts (Codex, our own art, no characters): `tools/art/sources/regions/dressing_<region>_concept_codex.png`.

## How it is built (WORLD-11's pipeline)

1. The user approves this board and the three concepts.
2. Codex draws one prop sheet per region on magenta (the village's `street_*_codex.png`), cut by `tools/art/cut_props.py` at sizes measured against Ivo's 29 art px (`tools/art/<region>_prop_sizes.json`), palette-snapped. Nature props get three season bands (`prop_seasonal_material.tres`); built props one.
3. What moves is a short loop through `AmbientMotion` (stops below memory 0.2): PixelLab `animate-with-text-v3` for cloth and nets, baked rotation (`RotationBake`) for windmill sails, drawn frames for embers. The user approves each sheet before it is placed.
4. Props are `Sprite2D` scenes under each room's `Props` (z -10); they never collide and never cover a gameplay cell, a jump line or a fight floor. `prop_grounding_test` checks every grounded prop stands on a ground cell.
5. Foreground (hanging ice, leaves, burned roots) goes in `ForegroundPass` only, at the room's top edge, never over a ledge Ivo lands on.

Regions run one at a time, each its own commit: Lake, then Orchards, then Caldera.

## WORLD-15 Frozen Lake (winter, memory 0.3, a dead lake)

**Sheet (built, one band):** frozen rowing boat with oars, broken pier stub, fish-drying rack (empty and hung with fish), nets on poles, eel traps, barrels, crates, rope coil, sled, ice-fishing hole with a stool and line, stone cairn, lantern on a post, the fisher hut's woodpile.
**Sheet (nature, three bands):** snow drifts (exists: `snow_drift`), frozen reeds, dead shrub, snowy rock, icicle clusters (wall and ceiling, three lengths).
**Moves:** the nets and a hung cloth sway (6 frames); the lantern flame (3); smoke from the hut chimney (8, the village's loop).
**People:** the fisherman (design 04 §5 lists him) in his hut, an idle loop like the village's (no talk). Question 2.
**Foreground:** icicle fringes on the cave rooms' ceilings.

| Room | Dressing |
|---|---|
| lake_fishing_village | Keeps its 22 pier posts and the hut front. Adds: the drying racks and nets on the deck (cols 9-34, 47-58), barrels and traps by the hut, a frozen boat in the lake under the deck, a lantern post at the landing, smoke from the hut. |
| lake_fisher_hut | Interior from its own small board, like the village interiors: nets on the wall, a stove, bunk, barrels, dried fish, a table with a mended net; the fisherman. |
| lake_shore | The open lake: two frozen boats on the far ice (under the causeway, never on the freezable pool's surface line), a broken pier at the east bank, a cairn on the west bank, reeds and drifts. |
| lake_waterfall_path | Icicles on the side walls between steps, a snow drift at the bench, a rope and a hanging lantern near the top opening. |
| lake_well | Icicles on the back wall above the ledge, an old bucket and rope near the hatch; nothing inside the squall box or the sealed chamber. |
| lake_high_wall | Icicles on the west face above the water, frozen moss on the east ledges' faces. |
| lake_chasm | Frost on the earth lips, roots hanging into the cleft (they read toward Enraizar), the border cairn kept. |
| lake_ice_caves | Ice formations on the floor at cols 1-8 and 32-38, icicles on the ceiling away from the two bats. |
| lake_frost_arena | Only the edges: ice columns on the shoulders and wall faces, a ring of icicles on the ceiling; the floor and the air stay empty. |
| lake_glacier | Icicles over the pool, a crevasse line on the back wall; the flashback's west lip stays clear. |
| lake_icefall | Icicles on the two shaft walls; the shaft is not narrowed. |

## WORLD-16 Wind Orchards (autumn, memory 0.25, windmills turning with memory)

**Sheet (built, one band):** small post windmill (sails baked, 4 sails), weather vane, hand cart of pears, crates and baskets of apples and pears, ladder, hay bales, sacks, fence runs, dry-stone wall caps, a well head, a signpost, a scarecrow (plain straw, not the guardian's bone mask), a beehive.
**Sheet (nature, three bands):** apple tree (the pear tree exists), small fruit tree, haystack, bramble, leaf piles (exist), tall grass tufts, fallen fruit.
**Moves:** windmill sails (baked rotation, speed from memory), the weather vane (4), hanging cloth and the inn sign (4), leaves blowing past (6).
**People:** the innkeeper behind the inn counter (design 04 §3.6 "estalajadeiro"), and a miller in the mill town. Question 2.
**Foreground:** branches with leaves at the top edges of the open rooms.
**Folded in:** WORLD-37 (the great windmill on orchard_summit's crest, a large baked prop) and WORLD-38 (vines and claw marks on orchard_arena's east face, the hint that it climbs). Question 3.

| Room | Dressing |
|---|---|
| orchard_mill_town | Two small windmills on the sky band (cols 1-58, rows 0-4) behind the street, fruit trees, hay bales, a cart of pears at the bench, crates by the inn, a signpost at the west end, a well head over the Hollow Tree well (posts on its lips), a fence along the lower street. The drawbridge swing stays clear. |
| orchard_inn | Interior from its own board: a smaller tavern, cider barrels, hanging herbs and pears, a fire, tables, the innkeeper. |
| orchard_terraces | Apple trees on the terraces, ladders, baskets, hay; the bench with a cart. |
| orchard_leaf_path | Trees whose fallen leaves make the leaf curtain read as theirs, bramble at the path's edges. |
| orchard_windy_gap | Keeps its pear tree; a weather vane on the east floor, leaves blowing west in the wind zone (backdrop depth only). |
| orchard_counterweights | Mill gear and a pulley wheel on the upper chamber's wall, sacks on the floors, rope coils. |
| orchard_summit | The great windmill (WORLD-37) on the crest beside the tor, hay and a fence on the slopes. |
| orchard_chasm_bridge | A wooden signpost, a fallen fence at the chasm's lip, a fruit tree on the mound. |
| orchard_crag | Hanging vines on the faces, a nest on the spire; WORLD-39 (natural rock tiles) stays its own item. |
| orchard_ridge | Hay bales and a fence on the steps, a fruit tree on the hill top by the letter. |
| orchard_well | A wooden frame and pulley over the pit, crates on the west floor. |
| orchard_arena | Only the edges: the east face's vines and claw marks (WORLD-38), dry leaf drifts in the corners; the fight floor stays empty. |
| orchard_cliff_chimney | Roots and a few vines in the lower pocket; the shaft stays bare rock. |

## WORLD-17 Summer Caldera (summer, memory 0.15, underground sun temple)

**Sheet (built, one band):** sandstone temple column (whole and broken, with its fallen drum), bronze brazier on a tripod, seated sun statue, sun-disk relief (back wall), carved lintel fragment, pottery shards, offering bowls, a toppled statue head, rubble.
**Sheet (nature, one band: underground, no seasons):** ash heaps (`ash_heap.png` exists, waiting), burned roots hanging from cracks, cinder piles, dry thorn shrubs at the open crater.
**Moves:** embers drifting from the braziers (3 frames, small, no glow).
**People:** none (an abandoned temple).
**The burned shadows** (GRD-04: "a lion of porous volcanic stone whose shadow stays burned on the ground"; "sombra depois", user, 2026-10-30): the lion's own silhouette scorched into caldera_arena's back wall and floor edge where it lay for years, two or three poses (lying, standing, roaring), black char at low contrast so the fight reads over them. Decals under `Props`, never on the floor line Ivo reads. Question 4.
**Foreground:** burned roots hanging from the ceilings' top edge.

| Room | Dressing |
|---|---|
| caldera_arena | The lion's burned shadows, two braziers and two columns at the walls, a sun-disk relief on the back wall; the floor stays empty. |
| caldera_temple_gate | The temple front: columns flanking the terrace, a carved lintel, the sun statue under the terrace's west end. |
| caldera_open_crater | Thorn shrubs and ash on the rim tops, a broken column on the cap platform's side, braziers by the bench. |
| caldera_long_corridor | A colonnade: whole and broken columns at its three pillars, statues in the alcove, shards on the floor. |
| caldera_chimney_base | Ash heaps, burned roots coming down the chimney, a brazier at the bench. |
| caldera_sun_stair | Sun reliefs between the shelves, a broken statue at the foot by the shrine niche. |
| caldera_cistern_bottom | Fallen columns, offering bowls on the dais, roots on the pillars. |
| caldera_seesaw, caldera_bait, caldera_dry_moat | Light: rubble and one or two columns on the back walls; ash and bones in the scorpion's tunnel (bait). The puzzle parts stay the only things that read as usable. |
| caldera_cistern | Village-side well shaft: a bucket, a frayed rope, moss over the water. |

## Questions for the user

1. **Scope.** Every room as listed (the arenas and puzzle rooms lightly), or only the main rooms first (the villages, the arenas, the benches' rooms)?
2. **People.** Add the fisherman (Frozen Lake) and the innkeeper and a miller (Wind Orchards), idle loops with no talk like WORLD-10? The Caldera stays empty.
3. **Fold in WORLD-37 and WORLD-38** (the great windmill, the hint on the arena's east face) into WORLD-16?
4. **The Sun Guardian's burned shadows:** the lion's own scorched silhouettes on the arena's wall and floor edge (proposed), or something else?
5. **The concepts:** approve the look of each region's concept, or what to change.
